import { afterEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { requestResource, useAuthStore, useLearningStore } from '../store'

function respond(body, status = 200) {
  vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: status < 400, status, json: async () => body }))
}
afterEach(() => vi.unstubAllGlobals())
describe('API response compatibility', () => {
  it('retains paginated items and totals for the admin page', async () => {
    const data = { items: [{ id: 'q1' }], total: 25, limit: 10, offset: 10 }
    const meta = { page: 2, limit: 10, total: 25, totalPages: 3 }
    respond({ success: true, data, meta })
    expect(await requestResource('admin/questions')).toEqual({ ...data, meta })
  })
  it('supports legacy responses', async () => {
    respond({ items: [], total: 0 })
    expect(await requestResource('admin/questions')).toEqual({ items: [], total: 0 })
  })
  it('handles null payloads with metadata', async () => {
    respond({ success: true, data: null, meta: {} })
    expect(await requestResource('test')).toBeNull()
  })
  it('propagates structured error details', async () => {
    respond({ success: false, error: { code: 'INVALID_INPUT', message: '参数错误', details: { field: 'title' } } }, 400)
    await expect(requestResource('test')).rejects.toMatchObject({ message: '参数错误', code: 'INVALID_INPUT', details: { field: 'title' } })
  })
  it('unwraps auth, lesson and guest responses', async () => {
    setActivePinia(createPinia())
    respond({ success: true, data: { user: { id: 'u1' } } })
    expect(await useAuthStore().request('me')).toEqual({ user: { id: 'u1' } })
    respond({ success: true, data: { title: 'lesson' } })
    expect(await useLearningStore().request('novel-lessons/1')).toEqual({ title: 'lesson' })
    respond({ success: true, data: { ready: true } })
    await useLearningStore().ensureGuest()
    expect(useLearningStore().guestReady).toBe(true)
  })
})
