import { afterEach, describe, expect, it, vi } from 'vitest'
import { startSpeechWorker } from '../tts/workerProtocol.js'

const settle = () => new Promise(resolve => setTimeout(resolve, 0))
function worker(load) {
  let receive
  const messages = []
  vi.stubGlobal('self', {
    addEventListener: (_type, fn) => { receive = fn },
    postMessage: msg => messages.push(msg),
  })
  startSpeechWorker(load)
  return { messages, send: data => receive({ data }) }
}
const raw = { data: new Float32Array([0.1, -0.2]), sampling_rate: 24000 }
afterEach(() => vi.unstubAllGlobals())

describe('speech worker protocol', () => {
  it('waits for initialization before synthesizing the first request', async () => {
    let ready
    const speak = vi.fn(async () => raw)
    const w = worker(() => new Promise(resolve => { ready = () => resolve({ speak }) }))
    w.send({ type: 'init' })
    w.send({ type: 'speak', id: 1, text: 'こんにちは' })
    await settle()
    expect(speak).not.toHaveBeenCalled()
    ready()
    await settle()
    expect(speak).toHaveBeenCalledWith('こんにちは', 'jf_alpha')
    expect(w.messages.find(msg => msg.type === 'audio')).toMatchObject({ id: 1, samplingRate: 24000 })
  })

  it('cancels old queued requests and sends audio for the latest ID', async () => {
    const speak = vi.fn(async () => raw)
    const w = worker(async () => ({ speak }))
    w.send({ type: 'speak', id: 5, text: '古い' })
    w.send({ type: 'stop' })
    w.send({ type: 'speak', id: 9, text: '新しい' })
    await settle()
    expect(speak).toHaveBeenCalledTimes(1)
    expect(w.messages).toContainEqual({ type: 'cancelled', id: 5 })
    expect(w.messages.find(msg => msg.type === 'audio').id).toBe(9)
  })

  it('reports initialization failure with the request ID and allows retry', async () => {
    const load = vi.fn().mockRejectedValueOnce(new Error('Missing bundled model')).mockResolvedValue({ speak: async () => raw })
    const w = worker(load)
    w.send({ type: 'speak', id: 1, text: '失敗' })
    await settle()
    expect(w.messages).toContainEqual({ type: 'error', id: 1, message: 'Missing bundled model' })
    w.send({ type: 'speak', id: 2, text: '再試行' })
    await settle()
    expect(w.messages.find(msg => msg.type === 'audio').id).toBe(2)
  })

  it('suppresses audio when stopped during synthesis', async () => {
    let finish
    const w = worker(async () => ({ speak: () => new Promise(resolve => { finish = () => resolve(raw) }) }))
    w.send({ type: 'speak', id: 1, text: '停止' })
    await settle()
    w.send({ type: 'stop' })
    finish()
    await settle()
    expect(w.messages.some(msg => msg.type === 'audio')).toBe(false)
    expect(w.messages).toContainEqual({ type: 'cancelled', id: 1 })
  })
})
