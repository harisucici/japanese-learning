<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch, nextTick } from 'vue'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import { useLearningStore } from '../store'
const route = useRoute(), router = useRouter(), api = useLearningStore()
const lesson = ref(null), error = ref(''), loading = ref(true), starting = ref(false), selectedWord = ref(null)

// Auto-scroll state for within-chapter pagination
const currentPageIndex = ref(0)
const pageRefs = ref([])
let scrollInterval = null
const isAutoScrolling = ref(false)
const scrollSpeed = 3000 // ms between pages

async function load() {
  loading.value = true; error.value = ''
  try {
    const id = route.params.id
    lesson.value = await api.request(`novel-lessons/${encodeURIComponent(id)}`)
    currentPageIndex.value = 0
    await nextTick()
    startAutoScroll()
  } catch (e) { error.value = e.message } finally { loading.value = false }
}
onMounted(load); watch(() => route.params.id, load)

async function start() { starting.value = true; error.value = ''; try { const s = await api.startFun(lesson.value.paperId); router.push(`/sessions/${s.id}`) } catch (e) { error.value = e.message } finally { starting.value = false } }

// --- Auto-scroll through pages ---
function startAutoScroll() {
  stopAutoScroll()
  isAutoScrolling.value = true
  scrollInterval = setInterval(() => {
    if (!lesson.value?.pages?.length) return
    if (currentPageIndex.value < lesson.value.pages.length - 1) {
      currentPageIndex.value++
      scrollToCurrentPage()
    } else {
      // Reached the last page, stop auto-scroll
      stopAutoScroll()
    }
  }, scrollSpeed)
}

function stopAutoScroll() {
  if (scrollInterval) {
    clearInterval(scrollInterval)
    scrollInterval = null
  }
  isAutoScrolling.value = false
}

async function scrollToCurrentPage() {
  await nextTick()
  const pageEl = pageRefs.value[currentPageIndex.value]
  if (pageEl) {
    pageEl.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }
}

function goToPage(index) {
  currentPageIndex.value = index
  stopAutoScroll()
  scrollToCurrentPage()
}

onBeforeUnmount(() => {
  stopAutoScroll()
})
</script>
<template><div class="content-page detail-page">
  <RouterLink class="back-dark" to="/novel">← 返回趣味阅读</RouterLink>
  <div v-if="loading" class="state-box">正在读取章节…</div>
  <div v-else-if="error" class="state-box error">{{error}} <button @click="load">重试</button></div>
  <template v-else>
    <div class="section-top"><p class="eyebrow">STORY / {{lesson.category}}</p><span>{{lesson.questionCount}} 道练习</span></div>
    <h2>{{lesson.title}}</h2>
    <p class="page-lead">{{lesson.note}}</p>
    <div class="detail-actions"><button class="primary-action" :disabled="!lesson.published||starting" @click="start">{{starting?'正在准备…':'开始本篇练习 ↗'}}</button></div>
    <details class="vocab-panel"><summary>本篇词卡（{{lesson.vocabulary?.length||0}}）<span>先阅读，再展开回顾</span></summary><div class="vocab-grid"><article v-for="(v,i) in lesson.vocabulary||[]" :key="i"><strong>{{v.word}}</strong><p>{{v.meaning||'原文记忆词'}} · 第 {{v.sourcePage}} 页</p><small>{{v.excerpt}}</small></article></div></details>

    <div class="auto-scroll-controls">
      <button v-if="isAutoScrolling" @click="stopAutoScroll" class="pause-btn">⏸ 暂停翻页</button>
      <button v-else @click="startAutoScroll" class="resume-btn">▶ 继续翻页</button>
      <span class="page-indicator">{{currentPageIndex + 1}} / {{lesson.pages?.length || 0}}</span>
    </div>

    <div class="pages-container">
      <article v-for="(p, i) in lesson.pages || []" :key="i" :ref="el => { if (el) pageRefs[i] = el }" class="reader-page page-section" :class="{ 'is-current': i === currentPageIndex }">
        <div class="reader-label">{{p.recall?'背诵回忆版':'原文阅读'}} · 第 {{p.number}} 页</div>
        <template v-if="p.readingTokens?.length">
          <p class="reader-hint">假名标在词语上方，点击词语查看中文释义。</p>
          <div class="annotated-text">
            <template v-for="(token,j) in p.readingTokens" :key="j">
              <button v-if="token.word" class="ruby-word" @click="selectedWord = (selectedWord === `${i}-${j}` ? null : `${i}-${j}`)">
                <ruby>{{token.word}}<rt>{{token.reading}}</rt></ruby>
                <span v-if="selectedWord === `${i}-${j}`" class="word-popover">{{token.meaning}}</span>
              </button>
              <span v-else>{{token.text}}</span>
            </template>
          </div>
        </template>
        <p v-else class="reading-text">{{p.text}}</p>
      </article>
    </div>
  </template>
</div></template>

<style scoped>
.auto-scroll-controls {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin: 1.5rem 0;
  padding: 1rem;
  background: #f5f5f5;
  border-radius: 8px;
}

.auto-scroll-controls button {
  padding: 0.5rem 1rem;
  border: 1px solid #ddd;
  border-radius: 6px;
  background: white;
  cursor: pointer;
  font-size: 0.9rem;
  transition: all 0.2s;
}

.auto-scroll-controls button:hover {
  background: #e9e9e9;
}

.auto-scroll-controls .pause-btn {
  background: #fff3cd;
  border-color: #ffc107;
}

.auto-scroll-controls .resume-btn {
  background: #d4edda;
  border-color: #28a745;
}

.page-indicator {
  margin-left: auto;
  font-size: 0.9rem;
  color: #666;
}

.pages-container {
  display: flex;
  flex-direction: column;
  gap: 0; /* 移除页面间距 */
}

.page-section {
  padding: 0; /* 移除内边距 */
  border: none; /* 移除边框 */
  border-radius: 0; /* 移除圆角 */
  transition: none; /* 移除过渡效果 */
  margin-bottom: 3rem; /* 页面间保留间距 */
}

.page-section:last-child {
  margin-bottom: 0;
}

.page-section.is-current {
  /* 高亮已移除 — 翻页不再显示蓝框 */
}

.reader-page {
  margin-bottom: 1.5rem;
}

.reader-label {
  font-size: 0.85rem;
  color: #666;
  margin-bottom: 0.5rem;
  font-weight: 500;
}

.reader-hint {
  font-size: 0.8rem;
  color: #999;
  margin-bottom: 1rem;
}

.annotated-text {
  line-height: 2.2;
  font-size: 1.1rem;
}

.ruby-word {
  position: relative;
  cursor: pointer;
  border-bottom: 1px dashed #2563eb;
  padding: 0 2px;
  background: none;
  border: none;
  font: inherit;
}

.ruby-word:hover {
  background: #e0f2fe;
}

.ruby-word ruby {
  ruby-align: center;
}

.word-popover {
  position: absolute;
  bottom: 100%;
  left: 50%;
  transform: translateX(-50%);
  background: #1f2937;
  color: white;
  padding: 0.4rem 0.6rem;
  border-radius: 4px;
  font-size: 0.85rem;
  white-space: nowrap;
  z-index: 10;
  margin-bottom: 0.5rem;
}

.reading-text {
  line-height: 2;
  font-size: 1.05rem;
  white-space: pre-wrap;
}
</style>

