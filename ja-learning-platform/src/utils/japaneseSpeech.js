import { Capacitor } from '@capacitor/core'
// Japanese TTS engine façade.
//
// - Synthesis runs in a Web Worker (ttsWorker.js) so the Kokoro WASM model
//   never blocks the main/UI thread.
// - Frequently used words are persisted in IndexedDB via ttsCache.js so the
//   second play is instant after the first generation.
// - A tiny in-memory LRU sits in front of IndexedDB for hot-path lookups.
// - `loadEngine()` kicks off the async model download and is exposed for
//   preloading at app startup; `ttsEngineStatus` is a tiny event-emitter
//   the UI can subscribe to (e.g. to show a "downloading model…" hint).

import { ttsCacheGet, ttsCacheSet } from './ttsCache.js'

const MEMORY_CACHE_LIMIT = 32

// ---------------------------------------------------------------------------
// Status emitter
// ---------------------------------------------------------------------------
// status: 'idle' | 'loading' | 'downloading' | 'initializing' | 'ready' | 'error'
const listeners = new Set()
let engineStatus = 'idle'
let engineError = ''

function setStatus(status, error) {
  if (error !== undefined) engineError = error
  if (engineStatus === status) return
  engineStatus = status
  for (const fn of listeners) {
    try { fn({ status: engineStatus, error: engineError }) } catch { /* ignore */ }
  }
}

export function onTtsEngineStatus(listener) {
  listeners.add(listener)
  // Emit current state immediately so late subscribers catch up.
  try { listener({ status: engineStatus, error: engineError }) } catch { /* ignore */ }
  return () => listeners.delete(listener)
}

export function getTtsEngineStatus() {
  return { status: engineStatus, error: engineError }
}

// ---------------------------------------------------------------------------
// Worker bootstrap
// ---------------------------------------------------------------------------
let worker = null
let workerReady = false
const pendingRequests = new Map() // id -> { resolve, reject }
let nextId = 1

function ensureWorker() {
  if (worker) return worker
  const WorkerCtor = typeof Worker !== 'undefined' ? Worker : null
  if (!WorkerCtor) {
    // Fallback: some environments disallow workers. Fail loudly so the UI can
    // show its own error state instead of hanging forever.
    throw new Error('Web Workers are not supported in this browser')
  }
  console.info('[TTS] platform:', Capacitor.getPlatform())
  worker = Capacitor.isNativePlatform()
    ? new Worker(new URL('/native-tts-v1/worker.js', window.location.origin), { type: 'module' })
    : new Worker(new URL('./ttsWorker.js', import.meta.url), { type: 'module' })
  worker.addEventListener('message', onWorkerMessage)
  worker.addEventListener('error', (event) => {
    failWorker(event?.message || 'Worker error')
  })
  return worker
}

function onWorkerMessage(event) {
  const msg = event.data || {}
  switch (msg.type) {
    case 'status': {
      const s = msg.status
      // 'ready' means the engine finished loading; anything before that while
      // no request is in flight describes the global engine state.
      if (s === 'ready') {
        workerReady = true
        setStatus('ready')
        // Warm up the AudioContext during engine init so the first speak()
        // call doesn't pay the resume latency on the user gesture.
        try { getAudioContext().resume() } catch { /* ignore */ }
      } else if (s === 'loading' || s === 'downloading' || s === 'initializing') {
        setStatus(s)
      }
      // Per-call statuses are forwarded to the speakJapanese callback below.
      if (msg.id != null && pendingRequests.has(msg.id)) {
        const pending = pendingRequests.get(msg.id)
        if (pending.onStatus) {
          const mapped =
            s === 'generating' ? 'generating'
            : s === 'loading' || s === 'downloading' || s === 'initializing' ? 'loading'
            : s
          try { pending.onStatus(mapped) } catch { /* ignore */ }
        }
      }
      break
    }
    case 'cancelled': {
      const pending = pendingRequests.get(msg.id)
      pendingRequests.delete(msg.id)
      pending?.reject(new Error('Speech cancelled'))
      break
    }
    case 'audio': {
      const pending = pendingRequests.get(msg.id)
      if (!pending) return
      pendingRequests.delete(msg.id)
      if (msg.format === 'mp3' || msg.format === 'wav') {
        // Web backend TTS returns an encoded audio ArrayBuffer.
        pending.resolve({ data: msg.buffer, samplingRate: msg.samplingRate, format: msg.format, encoded: true })
      } else {
        // Android native worker returns Float32 PCM.
        const data = new Float32Array(msg.buffer)
        pending.resolve({ data, samplingRate: msg.samplingRate })
      }
      break
    }
    case 'error': {
      if (msg.id != null && pendingRequests.has(msg.id)) {
        const pending = pendingRequests.get(msg.id)
        pendingRequests.delete(msg.id)
        console.error('[TTS] synthesis failed:', msg.message)
        pending.reject(new Error(msg.message || 'Worker error'))
      } else {
        failWorker(msg.message)
      }
      break
    }
  }
}

function failWorker(message) {
  console.error('[TTS] engine failed:', message)
  workerReady = false
  preloadPromise = null
  worker?.terminate()
  worker = null
  for (const pending of pendingRequests.values()) pending.reject(new Error(message))
  pendingRequests.clear()
  setStatus('error', message)
}

