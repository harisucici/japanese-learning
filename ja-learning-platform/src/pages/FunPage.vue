<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter, RouterLink } from 'vue-router'
import { useLearningStore } from '../store'
const api=useLearningStore(), router=useRouter()
const data=ref(null),error=ref(''),loading=ref(true),starting=ref(''),theme=ref('全部')
async function load(){loading.value=true;error.value='';try{data.value=await api.request('fun-papers')}catch(e){error.value=e.message}finally{loading.value=false}}
onMounted(load)
const themes=computed(()=>['全部',...new Set((data.value?.papers||[]).map(x=>x.theme))])
const papers=computed(()=>(data.value?.papers||[]).filter(x=>theme.value==='全部'||x.theme===theme.value))
async function start(id){starting.value=id;error.value='';try{const s=await api.startFun(id);router.push(`/sessions/${s.id}`)}catch(e){error.value=e.message}finally{starting.value=''}}
function difficultyLevel(paper) {
  const count = paper.questionCount || 0
  if (count <= 5) return { label: '入门', tone: 'easy' }
  if (count <= 15) return { label: '基础', tone: 'medium' }
  if (count <= 30) return { label: '进阶', tone: 'hard' }
  return { label: '挑战', tone: 'expert' }
}
function initialOf(title) {
  return (title || '?').trim().charAt(0) || '?'
}
</script>

<template>
  <div class="content-page">
    <!-- 桌面端：保持原有布局 -->
    <div class="desktop-only">
      <div class="section-top"><p class="eyebrow">LEARN BY PLAYING</p><span>{{ data?.papers?.length || 0 }} 组</span></div>
      <h2>趣味闯关，<em>从原文出发。</em></h2>
      <p class="page-lead">答对自动前进；答错查看讲解后继续。首次作答保存在后端。</p>
      <div v-if="loading" class="state-box">正在读取题组…</div>
      <div v-else-if="error" class="state-box error">{{ error }} <button @click="load">重新加载</button></div>
      <template v-if="data">
        <div class="source-note">{{ data.label }}</div>
        <div class="filters">
          <button v-for="t in themes" :key="t" :class="{ chosen: theme === t }" @click="theme = t">{{ t }}</button>
        </div>
        <div class="activity-grid">
          <article v-for="p in papers" :key="p.id" class="activity-card">
            <small>{{ p.theme }}</small>
            <h3>{{ p.title }}</h3>
            <p>{{ p.description }}</p>
            <div class="activity-meta">{{ p.questionCount }} 题 · {{ p.ready ? '可以开始' : '题组尚未完整入库' }}</div>
            <div class="activity-actions">
              <button class="primary-action" :disabled="!p.ready || !!starting" @click="start(p.id)">{{ starting === p.id ? '正在准备…' : '开始闯关 ↗' }}</button>
              <RouterLink v-if="p.readingLessonId || p.reading_lesson_id" :to="`/novel/${p.readingLessonId || p.reading_lesson_id}`" class="secondary-action">先读原文</RouterLink>
              <RouterLink v-else-if="p.material_ids?.length" :to="`/materials/${p.material_ids[0]}`" class="secondary-action">先读原文</RouterLink>
            </div>
          </article>
        </div>
        <p v-if="!papers.length" class="empty">当前主题暂无题组。</p>
      </template>
    </div>

    <!-- 移动端改造 -->
    <div class="mobile-only">
      <!-- 骨架屏 -->
      <div v-if="loading" class="mobile-fun-skeleton" aria-hidden="true">
        <div class="mobile-header">
          <div class="skeleton sk-eyebrow"></div>
          <div class="skeleton sk-title"></div>
          <div class="skeleton sk-desc"></div>
        </div>
        <div class="mobile-themes-skeleton">
          <div v-for="n in 4" :key="n" class="skeleton sk-chip"></div>
        </div>
        <div class="mobile-cards-skeleton">
          <div v-for="n in 3" :key="n" class="fun-card-skeleton">
            <div class="skeleton sk-fun-cover"></div>
            <div class="sk-fun-content">
              <div class="skeleton sk-fun-header"></div>
              <div class="skeleton sk-fun-title"></div>
              <div class="skeleton sk-fun-desc"></div>
              <div class="skeleton sk-fun-meta"></div>
              <div class="skeleton sk-fun-btn"></div>
            </div>
          </div>
        </div>
      </div>
      <div v-else-if="error" class="state-box error">{{ error }} <button @click="load">重新加载</button></div>
      <template v-else>
        <!-- 顶部标题 -->
        <div class="mobile-header">
          <p class="mobile-eyebrow">LEARN BY PLAYING</p>
          <h2 class="mobile-title">趣味闯关</h2>
          <p class="mobile-desc">答对自动前进；答错查看讲解后继续</p>
        </div>

        <!-- 主题分类标签（水平滚动） -->
        <div class="mobile-themes" role="tablist" aria-label="主题分类">
          <button
            v-for="t in themes"
            :key="t"
            type="button"
            :class="['theme-chip', { chosen: theme === t }]"
            @click="theme = t"
          >{{ t }}</button>
        </div>

        <!-- 活动卡片单列大卡片 -->
        <div class="mobile-cards">
          <article v-for="p in papers" :key="p.id" class="fun-card">
            <!-- 封面 -->
            <div class="fun-cover" :aria-hidden="true">
              <span class="cover-initial">{{ initialOf(p.title) }}</span>
              <span class="cover-badge">{{ p.questionCount }}题</span>
            </div>
            <!-- 内容 -->
            <div class="fun-content">
              <div class="fun-header">
                <span class="fun-theme">{{ p.theme }}</span>
                <span :class="['fun-difficulty', difficultyLevel(p).tone]">{{ difficultyLevel(p).label }}</span>
              </div>
              <h3 class="fun-title">{{ p.title }}</h3>
              <p class="fun-desc">{{ p.description }}</p>
              <div class="fun-meta">
                <span v-if="p.ready" class="ready-tag">✓ 可以开始</span>
                <span v-else class="pending-tag">⏳ 尚未完整入库</span>
              </div>
              <div class="fun-actions">
                <button
                  class="start-btn"
                  :disabled="!p.ready || starting === p.id"
                  @click="start(p.id)"
                >
                  {{ starting === p.id ? '准备中…' : '开始闯关 ↗' }}
                </button>
                <RouterLink
                  v-if="p.readingLessonId || p.reading_lesson_id"
                  :to="`/novel/${p.readingLessonId || p.reading_lesson_id}`"
                  class="read-link"
                >先读原文</RouterLink>
                <RouterLink
                  v-else-if="p.material_ids?.length"
                  :to="`/materials/${p.material_ids[0]}`"
                  class="read-link"
                >先读原文</RouterLink>
              </div>
            </div>
          </article>
          <p v-if="!papers.length" class="empty">当前主题暂无题组。</p>
        </div>
      </template>
    </div>
  </div>
