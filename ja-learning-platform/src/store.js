import { defineStore } from 'pinia'

const API_BASE = (import.meta.env.VITE_API_BASE_URL || '/api/reading').replace(/\/$/, '')
// Remove the token saved by earlier releases; all future identity is in an HttpOnly cookie.
try { window.localStorage.removeItem('learning_token') } catch { /* Storage may be disabled. */ }
export const assetUrl = (url) => {
  if (!url) return ''
  try {
    const parsed = new URL(url, window.location.origin)
    if (['localhost', '127.0.0.1'].includes(parsed.hostname) && ['3002', '3003'].includes(parsed.port)) parsed.host = window.location.host
    return parsed.href
  } catch { return url }
}

export async function requestResource(path, body, method = body === undefined ? 'GET' : 'POST') {
  const response = await fetch(`${API_BASE}/${path.replace(/^\//, '')}`, {
    method,
    credentials: 'include',
    headers: body === undefined ? {} : { 'Content-Type': 'application/json' },
    ...(body === undefined ? {} : { body: JSON.stringify(body) })
  })
  const data = await response.json().catch(() => ({}))
  if (!response.ok) throw new Error(typeof data.error === 'string' ? data.error : `服务请求失败（${response.status}）`)
  return data
}

export const useAppStore = defineStore('app', {
  state: () => ({ menuOpen: false, selectedCategory: '全部' }),
  actions: {
    toggleMenu() { this.menuOpen = !this.menuOpen },
    closeMenu() { this.menuOpen = false },
    selectCategory(category) { this.selectedCategory = category }
  }
})

export const useAuthStore = defineStore('auth', {
  state: () => ({ user: null, checked: false, loading: false }),
  actions: {
    async request(path, body, method = 'POST') {
      const response = await fetch(`${API_BASE}/auth/${path}`, {
        method,
        credentials: 'include',
        headers: body === undefined ? {} : { 'Content-Type': 'application/json' },
        ...(body === undefined ? {} : { body: JSON.stringify(body) })
      })
      const data = await response.json().catch(() => ({}))
      if (!response.ok) {
        const detail = data.error
        throw new Error(typeof detail === 'string' ? detail : detail?.fieldErrors
          ? Object.values(detail.fieldErrors).flat().join('；') : `服务请求失败（${response.status}）`)
      }
      return data
    },
    async check() {
      if (this.checked) return this.user
      this.loading = true
      try {
        const data = await this.request('me', undefined, 'GET')
        this.user = data.user
      } catch {
        this.user = null
      } finally {
        this.checked = true
        this.loading = false
      }
      return this.user
    },
    async login(payload) {
      const data = await this.request('login', payload)
      this.user = data.user
      this.checked = true
      useLearningStore().guestReady = false
      return data.user
    },
    async register(payload) {
      const data = await this.request('register', payload)
      this.user = data.user
      this.checked = true
      useLearningStore().guestReady = false
      return data.user
    },
    async saveProfile(payload) {
      const data = await this.request('profile', payload, 'PUT')
      this.user = data.user
      return data.user
    },
    async logout() {
      await this.request('logout', {})
      this.user = null
      this.checked = true
      const learning = useLearningStore()
      learning.session = null
      learning.guestReady = false
    }
  }
})

export const useLearningStore = defineStore('learning', {
  state: () => ({ guestReady: false, session: null, requestStage: '' }),
  actions: {
    async request(path, body, auth = false, retried = false) {
      this.requestStage = auth ? '检查访客身份' : '发送数据请求'
      if (auth) await this.ensureGuest()
      const base = API_BASE
      this.requestStage = '等待服务响应'
      const response = await fetch(`${base}/learning/${path}`, {
        method: body === undefined ? 'GET' : 'POST',
        credentials: 'include',
        signal: AbortSignal.timeout(15000),
        headers: body === undefined ? {} : { 'Content-Type': 'application/json' },
        ...(body === undefined ? {} : { body: JSON.stringify(body) })
      })
      const expectedBytes = Number(response.headers.get('content-length'))
      let data = {}
      if (response.body && Number.isFinite(expectedBytes) && expectedBytes > 0) {
        const reader = response.body.getReader()
        const chunks = []
        let received = 0
        while (received < expectedBytes) {
          this.requestStage = `读取响应内容（${response.status}，${received}/${expectedBytes} 字节）`
          const { value, done } = await reader.read()
          if (done) break
          chunks.push(value)
          received += value.byteLength
        }
        if (received < expectedBytes) throw new Error('练习数据传输不完整，请重试。')
        const bytes = new Uint8Array(received)
        let offset = 0
        for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength }
        data = JSON.parse(new TextDecoder().decode(bytes))
        reader.cancel().catch(() => {})
      } else {
        this.requestStage = `读取响应内容（${response.status}）`
        data = await response.json().catch(() => ({}))
      }
      if (auth && response.status === 401 && !retried) {
        this.guestReady = false
        await this.ensureGuest()
        return this.request(path, body, true, true)
      }
      if (!response.ok) {
        const error = new Error(data.error || `服务请求失败（${response.status}）`)
        error.status = response.status
        throw error
      }
      return data
    },
    async ensureGuest() {
      if (this.guestReady) return
      const response = await fetch(`${API_BASE}/learning/guest`, { method: 'POST', credentials: 'include', headers: { 'Content-Type': 'application/json' }, body: '{}' })
      const data = await response.json().catch(() => ({}))
      if (!response.ok || !data.ready) throw new Error(data.error || '无法建立学习会话')
      this.guestReady = true
    },
    async startFun(id) { this.session = await this.request('sessions', { level: 'n5', mode: 'fun', collectionId: id }, true); return this.session },
    async startExam(level, paperId, instantFeedback) { this.session = await this.request('sessions', { level, mode: 'exam', paperId, instantFeedback }, true); return this.session },
    async loadSession(id) {
      const path = `sessions/${encodeURIComponent(id)}`
      // Fetch the complete session (metadata + questions) in a single GET
      // request. The backend GET /sessions/:id returns the full state, so we
      // no longer need the separate /metadata and /questions POST calls —
      // this halves the round trips and the total bytes on the wire.
      const loadAll = async () => {
        const result = await this.request(path);
        return result;
      }
      try {
        this.session = await loadAll()
      } catch (error) {
        if (error.status !== 401) throw error
        this.guestReady = false
        await this.ensureGuest()
        this.session = await loadAll()
      }
      return this.session
    },
    async answer(id, questionId, optionId) { this.session = await this.request(`sessions/${encodeURIComponent(id)}/answers`, { questionId, optionId }, true); return this.session },
    async next(id) { this.session = await this.request(`sessions/${encodeURIComponent(id)}/next`, {}, true); return this.session },
    async section(id, action) { this.session = await this.request(`sessions/${encodeURIComponent(id)}/section`, { action }, true); return this.session }
  }
})
