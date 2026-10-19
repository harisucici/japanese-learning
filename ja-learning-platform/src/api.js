import { defineStore } from 'pinia'

const API_BASE = (import.meta.env.VITE_API_BASE_URL || '/api/reading').replace(/\/$/, '')
const READING_API_BASE = (import.meta.env.VITE_READING_API_BASE_URL || import.meta.env.VITE_MATERIALS_API_BASE_URL || '/api/reading').replace(/\/$/, '')
export const assetUrl = (url) => {
  if (!url) return ''
  try {
    const parsed = new URL(url, window.location.origin)
    if (['localhost', '127.0.0.1'].includes(parsed.hostname) && ['3002', '3003'].includes(parsed.port)) parsed.host = window.location.host
    return parsed.href
  } catch { return url }
}

export const useLearningStore = defineStore('learning', {
  state: () => ({ token: localStorage.getItem('learning_token') || '', session: null }),
  actions: {
    async request(path, body, auth = false, retried = false) {
      if (auth) await this.ensureGuest()
      const remoteReading = path === 'materials' || path.startsWith('materials/') || path === 'novel-lessons' || path.startsWith('novel-lessons/')
      const base = remoteReading ? READING_API_BASE : API_BASE
      const response = await fetch(`${base}/learning/${path}`, {
        method: body === undefined ? 'GET' : 'POST',
        headers: { ...(body === undefined ? {} : { 'Content-Type': 'application/json' }), ...(this.token ? { Authorization: `Bearer ${this.token}` } : {}) },
        ...(body === undefined ? {} : { body: JSON.stringify(body) })
      })
      const data = await response.json().catch(() => ({}))
      if (auth && response.status === 401 && !retried) {
        this.token = ''
        localStorage.removeItem('learning_token')
        await this.ensureGuest()
        return this.request(path, body, true, true)
      }
      if (!response.ok) throw new Error(data.error || `服务请求失败（${response.status}）`)
      return data
    },
    async ensureGuest() {
      if (this.token) return
      const response = await fetch(`${API_BASE}/learning/guest`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' })
      const data = await response.json().catch(() => ({}))
      if (!response.ok || !data.token) throw new Error(data.error || '无法创建学习身份')
      this.token = data.token
      localStorage.setItem('learning_token', data.token)
    },
    async startFun(id) { this.session = await this.request('sessions', { level: 'n5', mode: 'fun', collectionId: id }, true); return this.session },
    async startExam(level, paperId, instantFeedback) { this.session = await this.request('sessions', { level, mode: 'exam', paperId, instantFeedback }, true); return this.session },
    async loadSession(id) { this.session = await this.request(`sessions/${encodeURIComponent(id)}`, undefined, true); return this.session },
    async answer(id, questionId, optionId) { this.session = await this.request(`sessions/${encodeURIComponent(id)}/answers`, { questionId, optionId }, true); return this.session },
    async next(id) { this.session = await this.request(`sessions/${encodeURIComponent(id)}/next`, {}, true); return this.session },
    async section(id, action) { this.session = await this.request(`sessions/${encodeURIComponent(id)}/section`, { action }, true); return this.session }
  }
})
