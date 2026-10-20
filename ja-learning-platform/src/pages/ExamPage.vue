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
  <div class="content-page">
    <!-- 模式切换区 -->
    <div class="mode-switcher">
      <div class="mode-info">
        <p class="eyebrow">EXAM MODE</p>
        <h2>选择模式</h2>
      </div>
      <div class="mode-options">
        <button
          type="button"
          :class="{ active: mode === 'exam' }"
          @click="setMode('exam')"
        >
          <span class="mode-icon">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6">
              <circle cx="12" cy="12" r="10" />
              <path d="M12 6v6l4 2" />
            </svg>
          </span>
          <span class="mode-text">
            <strong>仿真考试</strong>
            <small>严格计时，中途不可暂停</small>
          </span>
        </button>
        <button
          type="button"
          :class="{ active: mode === 'practice' }"
          @click="setMode('practice')"
        >
          <span class="mode-icon">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6">
              <path d="M12 20h9" />
              <path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z" />
            </svg>
          </span>
          <span class="mode-text">
            <strong>练习模式</strong>
            <small>可暂停、可回看解析</small>
          </span>
        </button>
      </div>
      <p class="mode-hint">
        {{ mode === 'exam'
          ? '仿真模式：计时严格，听力播放时锁定界面，交卷后统一查看讲解。'
          : '练习模式：可随时暂停，答题后立即显示解析，适合日常巩固。' }}
      </p>
    </div>

    <div class="section-top">
      <p class="eyebrow">JLPT EXAM PRACTICE</p>
      <span>真题模拟</span>
    </div>
    <h2>把练习，<em>交给时间。</em></h2>
    <p class="page-lead">仅开放已核验完整试卷。科目计时由后端保存，刷新不会重置。</p>

    <div v-if="loading" class="state-box">正在读取试卷…</div>
    <div v-else-if="error" class="state-box error">
      {{ error }} <button @click="load">重试</button>
    </div>

    <template v-if="data">
      <div class="filters">
        <button
          v-for="l in ['n5','n4','n3','n2','n1']"
          :key="l"
          :class="{ chosen: level === l }"
          @click="level = l"
        >{{ l.toUpperCase() }}</button>
      </div>

      <div class="exam-rules">
        <strong>官方科目时长</strong>
        <span v-for="r in data.rules?.[level] || []" :key="r.title">
          {{ r.title }} · {{ r.minutes }} 分钟
        </span>
        <small>有考试年月的历年卷使用对应时期规则；科目之间不结转剩余时间。</small>
      </div>

      <label v-if="mode === 'exam'" class="feedback-toggle">
        <input v-model="feedback" type="checkbox">
        答错后立即显示答案和讲解
        <small>默认关闭，交卷后统一查看。</small>
      </label>

      <div class="item-list">
        <article v-for="(p, i) in papers" :key="p.id" class="list-row">
          <span class="item-index">{{ String(i + 1).padStart(2, '0') }}</span>
          <div>
            <small>{{ p.level?.toUpperCase() }} · {{ p.examYear || '官方问题集' }}</small>
            <h3>{{ p.title }}</h3>
            <p>{{ p.verificationNote }}</p>
          </div>
          <button
            class="primary-action"
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
/* 模式切换区 */
.mode-switcher {
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--theme-border, #d1ccb8);
  border-radius: 12px;
  padding: 28px 32px;
  margin: 32px 0 40px;
  display: grid;
  grid-template-columns: 1fr 2fr;
  grid-template-rows: auto auto;
  gap: 24px 32px;
  align-items: start;
}
.mode-info .eyebrow {
  margin: 0 0 6px;
}
.mode-info h2 {
  font: 500 22px 'Zen Kaku Gothic New', sans-serif;
  letter-spacing: 0.06em;
  margin: 0;
  color: var(--theme-text, #27302b);
}
.mode-options {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  grid-row: 1 / 3;
}
.mode-options button {
  display: flex;
  align-items: flex-start;
  gap: 14px;
  padding: 16px 18px;
  border: 1px solid var(--theme-border, #d1ccb8);
  background: transparent;
  cursor: pointer;
  text-align: left;
  border-radius: 10px;
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  color: var(--theme-text, #27302b);
}
.mode-options button:hover {
  border-color: #2563EB;
  background: rgba(37, 99, 235, 0.03);
}
.mode-options button.active {
  border-color: #2563EB;
  background: rgba(37, 99, 235, 0.06);
  box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.08);
}
.mode-icon {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  border-radius: 8px;
  background: rgba(37, 99, 235, 0.1);
  color: #2563EB;
  flex: none;
}
.mode-text {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}
.mode-text strong {
  font: 500 14px 'Zen Kaku Gothic New', sans-serif;
  letter-spacing: 0.04em;
}
.mode-text small {
  font-size: 11px;
  color: var(--theme-text-secondary, #67746a);
  line-height: 1.5;
}
.mode-hint {
  grid-column: 1 / -1;
  margin: 0;
  padding-top: 16px;
  border-top: 1px dashed var(--theme-border, #e2ded3);
  font-size: 12px;
  line-height: 1.8;
  color: var(--theme-text-secondary, #67746a);
  letter-spacing: 0.03em;
}

@media (max-width: 900px) {
  .mode-switcher {
    grid-template-columns: 1fr;
  }
  .mode-options {
    grid-row: auto;
  }
}

@media (max-width: 640px) {
  .mode-switcher {
    padding: 22px 20px;
  }
  .mode-options {
    grid-template-columns: 1fr;
  }
}
</style>
