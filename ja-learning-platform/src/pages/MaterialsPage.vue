<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useLearningStore } from '../store'
const api = useLearningStore(), data = ref(null), error = ref(''), loading = ref(true), query = ref(''), collection = ref('全部'), visibleCount = ref(24)
async function load() { loading.value = true; error.value = ''; try { data.value = await api.request('materials') } catch (e) { error.value = e.message } finally { loading.value = false } }
onMounted(load)
const collections = computed(() => ['全部', ...new Set((data.value?.items || []).map(x => x.collection))])
const items = computed(() => (data.value?.items || []).filter(x => (collection.value === '全部' || x.collection === collection.value) && x.title.toLowerCase().includes(query.value.trim().toLowerCase())))
const visibleItems = computed(() => items.value.slice(0, visibleCount.value))
watch([query, collection], () => { visibleCount.value = 24 })
const loadSentinel = ref(null)
let loadObserver
watch(loadSentinel, (element, previous) => {
  if (previous) loadObserver?.unobserve(previous)
  if (!element) return
  loadObserver ||= new IntersectionObserver(([entry]) => {
    if (entry?.isIntersecting && visibleCount.value < items.value.length) {
      visibleCount.value = Math.min(visibleCount.value + 24, items.value.length)
    }
  }, { rootMargin: '320px 0px' })
  loadObserver.observe(element)
})
onBeforeUnmount(() => loadObserver?.disconnect())
function formatDuration(seconds) {
  if (!seconds) return ''
  const mins = Math.floor(seconds / 60)
  if (mins < 60) return `${mins}分钟`
  const hours = Math.floor(mins / 60)
  const remainMins = mins % 60
  return remainMins ? `${hours}小时${remainMins}分钟` : `${hours}小时`
}
function initialOf(title) {
  return (title || '?').trim().charAt(0) || '?'
}
</script>

<template>
  <div class="content-page">
    <!-- 桌面端：保持原有布局 -->
    <div class="desktop-only">
      <div class="section-top"><p class="eyebrow">THE READING LIBRARY</p><span>{{ data?.total || 0 }} 篇文章</span></div>
      <h2>在素材里，<em>遇见新知。</em></h2>
      <p class="page-lead">从一篇文章开始，跟着声音读日语。</p>
    </div>

    <div v-if="loading" class="state-box desktop-only">正在读取文章…</div>
    <!-- 移动端骨架屏 -->
    <div v-if="loading" class="mobile-only">
      <div class="mobile-topbar">
        <div class="mobile-search">
          <div class="sk-block sk-search"></div>
        </div>
        <div class="mobile-filters">
          <div v-for="i in 4" :key="i" class="sk-block sk-chip"></div>
        </div>
      </div>
      <div class="mobile-list" style="padding-top: 12px;">
        <div v-for="i in 3" :key="i" class="sk-card"></div>
      </div>
    </div>
    <div v-else-if="error" class="state-box error">{{ error }} <button @click="load">重试</button></div>

    <template v-else>
      <!-- 桌面端控制区 -->
      <div class="desktop-only">
        <div class="source-note">{{ data.total }} 篇文章 · {{ data.audioCount }} 篇配有音频</div>
        <div class="controls">
          <input v-model="query" type="search" placeholder="搜索文章标题" aria-label="搜索文章">
          <div class="filters">
            <button v-for="c in collections" :key="c" :class="{ chosen: collection === c }" @click="collection = c">{{ c }}</button>
          </div>
        </div>
        <p class="result-count">当前显示 {{ items.length }} 篇</p>
        <div class="item-list">
          <RouterLink v-for="(m, i) in visibleItems" :key="m.id" :to="`/materials/${m.id}`" class="list-row">
            <span class="item-index">{{ String(i + 1).padStart(2, '0') }}</span>
            <div>
              <small>{{ m.collection }} · {{ m.audios?.length ? '配套音频' : '暂无音频' }}</small>
              <h3>{{ m.title }}</h3>
              <p>{{ m.hasText ? '阅读原文与听读' : '正文待整理 · 可先听读' }}</p>
            </div>
            <span class="row-action">进入 ↗</span>
          </RouterLink>
          <p v-if="!items.length" class="empty">没有找到对应文章。</p>
        </div>
        <button v-if="visibleCount < items.length" class="load-more" @click="visibleCount += 24">加载更多 · 已显示 {{ visibleItems.length }} / {{ items.length }} ↘</button>
      </div>

      <!-- 移动端改造 -->
      <div class="mobile-only">
        <!-- 搜索与筛选 -->
        <div class="mobile-topbar">
          <div class="mobile-search">
            <label class="search-field">
              <span class="search-icon" aria-hidden="true">⌕</span>
              <input v-model="query" type="search" placeholder="搜索文章" aria-label="搜索文章" />
            </label>
          </div>
          <div class="mobile-filters" role="tablist" aria-label="分类筛选">
            <button
              v-for="c in collections"
              :key="c"
              type="button"
              :class="['filter-chip', { chosen: collection === c }]"
              @click="collection = c"
            >{{ c }}</button>
          </div>
        </div>

        <p v-if="query.trim() || collection !== '全部'" class="mobile-result-count">找到 {{ items.length }} 篇</p>

        <!-- 紧凑文章列表 -->
        <div class="mobile-list">
          <RouterLink
            v-for="m in visibleItems"
            :key="m.id"
            :to="`/materials/${m.id}`"
            class="mobile-card"
          >
            <div class="card-thumb" :aria-hidden="true">
              <span class="thumb-initial">{{ initialOf(m.title) }}</span>
            </div>
            <div class="card-body">
              <h3 class="card-title">{{ m.title }}</h3>
              <div class="card-details">
                <span class="card-meta">{{ m.collection }}</span>
                <span class="info-dot" aria-hidden="true">·</span>
                <span class="info-item">{{ m.audios?.length ? `♪ ${formatDuration(m.audios[0]?.duration) || '有音频'}` : '阅读文章' }}</span>
              </div>
            </div>
            <span class="card-arrow" aria-hidden="true">↗</span>
          </RouterLink>
          <p v-if="!items.length" class="empty">没有找到对应文章。</p>
        </div>

        <div v-if="visibleCount < items.length" ref="loadSentinel" class="mobile-load-sentinel" aria-hidden="true"></div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.desktop-only { display: block; }
