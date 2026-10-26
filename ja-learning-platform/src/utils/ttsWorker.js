import { startSpeechWorker } from '../tts/workerProtocol.js'

// Ordinary browsers use online resources; Android uses the APK's nativeWorker.
const KOKORO_URL = 'https://cdn.jsdelivr.net/npm/kokoro-js-jp@0.2.0/dist/kokoro-jp.web.js'
startSpeechWorker(async () => {
  const { KokoroJP } = await import(/* @vite-ignore */ KOKORO_URL)
  return KokoroJP.load({ dtype: 'q8', device: 'wasm' })
})