</template>
<style scoped>
.desktop-only { display: block; }
.mobile-only { display: none; }

/* 移动端改造 */
@media (max-width: 768px) {
  .desktop-only { display: none; }
  .mobile-only { display: block; }

  /* 顶部标题 */
  .mobile-header {
    padding: 16px 16px 12px;
    background: var(--theme-surface, #fffdf8);
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
    margin: 0 0 6px;
    color: var(--theme-text, #27302b);
  }
  .mobile-desc {
    font-size: 13px;
    color: var(--theme-text-secondary, #67746a);
    margin: 0;
    line-height: 1.6;
  }

  /* 主题分类标签：水平滚动 */
  .mobile-themes {
    display: flex;
    gap: 8px;
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
    padding: 12px 16px;
    scrollbar-width: none;
    border-bottom: 1px solid var(--theme-border-soft, #e2ded3);
    background: var(--theme-surface, #fffdf8);
    position: sticky;
    top: 0;
    z-index: 20;
  }
  .mobile-themes::-webkit-scrollbar {
    display: none;
  }
  .theme-chip {
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
  .theme-chip:active {
    transform: scale(0.97);
  }
  .theme-chip.chosen {
    background: var(--theme-text, #27302b);
    color: var(--theme-surface, #fffdf8);
    border-color: var(--theme-text, #27302b);
  }

  /* 活动卡片列表 */
  .mobile-cards {
    display: flex;
    flex-direction: column;
    gap: 16px;
    padding: 16px 16px 80px;
  }
  .fun-card {
    display: flex;
    flex-direction: column;
    background: var(--theme-surface, #fffdf8);
    border: 1px solid var(--theme-border-soft, #e2ded3);
    border-radius: 14px;
    overflow: hidden;
    min-height: 180px;
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  }
  .fun-card:active {
    transform: scale(0.97);
  }

  /* 封面 */
  .fun-cover {
    width: 100%;
    height: 100px;
    background: linear-gradient(135deg, #e8f5ee 0%, #18766e 100%);
    color: #fffdf8;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
  }
  .cover-initial {
    font: 700 48px/1 'Zen Kaku Gothic New', sans-serif;
    opacity: 0.9;
  }
  .cover-badge {
    position: absolute;
    top: 10px;
    right: 10px;
    font-size: 12px;
    padding: 4px 10px;
    background: rgba(255, 253, 248, 0.9);
    color: #215a54;
    border-radius: 6px;
    font-weight: 600;
  }

  /* 内容区 */
  .fun-content {
    padding: 14px 16px 16px;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }
  .fun-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
  }
  .fun-theme {
    font-size: 12px;
    color: var(--color-primary, #2563EB);
    font-weight: 600;
    letter-spacing: 0.04em;
  }
  .fun-difficulty {
    font-size: 12px;
    padding: 3px 10px;
    border-radius: 6px;
    font-weight: 600;
  }
  .fun-difficulty.easy { background: #e8f5ee; color: #215a54; }
  .fun-difficulty.medium { background: #ecf4fa; color: #34536e; }
  .fun-difficulty.hard { background: #fbf0df; color: #74472c; }
  .fun-difficulty.expert { background: #faedf1; color: #633449; }

  .fun-title {
    font: 700 17px/1.35 'Zen Kaku Gothic New', sans-serif;
    margin: 0;
    color: var(--theme-text, #27302b);
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  .fun-desc {
    font-size: 13px;
    color: var(--theme-text-secondary, #67746a);
    margin: 0;
    line-height: 1.6;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  .fun-meta {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-top: 4px;
  }
  .ready-tag {
    font-size: 12px;
    color: #10b981;
    font-weight: 500;
  }
  .pending-tag {
    font-size: 12px;
    color: var(--theme-text-muted, #9a9486);
  }

  /* 操作区 */
  .fun-actions {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-top: 8px;
    flex-wrap: wrap;
  }
  .start-btn {
    flex: 1;
    min-height: 44px;
    padding: 12px 16px;
    background: var(--color-primary, #2563EB);
    color: #fff;
    border: none;
    border-radius: 10px;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
    touch-action: manipulation;
  }
  .start-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
  .start-btn:not(:disabled):active {
    background: #1d4ed8;
    transform: scale(0.97);
  }
  .read-link {
    flex: none;
    min-height: 44px;
    padding: 12px 14px;
    background: transparent;
    border: 1px solid var(--theme-border, #d1ccb8);
    border-radius: 10px;
    color: var(--theme-text, #27302b);
    text-decoration: none;
    font-size: 14px;
    font-weight: 500;
    display: grid;
    place-items: center;
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
    touch-action: manipulation;
  }
  .read-link:active {
    background: var(--theme-surface-alt, #f5f2e9);
    transform: scale(0.97);
  }

  .empty {
    padding: 40px 16px;
    text-align: center;
    color: var(--theme-text-secondary, #67746a);
    font-size: 14px;
  }

  /* 触控增强 */
  .theme-chip,
  .start-btn,
  .read-link {
    min-height: 44px;
    touch-action: manipulation;
  }
}

/* 极小屏 */
@media (max-width: 375px) {
  .mobile-title {
    font-size: 20px;
  }
  .fun-cover {
    height: 80px;
  }
  .cover-initial {
    font-size: 40px;
  }
}

/* 骨架屏样式 */
.mobile-fun-skeleton {
  padding: 16px;
}

.sk-eyebrow {
  height: 12px;
  width: 120px;
  margin-bottom: 8px;
}

.sk-title {
  height: 22px;
  width: 160px;
  margin-bottom: 8px;
}

.sk-desc {
  height: 14px;
  width: 200px;
}

.mobile-themes-skeleton {
  display: flex;
  gap: 8px;
  margin: 16px 0;
  overflow: hidden;
}

.sk-chip {
  height: 36px;
  min-width: 80px;
  border-radius: 18px;
}

.mobile-cards-skeleton {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.fun-card-skeleton {
  display: flex;
  gap: 12px;
  padding: 12px;
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--theme-border-soft, #e2ded3);
  border-radius: 12px;
  min-height: 120px;
}

.sk-fun-cover {
  width: 80px;
  height: 100px;
  border-radius: 8px;
  flex-shrink: 0;
}

.sk-fun-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.sk-fun-header {
  height: 20px;
  width: 100px;
}

.sk-fun-title {
  height: 18px;
  width: 180px;
}

.sk-fun-desc {
  height: 14px;
  width: 220px;
}

.sk-fun-meta {
  height: 12px;
  width: 140px;
}

.sk-fun-btn {
  height: 44px;
  width: 100%;
  border-radius: 10px;
  margin-top: 8px;
}

/* 交错进入动画 */
@media (max-width: 768px) {
  .fun-card {
    opacity: 0;
    transform: translateY(20px);
    animation: fade-up 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  }

  .fun-card:nth-child(1) { animation-delay: 0.1s; }
  .fun-card:nth-child(2) { animation-delay: 0.15s; }
  .fun-card:nth-child(3) { animation-delay: 0.2s; }
  .fun-card:nth-child(4) { animation-delay: 0.25s; }
  .fun-card:nth-child(5) { animation-delay: 0.3s; }
  .fun-card:nth-child(6) { animation-delay: 0.35s; }
  .fun-card:nth-child(7) { animation-delay: 0.4s; }
  .fun-card:nth-child(8) { animation-delay: 0.45s; }

  @keyframes fade-up {
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
}
</style>
