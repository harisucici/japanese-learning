<script setup>
/**
 * 成绩分析页面
 * 展示用户的详细学习统计数据
 */
import { computed, onMounted, ref } from 'vue'
import { requestResource, useLearningStore } from '../store'

const api = useLearningStore()
const loading = ref(true)
const error = ref('')
const statsData = ref(null)
const mistakesData = ref([])

/**
 * 加载统计数据
 */
async function loadStats() {
  loading.value = true
  error.value = ''
  try {
    await api.ensureGuest()
    const [stats, mistakes] = await Promise.all([
      requestResource('stats/me'),
      requestResource('stats/mistakes-detail')
    ])
    statsData.value = {
      ...stats,
      totalAnswered: stats.totalQuestions || 0,
      totalCorrect: stats.correctCount || 0,
      accuracy: isFinite(stats.accuracy) ? stats.accuracy * 100 : 0,
      byType: Object.fromEntries((stats.levelStats || []).map(item => [item.level, {
        accuracy: isFinite(item.accuracy) ? item.accuracy * 100 : 0,
        total: item.totalQuestions || 0,
        correct: item.correctCount || 0
      }]))
    }
    const mistakesArray = Array.isArray(mistakes) ? mistakes : (mistakes.items || mistakes.mistakes || [])
    mistakesData.value = mistakesArray.map(item => ({
      type: item.type || 'unknown',
      count: item.wrongCount || item.count || 0,
      knowledgePoint: item.question?.type || item.type || '未分类',
      questionSnippet: item.question?.content || item.content || ''
    }))
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

/**
 * 计算题型正确率
 */
const typeAccuracy = computed(() => {
  if (!statsData.value?.byType) return []
  return Object.entries(statsData.value.byType).map(([type, data]) => ({
    type: typeMap[type] || type,
    accuracy: isFinite(data.accuracy) ? data.accuracy : 0,
    total: data.total || 0,
    correct: data.correct || 0
  }))
})

const weakAreas = computed(() => {
  if (!statsData.value) return []
  return statsData.value.weakAreas || []
})

const mistakesList = computed(() => {
  if (!mistakesData.value) return []
  return mistakesData.value
})

/**
 * 题型映射
 */
const typeMap = {
  n5: 'N5', n4: 'N4', n3: 'N3', n2: 'N2', n1: 'N1',
  vocab: '词汇题',
  grammar: '语法题',
  reading: '阅读题',
  listening: '听力题'
}

// 错题手风琴展开状态
const expandedMistakes = ref(new Set())

function toggleMistake(index) {
  if (expandedMistakes.value.has(index)) {
    expandedMistakes.value.delete(index)
  } else {
    expandedMistakes.value.add(index)
  }
}

onMounted(loadStats)
</script>

<template>
  <div class="stats-page mob-stats">
    <section class="hero-simple">
      <div class="hero-copy">
        <p class="eyebrow light">MY STATISTICS</p>
        <h1>我的学习档案</h1>
        <p>在数据中看见成长</p>
      </div>
    </section>

    <section class="stats-main section-wrap">
      <!-- 骨架屏 -->
      <div v-if="loading" class="stats-skeleton">
        <div class="skeleton-overview">
          <div v-for="i in 3" :key="i" class="skeleton-card"></div>
        </div>
        <div class="skeleton-mistakes">
          <div v-for="i in 2" :key="i" class="skeleton-mistake-item"></div>
        </div>
        <div class="skeleton-suggestions">
          <div v-for="i in 2" :key="i" class="skeleton-suggestion-item"></div>
        </div>
      </div>
      <div v-else-if="error" class="state-box error">{{ error }} <button @click="loadStats">重试</button></div>
      <template v-else-if="statsData">
        <!-- 概览卡片 -->
        <div class="mob-overview-grid">
          <div class="mob-overview-card">
            <div class="overview-icon">📊</div>
            <div class="overview-value">{{ statsData.totalAnswered || 0 }}</div>
            <div class="overview-label">已答题数</div>
          </div>
          <div class="mob-overview-card">
            <div class="overview-icon">✓</div>
            <div class="overview-value">{{ statsData.totalCorrect || 0 }}</div>
            <div class="overview-label">答对题数</div>
          </div>
          <div class="mob-overview-card">
            <div class="overview-icon">%</div>
            <div class="overview-value">{{ statsData.accuracy ? Math.round(statsData.accuracy) : 0 }}%</div>
            <div class="overview-label">总体正确率</div>
          </div>
          <div class="mob-overview-card">
            <div class="overview-icon">⏱</div>
            <div class="overview-value">{{ statsData.totalTimeSpent ? Math.round(statsData.totalTimeSpent / 60) : 0 }}</div>
            <div class="overview-label">学习时长（分钟）</div>
          </div>
        </div>

        <!-- 分数说明 -->
        <div class="mob-score-notice">
          <h2>练习结果与正式考试成绩</h2>
          <div class="mob-score-types">
            <div class="score-type">
              <h3>练习分</h3>
              <div class="score-value">{{ statsData.totalCorrect || 0 }} / {{ statsData.totalAnswered || 0 }}</div>
              <p>你在所有练习中的实际答对题数</p>
            </div>
            <div class="score-type">
              <h3>练习正确率</h3>
              <div class="score-value">{{ statsData.accuracy?.toFixed(1) || 0 }}%</div>
              <p>根据本站已完成练习记录计算</p>
            </div>
            <div class="score-type">
              <h3>JLPT 正式得分</h3>
              <div class="score-value">— / 180</div>
              <p>需要参加正式考试才能获得</p>
            </div>
          </div>
        </div>

        <!-- 题型分项正确率 -->
        <h2 class="section-title">等级练习正确率</h2>
        <div class="mob-type-breakdown">
          <div v-for="item in typeAccuracy" :key="item.type" class="type-item">
            <div class="type-header">
              <span class="type-name">{{ item.type }}</span>
              <span class="type-stats">{{ item.correct }} / {{ item.total }} 题</span>
              <span class="type-accuracy">{{ Math.round(item.accuracy) }}%</span>
            </div>
            <div class="type-bar">
              <div class="type-bar-fill" :style="{ width: item.accuracy + '%' }"></div>
            </div>
          </div>
        </div>

        <!-- 错题知识点 - 手风琴折叠 -->
        <h2 class="section-title">错题对应知识点</h2>
        <div v-if="mistakesData.length === 0" class="state-box">暂无错题记录</div>
        <div v-else class="mob-mistakes-list">
          <div v-for="(mistake, index) in mistakesData" :key="index" class="mob-mistake-card">
            <button class="mob-mistake-header" @click="toggleMistake(index)">
              <div class="mob-mistake-title">
                <span class="mistake-type">{{ typeMap[mistake.type] || mistake.type }}</span>
                <span class="mistake-count">错误 {{ mistake.count }} 次</span>
              </div>
              <span class="mob-mistake-toggle">{{ expandedMistakes.has(index) ? '−' : '+' }}</span>
            </button>
            <div v-show="expandedMistakes.has(index)" class="mob-mistake-content">
              <p><strong>知识点：</strong>{{ mistake.knowledgePoint || '未分类' }}</p>
              <p v-if="mistake.questionSnippet"><strong>题目：</strong>{{ mistake.questionSnippet }}</p>
            </div>
          </div>
        </div>

        <!-- 优先复习建议 -->
        <h2 class="section-title">优先复习建议</h2>
        <div class="review-suggestions">
          <div v-if="statsData.weakAreas && statsData.weakAreas.length > 0" class="mob-suggestion-list">
            <div v-for="(area, index) in statsData.weakAreas.slice(0, 5)" :key="index" class="suggestion-item">
              <span class="suggestion-rank">{{ index + 1 }}</span>
              <div class="suggestion-content">
                <strong>{{ area.area }}</strong>
                <p>{{ area.suggestion }}</p>
              </div>
              <span class="suggestion-priority">优先级：{{ area.priority }}</span>
            </div>
          </div>
          <div v-else class="state-box">继续练习，系统会根据你的表现生成个性化建议</div>
        </div>
      </template>
    </section>
  </div>
</template>

<style scoped>
.hero-simple {
  height: 240px;
  position: relative;
  overflow: hidden;
  background: #536b69;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
}

.hero-copy {
  padding: 0 20px;
}

.hero-copy h1 {
  font-size: 28px;
  margin: 8px 0;
}

.hero-copy p {
  font-size: 14px;
  opacity: 0.9;
}

.stats-main {
  padding: 40px 20px;
  max-width: 640px;
  margin: 0 auto;
}

/* 概览卡片 - 移动端单列 */
.mob-overview-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  margin-bottom: 32px;
}

.mob-overview-card {
  min-height: 44px !important;
  background: #fffdf8;
  padding: 20px 16px;
  text-align: center;
  border: 1px solid #e3e0d4;
  border-radius: 12px;
  transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  touch-action: manipulation;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
.mob-overview-card:active {
  transform: scale(0.97);
  box-shadow: 0 4px 12px -6px rgba(0, 0, 0, 0.12);
}

.overview-icon {
  font-size: 28px;
  margin-bottom: 10px;
}

.overview-value {
  font: 600 32px 'Zen Kaku Gothic New', sans-serif;
  color: #3a5b4b;
  margin-bottom: 6px;
  font-variant-numeric: tabular-nums;
}

.overview-label {
  font-size: 12px;
  color: #7a8279;
  letter-spacing: 0.04em;
}

/* 分数说明 */
.mob-score-notice {
  background: #f5f2e9;
  padding: 24px 20px;
  margin: 32px 0;
  border-radius: 12px;
}

.mob-score-notice h2 {
  font: 600 18px 'Zen Kaku Gothic New', sans-serif;
  margin: 0 0 20px;
  color: #27302b;
}

.mob-score-types {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.score-type {
  background: #fffdf8;
  padding: 18px 20px;
  border-left: 3px solid #96795c;
  border-radius: 8px;
}

.score-type h3 {
  font: 600 16px 'Zen Kaku Gothic New', sans-serif;
  margin: 0 0 10px;
  color: #3a5b4b;
}

.score-value {
  font: 600 24px 'Zen Kaku Gothic New', sans-serif;
  color: #355247;
  margin-bottom: 10px;
  font-variant-numeric: tabular-nums;
}

.score-type p {
  font-size: 13px;
  line-height: 1.7;
  color: #7a8279;
  margin: 0;
}

.section-title {
  font: 600 20px 'Zen Kaku Gothic New', sans-serif;
  margin: 32px 0 16px;
  color: #27302b;
}

/* 题型分项 */
.mob-type-breakdown {
  display: flex;
  flex-direction: column;
  gap: 14px;
  margin-bottom: 32px;
}

.type-item {
  background: #fffdf8;
  padding: 18px 20px;
  border: 1px solid #e3e0d4;
  border-radius: 10px;
}

.type-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
  gap: 12px;
}

.type-name {
  font: 600 15px 'Zen Kaku Gothic New', sans-serif;
  color: #27302b;
  flex: 1;
}

.type-stats {
  font-size: 12px;
  color: #7a8279;
}

.type-accuracy {
  font: 600 18px 'Zen Kaku Gothic New', sans-serif;
  color: #355247;
  min-width: 50px;
  text-align: right;
  font-variant-numeric: tabular-nums;
}

.type-bar {
  height: 8px;
  background: #e3e0d4;
  border-radius: 4px;
  overflow: hidden;
}

.type-bar-fill {
  height: 100%;
  background: #355247;
  transition: width 0.3s ease;
}

/* 错题手风琴 */
.mob-mistakes-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 32px;
}

.mob-mistake-card {
  background: #fffdf8;
  border: 1px solid #e3e0d4;
  border-radius: 10px;
  overflow: hidden;
}

.mob-mistake-header {
  min-height: 44px !important;
  width: 100%;
  padding: 16px 20px;
  background: transparent;
  border: none;
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
  text-align: left;
  transition: background 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  touch-action: manipulation;
}

.mob-mistake-header:active {
  background: color-mix(in srgb, #e3e0d4 30%, transparent);
  transform: scale(0.97);
}

.mob-mistake-title {
  display: flex;
  flex-direction: column;
  gap: 4px;
  flex: 1;
}

.mistake-type {
  font: 600 14px 'Zen Kaku Gothic New', sans-serif;
  color: #96795c;
  letter-spacing: 0.03em;
}

.mistake-count {
  font-size: 12px;
  color: #a45d54;
}

.mob-mistake-toggle {
  font-size: 24px;
  font-weight: 300;
  color: #7a8279;
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.mob-mistake-content {
  padding: 0 20px 16px;
  border-top: 1px solid #e3e0d4;
  padding-top: 14px;
  animation: mistakeExpand 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}

@keyframes mistakeExpand {
  from {
    opacity: 0;
    transform: translateY(-4px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.mob-mistake-content p {
  font-size: 14px;
  line-height: 1.7;
  color: #5f6b60;
  margin: 8px 0;
}

.mob-mistake-content strong {
  color: #27302b;
}

/* 复习建议 */
.review-suggestions {
  margin-bottom: 40px;
}

.mob-suggestion-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.suggestion-item {
  display: flex;
  gap: 14px;
  align-items: flex-start;
  background: #fffdf8;
  padding: 18px 20px;
  border: 1px solid #e3e0d4;
  border-radius: 10px;
  transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  touch-action: manipulation;
  cursor: pointer;
}
.suggestion-item:active {
  transform: scale(0.97);
  box-shadow: 0 4px 12px -6px rgba(0, 0, 0, 0.12);
}

.suggestion-rank {
  width: 36px;
  height: 36px;
  background: #355247;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font: 600 16px 'Zen Kaku Gothic New', sans-serif;
  flex-shrink: 0;
}

.suggestion-content {
  flex: 1;
  min-width: 0;
}

.suggestion-content strong {
  display: block;
  font: 600 15px 'Zen Kaku Gothic New', sans-serif;
  color: #27302b;
  margin-bottom: 6px;
}

.suggestion-content p {
  font-size: 13px;
  line-height: 1.7;
  color: #5f6b60;
  margin: 0;
}

.suggestion-priority {
  font-size: 12px;
  color: #96795c;
  letter-spacing: 0.04em;
  flex-shrink: 0;
}

/* 骨架屏样式 */
.stats-skeleton {
  padding: 20px 0;
}

.skeleton-overview {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  margin-bottom: 32px;
}

.skeleton-card {
  height: 120px;
  background: linear-gradient(90deg, #f5f2e9 25%, #fffdf8 50%, #f5f2e9 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: 12px;
}

.skeleton-mistakes {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 32px;
}

.skeleton-mistake-item {
  height: 80px;
  background: linear-gradient(90deg, #f5f2e9 25%, #fffdf8 50%, #f5f2e9 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: 10px;
}

.skeleton-suggestions {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.skeleton-suggestion-item {
  height: 100px;
  background: linear-gradient(90deg, #f5f2e9 25%, #fffdf8 50%, #f5f2e9 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: 10px;
}

@keyframes shimmer {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}

/* 交错进入动画 */
@media (max-width: 768px) {
  .mob-timeline-item {
    opacity: 0;
    transform: translateY(16px);
    animation: item-enter 0.45s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  }
  .mob-timeline-item:nth-child(1) { animation-delay: 0.05s; }
  .mob-timeline-item:nth-child(2) { animation-delay: 0.1s; }
  .mob-timeline-item:nth-child(3) { animation-delay: 0.15s; }
  .mob-timeline-item:nth-child(4) { animation-delay: 0.2s; }
  .mob-timeline-item:nth-child(5) { animation-delay: 0.25s; }

  @keyframes item-enter {
    to { opacity: 1; transform: translateY(0); }
  }

  /* Apple HIG: 触控区域至少 44px */
  .mob-overview-card,
  .overview-card,
  .mob-mistake-header,
  .mistake-header,
  .accordion-header {
    min-height: 44px;
  }
}

/* 平板及以上 */
@media (min-width: 768px) {
  .stats-main {
    padding: 60px 40px;
    max-width: 900px;
  }

  .mob-overview-grid {
    grid-template-columns: repeat(4, 1fr);
    gap: 16px;
  }

  .mob-overview-card {
    padding: 24px 16px;
  }

  .overview-value {
    font-size: 36px;
  }

  .section-title {
    font-size: 24px;
    margin: 40px 0 20px;
  }

  .mob-score-notice {
    padding: 32px 28px;
    margin: 48px 0;
  }

  .mob-score-notice h2 {
    font-size: 22px;
  }

  .mob-score-types {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 20px;
  }
}
</style>
