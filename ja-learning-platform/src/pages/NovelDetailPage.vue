<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import { useLearningStore } from '../store'
import { speakJapanese, stopJapaneseSpeech } from '../utils/japaneseSpeech'

const route = useRoute(), router = useRouter(), api = useLearningStore()
const lesson = ref(null), error = ref(''), loading = ref(true), starting = ref(false)
const selectedWord = ref(null)
const speechStatus = ref('idle'), speechError = ref('')
const visibleCount = ref(2), loadTrigger = ref(null)
const fontSize = ref(18), showSettings = ref(false)
// 移动端底部抽屉（仅≤768px 使用）
const drawerToken = ref(null)
const visiblePages = computed(() => lesson.value?.pages?.slice(0, visibleCount.value) || [])
const hasMorePages = computed(() => visibleCount.value < (lesson.value?.pages?.length || 0))
let observer = null, loadVersion = 0, speechSelectionId = 0

function disconnectObserver() { observer?.disconnect(); observer = null }
async function selectWord(token, key, event) {
  const selectionId = ++speechSelectionId
  selectedWord.value = selectedWord.value === key ? null : key
  // 移动端：打开底部抽屉
  if (window.matchMedia('(max-width: 768px)').matches) {
    drawerToken.value = token
  }
  speechError.value = ''
  try {
    await speakJapanese(token.reading || token.word, status => {
      if (selectionId === speechSelectionId) speechStatus.value = status
    })
  } catch {
    if (selectionId === speechSelectionId) {
      speechStatus.value = 'idle'
      speechError.value = '发音暂时不可用，请检查网络或换用较新的浏览器后重试。'
    }
  }
}
async function load() {
  const version = ++loadVersion
  disconnectObserver()
  speechSelectionId++
  stopJapaneseSpeech()
  speechStatus.value = 'idle'; speechError.value = ''
  loading.value = true; error.value = ''; lesson.value = null
  selectedWord.value = null; drawerToken.value = null; visibleCount.value = 2
  try {
    const result = await api.request(`novel-lessons/${encodeURIComponent(route.params.id)}`)
    if (version === loadVersion) lesson.value = result
  } catch (e) { if (version === loadVersion) error.value = e.message }
  finally { if (version === loadVersion) loading.value = false }
}
async function start() {
  if (!lesson.value?.paperId) {
    error.value = '本篇尚未关联练习题'
    return
  }
  starting.value = true; error.value = ''
  try { 
    const paperId = lesson.value.paperId
    const s = await api.startFun(paperId)
    router.push(`/sessions/${s.id}`) 
  } catch (e) { 
    error.value = e.message 
  } finally { 
    starting.value = false 
  }
}
function adjustFont(delta) {
  fontSize.value = Math.max(16, Math.min(24, fontSize.value + delta))
}
watch([loadTrigger, visibleCount], async (_, __, onCleanup) => {
  let cancelled = false
  onCleanup(() => { cancelled = true; disconnectObserver() })
  disconnectObserver()
  if (!loadTrigger.value || !hasMorePages.value) return
  await nextTick()
  const element = loadTrigger.value
  if (cancelled || !element || !hasMorePages.value) return
  observer = new IntersectionObserver(([entry]) => {
    if (entry.isIntersecting && hasMorePages.value) {
      visibleCount.value = Math.min(visibleCount.value + 2, lesson.value?.pages?.length || 0)
    }
  }, { rootMargin: '400px 0px' })
  observer.observe(element)
}, { flush: 'post' })
watch(hasMorePages, (more) => { if (!more) disconnectObserver() })
onMounted(load)
watch(() => route.params.id, load)
onBeforeUnmount(() => { loadVersion++; speechSelectionId++; disconnectObserver(); stopJapaneseSpeech() })
</script>

