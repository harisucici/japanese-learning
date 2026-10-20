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
      totalAnswered: stats.totalQuestions,
      totalCorrect: stats.correctCount,
      accuracy: stats.accuracy * 100,
      byType: Object.fromEntries((stats.levelStats || []).map(item => [item.level, {
        accuracy: item.accuracy * 100,
        total: item.totalQuestions,
        correct: item.correctCount
      }]))
    }
    mistakesData.value = (mistakes.items || []).map(item => ({
      type: item.type,
      count: item.wrongCount,
      knowledgePoint: item.question?.type || item.type,
      questionSnippet: item.question?.content || ''
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
    accuracy: data.accuracy,
    total: data.total,
    correct: data.correct
  }))
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

/**
 * 本站仅显示实际练习正确率，不推算 JLPT 正式得分。
 */

onMounted(loadStats)
</script>

<template>
  <div class="stats-page">
    <section class="hero-simple">
      <div class="hero-copy">
        <p class="eyebrow light">MY STATISTICS</p>
        <h1>我的学习档案</h1>
        <p>在数据中看见成长</p>
      </div>
    </section>

    <section class="stats-main section-wrap">
      <div v-if="loading" class="state-box">正在加载统计数据…</div>
      <div v-else-if="error" class="state-box error">{{ error }} <button @click="loadStats">重试</button></div>
      <template v-else-if="statsData">
        <!-- 概览卡片 -->
        <div class="overview-grid">
          <div class="overview-card">
            <div class="overview-icon">📊</div>
            <div class="overview-value">{{ statsData.totalAnswered || 0 }}</div>
            <div class="overview-label">已答题数</div>
          </div>
          <div class="overview-card">
            <div class="overview-icon">✓</div>
            <div class="overview-value">{{ statsData.totalCorrect || 0 }}</div>
            <div class="overview-label">答对题数</div>
          </div>
          <div class="overview-card">
            <div class="overview-icon">%</div>
            <div class="overview-value">{{ statsData.accuracy ? Math.round(statsData.accuracy) : 0 }}%</div>
            <div class="overview-label">总体正确率</div>
          </div>
          <div class="overview-card">
            <div class="overview-icon">⏱</div>
            <div class="overview-value">{{ statsData.totalTimeSpent ? Math.round(statsData.totalTimeSpent / 60) : 0 }}</div>
            <div class="overview-label">学习时长（分钟）</div>
          </div>
        </div>

        <!-- 分数说明 -->
        <div class="score-notice">
          <h2>练习结果与正式考试成绩</h2>
          <div class="score-types">
            <div class="score-type">
              <h3>练习分</h3>
              <div class="score-value">{{ statsData.totalCorrect || 0 }} / {{ statsData.totalAnswered || 0 }}</div>
              <p>你在所有练习中的实际答对题数</p>
            </div>
            <div class="score-type">
              <h3>练习正确率</h3>
              <div class="score-value">{{statsData.accuracy?.toFixed(1) || 0}}%</div>
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
        <div class="type-breakdown">
          <div v-for="item in typeAccuracy" :key="item.type" class="type-item">
            <div class="type-header">
              <span class="type-name">{{ item.type }}</span>
              <span class="type-accuracy">{{ Math.round(item.accuracy) }}%</span>
            </div>
            <div class="type-bar">
              <div class="type-bar-fill" :style="{ width: item.accuracy + '%' }"></div>
            </div>
            <div class="type-stats">
              <span>答对 {{ item.correct }} / {{ item.total }} 题</span>
            </div>
          </div>
        </div>

        <!-- 错题知识点 -->
        <h2 class="section-title">错题对应知识点</h2>
        <div v-if="mistakesData.length === 0" class="state-box">暂无错题记录</div>
        <div v-else class="mistakes-list">
          <div v-for="(mistake, index) in mistakesData" :key="index" class="mistake-card">
            <div class="mistake-header">
              <span class="mistake-type">{{ typeMap[mistake.type] || mistake.type }}</span>
              <span class="mistake-count">错误 {{ mistake.count }} 次</span>
            </div>
            <div class="mistake-content">
              <p><strong>知识点：</strong>{{ mistake.knowledgePoint || '未分类' }}</p>
              <p v-if="mistake.questionSnippet"><strong>题目：</strong>{{ mistake.questionSnippet }}</p>
            </div>
          </div>
        </div>

        <!-- 优先复习建议 -->
        <h2 class="section-title">优先复习建议</h2>
        <div class="review-suggestions">
          <div v-if="statsData.weakAreas && statsData.weakAreas.length > 0" class="suggestion-list">
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
  height: 300px;
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
  padding: 0 5.7%;
}

