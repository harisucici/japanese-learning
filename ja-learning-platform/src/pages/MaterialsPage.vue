<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useLearningStore } from '../store'
const api = useLearningStore(), data = ref(null), error = ref(''), loading = ref(true), query = ref(''), collection = ref('全部'), visibleCount = ref(24)
async function load() { loading.value = true; error.value = ''; try { data.value = await api.request('materials') } catch (e) { error.value = e.message } finally { loading.value = false } }
onMounted(load)
const collections = computed(() => ['全部', ...new Set((data.value?.items || []).map(x => x.collection))])
const items = computed(() => (data.value?.items || []).filter(x => (collection.value === '全部' || x.collection === collection.value) && x.title.toLowerCase().includes(query.value.trim().toLowerCase())))
const visibleItems = computed(() => items.value.slice(0, visibleCount.value))
watch([query, collection], () => { visibleCount.value = 24 })
function difficultyTag(item) {
  const level = (item.level || item.collection || '').toString().toUpperCase()
  if (/N5|初/.test(level)) return { label: 'N5', tone: 'n5' }
  if (/N4/.test(level)) return { label: 'N4', tone: 'n4' }
  if (/N3/.test(level)) return { label: 'N3', tone: 'n3' }
  if (/N2/.test(level)) return { label: 'N2', tone: 'n2' }
  if (/N1/.test(level)) return { label: 'N1', tone: 'n1' }
  return { label: item.collection || '分类', tone: 'default' }
}
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
        <div class="mobile-header">
          <div class="sk-block" style="width: 60px; height: 10px;"></div>
          <div class="sk-block" style="width: 140px; height: 22px; margin-top: 6px;"></div>
          <div class="sk-block" style="width: 180px; height: 12px; margin-top: 6px;"></div>
        </div>
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
        <!-- 顶部搜索栏固定 -->
        <div class="mobile-topbar">
          <div class="mobile-header">
            <p class="mobile-eyebrow">THE READING LIBRARY</p>
            <h2 class="mobile-title">素材阅读馆</h2>
            <p class="mobile-count">{{ data.total }} 篇文章 · {{ data.audioCount }} 篇音频</p>
          </div>
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

        <p class="mobile-result-count">当前显示 {{ items.length }} 篇</p>

        <!-- 单列大卡片列表 -->
        <div class="mobile-list">
          <RouterLink
            v-for="m in visibleItems"
            :key="m.id"
            :to="`/materials/${m.id}`"
            class="mobile-card"
          >
            <div class="card-thumb" :aria-hidden="true">
              <span class="thumb-initial">{{ initialOf(m.title) }}</span>
              <span v-if="m.audios?.length" class="thumb-badge">音频</span>
            </div>
            <div class="card-body">
              <h3 class="card-title">{{ m.title }}</h3>
              <p class="card-meta">{{ m.collection }}</p>
              <div class="card-info">
                <span v-if="m.audios?.length" class="info-item">
                  <span class="info-icon">♪</span>
                  {{ formatDuration(m.audios[0]?.duration) || '有音频' }}
                </span>
                <span :class="['diff-tag', difficultyTag(m).tone]">{{ difficultyTag(m).label }}</span>
              </div>
              <p class="card-desc">{{ m.hasText ? '阅读原文与听读' : '正文待整理 · 可先听读' }}</p>
            </div>
          </RouterLink>
          <p v-if="!items.length" class="empty">没有找到对应文章。</p>
        </div>

        <button v-if="visibleCount < items.length" class="mobile-load-more" @click="visibleCount += 24">
          加载更多 · 已显示 {{ visibleItems.length }} / {{ items.length }} ↘
        </button>
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
  .mobile-header {
    padding: 14px 16px 10px;
  }
  .mobile-eyebrow {
    font-size: 12px;
    letter-spacing: 0.15em;
    color: var(--color-primary, #2563EB);
    margin: 0 0 6px;
    font-weight: 600;
  }
  .mobile-title {
    font: 700 22px/1.3 'Zen Kaku Gothic New', sans-serif;
    margin: 0 0 4px;
    color: var(--theme-text, #27302b);
  }
  .mobile-count {
    font-size: 12px;
    color: var(--theme-text-secondary, #67746a);
    margin: 0;
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
  }
  .mobile-filters::-webkit-scrollbar {
    display: none;
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
    padding: 10px 16px;
    font-size: 12px;
    color: var(--theme-text-secondary, #67746a);
  }

  /* 单列大卡片列表 */
  .mobile-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
    padding: 0 16px 80px;
  }
  .mobile-card {
    display: flex;
    gap: 14px;
    padding: 14px;
    min-height: 140px;
    background: var(--theme-surface, #fffdf8);
    border: 1px solid var(--theme-border-soft, #e2ded3);
    border-radius: 12px;
    text-decoration: none;
    color: inherit;
    transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1), box-shadow 0.3s ease;
    touch-action: manipulation;
  }
  .mobile-card:active {
    transform: scale(0.97);
  }

  /* 缩略图：aspect-ratio 4/3, width 100px */
  .card-thumb {
    flex: none;
    width: 100px;
    aspect-ratio: 4 / 3;
    border-radius: 8px;
    background: linear-gradient(135deg, #fbf0df 0%, #a35a2d 100%);
    color: #fffdf8;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    position: relative;
    overflow: hidden;
  }
  .thumb-initial {
    font: 600 36px/1 'Zen Kaku Gothic New', sans-serif;
  }
  .thumb-badge {
    position: absolute;
    bottom: 6px;
    right: 6px;
    font-size: 12px;
    padding: 3px 8px;
    background: rgba(255, 253, 248, 0.9);
    color: #74472c;
    border-radius: 4px;
    font-weight: 600;
  }

  /* 右侧内容 */
  .card-body {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
    gap: 6px;
  }
  .card-title {
    font: 600 16px/1.35 'Zen Kaku Gothic New', sans-serif;
    margin: 0;
    color: var(--theme-text, #27302b);
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  .card-meta {
    font-size: 12px;
    color: var(--color-primary, #2563EB);
    margin: 0;
    font-weight: 500;
  }
  .card-info {
    display: flex;
    align-items: center;
    gap: 10px;
    flex-wrap: wrap;
  }
  .info-item {
    display: flex;
    align-items: center;
    gap: 4px;
    font-size: 12px;
    color: var(--theme-text-secondary, #67746a);
  }
  .info-icon {
    font-size: 14px;
  }
  .diff-tag {
    font-size: 12px;
    padding: 3px 8px;
    border-radius: 4px;
    background: var(--theme-surface-alt, #f5f2e9);
    color: var(--theme-text-secondary, #67746a);
    font-weight: 600;
  }
  .diff-tag.n5 { background: #e8f5ee; color: #215a54; }
  .diff-tag.n4 { background: #ecf4fa; color: #34536e; }
  .diff-tag.n3 { background: #fbf0df; color: #74472c; }
  .diff-tag.n2 { background: #faedf1; color: #633449; }
  .diff-tag.n1 { background: #355247; color: #fffdf8; }
  .card-desc {
    font-size: 13px;
    color: var(--theme-text-secondary, #67746a);
    margin: 0;
    line-height: 1.5;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .empty {
    padding: 40px 16px;
    text-align: center;
    color: var(--theme-text-secondary, #67746a);
    font-size: 14px;
  }

  .mobile-load-more {
    display: block;
    margin: 20px auto 40px;
    min-height: 44px;
    padding: 12px 32px;
    background: transparent;
    border: 1px solid var(--theme-border, #d1ccb8);
    border-radius: 8px;
    color: var(--theme-text, #27302b);
    font-size: 14px;
    cursor: pointer;
  }
  .mobile-load-more:active {
    background: var(--theme-surface-alt, #f5f2e9);
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
    width: 88px;
  }
  .thumb-initial {
    font-size: 30px;
  }
  .card-title {
    font-size: 15px;
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
  gap: 14px;
  padding: 14px;
  min-height: 140px;
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--theme-border-soft, #e2ded3);
  border-radius: 12px;
}

.sk-card::before {
  content: '';
  flex: none;
  width: 100px;
  height: 75px;
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
</style>
