// Shared queue: initialization must complete before synthesis, and latest call wins.
export function startSpeechWorker(load) {
  let engine
  let loading
  let latestId = null
  let queue = Promise.resolve()
  const post = (type, payload = {}, transfer = []) => self.postMessage({ type, ...payload }, transfer)
  const initialize = () => {
    if (!loading) {
      post('status', { status: 'loading' })
      loading = Promise.resolve().then(load).then(value => {
        engine = value
        post('status', { status: 'ready' })
        return value
      }).catch(error => {
        loading = undefined
        throw error
      })
    }
    return loading
  }
  self.addEventListener('message', ({ data: msg }) => {
    if (msg.type === 'init') {
      initialize().catch(error => post('error', { message: error.message }))
    } else if (msg.type === 'stop') {
      latestId = null
    } else if (msg.type === 'speak') {
      latestId = msg.id
      queue = queue.catch(() => {}).then(async () => {
        await initialize()
        if (latestId !== msg.id) return post('cancelled', { id: msg.id })
        post('status', { id: msg.id, status: 'generating' })
        const raw = await engine.speak(msg.text, 'jf_alpha')
        if (latestId !== msg.id) return post('cancelled', { id: msg.id })
        const data = raw.data ?? raw.audio
        const buffer = data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength)
        post('audio', { id: msg.id, buffer, samplingRate: raw.sampling_rate ?? raw.samplingRate }, [buffer])
      }).catch(error => post('error', { id: msg.id, message: error.message }))
    }
  })
}
