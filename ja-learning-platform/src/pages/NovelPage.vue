<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useLearningStore } from '../store'
const api = useLearningStore()
const data = ref(null), error = ref(''), loading = ref(true), query = ref(''), category = ref('全部')
async function load() { loading.value = true; error.value = ''; try { data.value = await api.request('novel-lessons') } catch (e) { error.value = e.message } finally { loading.value = false } }
onMounted(load)
const categories = computed(() => ['全部', ...new Set((data.value?.lessons || []).map(x => x.category))])
const lessons = computed(() => (data.value?.lessons || []).filter(x => {
  const categoryMatch = category.value === '全部' || x.category === category.value
  const titleMatch = !query.value.trim() || (x.title && x.title.includes(query.value.trim()))
  return categoryMatch && titleMatch
}))
function difficultyTag(item) {
  const level = (item.level || item.category || '').toString().toUpperCase()
  if (/N5|初/.test(level)) return { label: 'N5 · 入门', tone: 'n5' }
  if (/N4/.test(level)) return { label: 'N4 · 基础', tone: 'n4' }
  if (/N3/.test(level)) return { label: 'N3 · 进阶', tone: 'n3' }
  if (/N2/.test(level)) return { label: 'N2 · 中高级', tone: 'n2' }
  if (/N1/.test(level)) return { label: 'N1 · 高级', tone: 'n1' }
  return { label: item.category || '分类', tone: 'default' }
}
function initialOf(title) {
  return (title || '?').trim().charAt(0) || '?'
}
</script>

<template>
  <div class="content-page">
    <div class="section-top"><p class="eyebrow">STORIES FROM THE LIBRARY</p><span>{{ data?.lessons?.length || 0 }} 篇</span></div>
    <h2>看故事，<em>记住词语。</em></h2>
    <p class="page-lead">按原文分章阅读，查看词卡与假名注释，再进入配套练习。</p>

    <div v-if="loading" class="state-box">正在读取章节…</div>
    <div v-else-if="error" class="state-box error">{{ error }} <button @click="load">重试</button></div>

    <template v-else>
      <div class="source-note">来源：{{ data.sourceTitle }} · {{ data.sourcePages }} 页 · 原作者：{{ data.attribution }}<br />资料标题中的等级为原作者标注；配套练习不是 JLPT 官方真题。</div>
      
      <!-- 桌面端：沿用原有搜索+筛选 -->
      <div class="controls">
        <input v-model="query" type="search" placeholder="搜索小说标题" aria-label="搜索小说标题">
        <div class="filters">
          <button v-for="c in categories" :key="c" :class="{ chosen: category === c }" @click="category = c">{{ c }}</button>
        </div>
      </div>

      <!-- 桌面端列表：原有布局 -->
      <div class="item-list desktop-only">
        <RouterLink v-for="(item, i) in lessons" :key="item.id" :to="`/novel/${item.id}`" class="list-row">
          <span class="item-index">{{ String(i + 1).padStart(2, '0') }}</span>
          <div>
            <small>{{ item.category }} · 第 {{ item.startPage }}–{{ item.endPage }} 页</small>
            <h3>{{ item.title }}</h3>
            <p>{{ item.questionCount }} 道练习 · {{ item.vocabularyCount }} 个原文词卡</p>
          </div>
          <span class="row-action">阅读与练习 ↗</span>
        </RouterLink>
        <p v-if="!lessons.length" class="empty">没有找到对应篇目。</p>
      </div>

      <!-- 移动端：卡片列表 -->
      <div class="novel-mobile mobile-only">
        <!-- 骨架屏 -->
        <div v-if="loading" class="mobile-novel-skeleton" aria-hidden="true">
          <div class="mobile-header">
            <div class="skeleton sk-eyebrow"></div>
            <div class="skeleton sk-title"></div>
            <div class="skeleton sk-desc"></div>
          </div>
          <div class="mobile-search">
            <div class="skeleton sk-search"></div>
          </div>
          <div class="mobile-filters-skeleton">
            <div v-for="n in 4" :key="n" class="skeleton sk-chip"></div>
          </div>
          <div class="mobile-list">
            <div v-for="n in 3" :key="n" class="mobile-card-skeleton">
              <div class="skeleton sk-cover"></div>
              <div class="sk-body">
                <div class="skeleton sk-card-title"></div>
                <div class="skeleton sk-card-meta"></div>
                <div class="skeleton sk-card-excerpt"></div>
                <div class="skeleton sk-card-excerpt short"></div>
              </div>
            </div>
          </div>
        </div>
        <div v-else-if="error" class="state-box error">{{ error }} <button @click="load">重试</button></div>
        <template v-else>
          <!-- 搜索栏固定 -->
          <div class="mobile-search">
          <label class="search-field">
            <span class="search-icon" aria-hidden="true">⌕</span>
            <input v-model="query" type="search" placeholder="搜索小说标题" aria-label="搜索小说标题" />
          </label>
        </div>

        <!-- 分类筛选：水平滚动 -->
        <div class="mobile-filters" role="tablist" aria-label="分类筛选">
          <button
            v-for="c in categories"
            :key="c"
            type="button"
            :class="['filter-chip', { chosen: category === c }]"
            @click="category = c"
          >{{ c }}</button>
        </div>

        <p class="mobile-count">当前显示 {{ lessons.length }} 篇</p>

        <!-- 卡片列表 -->
        <div class="mobile-list">
          <RouterLink
            v-for="item in lessons"
            :key="item.id"
            :to="`/novel/${item.id}`"
            class="mobile-card"
          >
            <div class="card-cover" :aria-hidden="true">
              <span class="cover-initial">{{ initialOf(item.title) }}</span>
              <span class="cover-meta">第 {{ item.startPage }}–{{ item.endPage }} 页</span>
            </div>
            <div class="card-body">
              <h3 class="card-title">{{ item.title }}</h3>
              <p class="card-author">{{ item.category }}</p>
              <p class="card-excerpt">{{ item.questionCount }} 道练习 · {{ item.vocabularyCount }} 个原文词卡</p>
              <div class="card-footer">
                <span :class="['diff-tag', difficultyTag(item).tone]">{{ difficultyTag(item).label }}</span>
                <span class="card-action">阅读 ↗</span>
              </div>
            </div>
          </RouterLink>
          <p v-if="!lessons.length" class="empty">没有找到对应篇目。</p>
        </div>
        </template>
      </div>
    </template>
  </div>
