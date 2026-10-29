import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './style.css'
import './mobile-motion.css'

const app = createApp(App).use(createPinia()).use(router)

// 预加载日语发音引擎（异步，不阻塞首屏渲染）
// Android 从 APK 内置资源加载；浏览器首次使用在线资源。
import { loadEngine } from './utils/japaneseSpeech.js'
if ('requestIdleCallback' in window) {
  requestIdleCallback(() => loadEngine().catch(err => {
    console.warn('[TTS] engine init failed:', err?.message || err)
  }), { timeout: 5000 })
} else {
  setTimeout(() => loadEngine().catch(err => {
    console.warn('[TTS] engine init failed:', err?.message || err)
  }), 2000)
}

app.mount('#app')
