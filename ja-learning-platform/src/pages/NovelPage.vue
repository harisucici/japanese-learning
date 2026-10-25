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
      <div class="source-note desktop-only">来源：{{ data.sourceTitle }} · {{ data.sourcePages }} 页 · 原作者：{{ data.attribution }}<br />资料标题中的等级为原作者标注；配套练习不是 JLPT 官方真题。</div>
      <details class="source-note mobile-only mobile-source-note">
        <summary>资料来源与说明</summary>
        <p>来源：{{ data.sourceTitle }} · {{ data.sourcePages }} 页 · 原作者：{{ data.attribution }}<br />资料标题中的等级为原作者标注；配套练习不是 JLPT 官方真题。</p>
      </details>
      
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

        <p v-if="query.trim() || category !== '全部'" class="mobile-count">找到 {{ lessons.length }} 篇</p>

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
            </div>
            <div class="card-body">
              <h3 class="card-title">{{ item.title }}</h3>
              <div class="card-details">
                <span>{{ item.category }}</span>
                <span class="meta-dot" aria-hidden="true">·</span>
                <span>{{ item.questionCount }} 练习</span>
                <span class="meta-dot" aria-hidden="true">·</span>
                <span>{{ item.vocabularyCount }} 词卡</span>
              </div>
            </div>
            <span class="card-arrow" aria-hidden="true">↗</span>
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
  .controls { display: none; }
  .content-page > h2 { font-size: 28px; line-height: 1.3; margin: 16px 0 4px; }
  .content-page > .page-lead { margin: 0 0 12px; line-height: 1.6; }
  .mobile-source-note { margin: 0 0 12px; padding: 0; border: 1px solid var(--season-line); border-radius: 10px; font-size: 12px; line-height: 1.6; }
  .mobile-source-note summary { min-height: 40px; display: flex; align-items: center; padding: 9px 12px; cursor: pointer; font-weight: 600; list-style: none; }
  .mobile-source-note summary::-webkit-details-marker { display: none; }
  .mobile-source-note summary::after { content: '⌄'; margin-left: auto; font-size: 18px; transition: transform .25s ease; }
  .mobile-source-note[open] summary::after { transform: rotate(180deg); }
  .mobile-source-note p { margin: 0; padding: 0 12px 12px; }
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
    margin: 0;
    padding: 8px 12px 4px;
    font-size: 12px;
    color: var(--theme-text-secondary, #67746a);
  }

  /* 紧凑阅读目录 */
  .mobile-list {
    display: flex;
    flex-direction: column;
    gap: 8px;
    padding: 8px 12px 80px;
  }
  .mobile-card {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 10px 12px;
    min-height: 76px;
    background: var(--theme-surface, #fffdf8);
    border: 1px solid var(--theme-border-soft, #e2ded3);
    border-radius: 10px;
    text-decoration: none;
    color: inherit;
    transition: transform 0.25s ease, background-color 0.25s ease, border-color 0.25s ease;
  }
  .mobile-card:active {
    transform: scale(0.985);
    background: var(--theme-surface-alt, #f5f2e9);
  }

  /* 小型书签 */
  .card-cover {
    flex: none;
    width: 44px;
    height: 52px;
    border-radius: 5px 8px 8px 5px;
    border-left: 3px solid #9b7662;
    background: linear-gradient(145deg, #f1dfca, #dcbca1);
    color: #694634;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
  }
  .cover-initial {
    font: 600 21px/1 'Noto Serif JP', 'Songti SC', serif;
  }

  .card-body {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
    gap: 6px;
  }
  .card-title {
    font: 600 15px/1.4 'Noto Serif JP', 'Songti SC', serif;
    margin: 0;
    color: var(--theme-text, #27302b);
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  .card-details {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 5px;
    color: var(--theme-text-secondary, #67746a);
    font-size: 11px;
  }
  .card-details span { white-space: nowrap; }
  .card-details span:first-child { color: #8b6046; }
  .meta-dot { color: #baa998; }
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
    width: 40px;
    height: 48px;
  }
  .cover-initial {
    font-size: 19px;
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
@media (max-width: 768px) {
  .mobile-search { padding: 5px 0 6px; border-bottom: 0; background: transparent; }
  .mobile-list { gap: 8px; padding: 8px 12px 80px; }
  .search-field { min-height: 40px; padding: 6px 10px; gap: 7px; border-radius: 7px; }
  .search-icon { font-size: 16px; }
  .search-field input { min-width: 0; min-height: 0 !important; height: 24px; padding: 0 !important; border: 0; border-radius: 0; font-size: 16px; line-height: 1.3; box-shadow: none; }
  .search-field input:focus { border: 0; box-shadow: none; }
  .mobile-filters { padding: 6px 0 8px; }
}
</style>
