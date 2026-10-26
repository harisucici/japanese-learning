/** Prepare reproducible APK-only TTS assets. Never put models in the web build. */
import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { createHash } from 'node:crypto'
import { build } from 'esbuild'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const lock = JSON.parse(await fs.readFile(path.join(root, 'scripts/tts-model-lock.json'), 'utf8'))
const cache = path.join(root, 'work/tts-model')
const output = path.join(root, 'android/app/build/generated/tts-assets/native-tts-v1')
const verifyOnly = process.argv.includes('--verify')

async function valid(file, spec) {
  try {
    const bytes = await fs.readFile(file)
    return bytes.length === spec.bytes && createHash('sha256').update(bytes).digest('hex') === spec.sha256
  } catch { return false }
}

async function ensureModel(name, spec) {
  const file = path.join(cache, name)
  if (await valid(file, spec)) return file
  if (verifyOnly) throw new Error(`Missing/corrupt model: ${name}`)
  await fs.mkdir(path.dirname(file), { recursive: true })
  const url = `https://huggingface.co/${lock.repository}/resolve/main/${name}`
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      console.log(`Preparing ${name}`)
      const response = await fetch(url, { signal: AbortSignal.timeout(300_000) })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const bytes = Buffer.from(await response.arrayBuffer())
      if (bytes.length !== spec.bytes || createHash('sha256').update(bytes).digest('hex') !== spec.sha256) {
        throw new Error(`Checksum mismatch: ${name}`)
      }
      await fs.writeFile(`${file}.part`, bytes)
      await fs.rename(`${file}.part`, file)
      return file
    } catch (error) {
      if (attempt === 2) throw error
    }
  }
}

if (!verifyOnly) await fs.rm(output, { recursive: true, force: true })

for (const [name, spec] of Object.entries(lock.files)) {
  const file = await ensureModel(name, spec)
  if (!verifyOnly) {
    const bundledName = name === 'onnx/model_q8f16.onnx' ? 'onnx/model.onnx' : name
    const dest = path.join(output, 'model', bundledName)
    await fs.mkdir(path.dirname(dest), { recursive: true })
    await fs.copyFile(file, dest)
  }
}

const japaneseSource = path.join(root, 'node_modules/kokoro-js-jp/dist')
const japaneseFiles = ['open_jtalk_dic_utf_8-1.11.tar.gz',
  'openjtalk-voice.htsvoice', 'openjtalk-wasm.wasm']
const wasmSource = path.join(root, 'node_modules/onnxruntime-web/dist')
const wasmFiles = (await fs.readdir(wasmSource)).filter(name => /^ort-wasm.*\.(mjs|wasm)$/.test(name))
if (!wasmFiles.some(name => name.endsWith('.wasm'))) throw new Error('ONNX WASM runtime missing; run npm ci')
for (const [source, destDir, names] of [[japaneseSource, 'japanese', japaneseFiles], [wasmSource, 'wasm', wasmFiles]]) {
  for (const name of names) {
    const file = path.join(source, name)
    if ((await fs.stat(file)).size === 0) throw new Error(`Empty TTS resource: ${file}`)
    if (!verifyOnly) {
      // AAPT silently inflates *.gz assets and strips their suffix.
      const bundledName = name.endsWith('.gz') ? `${name}.bin` : name
      const dest = path.join(output, destDir, bundledName)
      await fs.mkdir(path.dirname(dest), { recursive: true })
      await fs.copyFile(file, dest)
    }
  }
}
if (!verifyOnly) {
  await build({
    entryPoints: [path.join(root, 'src/tts/nativeWorker.js')],
    outfile: path.join(output, 'worker.js'),
    alias: { 'openjtalk-native': path.join(japaneseSource, 'openjtalk-wasm-wrapper-D6E3BSJO.js') },
    bundle: true, platform: 'browser', format: 'esm', target: 'es2022', minify: true,
  })
  for (const [name, source] of [
    ['kokoro-js-jp-LICENSE.txt', 'node_modules/kokoro-js-jp/LICENSE'],
    ['kokoro-js-jp-NOTICES.txt', 'node_modules/kokoro-js-jp/THIRD_PARTY_NOTICES.md'],
    ['kokoro-js-LICENSE.txt', 'node_modules/kokoro-js/LICENSE'],
    ['transformers-LICENSE.txt', 'node_modules/@huggingface/transformers/LICENSE'],
  ]) await fs.copyFile(path.join(root, source), path.join(output, name))
}
console.log(verifyOnly ? 'TTS model checksums and runtime resources verified' : `Bundled TTS ready: ${output}`)
