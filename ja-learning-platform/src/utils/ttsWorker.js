// Web TTS Worker: delegates synthesis to the backend /api/v1/tts/speak endpoint
// instead of loading the ~82MB Kokoro WASM model in the browser.
//
// Protocol (kept compatible with japaneseSpeech.js):
//   in:  { type: 'init' }
//   out: { type: 'status', status: 'ready' }
//   in:  { type: 'speak', id, text }
//   out: { type: 'status', id, status: 'generating' }
//   out: { type: 'audio', id, buffer: ArrayBuffer, format: 'mp3', samplingRate: 24000 }
//   out: { type: 'error', id, message }
//   in:  { type: 'stop' }  -> cancels the in-flight request

// Backend URL: in dev the Vite proxy rewrites /api/reading -> /api/v1 on :3000,
// so /api/reading/tts/speak resolves to the backend endpoint regardless of env.
const TTS_ENDPOINT = '/api/reading/tts/speak'

// Track the latest request id so 'stop' / superseded calls can be discarded.
let latestId = null
let activeController = null

self.addEventListener('message', ({ data: msg }) => {
  if (msg.type === 'init') {
    // No model to load — backend is always available.
    self.postMessage({ type: 'status', status: 'ready' })
    return
  }
  if (msg.type === 'stop') {
    latestId = null
    if (activeController) {
      try { activeController.abort() } catch { /* ignore */ }
      activeController = null
    }
    return
  }
  if (msg.type !== 'speak') return

  latestId = msg.id
  // Cancel any in-flight request.
  if (activeController) {
    try { activeController.abort() } catch { /* ignore */ }
    activeController = null
  }

  const controller = new AbortController()
  activeController = controller

  ;(async () => {
    self.postMessage({ type: 'status', id: msg.id, status: 'generating' })
    let response
    try {
      response = await fetch(TTS_ENDPOINT, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: msg.text }),
        signal: controller.signal,
      })
    } catch (err) {
      if (latestId !== msg.id) return
      self.postMessage({ type: 'error', id: msg.id, message: err.message || 'fetch failed' })
      return
    }
    if (latestId !== msg.id) return
    if (!response.ok) {
      let detail = ''
      try { detail = (await response.json())?.error || '' } catch { /* ignore */ }
      self.postMessage({ type: 'error', id: msg.id, message: `TTS ${response.status}${detail ? ': ' + detail : ''}` })
      return
    }

    let arrayBuffer
    try {
      arrayBuffer = await response.arrayBuffer()
    } catch (err) {
      if (latestId !== msg.id) return
      self.postMessage({ type: 'error', id: msg.id, message: 'failed to read audio data' })
      return
    }
    if (latestId !== msg.id) return

    // edge-tts returns mp3 @ 24kHz. SamplingRate is informational; the main
    // thread decodes via AudioContext.decodeAudioData and ignores this value.
    self.postMessage(
      { type: 'audio', id: msg.id, buffer: arrayBuffer, format: 'mp3', samplingRate: 24000 },
      [arrayBuffer],
    )
  })()
})