<template>
  <div class="content-page detail-page novel-detail">
    <!-- 顶部工具栏：返回、标题、设置 -->
    <div class="reader-topbar">
      <RouterLink class="topbar-back" to="/novel" aria-label="返回趣味阅读">←<span class="topbar-back-text">返回趣味阅读</span></RouterLink>
      <h1 class="topbar-title">{{ lesson?.title || '未命名章节' }}</h1>
      <button class="topbar-settings" type="button" @click="showSettings = !showSettings" :aria-expanded="showSettings" aria-label="阅读设置">⚙</button>
    </div>

    <!-- 设置面板（字体大小） -->
    <div v-if="showSettings" class="settings-panel">
      <div class="setting-row">
        <span class="setting-label">字体大小</span>
        <div class="font-controls">
          <button type="button" @click="adjustFont(-2)" aria-label="减小字号">A-</button>
          <span class="font-size">{{ fontSize }}px</span>
          <button type="button" @click="adjustFont(2)" aria-label="增大字号">A+</button>
        </div>
      </div>
    </div>

    <RouterLink class="back-dark desktop-only" to="/novel">← 返回趣味阅读</RouterLink>

    <div v-if="loading" class="state-box mob-novel-detail-skeleton" aria-hidden="true">
      <div class="sk-toolbar">
        <div class="skeleton sk-back"></div>
        <div class="skeleton sk-title"></div>
        <div class="skeleton sk-settings"></div>
      </div>
      <div class="sk-header">
        <div class="skeleton sk-meta"></div>
        <div class="skeleton sk-h2"></div>
        <div class="skeleton sk-lead"></div>
        <div class="skeleton sk-btn"></div>
      </div>
      <div class="sk-content">
        <div class="skeleton sk-intro"></div>
        <div v-for="n in 3" :key="n" class="sk-page">
          <div class="skeleton sk-line"></div>
          <div class="skeleton sk-line"></div>
          <div class="skeleton sk-line"></div>
          <div class="skeleton sk-line short"></div>
        </div>
      </div>
      <span class="desk-loading-text">正在读取章节…</span>
    </div>
    <div v-else-if="error && !lesson" class="state-box error">{{ error }} <button @click="load">重试</button></div>

    <template v-else-if="lesson">
      <header class="story-heading desktop-only">
        <div class="section-top"><p class="eyebrow">STORY / {{ lesson.category || '未分类' }}</p><span>{{ lesson.questionCount || 0 }} 道练习</span></div>
        <h2>{{ lesson.title || '未命名章节' }}</h2>
        <p class="page-lead">{{ lesson.note || '' }}</p>
        <div class="detail-actions"><button class="primary-action" :disabled="!lesson.published || !lesson.paperId || starting" @click="start">{{ starting ? '正在准备…' : '开始本篇练习 ↗' }}</button></div>
        <p v-if="error" class="action-error" role="alert">{{ error }}</p>
      </header>

      <!-- 移动端：精简头部 -->
      <header class="story-heading-mobile mobile-only">
        <div class="mobile-meta">{{ lesson.category || '未分类' }} · {{ lesson.questionCount || 0 }} 道练习</div>
        <h2>{{ lesson.title || '未命名章节' }}</h2>
        <p v-if="lesson.note" class="mobile-lead">{{ lesson.note }}</p>
        <div class="mobile-actions">
          <button class="primary-action" :disabled="!lesson.published || !lesson.paperId || starting" @click="start">
            {{ starting ? '正在准备…' : '开始练习 ↗' }}
          </button>
        </div>
        <p v-if="error" class="action-error" role="alert">{{ error }}</p>
      </header>

      <div class="reading-layout">
        <main class="reading-column">
          <div class="reading-intro">
            <span>原文阅读</span>
            <p>按自己的节奏往下读，后续内容会自动加载。点击词语查看释义。</p>
          </div>
          <div class="pages-container" :style="{ '--reader-font-size': fontSize + 'px' }">
            <article v-for="(p, i) in visiblePages" :key="p.number ?? i" class="reader-page page-section">
              <div v-if="p.recall" class="reader-label">背诵回忆版</div>
              <template v-if="p.readingTokens?.length">
                <p v-if="i === 0" class="reader-hint">假名标在词语上方，点击词语查看中文释义并听发音。首次使用会下载日语语音模型，可能需要稍等。</p>
                <p v-if="i === 0 && speechStatus !== 'idle'" class="speech-status" role="status">{{ speechStatus === 'playing' ? '正在播放发音…' : speechStatus === 'generating' ? '正在生成发音…' : '正在加载日语语音模型…' }}</p>
                <p v-if="i === 0 && speechError" class="speech-error" role="alert">{{ speechError }}</p>
                <div class="annotated-text">
                  <template v-for="(token, j) in p.readingTokens" :key="j">
                    <button v-if="token.word" type="button" class="ruby-word" :aria-expanded="selectedWord === `${i}-${j}`" @click="selectWord(token, `${i}-${j}`, $event)">
                      <ruby>{{ token.word }}<rt>{{ token.reading }}</rt></ruby>
                      <!-- 桌面端：popover -->
                      <span v-if="selectedWord === `${i}-${j}`" class="word-popover" role="tooltip">{{ token.meaning }}</span>
                    </button>
                    <span v-else>{{ token.text }}</span>
                  </template>
                </div>
              </template>
              <p v-else class="reading-text">{{ p.text }}</p>
            </article>
            <p v-if="lesson.pages?.length === 0" class="no-content">本章内容正在加载中…</p>
          </div>
          <div v-if="hasMorePages" ref="loadTrigger" class="load-trigger" role="status">向下滚动，继续阅读…</div>
          <div v-else-if="lesson.pages?.length" class="reading-end">本篇已读到底 · 可以回顾词卡或开始练习</div>
        </main>
        <aside class="reading-sidebar desktop-only">
          <details class="vocab-panel"><summary>本篇词卡（{{ lesson.vocabulary?.length || 0 }}）<span>先阅读，再展开回顾</span></summary><div class="vocab-grid"><article v-for="(v, i) in lesson.vocabulary || []" :key="i"><strong>{{ v.word }}</strong><p>{{ v.meaning || '原文记忆词' }}</p><small>{{ v.excerpt }}</small></article></div></details>
        </aside>
      </div>

      <!-- 移动端词卡底部抽屉 -->
      <div v-if="drawerToken" class="word-drawer-overlay" @click.self="drawerToken = null">
        <div class="word-drawer" role="dialog" aria-label="词卡">
          <div class="drawer-handle"></div>
          <div class="drawer-header">
            <div class="drawer-word-group">
              <h3>{{ drawerToken.word }}</h3>
              <span class="drawer-reading">{{ drawerToken.reading }}</span>
            </div>
            <button type="button" class="drawer-close" @click="drawerToken = null" aria-label="关闭">×</button>
          </div>
          <div class="drawer-body">
            <p class="drawer-meaning">{{ drawerToken.meaning }}</p>
            <p v-if="speechStatus !== 'idle'" class="drawer-speech" role="status">
              {{ speechStatus === 'playing' ? '正在播放发音…' : speechStatus === 'generating' ? '正在生成发音…' : '加载中…' }}
            </p>
            <p v-if="speechError" class="drawer-speech-error">{{ speechError }}</p>
          </div>
        </div>
      </div>
    </template>

    <!-- 移动端底部操作栏 -->
    <nav class="reader-bottombar mobile-only">
      <button class="bottom-btn" type="button" disabled aria-label="上一章">上一章</button>
      <RouterLink class="bottom-btn" to="/novel" aria-label="目录">目录</RouterLink>
      <button class="bottom-btn" type="button" disabled aria-label="下一章">下一章</button>
    </nav>
  </div>
