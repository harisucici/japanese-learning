// The model and Japanese dictionary are downloaded only after the first word click.
// Pin the browser bundle so its code and matching dictionary assets stay in sync.
const KOKORO_URL = 'https://cdn.jsdelivr.net/npm/kokoro-js-jp@0.2.0/dist/kokoro-jp.web.js'
const MAX_CACHED_WORDS = 24

let enginePromise
let audioContext
let currentSource
let requestId = 0
let generationQueue = Promise.resolve()
const audioCache = new Map()

function loadEngine() {
  if (!enginePromise) {
    enginePromise = import(/* @vite-ignore */ KOKORO_URL)
      .then(({ KokoroJP }) => KokoroJP.load({ dtype: 'q4', device: 'wasm' }))
      .catch(error => {
        enginePromise = undefined
        throw error
      })
  }
  return enginePromise
}

function remember(text, raw) {
  const audio = { data: raw.data ?? raw.audio, samplingRate: raw.sampling_rate }
  audioCache.set(text, audio)
  if (audioCache.size > MAX_CACHED_WORDS) audioCache.delete(audioCache.keys().next().value)
  return audio
}

export function stopJapaneseSpeech() {
  requestId++
  if (currentSource) {
    currentSource.onended = null
    currentSource.stop()
    currentSource.disconnect()
    currentSource = null
  }
}

export async function speakJapanese(text, onStatus = () => {}) {
  stopJapaneseSpeech()
  const id = requestId
  const AudioContextClass = window.AudioContext || window.webkitAudioContext
  if (!AudioContextClass) throw new Error('AudioContext is unavailable')
  audioContext ||= new AudioContextClass()
  // Resume during the click gesture, before model loading or synthesis awaits.
  const ready = audioContext.resume().then(() => true, () => false)

  let audio = audioCache.get(text)
  if (audio) {
    audioCache.delete(text)
    audioCache.set(text, audio)
  } else {
    onStatus(enginePromise ? 'generating' : 'loading')
    const engine = await loadEngine()
    if (id !== requestId) return
    onStatus('generating')
    const generation = generationQueue.then(() => id === requestId ? engine.speak(text, 'jf_alpha') : null)
    generationQueue = generation.catch(() => {})
    const raw = await generation
    if (id !== requestId || !raw) return
    audio = remember(text, raw)
  }

  if (!await ready) throw new Error('AudioContext could not start')
  if (id !== requestId) return
  const buffer = audioContext.createBuffer(1, audio.data.length, audio.samplingRate)
  buffer.copyToChannel(audio.data, 0)
  const source = audioContext.createBufferSource()
  source.buffer = buffer
  source.connect(audioContext.destination)
  source.onended = () => {
    source.disconnect()
    if (currentSource === source) {
      currentSource = null
      onStatus('idle')
    }
  }
  currentSource = source
  source.start()
  onStatus('playing')
}
