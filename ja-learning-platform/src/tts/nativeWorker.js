// Versioned native protocol: keep this entry compatible with installed v1 APKs.
import { KokoroJP } from 'kokoro-js-jp'
import { env } from '@huggingface/transformers'
import { startSpeechWorker } from './workerProtocol.js'
import { installInlineJapaneseWorker } from './inlineJapaneseWorker.js'

const base = new URL('./', self.location.href).href
const model = new URL('model/', base).pathname
env.allowLocalModels = true
env.allowRemoteModels = false
env.useBrowserCache = true
env.backends.onnx.wasm.wasmPaths = `${base}wasm/`
env.backends.onnx.wasm.numThreads = typeof navigator !== 'undefined' && navigator.hardwareConcurrency ? navigator.hardwareConcurrency : 4
console.info('[TTS] backend config: browserCache=true, wasmThreads=' + env.backends.onnx.wasm.numThreads)
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

installInlineJapaneseWorker(base)

// Detect the best available ONNX backend: prefer WebGPU when the runtime
// exposes a GPU adapter; otherwise fall back to multi-threaded WASM.
async function detectBestBackend() {
  if (typeof navigator !== 'undefined' && navigator.gpu) {
    try {
      const adapter = await navigator.gpu.requestAdapter()
      if (adapter) {
        console.info('[TTS] WebGPU available, using GPU backend')
        return { device: 'webgpu', dtype: 'fp32' }
      }
    } catch (e) {
      console.warn('[TTS] WebGPU detection failed:', e)
    }
  }
  console.info('[TTS] WebGPU not available, falling back to WASM')
  return { device: 'wasm', dtype: 'fp32' }
}

;(async () => {
  const backend = await detectBestBackend()
  console.info('[TTS] selected backend: device=' + backend.device + ', dtype=' + backend.dtype +
    ', threads=' + env.backends.onnx.wasm.numThreads)
  startSpeechWorker(() => KokoroJP.load({
    modelId: model,
    // Transformers 3.x has no q8f16 name; the pinned ONNX graph is packaged
    // as model.onnx. Precision is encoded in the graph itself.
    dtype: backend.dtype,
    device: backend.device,
    japanese: { assetsUrl: `${base}japanese` },
  }))
})()
