<script setup>
import { onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useLearningStore } from '../store'

const api = useLearningStore()
const data = ref(null)
const error = ref('')
const loading = ref(true)

async function load() {
  loading.value = true
  error.value = ''
  try {
    data.value = await api.request('dashboard', undefined, true)
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

onMounted(load)

const format = (value) => value ? new Date(value).toLocaleString('zh-CN') : '—'

// 会话时长格式化（如果后端提供时长）
const formatDuration = (createdAt, completedAt) => {
  if (!createdAt || !completedAt) return null
  const ms = new Date(completedAt) - new Date(createdAt)
  if (ms < 0) return null
  const mins = Math.floor(ms / 60000)
  const secs = Math.floor((ms % 60000) / 1000)
  if (mins > 0) return `${mins}分${secs}秒`
  return `${secs}秒`
}
</script>

<template>
  <div class="content-page history-mobile">
    <div class="mob-page-head">
      <p class="eyebrow">YOUR LEARNING RECORD</p>
      <h2>学习记录</h2>
      <p class="mob-lead">作答记录与成绩来自后端数据库。当前浏览器通过 Cookie 关联服务端学习记录。</p>
    </div>

    <div v-if="loading" class="state-box mob-skeleton-wrap">
      <div class="mob-stats-grid mob-stats-skeleton">
        <div v-for="n in 4" :key="n" class="mob-stat-card shimmer-card">
          <div class="mob-sk-value shimmer"></div>
          <div class="mob-sk-label shimmer"></div>
        </div>
      </div>
      <div class="mob-timeline-skeleton">
        <div v-for="n in 5" :key="n" class="mob-timeline-item">
          <div class="mob-tl-dot shimmer"></div>
          <div class="mob-tl-content">
            <div class="mob-tl-top">
              <div class="mob-sk-date shimmer"></div>
              <div class="mob-sk-badge shimmer"></div>
            </div>
            <div class="mob-sk-title shimmer"></div>
            <div class="mob-sk-meta shimmer"></div>
          </div>
          <div class="mob-sk-action shimmer"></div>
        </div>
      </div>
    </div>
    <div v-else-if="error" class="state-box error">
      {{ error }} <button @click="load">重试</button>
    </div>

    <template v-if="data">
      <!-- 2x2 统计概览 -->
      <div class="mob-stats-grid">
        <div class="mob-stat-card">
          <strong>{{ data.totalAnswered }}</strong>
          <span>已答题数</span>
        </div>
        <div class="mob-stat-card">
          <strong>{{ data.accuracy == null ? '—' : `${(data.accuracy * 100).toFixed(1)}%` }}</strong>
          <span>正确率</span>
        </div>
        <div class="mob-stat-card">
          <strong>{{ data.completedSessions }}</strong>
          <span>完成练习</span>
        </div>
        <div class="mob-stat-card">
          <strong>{{ data.wrongCount }}</strong>
          <span>答错次数</span>
        </div>
      </div>

      <!-- 会话时间线 -->
      <h3 class="mob-subhead">学习记录</h3>
      <div class="mob-timeline">
        <RouterLink
          v-for="(s, i) in data.sessions || []"
          :key="s.id"
          :to="`/sessions/${s.id}`"
          class="mob-timeline-item"
          :style="{ '--i': i }"
        >
          <div class="mob-tl-dot" :class="s.mode">
            {{ s.mode === 'exam' ? '試' : '學' }}
          </div>
          <div class="mob-tl-content">
            <div class="mob-tl-top">
              <small>{{ format(s.createdAt) }}</small>
              <span class="mob-tl-badge" :class="{ completed: !!s.completedAt }">
                {{ s.completedAt ? '已完成' : '进行中' }}
              </span>
            </div>
            <h3>
              {{ s.mode === 'fun' ? (s.activityTitle || '素材练习') : s.level?.toUpperCase() + ' 模拟考试' }}
            </h3>
            <div class="mob-tl-meta">
              <span>已答 {{ s.answeredCount }} / {{ s.totalQuestions }} 题</span>
              <span v-if="formatDuration(s.createdAt, s.completedAt)" class="mob-tl-duration">
                · {{ formatDuration(s.createdAt, s.completedAt) }}
              </span>
            </div>
          </div>
          <span class="mob-tl-action">
            {{ s.completedAt ? `${s.score} 分` : '继续 ↗' }}
          </span>
        </RouterLink>
        <p v-if="!data.sessions?.length" class="empty">
          还没有练习记录。完成一次练习后，这里会显示真实成绩。
        </p>
      </div>
    </template>
  </div>
</template>

<style scoped>
.history-mobile {
  max-width: 640px;
  margin: 0 auto;
  padding: 20px 16px 40px;
  --spring-ease: cubic-bezier(0.34, 1.56, 0.64, 1);
  --spring-duration: 200ms;
}

.mob-page-head {
  margin-bottom: 24px;
}
.mob-page-head h2 {
  font: 600 24px/1.3 var(--app-font-family);
  color: var(--theme-text, #27302b);
  margin: 6px 0 8px;
}
.mob-lead {
  font-size: 14px;
  line-height: 1.7;
  color: var(--theme-text-secondary, #67746a);
  margin: 0;
}

/* 2x2 统计网格 */
.mob-stats-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  margin-bottom: 32px;
}
.mob-stat-card {
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--theme-border, #e3e0d4);
  border-radius: 12px;
  padding: 18px 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  text-align: center;
  transition: transform var(--spring-duration) var(--spring-ease);
}
.mob-stat-card:active {
  transform: scale(0.97);
}
.mob-stat-card strong {
  font: 600 28px/1 var(--app-font-family);
  color: var(--season-accent, #355247);
  font-variant-numeric: tabular-nums;
}
.mob-stat-card span {
  font-size: 12px;
  color: var(--theme-text-secondary, #7a8279);
  letter-spacing: 0.04em;
}

/* 时间线标题 */
.mob-subhead {
  font: 600 18px/1.3 var(--app-font-family);
  color: var(--theme-text, #27302b);
  margin: 0 0 16px;
  padding-left: 4px;
}

/* 时间线列表 */
.mob-timeline {
  position: relative;
  padding-left: 28px;
}
.mob-timeline::before {
  content: '';
  position: absolute;
  left: 14px;
  top: 12px;
  bottom: 12px;
  width: 2px;
  background: var(--theme-border, #e3e0d4);
  border-radius: 1px;
}

.mob-timeline-item {
  position: relative;
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 14px 16px 14px 0;
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--theme-border, #e3e0d4);
  border-radius: 12px;
  margin-bottom: 12px;
  text-decoration: none;
  color: inherit;
  transition: transform var(--spring-duration) var(--spring-ease),
              border-color 0.15s, box-shadow 0.15s;
  animation: spring-fade-in 400ms var(--spring-ease) both;
  animation-delay: calc(var(--i, 0) * 50ms);
}
.mob-timeline-item:active {
  transform: scale(0.97);
}
.mob-timeline-item:hover {
  border-color: var(--season-accent, #57718c);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.mob-tl-dot {
  position: absolute;
  left: -36px;
  top: 14px;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: var(--season-accent, #57718c);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font: 600 12px var(--app-font-family);
  border: 2px solid var(--theme-surface, #fffdf8);
  box-shadow: 0 0 0 2px var(--theme-border, #e3e0d4);
  flex-shrink: 0;
}
.mob-tl-dot.exam {
  background: #2563EB;
}

.mob-tl-content {
  flex: 1;
  min-width: 0;
}
.mob-tl-top {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}
.mob-tl-top small {
  font-size: 12px;
  color: var(--theme-text-secondary, #8a9389);
}
.mob-tl-badge {
  font-size: 12px;
  padding: 2px 8px;
  border-radius: 10px;
  background: color-mix(in srgb, #2563EB 8%, transparent);
  color: #2563EB;
  letter-spacing: 0.04em;
}
.mob-tl-badge.completed {
  background: color-mix(in srgb, #10b981 8%, transparent);
  color: #059669;
}
.mob-tl-content h3 {
  font: 500 15px/1.4 var(--app-font-family);
  color: var(--theme-text, #27302b);
  margin: 0 0 4px;
}
.mob-tl-meta {
  font-size: 12px;
  color: var(--theme-text-secondary, #67746a);
}
.mob-tl-duration {
  color: var(--theme-text-secondary, #8a9389);
}
.mob-tl-action {
  flex-shrink: 0;
  font: 600 14px var(--app-font-family);
  color: var(--season-accent, #355247);
  align-self: center;
}

.empty {
  text-align: center;
  font-size: 14px;
  color: var(--theme-text-secondary, #67746a);
  padding: 32px 16px;
  margin: 0;
}

/* 平板及以上 */
@media (min-width: 768px) {
  .history-mobile {
    max-width: 800px;
    padding: 40px 32px 60px;
  }
  .mob-stats-grid {
    gap: 16px;
  }
  .mob-stat-card {
    padding: 24px 16px;
  }
  .mob-stat-card strong {
    font-size: 32px;
  }
}

/* Spring 进入动画 */
@keyframes spring-fade-in {
  from {
    opacity: 0;
    transform: translateY(12px) scale(0.98);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

/* 骨架屏 */
.mob-skeleton-wrap {
  display: block;
  padding: 0;
}
.mob-stats-skeleton {
  pointer-events: none;
}
.shimmer-card {
  align-items: center;
}
.mob-sk-value {
  width: 72px;
  height: 28px;
  border-radius: 6px;
}
.mob-sk-label {
  width: 56px;
  height: 12px;
  border-radius: 6px;
}

/* Shimmer 动画 */
@keyframes shimmer {
  0% { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}
.shimmer {
  background: linear-gradient(
    90deg,
    var(--theme-surface-alt, #f5f2e9) 0%,
    var(--theme-surface, #fffdf8) 50%,
    var(--theme-surface-alt, #f5f2e9) 100%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: 6px;
}

/* 骨架时间线 */
.mob-timeline-skeleton .mob-timeline-item {
  cursor: default;
  animation: none;
}
.mob-tl-dot.shimmer {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  flex-shrink: 0;
}
.mob-tl-top {
  display: flex;
  align-items: center;
  gap: 8px;
}
.mob-sk-date {
  width: 90px;
  height: 12px;
}
.mob-sk-badge {
  width: 48px;
  height: 16px;
  border-radius: 10px;
}
.mob-sk-title {
  width: 65%;
  height: 15px;
  margin: 8px 0 6px;
}
.mob-sk-meta {
  width: 45%;
  height: 12px;
}
.mob-sk-action {
  width: 48px;
  height: 16px;
  align-self: center;
  flex-shrink: 0;
}

/* 减弱动画模式 */
@media (prefers-reduced-motion: reduce) {
  .mob-timeline-item {
    animation: none;
    transition: border-color 0.15s, box-shadow 0.15s;
  }
  .mob-stat-card {
    transition: none;
  }
}
</style>