function requestSynthesis(text, onStatus) {
  return new Promise((resolve, reject) => {
    const w = ensureWorker()
    const id = nextId++
    pendingRequests.set(id, { resolve, reject, onStatus })
    w.postMessage({ type: 'speak', id, text })
  })
}

// ---------------------------------------------------------------------------
// Public: preload the engine at app startup
// ---------------------------------------------------------------------------
let preloadPromise = null

export function loadEngine() {
  if (workerReady) return Promise.resolve()
  if (preloadPromise) return preloadPromise
  try {
    const w = ensureWorker()
    setStatus('loading', '')
    preloadPromise = new Promise((resolve, reject) => {
      const off = onTtsEngineStatus(({ status, error }) => {
        if (status === 'ready' || status === 'error') {
          queueMicrotask(() => off())
          if (status === 'ready') resolve()
          else reject(new Error(error || 'Engine failed to load'))
        }
      })
      w.postMessage({ type: 'init' })
    }).catch(error => {
      preloadPromise = null
      throw error
    })
    return preloadPromise
  } catch (error) {
    failWorker(error.message)
    return Promise.reject(error)
  }
}

// ---------------------------------------------------------------------------
// In-memory LRU cache (Float32 PCM, lives on main thread)
// ---------------------------------------------------------------------------
const memoryCache = new Map()

function memoryGet(key) {
  if (!memoryCache.has(key)) return null
  const value = memoryCache.get(key)
  // Refresh: delete+reinsert to keep insertion order LRU-ish.
  memoryCache.delete(key)
  memoryCache.set(key, value)
  return value
}

function memorySet(key, value) {
  if (memoryCache.has(key)) memoryCache.delete(key)
  memoryCache.set(key, value)
  while (memoryCache.size > MEMORY_CACHE_LIMIT) {
    const oldest = memoryCache.keys().next().value
    memoryCache.delete(oldest)
  }
}

// ---------------------------------------------------------------------------
// Audio playback
// ---------------------------------------------------------------------------
let audioContext = null
let currentSource = null
let requestId = 0

function getAudioContext() {
  const Ctor = typeof window !== 'undefined'
    ? (window.AudioContext || window.webkitAudioContext)
    : null
  if (!Ctor) throw new Error('AudioContext is unavailable')
  if (!audioContext) audioContext = new Ctor()
  return audioContext
}

export function stopJapaneseSpeech() {
  requestId++
  if (currentSource) {
    try { currentSource.onended = null; currentSource.stop() } catch { /* ignore */ }
    try { currentSource.disconnect() } catch { /* ignore */ }
    currentSource = null
  }
  for (const pending of pendingRequests.values()) pending.reject(new Error('Speech cancelled'))
  pendingRequests.clear()
  // Tell the worker to invalidate any in-flight generation.
  if (worker) {
    try { worker.postMessage({ type: 'stop' }) } catch { /* ignore */ }
  }
}

export async function speakJapanese(text, onStatus = () => {}) {
  stopJapaneseSpeech()
  getAudioContext().resume().catch(() => {})
  const id = requestId

  // 1. Hot path: in-memory cache.
  let audio = memoryGet(text)
  if (audio) {
    await playBuffer(audio, id, onStatus)
    return
  }

  // 2. Warm path: IndexedDB persistent cache.
  const cached = await ttsCacheGet(text).catch(() => null)
  if (cached && cached.data && cached.samplingRate) {
    memorySet(text, cached)
    if (id !== requestId) return
    await playBuffer(cached, id, onStatus)
    return
  }

  // 3. Cold path: synthesize in the Web Worker.
  onStatus(engineStatus === 'ready' ? 'generating' : 'loading')
  let result
  try {
    result = await requestSynthesis(text, onStatus)
  } catch (err) {
    if (id !== requestId) return
    throw err
  }
  if (id !== requestId) return
  if (!result?.data || !result.samplingRate) {
    throw new Error('Synthesis returned no audio')
  }

  memorySet(text, result)
  // Persist asynchronously; don't await — playback doesn't depend on it.
  ttsCacheSet(text, result.data, result.samplingRate, result.format).catch(() => {})

  await playBuffer(result, id, onStatus)
}

async function playBuffer(audio, id, onStatus) {
  const ctx = getAudioContext()
  // Resume during the click gesture, before the first sample plays.
  try { await ctx.resume() } catch { /* ignore */ }
  if (id !== requestId) return

  let source
  if (audio.encoded) {
    // Web backend TTS: decode mp3/wav ArrayBuffer via AudioContext.
    let audioBuffer
    try {
      audioBuffer = await ctx.decodeAudioData(audio.data.slice(0))
    } catch (err) {
      console.error('[TTS] decodeAudioData failed:', err)
      if (id === requestId) onStatus('error')
      return
    }
    source = ctx.createBufferSource()
    source.buffer = audioBuffer
  } else {
    // Android native worker: Float32 PCM.
    const buffer = ctx.createBuffer(1, audio.data.length, audio.samplingRate)
    buffer.copyToChannel(audio.data, 0)
    source = ctx.createBufferSource()
    source.buffer = buffer
  }
  source.connect(ctx.destination)
  source.onended = () => {
    try { source.disconnect() } catch { /* ignore */ }
    if (currentSource === source) {
      currentSource = null
      if (id === requestId) onStatus('idle')
    }
  }
  currentSource = source
  source.start()
  onStatus('playing')
}
