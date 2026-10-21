<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import { useLearningStore } from '../store'
import { speakJapanese, stopJapaneseSpeech } from '../utils/japaneseSpeech'

const route = useRoute(), router = useRouter(), api = useLearningStore()
const lesson = ref(null), error = ref(''), loading = ref(true), starting = ref(false), selectedWord = ref(null)
const speechStatus = ref('idle'), speechError = ref('')
const visibleCount = ref(2), loadTrigger = ref(null)
const visiblePages = computed(() => lesson.value?.pages?.slice(0, visibleCount.value) || [])
const hasMorePages = computed(() => visibleCount.value < (lesson.value?.pages?.length || 0))
let observer = null, loadVersion = 0, speechSelectionId = 0

function disconnectObserver() { observer?.disconnect(); observer = null }
async function selectWord(token, key) {
  const selectionId = ++speechSelectionId
  selectedWord.value = selectedWord.value === key ? null : key
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
  selectedWord.value = null; visibleCount.value = 2
  try {
    const result = await api.request(`novel-lessons/${encodeURIComponent(route.params.id)}`)
    if (version === loadVersion) lesson.value = result
  } catch (e) { if (version === loadVersion) error.value = e.message }
  finally { if (version === loadVersion) loading.value = false }
}
async function start() {
  starting.value = true; error.value = ''
  try { const s = await api.startFun(lesson.value.paperId); router.push(`/sessions/${s.id}`) }
  catch (e) { error.value = e.message }
  finally { starting.value = false }
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
      visibleCount.value = Math.min(visibleCount.value + 2, lesson.value.pages.length)
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
    <RouterLink class="back-dark" to="/novel">← 返回趣味阅读</RouterLink>
    <div v-if="loading" class="state-box">正在读取章节…</div>
    <div v-else-if="error && !lesson" class="state-box error">{{ error }} <button @click="load">重试</button></div>
    <template v-else-if="lesson">
      <header class="story-heading">
        <div class="section-top"><p class="eyebrow">STORY / {{ lesson.category }}</p><span>{{ lesson.questionCount }} 道练习</span></div>
        <h2>{{ lesson.title }}</h2>
        <p class="page-lead">{{ lesson.note }}</p>
        <div class="detail-actions"><button class="primary-action" :disabled="!lesson.published || starting" @click="start">{{ starting ? '正在准备…' : '开始本篇练习 ↗' }}</button></div>
        <p v-if="error" class="action-error" role="alert">{{ error }}</p>
      </header>
      <div class="reading-layout">
        <main class="reading-column">
          <div class="reading-intro"><span>原文阅读</span><p>按自己的节奏往下读，后续内容会自动加载。</p></div>
          <div class="pages-container">
            <article v-for="(p, i) in visiblePages" :key="p.number ?? i" class="reader-page page-section">
              <div v-if="p.recall" class="reader-label">背诵回忆版</div>
              <template v-if="p.readingTokens?.length">
                <p v-if="i === 0" class="reader-hint">假名标在词语上方，点击词语查看中文释义并听发音。首次使用会下载日语语音模型，可能需要稍等。</p>
                <p v-if="i === 0 && speechStatus !== 'idle'" class="speech-status" role="status">{{ speechStatus === 'playing' ? '正在播放发音…' : speechStatus === 'generating' ? '正在生成发音…' : '正在加载日语语音模型…' }}</p>
                <p v-if="i === 0 && speechError" class="speech-error" role="alert">{{ speechError }}</p>
                <div class="annotated-text">
                  <template v-for="(token, j) in p.readingTokens" :key="j">
                    <button v-if="token.word" type="button" class="ruby-word" :aria-expanded="selectedWord === `${i}-${j}`" @click="selectWord(token, `${i}-${j}`)">
                      <ruby>{{ token.word }}<rt>{{ token.reading }}</rt></ruby>
                      <span v-if="selectedWord === `${i}-${j}`" class="word-popover" role="tooltip">{{ token.meaning }}</span>
                    </button>
                    <span v-else>{{ token.text }}</span>
                  </template>
                </div>
              </template>
              <p v-else class="reading-text">{{ p.text }}</p>
            </article>
          </div>
          <div v-if="hasMorePages" ref="loadTrigger" class="load-trigger" role="status">向下滚动，继续阅读…</div>
          <div v-else-if="lesson.pages?.length" class="reading-end">本篇已读到底 · 可以回顾词卡或开始练习</div>
        </main>
        <aside class="reading-sidebar">
          <details class="vocab-panel"><summary>本篇词卡（{{ lesson.vocabulary?.length || 0 }}）<span>先阅读，再展开回顾</span></summary><div class="vocab-grid"><article v-for="(v, i) in lesson.vocabulary || []" :key="i"><strong>{{ v.word }}</strong><p>{{ v.meaning || '原文记忆词' }}</p><small>{{ v.excerpt }}</small></article></div></details>
        </aside>
      </div>
    </template>
  </div>
</template>

<style scoped>
.novel-detail { --reader-accent: var(--season-accent, #a44769); --reader-ink: var(--season-ink, #633449); --reader-line: var(--season-line, #e8cbd5); --reader-soft: var(--season-soft, #faedf1); }
.story-heading { max-width: 900px; padding-bottom: 8px; }
.story-heading h2 { margin-top: 28px; line-height: 1.35; }
.story-heading .page-lead { max-width: 680px; }
.story-heading .detail-actions { margin: 28px 0 32px; }
.action-error { color: #984d45; font-size: 13px; }
.reading-layout { display: grid; grid-template-columns: minmax(0, 1fr) minmax(230px, 285px); gap: clamp(24px, 4vw, 56px); align-items: start; margin-top: 25px; }
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
.annotated-text, .reading-text { white-space: pre-wrap; overflow-wrap: anywhere; font-size: var(--base-font-size, 17px); line-height: var(--base-line-height, 2.2); color: inherit; }
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
@media (max-width: 800px) { .reading-layout { grid-template-columns: 1fr; } .vocab-grid { max-height: 50vh; } }
@media (max-width: 480px) { .reader-label { margin-bottom: 20px; } .story-heading .detail-actions { margin-bottom: 24px; } }
</style>