.mobile-only { display: none; }

/* 移动端改造 */
@media (max-width: 768px) {
  .desktop-only { display: none; }
  .mobile-only { display: block; }

  /* 顶部搜索栏固定 */
  .mobile-topbar {
    position: sticky;
    top: 0;
    z-index: 20;
    background: var(--theme-surface, #fffdf8);
    border-bottom: 1px solid var(--theme-border-soft, #e2ded3);
    padding-bottom: 12px;
  }
  /* 搜索框 */
  .mobile-search {
    padding: 0 16px 10px;
  }
  .search-field {
    display: flex;
    align-items: center;
    gap: 8px;
    background: var(--theme-surface-alt, #f5f2e9);
    border: 1px solid var(--theme-border, #d1ccb8);
    border-radius: 10px;
    padding: 10px 14px;
    min-height: 44px;
  }
  .search-icon {
    font-size: 18px;
    color: var(--theme-text-secondary, #67746a);
  }
  .search-field input {
    flex: 1;
    border: 0;
    background: transparent;
    outline: none;
    font-size: 16px;
    color: var(--theme-text, #27302b);
  }
  .search-field:focus-within {
    border-color: var(--color-primary, #2563EB);
    box-shadow: 0 0 0 3px color-mix(in srgb, var(--color-primary, #2563EB) 18%, transparent);
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  }

  /* 分类筛选：水平滚动 */
  .mobile-filters {
    display: flex;
    gap: 8px;
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
    padding: 0 16px;
    scrollbar-width: none;
    position: relative;
    background:
      linear-gradient(to right, var(--theme-surface, #fffdf8) 0%, transparent 8%, transparent 92%, var(--theme-surface, #fffdf8) 100%);
  }
  .mobile-filters::-webkit-scrollbar {
    display: none;
  }
  .mobile-filters::before,
  .mobile-filters::after {
    content: '';
    position: absolute;
    top: 0;
    bottom: 0;
    width: 20px;
    pointer-events: none;
    z-index: 1;
  }
  .mobile-filters::before {
    left: 0;
    background: linear-gradient(to right, var(--theme-surface, #fffdf8) 0%, transparent 100%);
  }
  .mobile-filters::after {
    right: 0;
    background: linear-gradient(to left, var(--theme-surface, #fffdf8) 0%, transparent 100%);
  }
  .filter-chip {
    flex: none;
    min-height: 44px;
    padding: 8px 14px;
    border-radius: 999px;
    border: 1px solid var(--theme-border, #d1ccb8);
    background: var(--theme-surface, #fffdf8);
    color: var(--theme-text, #27302b);
    font-size: 14px;
    cursor: pointer;
    white-space: nowrap;
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
    touch-action: manipulation;
  }
  .filter-chip:active {
    transform: scale(0.97);
  }
  .filter-chip.chosen {
    background: var(--theme-text, #27302b);
    color: var(--theme-surface, #fffdf8);
    border-color: var(--theme-text, #27302b);
  }

  .mobile-result-count {
    margin: 0;
    padding: 9px 16px 5px;
    font-size: 12px;
    color: var(--theme-text-secondary, #67746a);
  }

  /* 单列文章目录 */
  .mobile-list {
    display: flex;
    flex-direction: column;
    gap: 8px;
    padding: 10px 12px 80px;
  }
  .mobile-card {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 10px 12px;
    min-height: 72px;
    background: var(--theme-surface, #fffdf8);
    border: 1px solid var(--theme-border-soft, #e2ded3);
    border-radius: 10px;
    text-decoration: none;
    color: inherit;
    transition: transform 0.25s ease, background-color 0.25s ease, border-color 0.25s ease;
    touch-action: manipulation;
  }
  .mobile-card:active {
    transform: scale(0.985);
    background: var(--theme-surface-alt, #f5f2e9);
  }

  /* 小型纸签 */
  .card-thumb {
    flex: none;
    width: 44px;
    height: 50px;
    border-radius: 5px 8px 8px 5px;
    border-left: 3px solid #a36f52;
    background: linear-gradient(135deg, #f7ebd8, #e8d0af);
    color: #68482f;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    overflow: hidden;
  }
  .thumb-initial {
    font: 600 21px/1 'Noto Serif JP', 'Songti SC', serif;
  }

  .card-body {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
    gap: 5px;
  }
  .card-title {
    font: 600 15px/1.35 'Noto Serif JP', 'Songti SC', serif;
    margin: 0;
    color: var(--theme-text, #27302b);
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  .card-meta {
    color: #8b6046;
  }
  .card-details {
    display: flex;
    align-items: center;
    gap: 5px;
    white-space: nowrap;
    overflow: hidden;
    font-size: 11px;
  }
  .info-item {
    color: var(--theme-text-secondary, #67746a);
  }
  .info-dot {
    color: #baa998;
  }
  .card-arrow {
    flex: none;
    color: #8b6046;
    font-size: 18px;
    line-height: 1;
  }

  .empty {
    padding: 40px 16px;
    text-align: center;
    color: var(--theme-text-secondary, #67746a);
    font-size: 14px;
  }

  .mobile-load-sentinel {
    height: 1px;
  }

  /* 触控增强 */
  .mobile-card,
  .filter-chip {
    min-height: 44px;
    touch-action: manipulation;
  }
}

/* 极小屏 */
@media (max-width: 375px) {
  .card-thumb {
    width: 38px;
    height: 44px;
  }
  .thumb-initial {
    font-size: 18px;
  }
  .card-title {
    font-size: 14px;
  }
  .card-details {
    font-size: 12px;
  }
  .mobile-card {
    padding: 8px 10px;
    gap: 10px;
  }
  .search-field {
    padding: 8px 12px;
    min-height: 40px;
  }
  .search-field input {
    font-size: 15px;
  }
  .filter-chip {
    font-size: 13px;
    padding: 6px 12px;
    min-height: 40px;
  }
}

/* 骨架屏样式 */
@keyframes sk-shimmer {
  0% { background-position: -400px 0; }
  100% { background-position: 400px 0; }
}

.sk-block {
  background: linear-gradient(90deg, #f0ece3 0%, #e8e3d7 50%, #f0ece3 100%);
  background-size: 800px 100%;
  animation: sk-shimmer 1.5s infinite linear;
  border-radius: 6px;
}

.sk-search {
  width: 100%;
  height: 44px;
  border-radius: 10px;
}

.sk-chip {
  flex: none;
  width: 60px;
  height: 44px;
  border-radius: 999px;
}

.sk-card {
  display: flex;
  gap: 12px;
  padding: 10px 12px;
  min-height: 72px;
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--theme-border-soft, #e2ded3);
  border-radius: 12px;
}

.sk-card::before {
  content: '';
  flex: none;
  width: 44px;
  height: 50px;
  background: linear-gradient(90deg, #f0ece3 0%, #e8e3d7 50%, #f0ece3 100%);
  background-size: 800px 100%;
  animation: sk-shimmer 1.5s infinite linear;
  border-radius: 8px;
}

.sk-card::after {
  content: '';
  flex: 1;
  background: linear-gradient(90deg, #f0ece3 0%, #e8e3d7 50%, #f0ece3 100%);
  background-size: 800px 100%;
  animation: sk-shimmer 1.5s infinite linear;
  border-radius: 6px;
}

/* 交错进入动画 */
@media (max-width: 768px) {
  .mobile-card {
    opacity: 0;
    transform: translateY(20px);
    animation: fade-up 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  }

  .mobile-card:nth-child(1) { animation-delay: 0.1s; }
  .mobile-card:nth-child(2) { animation-delay: 0.15s; }
  .mobile-card:nth-child(3) { animation-delay: 0.2s; }
  .mobile-card:nth-child(4) { animation-delay: 0.25s; }
  .mobile-card:nth-child(5) { animation-delay: 0.3s; }
  .mobile-card:nth-child(6) { animation-delay: 0.35s; }
  .mobile-card:nth-child(7) { animation-delay: 0.4s; }
  .mobile-card:nth-child(8) { animation-delay: 0.45s; }

  @keyframes fade-up {
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
}
@media (max-width: 768px) {
  .mobile-topbar { padding: 8px 0 7px; }
  .mobile-search { padding: 0 12px 7px; }
  .search-field { min-height: 40px; padding: 6px 10px; gap: 7px; border-radius: 7px; }
  .search-icon { font-size: 16px; }
  .search-field input { min-width: 0; min-height: 0 !important; height: 24px; padding: 0 !important; border: 0; border-radius: 0; font-size: 16px; line-height: 1.3; box-shadow: none; }
  .search-field input:focus { border: 0; box-shadow: none; }
  .mobile-filters { padding: 0 12px; }
}
</style>
