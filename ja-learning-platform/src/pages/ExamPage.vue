<script setup>
import { computed,onMounted,ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useLearningStore } from '../store'
import AnswerCard from '../components/AnswerCard.vue'
import TimeWarning from '../components/TimeWarning.vue'

// 模式：exam（仿真严格计时）/ practice（练习可暂停）
const api = useLearningStore()
const router = useRouter()
const route = useRoute()

const data = ref(null)
const error = ref('')
const loading = ref(true)
const level = ref('n5')
const feedback = ref(false)
const starting = ref('')

// 模式由 URL 参数决定，默认 exam
const mode = computed(() => {
  const m = route.query.mode
  return m === 'practice' ? 'practice' : 'exam'
})

function setMode(m) {
  router.replace({ query: { ...route.query, mode: m } })
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    data.value = await api.request('exam-papers')
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

onMounted(load)

const papers = computed(() => (data.value?.papers || []).filter(x => x.level === level.value))

async function start(p) {
  starting.value = p.id
  error.value = ''
  try {
    // practice 模式：禁用立即反馈（练习由后端记录）
    const instantFeedback = mode.value === 'practice' ? false : feedback.value
    const s = await api.startExam(level.value, p.id, instantFeedback)
    // 将模式信息透传到 session（保留为 URL 参数，供 SessionPage 读取）
    router.push({ path: `/sessions/${s.id}`, query: { mode: mode.value } })
  } catch (e) {
    error.value = e.message
  } finally {
    starting.value = ''
  }
}
</script>

<template>
  <div class="content-page exam-mobile">
    <!-- Tab 模式切换 -->
    <div class="mob-mode-tabs">
      <button
        type="button"
        :class="['mob-tab', { active: mode === 'exam' }]"
        @click="setMode('exam')"
      >
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
          <circle cx="12" cy="12" r="10" />
          <path d="M12 6v6l4 2" />
        </svg>
        仿真考试
      </button>
      <button
        type="button"
        :class="['mob-tab', { active: mode === 'practice' }]"
        @click="setMode('practice')"
      >
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
          <path d="M12 20h9" />
          <path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z" />
        </svg>
        练习模式
      </button>
    </div>
    <p class="mob-mode-hint">
      {{ mode === 'exam'
        ? '仿真模式：计时严格，听力播放时锁定界面，交卷后统一查看讲解。'
        : '练习模式：可随时暂停，答题后立即显示解析，适合日常巩固。' }}
    </p>

    <div class="mob-header">
      <p class="eyebrow">JLPT EXAM PRACTICE</p>
      <h2>真题模拟</h2>
      <p class="mob-lead">仅开放已核验完整试卷。科目计时由后端保存，刷新不会重置。</p>
    </div>

    <!-- 骨架屏：加载时展示 3 张试卷卡片骨架 -->
    <div v-if="loading" class="mob-skeleton-list">
      <div v-for="n in 3" :key="n" class="mob-skeleton-card">
        <div class="mob-sk-head">
          <div class="mob-sk-idx shimmer"></div>
          <div class="mob-sk-meta">
            <div class="mob-sk-small shimmer"></div>
            <div class="mob-sk-title shimmer"></div>
          </div>
        </div>
        <div class="mob-sk-note shimmer"></div>
        <div class="mob-sk-note short shimmer"></div>
        <div class="mob-sk-btn shimmer"></div>
      </div>
    </div>
    <div v-else-if="error" class="state-box error">
      {{ error }} <button @click="load">重试</button>
    </div>

    <template v-if="data">
      <!-- 等级筛选 -->
      <div class="mob-level-chips">
        <button
          v-for="l in ['n5','n4','n3','n2','n1']"
          :key="l"
          :class="['mob-chip', { chosen: level === l }]"
          @click="level = l"
        >{{ l.toUpperCase() }}</button>
      </div>

      <!-- 科目时长 -->
      <div class="mob-rules-card">
        <strong>官方科目时长</strong>
        <span v-for="r in data.rules?.[level] || []" :key="r.title">
          {{ r.title }} · {{ r.minutes }} 分钟
        </span>
      </div>

      <label v-if="mode === 'exam'" class="mob-feedback-toggle">
        <input v-model="feedback" type="checkbox">
        <span>
          答错后立即显示答案和讲解
          <small>默认关闭，交卷后统一查看。</small>
        </span>
      </label>

      <!-- 试卷卡片列表 -->
      <div class="mob-paper-list">
        <article v-for="(p, i) in papers" :key="p.id" class="mob-paper-card">
          <div class="mob-paper-head">
            <span class="mob-paper-idx">{{ String(i + 1).padStart(2, '0') }}</span>
            <div class="mob-paper-meta">
              <small>{{ p.level?.toUpperCase() }} · {{ p.examYear || '官方问题集' }}</small>
              <h3>{{ p.title }}</h3>
            </div>
          </div>
          <p class="mob-paper-note">{{ p.verificationNote }}</p>
          <button
            class="mob-paper-btn"
            :disabled="!p.ready || !!starting"
            @click="start(p)"
          >
            {{ p.ready ? (starting === p.id ? '正在准备…' : (mode === 'exam' ? '开始考试' : '开始练习')) : '材料待完整入库' }}
          </button>
        </article>
      </div>

      <p v-if="!papers.some(p => p.ready)" class="source-note">
        当前没有通过完整性校验的整卷。缺少科目、标准答案或听力材料的资料不能开始考试。
      </p>
    </template>
  </div>
</template>

<style scoped>
.exam-mobile {
  max-width: 640px;
  margin: 0 auto;
  padding: 16px;
}

/* Tab 模式切换 - 48px 高 */
.mob-mode-tabs {
  display: flex;
  height: 48px;
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid var(--theme-border, #d1ccb8);
  background: var(--theme-surface, #fffdf8);
}
.mob-tab {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border: none;
  background: transparent;
  cursor: pointer;
  font: 500 14px/1 var(--app-font-family);
  color: var(--theme-text-secondary, #67746a);
  transition: all 0.2s;
  letter-spacing: 0.03em;
}
.mob-tab.active {
  background: var(--season-accent, #57718c);
  color: #fff;
  font-weight: 600;
}
.mob-mode-hint {
  font-size: 12px;
  line-height: 1.8;
  color: var(--theme-text-secondary, #67746a);
  margin: 12px 0 24px;
  padding: 0 4px;
  letter-spacing: 0.02em;
}

.mob-header {
  margin-bottom: 24px;
}
.mob-header h2 {
  font: 600 22px/1.4 var(--app-font-family);
  color: var(--theme-text, #27302b);
  margin: 6px 0 8px;
}
.mob-lead {
  font-size: 14px;
  line-height: 1.7;
  color: var(--theme-text-secondary, #67746a);
  margin: 0;
}

/* 等级筛选 */
.mob-level-chips {
  display: flex;
  gap: 8px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}
.mob-chip {
  min-width: 52px;
  min-height: 44px !important;
  height: auto;
  border: 1px solid var(--theme-border, #d1ccb8);
  background: var(--theme-surface, #fffdf8);
  border-radius: 20px;
  font: 600 13px var(--app-font-family);
  color: var(--theme-text-secondary, #67746a);
  cursor: pointer;
  transition: all 0.15s;
  letter-spacing: 0.05em;
}
.mob-chip.chosen {
  background: var(--season-accent, #57718c);
  color: #fff;
  border-color: var(--season-accent, #57718c);
}

/* 科目时长 */
.mob-rules-card {
  background: var(--theme-surface-alt, #f8f6ee);
  border: 1px solid var(--theme-border, #e2ded3);
  border-radius: 10px;
  padding: 14px 16px;
  margin-bottom: 16px;
  display: flex;
  flex-wrap: wrap;
  gap: 6px 12px;
  align-items: center;
  font-size: 13px;
  color: var(--theme-text-secondary, #67746a);
}
.mob-rules-card strong {
  color: var(--theme-text, #27302b);
  font-size: 13px;
  width: 100%;
  margin-bottom: 2px;
}

/* 反馈开关 */
.mob-feedback-toggle {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 14px 16px;
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--theme-border, #e2ded3);
  border-radius: 10px;
  margin-bottom: 20px;
  cursor: pointer;
  font-size: 14px;
  color: var(--theme-text, #27302b);
  line-height: 1.5;
}
.mob-feedback-toggle input {
  margin-top: 2px;
  width: 18px;
  height: 18px;
  flex-shrink: 0;
}
.mob-feedback-toggle small {
  display: block;
  font-size: 12px;
  color: var(--theme-text-secondary, #67746a);
  margin-top: 2px;
}

/* 试卷卡片列表 */
.mob-paper-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-bottom: 24px;
}
.mob-paper-card {
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--theme-border, #d1ccb8);
  border-radius: 14px;
  padding: 20px;
  transition: border-color 0.2s;
}
.mob-paper-head {
  display: flex;
  align-items: flex-start;
  gap: 14px;
}
.mob-paper-idx {
  font: 700 14px/1 var(--app-font-family);
  color: var(--season-accent, #57718c);
  background: color-mix(in srgb, var(--season-accent, #57718c) 10%, transparent);
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  flex-shrink: 0;
}
.mob-paper-meta small {
  font-size: 12px;
  color: var(--theme-text-secondary, #67746a);
  letter-spacing: 0.04em;
  text-transform: uppercase;
}
.mob-paper-meta h3 {
  font: 500 16px/1.4 var(--app-font-family);
  color: var(--theme-text, #27302b);
  margin: 4px 0 0;
}
.mob-paper-note {
  font-size: 13px;
  color: var(--theme-text-secondary, #67746a);
  line-height: 1.6;
  margin: 12px 0 16px;
}
.mob-paper-btn {
  display: block;
  width: 100%;
  height: 48px;
  border: none;
  border-radius: 10px;
  background: var(--season-accent, #57718c);
  color: #fff;
  font: 600 15px var(--app-font-family);
  letter-spacing: 0.06em;
  cursor: pointer;
  transition: all 0.2s;
}
.mob-paper-btn:hover:not(:disabled) {
  filter: brightness(1.1);
}
.mob-paper-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

/* 骨架屏：加载时展示 3 张试卷卡片骨架 */
.mob-skeleton-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-bottom: 24px;
}

.mob-skeleton-card {
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--theme-border, #d1ccb8);
  border-radius: 14px;
  padding: 20px;
}

.mob-sk-head {
  display: flex;
  align-items: flex-start;
  gap: 14px;
  margin-bottom: 16px;
}

.mob-sk-idx {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  flex-shrink: 0;
}

.mob-sk-meta {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.mob-sk-small {
  width: 40%;
  height: 12px;
  border-radius: 6px;
}

.mob-sk-title {
  width: 70%;
  height: 16px;
  border-radius: 6px;
}

.mob-sk-note {
  width: 100%;
  height: 13px;
  border-radius: 6px;
  margin-bottom: 8px;
}

.mob-sk-note.short {
  width: 85%;
  margin-bottom: 16px;
}

.mob-sk-btn {
  width: 100%;
  height: 48px;
  border-radius: 10px;
}

/* Shimmer 动画 */
@keyframes shimmer {
  0% {
    background-position: -200% 0;
  }
  100% {
    background-position: 200% 0;
  }
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
}

/* Spring 过渡变量 */
:root {
  --spring-ease: cubic-bezier(0.34, 1.56, 0.64, 1);
  --spring-duration: 200ms;
}

/* Tab 模式切换 Spring 过渡 */
.mob-mode-tabs {
  transition: all var(--spring-duration) var(--spring-ease);
}

.mob-tab {
  transition: all var(--spring-duration) var(--spring-ease);
}

.mob-tab:active {
  transform: scale(0.97);
}

/* 试卷卡片 Spring 过渡 + :active 缩放 */
.mob-paper-card {
  transition: all var(--spring-duration) var(--spring-ease);
}

.mob-paper-card:active {
  transform: scale(0.97);
}

/* 等级筛选 Spring 过渡 */
.mob-chip {
  transition: all var(--spring-duration) var(--spring-ease);
}

.mob-chip:active {
  transform: scale(0.97);
}

/* 开始按钮 Spring 过渡 + :active 缩放 */
.mob-paper-btn {
  transition: all var(--spring-duration) var(--spring-ease);
}

.mob-paper-btn:active:not(:disabled) {
  transform: scale(0.97);
}

/* Desktop 保留原有样式的兼容性 */
@media (min-width: 641px) {
  .exam-mobile {
    max-width: 800px;
    padding: 24px 32px;
  }
  .mob-paper-card {
    padding: 24px 28px;
  }
}

/* 交错进入动画 */
@media (max-width: 768px) {
  .mob-mode-hint { margin: 8px 0 12px; line-height: 1.55; }
  .mob-header { margin-bottom: 12px; }
  .mob-level-chips { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 6px; margin-bottom: 12px; }
  .mob-chip { min-width: 0; }
  .mob-paper-card {
    opacity: 0;
    transform: translateY(16px);
    animation: item-enter 0.45s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  }
  .mob-paper-card:nth-child(1) { animation-delay: 0.05s; }
  .mob-paper-card:nth-child(2) { animation-delay: 0.1s; }
  .mob-paper-card:nth-child(3) { animation-delay: 0.15s; }
  .mob-paper-card:nth-child(4) { animation-delay: 0.2s; }
  .mob-paper-card:nth-child(5) { animation-delay: 0.25s; }

  @keyframes item-enter {
    to { opacity: 1; transform: translateY(0); }
  }
}
</style>