</template>

<style scoped>
.novel-detail { 
  --reader-accent: var(--season-accent, #a44769); 
  --reader-ink: var(--season-ink, #633449); 
  --reader-line: var(--season-line, #e8cbd5); 
  --reader-soft: var(--season-soft, #faedf1); 
}

/* 桌面端/移动端通用工具栏 */
.reader-topbar {
  display: none;
}

.desktop-only { display: block; }
.mobile-only { display: none; }

/* 顶部工具栏样式 */
.reader-topbar {
  position: sticky;
  top: 0;
  z-index: 40;
  background: var(--theme-surface, #fffdf8);
  border-bottom: 1px solid var(--reader-line);
  padding: 10px 16px;
  display: flex;
  align-items: center;
  gap: 10px;
  min-height: 48px;
  backdrop-filter: blur(8px);
}
.topbar-back {
  flex: none;
  width: 40px;
  height: 40px;
  display: grid;
  place-items: center;
  border-radius: 10px;
  background: var(--reader-soft);
  color: var(--reader-ink);
  text-decoration: none;
  font-size: 18px;
  font-weight: 600;
}
.topbar-back:active {
  transform: scale(0.95);
}
.topbar-title {
  flex: 1;
  min-width: 0;
  font: 600 15px/1.3 'Zen Kaku Gothic New', sans-serif;
  margin: 0;
  color: var(--reader-ink);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  text-align: center;
}
.topbar-settings {
  flex: none;
  width: 40px;
  height: 40px;
  display: grid;
  place-items: center;
  border: 1px solid var(--reader-line);
  border-radius: 10px;
  background: transparent;
  color: var(--reader-ink);
  font-size: 18px;
  cursor: pointer;
}
.topbar-settings:active {
  background: var(--reader-soft);
}

/* 设置面板 */
.settings-panel {
  display: none;
}
.setting-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background: var(--reader-soft);
  border-bottom: 1px solid var(--reader-line);
}
.setting-label {
  font-size: 13px;
  color: var(--reader-ink);
  font-weight: 600;
}
.font-controls {
  display: flex;
  align-items: center;
  gap: 10px;
}
.font-controls button {
  min-width: 44px;
  min-height: 44px;
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--reader-line);
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  color: var(--reader-ink);
  cursor: pointer;
}
.font-controls button:active {
  background: var(--reader-line);
}
.font-size {
  font-size: 13px;
  color: var(--reader-ink);
  min-width: 48px;
  text-align: center;
  font-variant-numeric: tabular-nums;
}

/* 移动端精简头部 */
.story-heading-mobile {
  padding: 20px 16px 16px;
  border-bottom: 1px solid var(--reader-line);
}
.mobile-meta {
  font-size: 12px;
  color: var(--reader-accent);
  letter-spacing: 0.08em;
  font-weight: 600;
  margin-bottom: 8px;
}
.story-heading-mobile h2 {
  font: 700 22px/1.35 'Zen Kaku Gothic New', sans-serif;
  margin: 0 0 8px;
  color: var(--reader-ink);
}
.mobile-lead {
  font-size: 13px;
  line-height: 1.7;
  color: var(--theme-text-secondary, #67746a);
  margin: 0 0 16px;
}
.mobile-actions {
  margin-top: 12px;
}
.mobile-actions .primary-action {
  width: 100%;
  min-height: 44px;
  padding: 12px;
  font-size: 15px;
}
.action-error {
  color: #984d45;
  font-size: 13px;
  margin-top: 8px;
}

.story-heading { max-width: 900px; padding-bottom: 8px; }
.story-heading h2 { margin-top: 28px; line-height: 1.35; }
.story-heading .page-lead { max-width: 680px; }
.story-heading .detail-actions { margin: 28px 0 32px; }

.reading-layout { 
  display: grid; 
  grid-template-columns: minmax(0, 1fr) minmax(230px, 285px); 
  gap: clamp(24px, 4vw, 56px); 
  align-items: start; 
  margin-top: 25px; 
}
.reading-column, .reading-sidebar { min-width: 0; }
.reading-intro { border-top: 1px solid var(--reader-line); padding: 20px 0 18px; display: flex; align-items: baseline; flex-wrap: wrap; gap: 8px 18px; }
.reading-intro span { color: var(--reader-ink); font-size: 13px; font-weight: 700; letter-spacing: .1em; }
.reading-intro p { margin: 0; color: var(--theme-text-secondary, #67746a); font-size: 12px; line-height: 1.8; }
.pages-container { display: grid; gap: 24px; }
.page-section { margin: 0; border: 0; border-radius: 0; padding: 0; background: transparent; color: var(--theme-text, #35473d); }
.reader-label { padding: 16px 0; margin-bottom: 24px; border-top: 1px solid var(--reader-line); border-bottom: 1px solid var(--reader-line); color: var(--reader-ink); font-size: 12px; font-weight: 700; letter-spacing: .08em; }
.reader-hint { margin: 0 0 24px; font-size: 12px; line-height: 1.8; color: var(--theme-text-secondary, #788177); }
.speech-status, .speech-error { margin: -12px 0 20px; font-size: 12px; line-height: 1.6; color: var(--reader-ink); }
.speech-error { color: #984d45; }

.annotated-text, .reading-text { 
  white-space: pre-wrap; 
  overflow-wrap: anywhere; 
  font-size: var(--reader-font-size, var(--base-font-size, 17px)); 
  line-height: var(--base-line-height, 2.2); 
  color: inherit; 
}
.reading-text { margin: 0; }

.ruby-word { position: relative; display: inline; padding: 0 2px; border: 0; background: transparent; color: inherit; cursor: pointer; font: inherit; text-decoration: underline dotted var(--reader-accent); text-decoration-thickness: 1px; text-underline-offset: .22em; }
.ruby-word rt { font-size: var(--ruby-font-size, 11px); }
.ruby-word:hover, .ruby-word:focus-visible { color: var(--reader-ink); background: var(--reader-soft); }
.ruby-word:focus-visible { outline: 2px solid var(--reader-accent); outline-offset: 3px; }
.word-popover { position: absolute; bottom: calc(100% + 10px); left: 50%; transform: translateX(-50%); z-index: 2; max-width: min(280px, 70vw); width: max-content; padding: 8px 12px; background: var(--reader-ink); color: #fff; border-radius: 4px; font-size: 12px; line-height: 1.5; white-space: normal; letter-spacing: 0; box-shadow: 0 6px 18px #0002; }
.vocab-panel { margin: 0; padding: 24px; border: 1px solid var(--reader-line); background: var(--reader-soft); color: var(--reader-ink); }
.vocab-panel summary { font-size: 16px; line-height: 1.6; }
.vocab-panel summary span { color: var(--reader-ink); opacity: .7; }
.vocab-grid { grid-template-columns: 1fr; gap: 14px; max-height: 65vh; overflow-y: auto; }
.vocab-grid article { border-color: var(--reader-line); }
.vocab-grid p, .vocab-grid small { color: var(--reader-ink); }
.load-trigger, .reading-end { padding: 32px 16px; text-align: center; color: var(--reader-ink); font-size: 12px; letter-spacing: .05em; }
.reading-end { border-top: 1px solid var(--reader-line); margin-top: 20px; }

/* 移动端词卡底部抽屉 */
.word-drawer-overlay {
  position: fixed;
  inset: 0;
  z-index: 100;
  background: rgba(0, 0, 0, 0.35);
  display: flex;
  align-items: flex-end;
  justify-content: center;
  animation: fadeIn 0.2s ease;
}
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}
.word-drawer {
  background: var(--theme-surface, #fffdf8);
  width: 100%;
  max-width: 640px;
  height: 50vh;
  min-height: 240px;
  border-radius: 16px 16px 0 0;
  display: flex;
  flex-direction: column;
  box-shadow: 0 -8px 30px rgba(0, 0, 0, 0.15);
  animation: slideUp 0.25s cubic-bezier(0.16, 1, 0.3, 1);
  overflow: hidden;
}
@keyframes slideUp {
  from { transform: translateY(100%); }
  to { transform: translateY(0); }
}
.drawer-handle {
  width: 36px;
  height: 4px;
  background: var(--reader-line);
  border-radius: 2px;
  margin: 10px auto 0;
  flex: none;
}
.drawer-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 16px 20px 8px;
  gap: 12px;
}
.drawer-word-group {
  min-width: 0;
}
.drawer-word-group h3 {
  font: 700 24px/1.2 'Zen Kaku Gothic New', sans-serif;
  margin: 0 0 4px;
  color: var(--reader-ink);
}
.drawer-reading {
  font-size: 14px;
  color: var(--reader-accent);
  font-weight: 500;
}
.drawer-close {
  flex: none;
  width: 40px;
  height: 40px;
  display: grid;
  place-items: center;
  border: 1px solid var(--reader-line);
  border-radius: 50%;
  background: transparent;
  color: var(--reader-ink);
  font-size: 22px;
  line-height: 1;
  cursor: pointer;
}
.drawer-close:active {
  background: var(--reader-soft);
}
.drawer-body {
  flex: 1;
  padding: 12px 20px 24px;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}
.drawer-meaning {
  font-size: 16px;
  line-height: 1.7;
  color: var(--theme-text, #27302b);
  margin: 0 0 16px;
}
.drawer-speech {
  font-size: 13px;
  color: var(--reader-ink);
  padding: 10px 14px;
  background: var(--reader-soft);
  border-radius: 8px;
  margin: 0;
}
.drawer-speech-error {
  font-size: 13px;
  color: #984d45;
  margin: 0;
}

/* 移动端底部操作栏 */
.reader-bottombar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 56px;
  background: var(--theme-surface, #fffdf8);
  border-top: 1px solid var(--reader-line);
  display: flex;
  align-items: center;
  gap: 0;
  padding: 0 8px;
  z-index: 30;
  padding-bottom: env(safe-area-inset-bottom, 0);
}
.bottom-btn {
  flex: 1;
  min-height: 44px;
  display: grid;
  place-items: center;
  padding: 0 12px;
  background: transparent;
  border: none;
  color: var(--reader-ink);
  text-decoration: none;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  border-radius: 8px;
  transition: background 0.3s cubic-bezier(0.34, 1.56, 0.64, 1),
              transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}
.bottom-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}
.bottom-btn:not(:disabled):active {
  background: var(--reader-soft);
  transform: scale(0.97);
}

/* 移动端改造 */
@media (max-width: 768px) {
  .desktop-only { display: none !important; }
  .mobile-only { display: block; }
  .reader-topbar { display: flex; }
  .settings-panel { display: block; }

  .novel-detail {
    padding-bottom: 80px;
  }

  .reading-layout {
    grid-template-columns: 1fr;
    margin-top: 0;
  }

  .reading-intro {
    padding: 16px;
    border-top: none;
    border-bottom: 1px solid var(--reader-line);
  }
  .reading-intro span {
    font-size: 12px;
  }
  .reading-intro p {
    font-size: 13px;
  }

  .pages-container {
    padding: 0 16px;
    gap: 20px;
  }
  
  /* 字体 ≥ 18px、行高 ≥ 1.8、padding 16px */
  .annotated-text, .reading-text {
    font-size: var(--reader-font-size, 18px);
    line-height: 1.8;
  }

  .ruby-word {
    min-height: 44px;
    touch-action: manipulation;
  }
  .ruby-word rt {
    font-size: 12px;
  }

  /* 隐藏桌面端 popover（移动端用抽屉代替） */
  .word-popover {
    display: none;
  }

  .load-trigger, .reading-end {
    padding: 24px 16px;
    font-size: 13px;
  }
}

@media (max-width: 800px) and (min-width: 769px) {
  .reading-layout { grid-template-columns: 1fr; }
  .vocab-grid { max-height: 50vh; }
}

@media (max-width: 480px) {
  .reader-label { margin-bottom: 20px; }
  .story-heading-mobile h2 { font-size: 20px; }
}

/* ===== 骨架屏（移动端小说详情页） ===== */
.mob-novel-detail-skeleton {
  padding: 0 16px 32px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}
.mob-novel-detail-skeleton .skeleton {
  background: linear-gradient(90deg, #f5f2e9 25%, #fffdf8 50%, #f5f2e9 75%);
  background-size: 200% 100%;
  animation: novel-shimmer 1.5s ease-in-out infinite;
  border-radius: 6px;
}
@keyframes novel-shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
.sk-toolbar {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 0;
}
.sk-back {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  flex: none;
}
.sk-title {
  flex: 1;
  height: 18px;
}
.sk-settings {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  flex: none;
}
.sk-header {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 16px 0;
  border-bottom: 1px solid var(--reader-line, #e8cbd5);
}
.sk-meta {
  width: 40%;
  height: 12px;
}
.sk-h2 {
  width: 70%;
  height: 22px;
  border-radius: 6px;
}
.sk-lead {
  width: 90%;
  height: 14px;
}
.sk-btn {
  width: 100%;
  height: 44px;
  margin-top: 8px;
  border-radius: 10px;
}
.sk-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding-top: 8px;
}
.sk-intro {
  width: 50%;
  height: 14px;
  margin-bottom: 4px;
}
.sk-page {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 12px 0;
}
.sk-line {
  width: 100%;
  height: 16px;
  border-radius: 4px;
}
.sk-line.short {
  width: 60%;
}
.desk-loading-text {
  display: none;
}
@media (max-width: 768px) {
  .mob-novel-detail-skeleton {
    padding-top: 8px;
  }
}
</style>
