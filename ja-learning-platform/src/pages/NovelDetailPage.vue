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
const fontSize = ref(18), showFontSizeDrawer = ref(false)
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
  } catch (speechFailure) {
    console.error('[TTS] word playback failed:', speechFailure)
    if (selectionId === speechSelectionId) {
      speechStatus.value = 'idle'
      speechError.value = '发音暂时不可用，请稍后重试。'
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
  fontSize.value = Math.max(14, Math.min(32, fontSize.value + delta))
}
const fontSettingsButton = ref(null), fontDialog = ref(null)
let previousBodyOverflow = '', previouslyFocused = null
function openFontSizeSettings() { showFontSizeDrawer.value = true }
function onSettingsKeydown(event) {
  if (event.key === 'Escape') showFontSizeDrawer.value = false
  if (event.key !== 'Tab' || !fontDialog.value) return
  const controls = [...fontDialog.value.querySelectorAll('button:not(:disabled), input')]
  const first = controls[0], last = controls[controls.length - 1]
  if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last?.focus() }
  else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first?.focus() }
}
watch(showFontSizeDrawer, async (open) => {
  if (open) {
    previouslyFocused = document.activeElement
    previousBodyOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    await nextTick()
    fontDialog.value?.focus()
  } else {
    document.body.style.overflow = previousBodyOverflow
    previouslyFocused?.focus()
  }
})
onBeforeUnmount(() => { if (showFontSizeDrawer.value) document.body.style.overflow = previousBodyOverflow })
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
    <div class="reader-toolbar">
      <nav class="reader-topbar" aria-label="阅读工具栏">
        <RouterLink class="topbar-back" to="/novel" aria-label="返回趣味阅读目录">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><path d="m14 6-6 6 6 6" stroke-linecap="round" stroke-linejoin="round" /></svg>
          <span>返回</span>
        </RouterLink>
        <span class="topbar-title">{{ lesson?.title || '原文阅读' }}</span>
        <button class="topbar-settings" ref="fontSettingsButton" :class="{ active: showFontSizeDrawer }" type="button" @click="openFontSizeSettings()" :aria-expanded="showFontSizeDrawer" aria-controls="reader-font-settings" aria-label="调整阅读字号">
          <span class="settings-mark" aria-hidden="true">Aa</span>
        </button>
      </nav>
    </div>

    <div v-if="loading" class="state-box mob-novel-detail-skeleton" aria-hidden="true">
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
                <p v-if="i === 0" class="reader-hint">假名标在词语上方，点击词语查看中文释义并听发音。首次发音需要稍等片刻，正在准备语音引擎。</p>
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

      <Teleport to="body">
        <Transition name="font-sheet">
          <div v-if="showFontSizeDrawer" class="font-size-drawer-overlay" @click.self="showFontSizeDrawer = false" @keydown="onSettingsKeydown">
            <section ref="fontDialog" id="reader-font-settings" class="font-size-drawer" role="dialog" aria-modal="true" aria-labelledby="font-sheet-title" tabindex="-1">
              <div class="drawer-handle" aria-hidden="true"></div>
              <div class="font-sheet-heading">
                <div><h2 id="font-sheet-title">阅读字号</h2><p>调到适合你的大小，安心读下去。</p></div>
                <button type="button" class="drawer-close" @click="showFontSizeDrawer = false" aria-label="关闭字号设置">×</button>
              </div>
              <div class="font-sheet-content">
                <div class="font-size-preview">
                  <span class="preview-label">效果预览</span>
                  <p :style="{ fontSize: fontSize + 'px' }" lang="ja">風がそっと木々を揺らす。<br>今日は、少し遠くまで歩こう。</p>
                </div>
                <div class="font-size-caption"><label for="reader-font-range">正文字号</label><output for="reader-font-range" aria-live="polite">{{ fontSize }}<small> px</small></output></div>
                <div class="font-slider-row">
                  <button type="button" @click="adjustFont(-1)" :disabled="fontSize <= 14" aria-label="减小字号">A−</button>
                  <input id="reader-font-range" v-model.number="fontSize" type="range" min="14" max="32" step="1" :aria-valuetext="fontSize + ' 像素'" />
                  <button type="button" @click="adjustFont(1)" :disabled="fontSize >= 32" aria-label="增大字号">A+</button>
                </div>
                <div class="font-presets" aria-label="快捷字号">
                  <button v-for="preset in [{ size: 16, label: '小' }, { size: 18, label: '标准' }, { size: 22, label: '大' }, { size: 26, label: '特大' }]" :key="preset.size" type="button" :aria-pressed="fontSize === preset.size" @click="fontSize = preset.size">{{ preset.label }}<small>{{ preset.size }}</small></button>
                </div>
              </div>
              <div class="font-sheet-footer"><button type="button" class="font-reset" @click="fontSize = 18">恢复默认</button><button type="button" class="font-size-confirm" @click="showFontSizeDrawer = false">完成</button></div>
            </section>
          </div>
        </Transition>
      </Teleport>
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
  padding-top: calc(72px + env(safe-area-inset-top, 0px));
  --reader-accent: var(--season-accent, #a44769);
  --reader-ink: var(--season-ink, #633449);
  --reader-line: var(--season-line, #e8cbd5);
  --reader-soft: var(--season-soft, #faedf1);
}

.desktop-only { display: block; }
.mobile-only { display: none; }

.reader-toolbar {
  position: fixed;
  inset: 0 0 auto;
  z-index: 40;
  display: block;
  margin: 0;
  padding-top: env(safe-area-inset-top, 0px);
  border-bottom: 1px solid var(--reader-line);
  background: var(--theme-surface, #fffdf8);
}
.reader-topbar {
  display: grid;
  grid-template-columns: 84px minmax(0, 1fr) 84px;
  align-items: center;
  gap: 8px;
  min-height: 64px;
  padding: 8px 20px;
}
.topbar-back, .topbar-settings {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
  min-height: 44px;
  padding: 0 10px;
  border: 1px solid transparent;
  border-radius: 12px;
  color: var(--reader-ink);
  background: transparent;
  text-decoration: none;
  white-space: nowrap;
  font-family: inherit;
  font-size: 13px;
  font-weight: 500;
  line-height: 1.2;
  cursor: pointer;
  touch-action: manipulation;
}
.topbar-back { justify-self: start; padding-left: 0; }
.topbar-settings { grid-column: 3; justify-self: end; border-color: var(--reader-line); }
.topbar-settings.active, .topbar-settings:hover { background: var(--reader-soft); }
.topbar-back:focus-visible, .topbar-settings:focus-visible, .font-controls button:focus-visible {
  outline: 2px solid var(--reader-accent);
  outline-offset: 3px;
}
.settings-mark { font: 600 20px/1 Georgia, serif; letter-spacing: -.06em; }
.reading-layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(230px, 285px);
  gap: clamp(24px, 4vw, 56px);
  align-items: start;
  margin: 0 auto;
  max-width: 1200px;
  padding: 24px 32px 64px;
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

  /* 移动端工具栏：sticky + 半透明背景 */
  .reader-toolbar {
    position: fixed;
    inset: 0 0 auto;
    z-index: 50;
    margin-bottom: 0;
    border-bottom: 1px solid var(--reader-line);
    background: rgba(255, 253, 248, 0.95);
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
  }
  .reader-topbar {
    display: grid;
    grid-template-columns: 68px minmax(0, 1fr) 48px;
    align-items: center;
    padding: 8px 16px;
    min-height: 56px;
  }
  .topbar-settings {
    justify-self: end;
    border-color: var(--reader-line);
    background: rgba(255, 253, 248, 0.85);
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
  }
  .topbar-back {
    background: rgba(255, 253, 248, 0.85);
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
  }

  /* 移动端隐藏 header，只保留工具栏 */
  header.story-heading-mobile {
    display: none !important;
  }

  .novel-detail {
    padding-top: calc(72px + env(safe-area-inset-top, 0px));
    padding-bottom: 80px;
  }

  .reading-layout {
    grid-template-columns: 1fr;
    margin-top: 0;
    padding: 0 0 32px;
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
  .reader-topbar { padding-inline: 16px; }
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

<style scoped>
.topbar-title { min-width: 0; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; text-align: center; font-size: 14px; font-weight: 500; color: var(--reader-ink); }
.reader-topbar { width: 100%; box-sizing: border-box; max-width: 1280px; margin: auto; }
.reader-bottombar { display: none; }
@media (max-width: 768px) { .reader-bottombar { display: flex; } }
.font-size-drawer-overlay { --reader-ink: var(--season-ink, #633449); --reader-accent: var(--season-accent, #a44769); --reader-line: var(--season-line, #e8cbd5); --reader-soft: var(--season-soft, #faedf1); position: fixed; inset: 0; z-index: 1200; display: flex; align-items: flex-end; justify-content: center; background: #17241f66; backdrop-filter: blur(4px); }
.font-size-drawer { width: min(100%, 520px); box-sizing: border-box; max-height: calc(100dvh - 24px); overflow-y: auto; overscroll-behavior: contain; padding: 0 24px max(20px, env(safe-area-inset-bottom)); border: 1px solid var(--reader-line); border-bottom: 0; border-radius: 28px 28px 0 0; background: var(--theme-surface, #fffdf8); color: var(--theme-text, #35473d); box-shadow: 0 -12px 60px #15241f26; font-family: inherit; outline: none; }
.font-sheet-heading { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 22px 0; }
.font-sheet-heading h2 { margin: 0; font-weight: 600; font-family: inherit; font-size: 20px; line-height: 1.4; color: var(--reader-ink); }
.font-sheet-heading p { margin: 6px 0 0; font-size: 13px; line-height: 1.6; color: var(--theme-text-secondary, #72796f); }
.font-size-preview { padding: 18px 20px; border: 1px solid var(--reader-line); border-radius: 16px; background: var(--reader-soft); }
.preview-label { font-size: 11px; letter-spacing: .12em; color: var(--reader-ink); opacity: .75; }
.font-size-preview p { margin: 12px 0 0; min-height: 96px; font-family: 'Noto Serif JP', serif; line-height: 1.9; overflow-wrap: anywhere; color: var(--reader-ink); }
.font-size-caption { display: flex; align-items: center; justify-content: space-between; margin: 24px 0 8px; }
.font-size-caption label { font-size: 14px; font-weight: 600; }
.font-size-caption output { font-size: 24px; font-weight: 600; font-variant-numeric: tabular-nums; color: var(--reader-ink); }
.font-size-caption small { font-size: 12px; font-weight: 400; }
.font-slider-row { display: flex; align-items: center; gap: 16px; }
.font-slider-row button { flex: 0 0 44px; height: 44px; border: 1px solid var(--reader-line); border-radius: 12px; background: var(--theme-surface, #fffdf8); color: var(--reader-ink); font-size: 17px; cursor: pointer; }
.font-slider-row button:disabled { opacity: .35; cursor: default; }
.font-slider-row input { width: 100%; min-width: 0; height: 44px; margin: 0; accent-color: var(--reader-accent); cursor: pointer; }
.font-presets { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; margin-top: 16px; }
.font-presets button { min-height: 58px; border: 1px solid var(--reader-line); border-radius: 12px; background: transparent; color: var(--reader-ink); font-family: inherit; font-weight: 500; line-height: 1.4; font-size: 14px; cursor: pointer; }
.font-presets button small { display: block; margin-top: 3px; font-size: 11px; opacity: .7; }
.font-presets button[aria-pressed="true"] { background: var(--reader-soft); border-color: var(--reader-accent); box-shadow: inset 0 0 0 1px var(--reader-accent); }
.font-sheet-footer { display: grid; grid-template-columns: 1fr 2fr; gap: 12px; padding-top: 24px; }
.font-sheet-footer button { min-height: 48px; border-radius: 14px; font-family: inherit; font-size: 15px; font-weight: 600; cursor: pointer; }
.font-reset { border: 1px solid var(--reader-line); background: transparent; color: var(--reader-ink); }
.font-size-confirm { border: 0; background: var(--reader-accent); color: #fff; }
.font-size-drawer button:focus-visible, .font-slider-row input:focus-visible { outline: 2px solid var(--reader-accent); outline-offset: 3px; }
.font-sheet-enter-active, .font-sheet-leave-active { transition: opacity .2s ease; }
.font-sheet-enter-active .font-size-drawer, .font-sheet-leave-active .font-size-drawer { transition: transform .25s ease; }
.font-sheet-enter-from, .font-sheet-leave-to { opacity: 0; }
.font-sheet-enter-from .font-size-drawer, .font-sheet-leave-to .font-size-drawer { transform: translateY(100%); }
@media (max-width: 380px) { .font-size-drawer { padding-inline: 18px; } .font-sheet-heading p { font-size: 12px; } }
@media (prefers-reduced-motion: reduce) { .font-sheet-enter-active, .font-sheet-leave-active, .font-sheet-enter-active .font-size-drawer, .font-sheet-leave-active .font-size-drawer { transition: none; } }
</style>