</template>

<style scoped>
/* 桌面端：保持原有布局，隐藏移动端专属内容 */
.desktop-only {
  display: block;
}
.mobile-only {
  display: none;
}

/* 移动端改造 */
@media (max-width: 768px) {
  .desktop-only {
    display: none;
  }
  .mobile-only {
    display: block;
  }

  /* 搜索栏固定顶部 */
  .mobile-search {
    position: sticky;
    top: 0;
    z-index: 20;
    background: var(--theme-surface, #fffdf8);
    padding: 12px 16px;
    border-bottom: 1px solid var(--theme-border-soft, #e2ded3);
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

  /* 分类筛选：水平滚动 */
  .mobile-filters {
    display: flex;
    gap: 8px;
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
    padding: 12px 16px;
    scrollbar-width: none;
  }
  .mobile-filters::-webkit-scrollbar {
    display: none;
  }
  .filter-chip {
    flex: none;
    min-height: 36px;
    padding: 8px 14px;
    border-radius: 999px;
    border: 1px solid var(--theme-border, #d1ccb8);
    background: var(--theme-surface, #fffdf8);
    color: var(--theme-text, #27302b);
    font-size: 14px;
    cursor: pointer;
    white-space: nowrap;
  }
  .filter-chip.chosen {
    background: var(--theme-text, #27302b);
    color: var(--theme-surface, #fffdf8);
    border-color: var(--theme-text, #27302b);
  }

  .mobile-count {
    padding: 8px 16px;
    font-size: 12px;
    color: var(--theme-text-secondary, #67746a);
  }

  /* 卡片列表 */
  .mobile-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
    padding: 0 16px 80px;
  }
  .mobile-card {
    display: flex;
    gap: 12px;
    padding: 12px;
    min-height: 120px;
    background: var(--theme-surface, #fffdf8);
    border: 1px solid var(--theme-border-soft, #e2ded3);
    border-radius: 12px;
    text-decoration: none;
    color: inherit;
    transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1),
                box-shadow 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  }
  .mobile-card:active {
    transform: scale(0.97);
  }

  /* 封面：3/4 比例，80px 宽 */
  .card-cover {
    flex: none;
    width: 80px;
    aspect-ratio: 3 / 4;
    border-radius: 8px;
    background: linear-gradient(145deg, #e8d1ac 0%, #a35a2d 100%);
    color: #fffdf8;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    position: relative;
    overflow: hidden;
  }
  .cover-initial {
    font: 600 32px/1 'Zen Kaku Gothic New', sans-serif;
  }
  .cover-meta {
    position: absolute;
    bottom: 6px;
    font-size: 12px;
    letter-spacing: 0.08em;
    opacity: 0.85;
    text-align: center;
    padding: 0 4px;
  }

  /* 右侧内容 */
  .card-body {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
    gap: 4px;
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
  .card-author {
    font-size: 12px;
    color: var(--theme-text-secondary, #67746a);
    margin: 0;
  }
  .card-excerpt {
    font-size: 13px;
    color: var(--theme-text-secondary, #67746a);
    margin: 0;
    line-height: 1.5;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  .card-footer {
    margin-top: auto;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
    padding-top: 6px;
  }
  .diff-tag {
    font-size: 12px;
    padding: 3px 8px;
    border-radius: 4px;
    background: var(--theme-surface-alt, #f5f2e9);
    color: var(--theme-text-secondary, #67746a);
  }
  .diff-tag.n5 { background: #e8f5ee; color: #215a54; }
  .diff-tag.n4 { background: #ecf4fa; color: #34536e; }
  .diff-tag.n3 { background: #fbf0df; color: #74472c; }
  .diff-tag.n2 { background: #faedf1; color: #633449; }
  .diff-tag.n1 { background: #355247; color: #fffdf8; }
  .card-action {
    font-size: 12px;
    color: var(--color-primary, #2563EB);
  }

  .empty {
    padding: 40px 16px;
    text-align: center;
    color: var(--theme-text-secondary, #67746a);
    font-size: 14px;
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
  .card-cover {
    width: 68px;
  }
  .cover-initial {
    font-size: 26px;
  }
  .card-title {
    font-size: 15px;
  }
}

/* 骨架屏 */
.mobile-novel-skeleton {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.mobile-header {
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.sk-eyebrow {
  width: 60px;
  height: 12px;
}

.sk-title {
  width: 70%;
  height: 22px;
}

.sk-desc {
  width: 90%;
  height: 14px;
}

.mobile-search {
  padding: 0 16px;
}

.sk-search {
  height: 44px;
  border-radius: 22px;
}

.mobile-filters-skeleton {
  display: flex;
  gap: 8px;
  padding: 0 16px;
  overflow: hidden;
}

.sk-chip {
  width: 60px;
  height: 36px;
  border-radius: 18px;
  flex-shrink: 0;
}

.mobile-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 0 16px;
}

.mobile-card-skeleton {
  display: flex;
  gap: 12px;
  padding: 12px;
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--theme-border-soft, #e2ded3);
  border-radius: 12px;
  min-height: 120px;
}

.sk-cover {
  width: 80px;
  height: 106px;
  border-radius: 8px;
  flex-shrink: 0;
}

.sk-body {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.sk-card-title {
  width: 80%;
  height: 16px;
}

.sk-card-meta {
  width: 50%;
  height: 12px;
}

.sk-card-excerpt {
  width: 100%;
  height: 12px;
}

.sk-card-excerpt.short {
  width: 70%;
}

/* 极小屏 */
@media (max-width: 375px) {
  .sk-cover {
    width: 68px;
    height: 90px;
  }
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
