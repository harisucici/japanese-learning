// Versioned native protocol: keep this entry compatible with installed v1 APKs.
import { KokoroJP } from 'kokoro-js-jp'
import { env } from '@huggingface/transformers'
import { startSpeechWorker } from './workerProtocol.js'

const base = new URL('./', self.location.href).href
const model = new URL('model/', base).pathname
env.allowLocalModels = true
env.allowRemoteModels = false
env.useBrowserCache = false
env.backends.onnx.wasm.wasmPaths = `${base}wasm/`
env.backends.onnx.wasm.numThreads = 1
// kokoro-js fixes the voice URL to HuggingFace. Redirect only that known path
// to the packaged voice; reject any other non-native request in this worker.
const localFetch = self.fetch.bind(self)
const voicePrefix = 'https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/resolve/main/voices/'
self.fetch = (input, options) => {
  const original = typeof input === 'string' || input instanceof URL ? String(input) : input.url
  const url = new URL(original, self.location.href)
  const target = url.href.startsWith(voicePrefix)
    ? new URL(`model/voices/${url.pathname.split('/').pop()}`, base)
    : url
  if (!target.href.startsWith(base)) return Promise.reject(new Error(`Non-bundled TTS resource: ${target.href}`))
  return localFetch(target.href, options)
}

startSpeechWorker(() => KokoroJP.load({
  modelId: model,
  // Transformers 3.x has no q8f16 name; the pinned ONNX graph is packaged
  // as model.onnx. Precision is encoded in the graph itself.
  dtype: 'fp32',
  device: 'wasm',
  japanese: { assetsUrl: `${base}japanese` },
}))
