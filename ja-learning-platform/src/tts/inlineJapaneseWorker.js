import createOpenJTalkModule from 'openjtalk-native'

// Android WebView does not route nested worker loads through the app's asset
// interceptor. Run Open JTalk inside the existing off-main-thread TTS worker.
// The pinned Kokoro library expects this small Worker message interface.
export function installInlineJapaneseWorker(base) {
  const BrowserWorker = self.Worker
  class JapaneseWorker {
    listeners = new Set()
    modulePromise = null
    queue = Promise.resolve()

    addEventListener(type, listener) {
      if (type === 'message') this.listeners.add(listener)
    }

    getModule() {
      this.modulePromise ??= createOpenJTalkModule({
        locateFile: file => file.endsWith('.wasm') ? `${base}japanese/openjtalk-wasm.wasm` : file,
      })
      return this.modulePromise
    }

    postMessage(request) {
      this.queue = this.queue.then(async () => {
        try {
          const module = await this.getModule()
          let result
          if (request.method === 'configure') {
            const config = request.args[0]
            await module.configure(config.dicUrl, config.voiceUrl, config.dicArchiveUrl)
          } else if (request.method === 'runFrontend') {
            result = module.runFrontend(request.args[0])
          } else {
            throw new Error(`Unsupported native G2P operation: ${request.method}`)
          }
          for (const listener of this.listeners) listener({ data: { id: request.id, ok: true, result } })
        } catch (error) {
          for (const listener of this.listeners) listener({ data: { id: request.id, ok: false, error: error.message } })
        }
      })
    }
  }
  self.Worker = function (url, options) {
    if (new URL(url, self.location.href).href === `${base}japanese/browser/worker.js`) return new JapaneseWorker()
    return new BrowserWorker(url, options)
  }
}
