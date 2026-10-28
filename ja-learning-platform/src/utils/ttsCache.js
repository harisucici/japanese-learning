// IndexedDB-backed LRU cache for Japanese TTS audio clips.
//
// Supports two storage shapes:
//   - encoded (mp3/wav ArrayBuffer from the backend TTS)
//   - raw Float32 PCM (from the Android native worker, or legacy cache entries)
//
// Each record carries a `format` field. Entries written by older versions of the
// app lack this field and are treated as Float32 PCM so existing caches remain
// usable after upgrade.

const DB_NAME = 'jaleaning-tts'
const DB_VERSION = 2
const STORE = 'audio'
const MAX_ENTRIES = 100

let dbPromise

function openDB() {
  if (dbPromise) return dbPromise
  dbPromise = new Promise((resolve) => {
    if (typeof indexedDB === 'undefined') { resolve(null); return }
    let req
    try {
      req = indexedDB.open(DB_NAME, DB_VERSION)
    } catch {
      resolve(null)
      return
    }
    req.onupgradeneeded = () => {
      const db = req.result
      if (!db.objectStoreNames.contains(STORE)) {
        const store = db.createObjectStore(STORE, { keyPath: 'key' })
        store.createIndex('lastUsed', 'lastUsed')
      }
    }
    req.onsuccess = () => resolve(req.result)
    req.onerror = () => resolve(null)
    req.onblocked = () => resolve(null)
  })
  return dbPromise
}

function toBuffer(data) {
  if (data instanceof ArrayBuffer) {
    return data.slice(0)
  }
  if (ArrayBuffer.isView(data)) {
    return data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength)
  }
  throw new Error('ttsCacheSet: unsupported audio data type')
}

function toFloat32(buffer) {
  // Defensive copy — caller may mutate the returned view.
  return new Float32Array(buffer.slice(0))
}

function isEncodedFormat(format) {
  return format === 'mp3' || format === 'wav' || format === 'ogg' || format === 'webm'
}

export async function ttsCacheGet(key) {
  const db = await openDB()
  if (!db) return null
  return new Promise((resolve) => {
    let resolved = false
    const done = (value) => { if (!resolved) { resolved = true; resolve(value) } }
    try {
      const tx = db.transaction(STORE, 'readonly')
      const req = tx.objectStore(STORE).get(key)
      req.onsuccess = () => {
        const rec = req.result
        if (!rec) { done(null); return }
        // Refresh lastUsed in a separate tx so the read can return immediately.
        try {
          const utx = db.transaction(STORE, 'readwrite')
          utx.objectStore(STORE).put({ ...rec, lastUsed: Date.now() })
        } catch { /* ignore */ }
        try {
          if (isEncodedFormat(rec.format)) {
            // Encoded audio ArrayBuffer — return as-is, tagged `encoded: true`.
            done({
              data: rec.buffer.slice(0),
              samplingRate: rec.samplingRate,
              format: rec.format,
              encoded: true,
            })
          } else {
            // Float32 PCM (legacy cache entries have no `format` field).
            done({ data: toFloat32(rec.buffer), samplingRate: rec.samplingRate })
          }
        } catch { done(null) }
      }
      req.onerror = () => done(null)
      tx.onerror = () => done(null)
    } catch { done(null) }
  })
}

export async function ttsCacheSet(key, data, samplingRate, format) {
  const db = await openDB()
  if (!db) return false
  const buffer = toBuffer(data)
  const storedFormat = format || 'pcm'
  await new Promise((resolve) => {
    try {
      const tx = db.transaction(STORE, 'readwrite')
      tx.objectStore(STORE).put({
        key,
        buffer,
        samplingRate,
        format: storedFormat,
        lastUsed: Date.now(),
      })
      tx.oncomplete = resolve
      tx.onerror = resolve
      tx.onabort = resolve
    } catch { resolve() }
  })
  await evictLRU()
  return true
}

async function evictLRU() {
  const db = await openDB()
  if (!db) return
  await new Promise((resolve) => {
    try {
      const tx = db.transaction(STORE, 'readwrite')
      const store = tx.objectStore(STORE)
      const countReq = store.count()
      countReq.onsuccess = () => {
        const total = countReq.result
        if (total <= MAX_ENTRIES) { resolve(); return }
        const idx = store.index('lastUsed')
        const openReq = idx.openCursor()
        let toDelete = total - MAX_ENTRIES
        openReq.onsuccess = () => {
          const cursor = openReq.result
          if (!cursor || toDelete <= 0) { resolve(); return }
          try { cursor.delete() } catch { /* ignore */ }
          toDelete--
          cursor.continue()
        }
      }
      tx.oncomplete = resolve
      tx.onerror = resolve
      tx.onabort = resolve
    } catch { resolve() }
  })
}

export async function ttsCacheClear() {
  const db = await openDB()
  if (!db) return
  return new Promise((resolve) => {
    try {
      const tx = db.transaction(STORE, 'readwrite')
      tx.objectStore(STORE).clear()
      tx.oncomplete = resolve
      tx.onerror = resolve
    } catch { resolve() }
  })
}