.stats-main {
  padding-top: 60px;
}

.overview-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
  margin: 0 0 60px;
}

.overview-card {
  background: #fffdf8;
  padding: 30px;
  text-align: center;
  border: 1px solid #e3e0d4;
}

.overview-icon {
  font-size: 32px;
  margin-bottom: 12px;
}

.overview-value {
  font: 36px 'Zen Kaku Gothic New', sans-serif;
  color: #3a5b4b;
  margin-bottom: 8px;
}

.overview-label {
  font-size: 13px;
  color: #7a8279;
  letter-spacing: 0.05em;
}

.score-notice {
  background: #f5f2e9;
  padding: 40px;
  margin: 60px 0;
}

.score-notice h2 {
  font: 24px 'Zen Kaku Gothic New', sans-serif;
  margin: 0 0 30px;
  color: #27302b;
}

.score-types {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 30px;
}

.score-type {
  background: #fffdf8;
  padding: 25px;
  border-left: 3px solid #96795c;
}

.score-type h3 {
  font: 18px 'Zen Kaku Gothic New', sans-serif;
  margin: 0 0 12px;
  color: #3a5b4b;
}

.score-value {
  font: 28px 'Zen Kaku Gothic New', sans-serif;
  color: #355247;
  margin-bottom: 12px;
}

.score-type p {
  font-size: 13px;
  line-height: 1.8;
  color: #7a8279;
  margin: 0;
}

.section-title {
  font: 24px 'Zen Kaku Gothic New', sans-serif;
  margin: 60px 0 30px;
  color: #27302b;
}

.type-breakdown {
  display: grid;
  gap: 25px;
  margin: 0 0 60px;
}

.type-item {
  background: #fffdf8;
  padding: 25px;
  border: 1px solid #e3e0d4;
}

.type-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.type-name {
  font: 16px 'Zen Kaku Gothic New', sans-serif;
  color: #27302b;
}

.type-accuracy {
  font: 20px 'Zen Kaku Gothic New', sans-serif;
  color: #355247;
}

.type-bar {
  height: 8px;
  background: #e3e0d4;
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 10px;
}

.type-bar-fill {
  height: 100%;
  background: #355247;
  transition: width 0.3s ease;
}

.type-stats {
  font-size: 13px;
  color: #7a8279;
}

.mistakes-list {
  display: grid;
  gap: 20px;
  margin: 0 0 60px;
}

.mistake-card {
  background: #fffdf8;
  padding: 25px;
  border: 1px solid #e3e0d4;
}

.mistake-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.mistake-type {
  font: 14px 'Zen Kaku Gothic New', sans-serif;
  color: #96795c;
  letter-spacing: 0.05em;
}

.mistake-count {
  font-size: 13px;
  color: #a45d54;
}

.mistake-content p {
  font-size: 14px;
  line-height: 1.8;
  color: #5f6b60;
  margin: 8px 0;
}

.review-suggestions {
  margin: 0 0 60px;
}

.suggestion-list {
  display: grid;
  gap: 20px;
}

.suggestion-item {
  display: flex;
  gap: 20px;
  align-items: flex-start;
  background: #fffdf8;
  padding: 25px;
  border: 1px solid #e3e0d4;
}

.suggestion-rank {
  width: 40px;
  height: 40px;
  background: #355247;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font: 18px 'Zen Kaku Gothic New', sans-serif;
  flex-shrink: 0;
}

.suggestion-content {
  flex: 1;
}

.suggestion-content strong {
  display: block;
  font: 16px 'Zen Kaku Gothic New', sans-serif;
  color: #27302b;
  margin-bottom: 8px;
}

.suggestion-content p {
  font-size: 13px;
  line-height: 1.8;
  color: #5f6b60;
  margin: 0;
}

.suggestion-priority {
  font-size: 12px;
  color: #96795c;
  letter-spacing: 0.05em;
}

@media (max-width: 968px) {
  .overview-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .score-types {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .overview-grid {
    grid-template-columns: 1fr;
  }
}
</style>
