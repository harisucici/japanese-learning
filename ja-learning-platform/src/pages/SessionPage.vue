<script setup>
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { assetUrl, useLearningStore } from '../store'
import AnswerCard from '../components/AnswerCard.vue'
import TimeWarning from '../components/TimeWarning.vue'
import ReadingText from '../components/ReadingText.vue'

const route = useRoute()
const router = useRouter()
const api = useLearningStore()

// 模式（exam 严格计时 / practice 可暂停）
const mode = computed(() => route.query.mode === 'practice' ? 'practice' : 'exam')

// 状态
const loading = ref(true)
const loadingStep = ref('准备请求')
const error = ref('')
const busy = ref(false)
const now = ref(Date.now())
const showAnswered = ref(false)
const serverOffset = ref(0)
const examAudio = ref(null)
const audioPlaying = ref(false)
const audioLocked = ref(false) // 听力播放时锁定界面
const audioError = ref('')
const blankAnswer = ref('')

// 小说课程缓存（用于渲染假名标注）
const novelLessonCache = ref(new Map())

// 标记题号（用户可标记需要回看的题）
const markedQuestions = ref([])

// 交卷确认弹窗
const showSubmitConfirm = ref(false)

// 移动端答题卡抽屉
const mobileAnswerSheetOpen = ref(false)

let timer = null
let loadingInProgress = false

// 计算属性
const session = computed(() => api.session?.id === route.params.id ? api.session : null)
const questions = computed(() => session.value?.questions || [])
const question = computed(() => questions.value[session.value?.currentIndex || 0])

// 当前题目的原文段落（带假名标注）
const questionPassageText = computed(() => {
  const q = question.value
  if (!q?.provenance || q.provenance.kind !== 'user_material') return ''
  if (q.provenance.collection === 'novel' && q.provenance.lessonId) {
    const lesson = novelLessonCache.value.get(q.provenance.lessonId)
    if (lesson && q.provenance.pdfPage != null) {
      const page = lesson.pages?.find(p => p.number === q.provenance.pdfPage)
      if (page?.readingTokens?.length) {
        return page.readingTokens.map(token => {
          if (token.word && token.reading) {
            return `[${token.word}:${token.reading}]`
          }
          return token.text || ''
        }).join('')
      }
    }
  }
  return q.provenance.passage || ''
})
const answer = computed(() => (session.value?.answers || []).find(a => a.questionId === question.value?.id))
const exam = computed(() => session.value?.examConfig)
const section = computed(() => exam.value?.sections?.[exam.value.sectionIndex])
const remaining = computed(() => {
  if (!exam.value?.deadline) return '—'
  const deadlineMs = Date.parse(exam.value.deadline)
  if (isNaN(deadlineMs)) return '—'
  const offset = serverOffset.value
  const seconds = Math.max(0, Math.ceil((deadlineMs - now.value - offset) / 1000))
  return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`
})
const remainingSeconds = computed(() => {
  if (!exam.value?.deadline) return null
  const deadlineMs = Date.parse(exam.value.deadline)
  if (isNaN(deadlineMs)) return null
  const offset = serverOffset.value
  return Math.max(0, Math.ceil((deadlineMs - now.value - offset) / 1000))
})

const wrong = computed(() => (session.value?.answers || []).filter(a => a.isCorrect === false))

const answeredNums = computed(() => {
  const answers = session.value?.answers || []
  const answeredIds = new Set(answers.map(a => a.questionId))
  return questions.value
    .map((q, i) => ({ id: q.id, num: i + 1 }))
    .filter(q => answeredIds.has(q.id))
    .map(q => q.num)
})

const unansweredNums = computed(() => {
  const answeredSet = new Set(answeredNums.value)
  return questions.value
    .map((_, i) => i + 1)
    .filter(n => !answeredSet.has(n))
})

const currentNum = computed(() => (session.value?.currentIndex || 0) + 1)

const isCurrentMarked = computed(() => markedQuestions.value.includes(currentNum.value))

// 答题统计（用于交卷抽屉）
const submitStats = computed(() => ({
  total: questions.value.length,
  answered: answeredNums.value.length,
  unanswered: unansweredNums.value.length,
  marked: markedQuestions.value.length
}))

function optionText(q, id) {
  return q?.options?.find(o => o.id === id)?.content || id || '—'
}

async function load() {
  if (loadingInProgress) return
  loadingInProgress = true
  loading.value = !session.value?.questions?.length
  error.value = ''
  loadingStep.value = '请求练习数据'
  try {
    await api.loadSession(route.params.id)
    loadingStep.value = '处理题目'
    const serverNowMs = Date.parse(api.session.serverNow)
    if (!isNaN(serverNowMs)) {
      serverOffset.value = serverNowMs - Date.now()
    } else {
      serverOffset.value = 0
    }
  } catch (e) {
    error.value = e.name === 'TimeoutError' ? '读取超时，请重试。' : e.message
  } finally {
    loading.value = false
    loadingInProgress = false
  }
}

watch(question, async (q) => {
  if (!q?.provenance || q.provenance.kind !== 'user_material') return
  if (q.provenance.collection !== 'novel' || !q.provenance.lessonId) return
  if (novelLessonCache.value.has(q.provenance.lessonId)) return
  try {
    const lesson = await api.request(`novel-lessons/${encodeURIComponent(q.provenance.lessonId)}`)
    novelLessonCache.value.set(q.provenance.lessonId, lesson)
  } catch (e) {
    console.warn('Failed to load novel lesson for furigana:', e)
  }
}, { immediate: true })

onMounted(() => {
  load()
  if (timer) clearInterval(timer)
  timer = setInterval(() => {
    now.value = Date.now()
    if (timer && exam.value?.deadline) {
      const deadlineMs = Date.parse(exam.value.deadline)
      if (!isNaN(deadlineMs) && deadlineMs <= now.value + serverOffset.value) {
        clearInterval(timer)
        timer = null
        if (session.value && !session.value.completedAt) {
          session.value.completedAt = new Date().toISOString()
        }
      }
    }
  }, 1000)
})

onUnmounted(() => {
  if (timer) {
    clearInterval(timer)
    timer = null
  }
})
watch(() => route.params.id, (newId, oldId) => {
  if (newId && newId !== oldId) load()
})

async function act(fn) {
  busy.value = true
  error.value = ''
  try {
    await fn()
  } catch (e) {
    error.value = e.message
    await api.loadSession(route.params.id).catch(() => {})
  } finally {
    busy.value = false
  }
}

function choose(optionId) {
  if (!question.value || answer.value) return
  if (audioLocked.value) return
  act(() => api.answer(route.params.id, question.value.id, optionId))
}

function submitBlank() {
  const value = blankAnswer.value.trim()
  if (!value || !question.value || answer.value) return
  if (audioLocked.value) return
  act(async () => {
    await api.answer(route.params.id, question.value.id, value)
    blankAnswer.value = ''
  })
}

function requestSubmitSection() {
  showSubmitConfirm.value = true
}

async function confirmSubmit() {
  showSubmitConfirm.value = false
  mobileAnswerSheetOpen.value = false
  await act(() => api.section(route.params.id, 'submit'))
}

function cancelSubmit() {
  showSubmitConfirm.value = false
}

async function jumpToQuestion(num) {
  if (audioLocked.value) return
  const targetIndex = num - 1
  const currentIndex = session.value?.currentIndex || 0
  if (targetIndex === currentIndex) {
    mobileAnswerSheetOpen.value = false
    return
  }

  const steps = targetIndex - currentIndex
  if (steps > 0) {
    await act(async () => {
      for (let i = 0; i < steps; i++) {
        try {
          await api.next(route.params.id)
        } catch (e) {
          throw new Error(`跳转失败：${e.message}`)
        }
      }
    })
  } else {
    await act(async () => {
      try {
        await api.jump(route.params.id, targetIndex)
      } catch (e) {
        throw new Error(`跳转失败：${e.message}`)
      }
    })
  }
  mobileAnswerSheetOpen.value = false
}

function toggleMark(num) {
  const idx = markedQuestions.value.indexOf(num)
  if (idx >= 0) {
    markedQuestions.value.splice(idx, 1)
  } else {
    markedQuestions.value.push(num)
  }
}

function toggleCurrentMark() {
  toggleMark(currentNum.value)
}

function openAnswerSheet() {
  mobileAnswerSheetOpen.value = true
}
function closeAnswerSheet() {
  mobileAnswerSheetOpen.value = false
}

async function prevQuestion() {
  if (audioLocked.value || currentNum.value <= 1) return
  await jumpToQuestion(currentNum.value - 1)
}
async function nextQuestion() {
  if (audioLocked.value || currentNum.value >= questions.value.length) return
  await act(() => api.next(route.params.id))
}

async function playExamAudio() {
  try {
    const audio = examAudio.value
    if (!audio) return
    const elapsed = Math.max(0, (now.value + serverOffset.value - Date.parse(exam.value.sectionStartedAt)) / 1000)
    if (audio.readyState < 1) {
      await new Promise((resolve, reject) => {
        const cleanup = () => {
          audio.removeEventListener('loadedmetadata', resolve)
          audio.removeEventListener('error', reject)
        }
        const onLoaded = () => { cleanup(); resolve() }
        const onError = () => { cleanup(); reject(new Error('Audio load failed')) }
        audio.addEventListener('loadedmetadata', onLoaded, { once: true })
        audio.addEventListener('error', onError, { once: true })
      })
    }
    if (audio.duration && isFinite(audio.duration)) {
      audio.currentTime = Math.min(elapsed, Math.max(0, audio.duration - 0.1))
    } else {
      audio.currentTime = Math.max(0, elapsed)
    }
    await audio.play()
    audioPlaying.value = true
    audioLocked.value = true
    audioError.value = ''
  } catch {
    audioError.value = '浏览器需要点击后才能播放，或音频暂不可用。计时仍在继续。'
  }
}

function onAudioEnded() {
  audioPlaying.value = false
  audioLocked.value = false
}

function back() {
  if (audioLocked.value) return
  router.push(session.value?.mode === 'fun' ? '/fun' : '/mock-exam')
}

const isQuestionActive = computed(() => {
  return session.value && !session.value.completedAt && !exam.value?.waitingSection && question.value
})
</script>
<template>
  <div class="session-shell" :class="{ 'is-active-session': isQuestionActive }">
    <TimeWarning v-if="exam" :remaining-seconds="remainingSeconds" />

    <!-- 桌面端顶栏 -->
    <div class="session-top desk-top">
      <button @click="back" :disabled="audioLocked">← 返回学习页</button>
      <strong>山间书院 · {{ mode === 'practice' ? '练习模式' : '模拟考试' }}</strong>
      <button v-if="session" @click="showAnswered = !showAnswered">
        已答 {{ session.answers?.length || 0 }} 题
      </button>
    </div>

    <!-- 移动端顶栏：返回 / 题号 / 计时 / 标记 -->
    <header v-if="isQuestionActive" class="mob-top">
      <button class="mob-top-btn mob-back" @click="back" :disabled="audioLocked || busy" aria-label="返回">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M19 12H5M12 19l-7-7 7-7" />
        </svg>
      </button>
      <div class="mob-top-center">
        <span class="mob-qnum">{{ currentNum }} / {{ questions.length }}</span>
        <span class="mob-timer" :class="{ warn: remainingSeconds != null && remainingSeconds < 60 }">
          {{ remaining }}
        </span>
      </div>
      <button
        class="mob-top-btn mob-mark-btn"
        :class="{ marked: isCurrentMarked }"
        @click="toggleCurrentMark"
        :disabled="audioLocked || busy"
        :aria-label="isCurrentMarked ? '取消标记' : '标记本题'"
      >
        <svg width="18" height="18" viewBox="0 0 24 24" :fill="isCurrentMarked ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="2">
          <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
        </svg>
      </button>
    </header>

    <div v-if="mode === 'practice'" class="mode-banner">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
        <path d="M12 20h9" />
        <path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z" />
      </svg>
      <span>练习模式 · 答题后立即显示讲解，可随时暂停</span>
    </div>

    <div class="session-body">
      <!-- 骨架屏 -->
      <div v-if="loading" class="mob-skeleton-shell">
        <div class="mob-skeleton-question">
          <div class="mob-sk-q-meta">
            <div class="mob-sk-pill shimmer"></div>
            <div class="mob-sk-pill timer shimmer"></div>
          </div>
          <div class="mob-sk-q-text">
            <div class="mob-sk-line shimmer"></div>
            <div class="mob-sk-line long shimmer"></div>
            <div class="mob-sk-line medium shimmer"></div>
          </div>
          <div class="mob-sk-options">
            <div v-for="n in 4" :key="n" class="mob-sk-option shimmer">
              <div class="mob-sk-opt-letter"></div>
              <div class="mob-sk-opt-text">
                <div class="mob-sk-opt-line shimmer"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div v-else-if="error && !session" class="state-box error">
        {{ error }} <button @click="load">重试</button>
      </div>

      <template v-else-if="session">
        <div v-if="error" class="state-box error">{{ error }}</div>

        <template v-if="session.completedAt">
          <p class="eyebrow">SESSION COMPLETED</p>
          <h1>练习已完成</h1>
          <div class="score-panel">
            <strong>{{ session.score }}<small> / 100 分</small></strong>
            <p>答对 {{ session.correctCount }} / {{ session.totalQuestions }} 题 · 答错 {{ wrong.length }} 题</p>
            <p>
              总分由后端根据首次作答计算并保存。
              {{ session.mode === 'exam' ? '此分数是练习正确率，不是 JLPT 官方量尺成绩。' : '' }}
            </p>
          </div>
          <h2>{{ wrong.length ? '本次错题回顾' : '本次全部答对' }}</h2>
          <article v-for="a in wrong" :key="a.questionId" class="answer-review">
            <h3>{{ questions.find(q => q.id === a.questionId)?.content }}</h3>
            <p>你的答案：{{ optionText(questions.find(q => q.id === a.questionId), a.selectedOptionId) }}</p>
            <p>正确答案：{{ optionText(questions.find(q => q.id === a.questionId), a.correctOptionId) }}</p>
            <p>{{ a.explanation?.sentenceStructure || '该题暂未收录讲解' }}</p>
          </article>
          <button class="primary-action" @click="back">返回学习页</button>
        </template>

        <template v-else-if="exam?.waitingSection">
          <p class="eyebrow">SECTION COMPLETED</p>
          <h1>本科目已交卷</h1>
          <p>下一科：{{ exam.sections?.[exam.sectionIndex + 1]?.title }} · {{ exam.sections?.[exam.sectionIndex + 1]?.minutes }} 分钟</p>
          <button class="primary-action" :disabled="busy" @click="act(() => api.section(route.params.id, 'start'))">
            开始下一科 ↗
          </button>
        </template>

        <template v-else-if="question">
          <div class="exam-layout">
            <main class="exam-main">
              <!-- 桌面端进度条 -->
              <div class="session-progress desk-only">
                <span>{{ session.currentIndex + 1 }} / {{ questions.length }}</span>
                <div><span :style="{ width: `${(session.answers?.length || 0) / questions.length * 100}%` }"></span></div>
              </div>

              <!-- 桌面端时钟 -->
              <div v-if="exam" class="exam-clock desk-only">
                <strong>{{ section?.title }}</strong>
                <span>剩余 {{ remaining }}</span>
                <button :disabled="busy || audioLocked" @click="requestSubmitSection">
                  提前提交本科目
                </button>
                <p>
                  {{ mode === 'practice'
                    ? '练习模式：每题作答后立即显示讲解。'
                    : (exam.instantFeedback ? '错题立即讲解已开启；查看讲解仍计时。' : '严格计时；交卷后统一查看答案和讲解。') }}
                </p>

                <div v-if="section?.audioUrl || question.audioUrl" class="exam-audio">
                  <audio
                    ref="examAudio"
                    :src="assetUrl(section?.audioUrl || question.audioUrl)"
                    @ended="onAudioEnded"
                  ></audio>
                  <button v-if="!audioPlaying" type="button" @click="playExamAudio">
                    开始听力（从当前考试时间恢复）
                  </button>
                  <span v-else class="audio-playing">
                    <svg class="audio-pulse" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" />
                      <path d="M19 10v2a7 7 0 0 1-14 0v-2M12 19v4M8 23h8" />
                    </svg>
                    听力播放中 · 界面已锁定
                  </span>
                  <small v-if="audioError">{{ audioError }}</small>
                  <small v-if="audioLocked && !audioError" class="audio-lock-hint">
                    听力播放期间禁止跳转、交卷或离开页面，播放结束后自动解锁。
                  </small>
                </div>
              </div>

              <!-- 移动端听力区 -->
              <div v-if="(section?.audioUrl || question.audioUrl) && !audioPlaying" class="mob-audio-block mob-only">
                <audio
                  ref="examAudio"
                  :src="assetUrl(section?.audioUrl || question.audioUrl)"
                  @ended="onAudioEnded"
                ></audio>
                <button type="button" class="mob-audio-play" @click="playExamAudio">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor">
                    <polygon points="6 3 20 12 6 21 6 3" />
                  </svg>
                  开始听力
                </button>
                <small v-if="audioError" class="mob-audio-error">{{ audioError }}</small>
              </div>
              <div v-else-if="audioPlaying" class="mob-audio-playing mob-only">
                <svg class="audio-pulse" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" />
                  <path d="M19 10v2a7 7 0 0 1-14 0v-2M12 19v4M8 23h8" />
                </svg>
                听力播放中 · 界面已锁定
              </div>

              <article class="question-panel">
                <small>
                  {{ question.level === 'ungraded' ? '素材练习' : question.level?.toUpperCase() }} · {{ question.type }}
                </small>

                <div v-if="audioLocked" class="audio-lock-banner">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                    <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                  </svg>
                  <span>听力播放中，界面已锁定</span>
                </div>

                <ReadingText
                  v-if="questionPassageText"
                  :text="questionPassageText"
                  :title="`原文线索：${question.provenance.title}`"
                  :collapsible="true"
                  :default-open="question.provenance?.collection !== 'novel'"
                  :no-copy="true"
                />

                <h1 class="mob-question-text">{{ question.content }}</h1>
                <p v-if="question.provenance" class="source-caption">
                  {{ question.provenance.kind === 'user_material' ? '素材改编 · 非官方真题' : '官方问题集' }}
                  {{ question.provenance.sourcePage ? ` · 原文第 ${question.provenance.sourcePage} 页` : '' }}
                </p>
              </article>

              <form
                v-if="question.type === 'fillInBlank' && !question.options?.length"
                class="blank-answer"
                @submit.prevent="submitBlank"
              >
                <label for="blank-answer">填写原 PDF 回忆版中的空缺</label>
                <input
                  id="blank-answer"
                  v-model="blankAnswer"
                  :disabled="busy || !!answer || audioLocked"
                  autocomplete="off"
                  maxlength="100"
                />
                <button
                  class="primary-action"
                  :disabled="busy || !!answer || !blankAnswer.trim() || audioLocked"
                  type="submit"
                >提交答案</button>
              </form>

              <div v-else class="options mob-options">
                <button
                  v-for="(o, i) in question.options || []"
                  :key="o.id"
                  :class="{
                    correct: answer?.correctOptionId === o.id,
                    wrong: answer?.selectedOptionId === o.id && answer?.isCorrect === false,
                    selected: answer?.selectedOptionId === o.id
                  }"
                  :disabled="busy || !!answer || audioLocked"
                  @click="choose(o.id)"
                >
                  <span class="opt-letter">{{ String.fromCharCode(65 + i) }}</span>
                  <span class="opt-text">{{ o.content }}</span>
                </button>
              </div>

              <div v-if="session.awaitingNext && answer" class="answer-review">
                <strong>{{ answer.isCorrect ? '回答正确' : '回答错误 · 本题已锁定' }}</strong>
                <p>你的答案：{{ optionText(question, answer.selectedOptionId) }}</p>
                <p>正确答案：{{ optionText(question, answer.correctOptionId) }}</p>
                <p>{{ answer.explanation?.sentenceStructure || '该题暂未收录讲解' }}</p>
                <small v-if="answer.explanation?.note">{{ answer.explanation.note }}</small>
                <button
                  class="primary-action"
                  :disabled="busy"
                  @click="act(() => api.next(route.params.id))"
                >{{ session.currentIndex + 1 === questions.length ? '查看总分' : '下一题' }} ↗</button>
              </div>
            </main>

            <!-- 桌面端侧边答题卡 -->
            <aside class="exam-side desk-only">
              <AnswerCard
                :total="questions.length"
                :answered="answeredNums"
                :marked="markedQuestions"
                :current="currentNum"
                :section-title="section?.title"
                :section-index="exam?.sectionIndex"
                :section-total="exam?.sections?.length"
                @jump="jumpToQuestion"
                @toggle-mark="toggleMark"
              />
              <button class="desk-submit-btn" :disabled="busy || audioLocked" @click="requestSubmitSection">
                提前交卷
              </button>
            </aside>
          </div>
        </template>

        <div v-if="showAnswered" class="answered-drawer">
          <button @click="showAnswered = false">关闭 ×</button>
          <h2>已答记录</h2>
          <p>首次答案已锁定，仅可回看。</p>
          <article v-for="a in session.answers || []" :key="a.questionId">
            <strong>{{ questions.find(q => q.id === a.questionId)?.content }}</strong>
            <p>你的答案：{{ optionText(questions.find(q => q.id === a.questionId), a.selectedOptionId) }}</p>
            <p v-if="a.isCorrect !== undefined">
              {{ a.isCorrect ? '回答正确' : '回答错误' }} · {{ a.explanation?.sentenceStructure }}
            </p>
          </article>
        </div>
      </template>
    </div>

    <!-- 移动端底部操作栏 -->
    <div v-if="isQuestionActive" class="mob-bottom-bar">
      <button
        class="mob-bottom-btn"
        :disabled="currentNum <= 1 || busy || audioLocked"
        @click="prevQuestion"
        aria-label="上一题"
      >
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M15 18l-6-6 6-6" />
        </svg>
        上一题
      </button>
      <button
        class="mob-bottom-btn mob-sheet-btn"
        @click="openAnswerSheet"
        aria-label="答题卡"
      >
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="3" y="3" width="7" height="7" />
          <rect x="14" y="3" width="7" height="7" />
          <rect x="3" y="14" width="7" height="7" />
          <rect x="14" y="14" width="7" height="7" />
        </svg>
        答题卡
      </button>
      <button
        class="mob-bottom-btn"
        :disabled="currentNum >= questions.length || busy || audioLocked"
        @click="nextQuestion"
        aria-label="下一题"
      >
        下一题
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M9 18l6-6-6-6" />
        </svg>
      </button>
    </div>

    <!-- 移动端答题卡抽屉 -->
    <Transition name="sheet">
      <div v-if="mobileAnswerSheetOpen" class="mob-sheet-backdrop mob-only" @click.self="closeAnswerSheet">
        <div class="mob-sheet" role="dialog" aria-label="答题卡">
          <div class="mob-sheet-handle" @click="closeAnswerSheet"></div>
          <header class="mob-sheet-head">
            <div>
              <p class="eyebrow">ANSWER SHEET</p>
              <h3>{{ section?.title || '答题卡' }}</h3>
            </div>
            <button class="mob-sheet-close" @click="closeAnswerSheet" aria-label="关闭">×</button>
          </header>
          <div class="mob-sheet-stats">
            <span class="mob-stat"><em class="dot answered"></em>已答 {{ submitStats.answered }}</span>
            <span class="mob-stat"><em class="dot marked"></em>标记 {{ submitStats.marked }}</span>
            <span class="mob-stat"><em class="dot unanswered"></em>未答 {{ submitStats.unanswered }}</span>
          </div>
          <div class="mob-sheet-grid">
            <button
              v-for="n in questions.length"
              :key="n"
              :class="[
                'mob-sheet-item',
                {
                  current: n === currentNum,
                  answered: answeredNums.includes(n) && n !== currentNum,
                  marked: markedQuestions.includes(n) && !answeredNums.includes(n)
                }
              ]"
              @click="jumpToQuestion(n)"
            >
              {{ n }}
              <span v-if="markedQuestions.includes(n) && !answeredNums.includes(n)" class="mob-sheet-mark">★</span>
            </button>
          </div>
          <footer class="mob-sheet-foot">
            <button class="mob-sheet-submit" :disabled="busy || audioLocked" @click="requestSubmitSection">
              交卷
            </button>
          </footer>
        </div>
      </div>
    </Transition>

    <!-- 桌面端居中模态框 -->
    <Transition name="submit-modal">
      <div v-if="showSubmitConfirm" class="submit-modal-backdrop desk-only" @click.self="cancelSubmit">
        <div class="submit-modal" role="dialog" aria-label="确认交卷">
          <header class="submit-modal-head">
            <div>
              <p class="eyebrow">SUBMIT CONFIRM</p>
              <h2>确认提交本科目？</h2>
            </div>
            <button class="submit-modal-close" type="button" @click="cancelSubmit">×</button>
          </header>

          <div class="submit-modal-body">
            <p class="submit-warning">提交后不能返回本科目，未答题按错误计分。</p>

            <div class="submit-stats-row">
              <span>已答 <strong>{{ submitStats.answered }}</strong></span>
              <span>未答 <strong>{{ submitStats.unanswered }}</strong></span>
              <span>标记 <strong>{{ submitStats.marked }}</strong></span>
            </div>

            <div v-if="unansweredNums.length > 0" class="unanswered-block">
              <p class="unanswered-label">
                您还有 <strong>{{ unansweredNums.length }}</strong> 道题未作答：
              </p>
              <div class="unanswered-grid">
                <span v-for="num in unansweredNums" :key="num" class="unanswered-chip">
                  第 {{ num }} 题
                </span>
              </div>
            </div>

            <div v-else class="all-answered">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                <polyline points="22 4 12 14.01 9 11.01" />
              </svg>
              <span>所有题目均已作答，可以提交。</span>
            </div>
          </div>

          <footer class="submit-modal-foot">
            <button class="secondary-action" @click="cancelSubmit">继续答题</button>
            <button class="primary-action primary-action-danger" @click="confirmSubmit">
              确认提交
            </button>
          </footer>
        </div>
      </div>
    </Transition>

    <!-- 移动端交卷底部抽屉 -->
    <Transition name="sheet">
      <div v-if="showSubmitConfirm" class="mob-sheet-backdrop mob-only" @click.self="cancelSubmit">
        <div class="mob-sheet mob-submit-sheet" role="dialog" aria-label="确认交卷">
          <div class="mob-sheet-handle" @click="cancelSubmit"></div>
          <header class="mob-sheet-head">
            <div>
              <p class="eyebrow">SUBMIT</p>
              <h3>确认提交本科目？</h3>
            </div>
            <button class="mob-sheet-close" @click="cancelSubmit" aria-label="关闭">×</button>
          </header>
          <div class="mob-submit-body">
            <p class="submit-warning">提交后不能返回本科目，未答题按错误计分。</p>
            <div class="submit-stats-row">
              <span>已答 <strong>{{ submitStats.answered }}</strong></span>
              <span>未答 <strong>{{ submitStats.unanswered }}</strong></span>
              <span>标记 <strong>{{ submitStats.marked }}</strong></span>
            </div>
            <div v-if="unansweredNums.length > 0" class="unanswered-block">
              <p class="unanswered-label">还有 <strong>{{ unansweredNums.length }}</strong> 题未答</p>
              <div class="unanswered-grid">
                <span v-for="num in unansweredNums.slice(0, 20)" :key="num" class="unanswered-chip">
                  {{ num }}
                </span>
                <span v-if="unansweredNums.length > 20" class="unanswered-chip">…</span>
              </div>
            </div>
            <div v-else class="all-answered">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                <polyline points="22 4 12 14.01 9 11.01" />
              </svg>
              <span>所有题目均已作答</span>
            </div>
          </div>
          <footer class="mob-sheet-foot">
            <button class="mob-cancel-btn" @click="cancelSubmit">继续答题</button>
            <button class="mob-confirm-btn" @click="confirmSubmit">确认交卷</button>
          </footer>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
/* ===== 通用工具 ===== */
.desk-only { }
.mob-only { display: none; }

/* ===== 顶栏 ===== */
.session-top.desk-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 18px 6%;
}

.mob-top {
  position: sticky;
  top: 0;
  z-index: 20;
  height: 56px;
  background: var(--theme-surface, #fffdf8);
  border-bottom: 1px solid var(--theme-border, #e2ded3);
  display: none;
  align-items: center;
  padding: 0 12px;
  gap: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}
.mob-top-btn {
  width: 44px;
  height: 44px;
  border: none;
  background: transparent;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: var(--theme-text, #27302b);
  border-radius: 10px;
  transition: background 0.15s;
}
.mob-top-btn:active:not(:disabled) {
  background: color-mix(in srgb, var(--theme-text, #27302b) 8%, transparent);
}
.mob-top-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}
.mob-top-center {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  min-width: 0;
}
.mob-qnum {
  font: 500 13px/1 'Zen Kaku Gothic New', sans-serif;
  color: var(--theme-text-secondary, #67746a);
  letter-spacing: 0.05em;
}
.mob-timer {
  font: 500 18px/1 'Zen Kaku Gothic New', sans-serif;
  color: var(--theme-text, #27302b);
  letter-spacing: 0.06em;
  font-variant-numeric: tabular-nums;
  font-weight: 500;
}
.mob-timer.warn {
  color: #dc2626;
}
.mob-mark-btn.marked {
  color: #f59e0b;
}

/* ===== 答题布局 ===== */
.session-shell.is-active-session .session-body {
  padding-bottom: 0;
}

.exam-layout {
  display: grid;
  grid-template-columns: 1fr 280px;
  gap: 32px;
  align-items: start;
}
.exam-side {
  position: sticky;
  top: 110px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.desk-submit-btn {
  height: 44px;
  border: 1px solid #dc2626;
  background: transparent;
  color: #dc2626;
  border-radius: 8px;
  font: 500 13px 'Zen Kaku Gothic New', sans-serif;
  letter-spacing: 0.06em;
  cursor: pointer;
  transition: all 0.2s;
}
.desk-submit-btn:hover:not(:disabled) {
  background: #dc2626;
  color: #fff;
}
.desk-submit-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

/* 题目文字在桌面端保持原样 */
.question-panel h1 {
  font: 500 20px/1.6 'Zen Kaku Gothic New', sans-serif;
  margin: 14px 0;
}

/* 选项在桌面端保持原样 */
.options button {
  display: flex;
  align-items: center;
  gap: 14px;
}

/* ===== 移动端听力区 ===== */
.mob-audio-block {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  padding: 20px;
  margin: 16px;
  background: color-mix(in srgb, #2563EB 6%, transparent);
  border: 1px solid color-mix(in srgb, #2563EB 20%, transparent);
  border-radius: 12px;
}
.mob-audio-play {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 24px;
  background: #2563EB;
  color: #fff;
  border: none;
  border-radius: 28px;
  font: 500 15px 'Zen Kaku Gothic New', sans-serif;
  letter-spacing: 0.04em;
  cursor: pointer;
  min-height: 48px;
}
.mob-audio-play:active {
  filter: brightness(0.92);
}
.mob-audio-error {
  color: #c2410c;
  font-size: 12px;
  text-align: center;
}
.mob-audio-playing {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 14px;
  margin: 16px;
  background: color-mix(in srgb, #2563EB 8%, transparent);
  border-radius: 10px;
  color: #2563EB;
  font-size: 13px;
  letter-spacing: 0.03em;
}

/* ===== 移动端底部操作栏 ===== */
.mob-bottom-bar {
  display: none;
}

/* ===== 移动端答题卡/交卷抽屉 ===== */
.mob-sheet-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(20, 32, 28, 0.45);
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
  z-index: 100;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}
.mob-sheet {
  background: var(--theme-surface, #fffdf8);
  color: var(--theme-text, #27302b);
  width: 100%;
  max-width: 640px;
  max-height: 75vh;
  border-radius: 20px 20px 0 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  box-shadow: 0 -10px 40px rgba(0, 0, 0, 0.15);
}
.mob-sheet-handle {
  width: 40px;
  height: 4px;
  background: var(--theme-border, #d1ccb8);
  border-radius: 2px;
  margin: 10px auto 4px;
  cursor: pointer;
}
.mob-sheet-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 12px 20px 14px;
  border-bottom: 1px solid var(--theme-border, #e2ded3);
}
.mob-sheet-head h3 {
  font: 500 17px 'Zen Kaku Gothic New', sans-serif;
  letter-spacing: 0.04em;
  margin: 4px 0 0;
}
.mob-sheet-close {
  width: 36px;
  height: 36px;
  border: none;
  background: transparent;
  font-size: 26px;
  cursor: pointer;
  color: inherit;
  opacity: 0.6;
  line-height: 1;
}
.mob-sheet-close:active { opacity: 1; }

.mob-sheet-stats {
  display: flex;
  gap: 14px;
  padding: 12px 20px;
  border-bottom: 1px solid var(--theme-border, #e2ded3);
  font-size: 12px;
  color: var(--theme-text-secondary, #67746a);
}
.mob-stat {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.mob-stat .dot {
  display: inline-block;
  width: 10px;
  height: 10px;
  border-radius: 3px;
}
.mob-stat .dot.answered { background: #10b981; }
.mob-stat .dot.marked { background: #f59e0b; }
.mob-stat .dot.unanswered { background: #d1ccb8; }

.mob-sheet-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(44px, 1fr));
  gap: 12px;
  padding: 16px 20px;
  margin: 20px 0;
  overflow-y: auto;
  flex: 1;
}
.mob-sheet-item {
  position: relative;
  width: 44px;
  height: 44px;
  aspect-ratio: unset;
  border: 1px solid var(--theme-border, #d1ccb8);
  background: var(--theme-surface-alt, #f5f2e9);
  color: var(--theme-text-secondary, #8a9389);
  border-radius: 12px;
  font: 500 16px/1 'Zen Kaku Gothic New', sans-serif;
  cursor: pointer;
  transition: transform 0.2s var(--spring-ease), background 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
}
.mob-sheet-item:active {
  transform: scale(0.9);
}
.mob-sheet-item.current {
  background: #2563EB;
  color: #fff;
  border-color: #2563EB;
  box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.18);
  font-weight: 600;
}
.mob-sheet-item.answered {
  background: #10b981;
  color: #fff;
  border-color: #10b981;
}
.mob-sheet-item.marked {
  background: #f59e0b;
  color: #fff;
  border-color: #f59e0b;
}
.mob-sheet-mark {
  position: absolute;
  top: -4px;
  right: -2px;
  font-size: 12px;
  line-height: 1;
}

.mob-sheet-foot {
  padding: 12px 20px calc(12px + env(safe-area-inset-bottom, 0));
  border-top: 1px solid var(--theme-border, #e2ded3);
  background: var(--theme-surface-alt, #f8f6ee);
}
.mob-sheet-submit {
  display: block;
  width: 100%;
  height: 52px;
  border: none;
  border-radius: 12px;
  background: #dc2626;
  color: #fff;
  font: 600 16px 'Zen Kaku Gothic New', sans-serif;
  letter-spacing: 0.08em;
  cursor: pointer;
  transition: filter 0.15s;
}
.mob-sheet-submit:hover:not(:disabled) {
  filter: brightness(1.08);
}
.mob-sheet-submit:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* 移动端交卷确认抽屉内的内容 */
.mob-submit-body {
  padding: 14px 20px;
  overflow-y: auto;
  flex: 1;
}
.submit-stats-row {
  display: flex;
  justify-content: space-around;
  gap: 10px;
  padding: 12px;
  background: var(--theme-surface-alt, #f8f6ee);
  border-radius: 10px;
  margin-bottom: 14px;
  font-size: 13px;
  color: var(--theme-text-secondary, #67746a);
}
.submit-stats-row strong {
  color: var(--theme-text, #27302b);
  font-size: 18px;
  margin-left: 4px;
  font-variant-numeric: tabular-nums;
}
.mob-cancel-btn,
.mob-confirm-btn {
  flex: 1;
  height: 48px;
  border-radius: 10px;
  font: 500 15px 'Zen Kaku Gothic New', sans-serif;
  cursor: pointer;
  letter-spacing: 0.04em;
}
.mob-cancel-btn {
  border: 1px solid var(--theme-border, #d1ccb8);
  background: transparent;
  color: var(--theme-text, #27302b);
}
.mob-confirm-btn {
  border: none;
  background: #dc2626;
  color: #fff;
  font-weight: 600;
}
.mob-sheet-foot {
  display: flex;
  gap: 10px;
}

/* Sheet 动画 */
.sheet-enter-active,
.sheet-leave-active {
  transition: opacity 0.25s ease;
}
.sheet-enter-active .mob-sheet,
.sheet-leave-active .mob-sheet {
  transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}
.sheet-enter-from,
.sheet-leave-to { opacity: 0; }
.sheet-enter-from .mob-sheet,
.sheet-leave-to .mob-sheet {
  transform: translateY(100%);
}
:root[data-reduce-motion="true"] .sheet-enter-active,
:root[data-reduce-motion="true"] .sheet-leave-active,
:root[data-reduce-motion="true"] .sheet-enter-active .mob-sheet,
:root[data-reduce-motion="true"] .sheet-leave-active .mob-sheet {
  transition: none;
}

/* ===== 桌面端模态框样式（保留） ===== */
.audio-lock-banner {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 14px;
  background: rgba(37, 99, 235, 0.08);
  border: 1px solid rgba(37, 99, 235, 0.2);
  border-radius: 8px;
  margin-bottom: 16px;
  color: #2563EB;
  font-size: 12px;
  letter-spacing: 0.03em;
}
.audio-lock-banner svg { flex: none; }
.audio-playing {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: #2563EB;
  font-weight: 500;
}
.audio-pulse { animation: audioPulse 1.6s ease-in-out infinite; }
@keyframes audioPulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.4; }
}
.audio-lock-hint {
  width: 100%;
  color: #2563EB;
  font-style: italic;
}
:root[data-reduce-motion="true"] .audio-pulse { animation: none; }

.submit-modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(20, 32, 28, 0.4);
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}
.submit-modal {
  background: var(--theme-surface, #fffdf8);
  color: var(--theme-text, #27302b);
  border-radius: 16px;
  width: min(520px, 100%);
  max-height: 80vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 30px 60px -20px rgba(0, 0, 0, 0.3);
  border: 1px solid var(--theme-border, rgba(0, 0, 0, 0.08));
}
.submit-modal-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 28px 32px 20px;
  border-bottom: 1px solid var(--theme-border, #d9d4c3);
}
.submit-modal-head h2 {
  font: 500 20px 'Zen Kaku Gothic New', sans-serif;
  letter-spacing: 0.06em;
  margin: 6px 0 0;
}
.submit-modal-close {
  width: 32px;
  height: 32px;
  border: 0;
  background: transparent;
  cursor: pointer;
  font-size: 22px;
  opacity: 0.6;
  color: inherit;
}
.submit-modal-close:hover { opacity: 1; }
.submit-modal-body {
  padding: 24px 32px;
  overflow-y: auto;
  flex: 1;
}
.submit-warning {
  font-size: 13px;
  color: #c2410c;
  background: rgba(245, 158, 11, 0.08);
  border: 1px solid rgba(245, 158, 11, 0.2);
  padding: 12px 16px;
  border-radius: 8px;
  margin: 0 0 20px;
  line-height: 1.6;
}
.unanswered-block { margin-top: 16px; }
.unanswered-label {
  font-size: 13px;
  color: var(--theme-text-secondary, #67746a);
  margin: 0 0 12px;
}
.unanswered-label strong {
  color: #c2410c;
  font-weight: 600;
}
.unanswered-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.unanswered-chip {
  padding: 6px 12px;
  background: rgba(239, 68, 68, 0.08);
  border: 1px solid rgba(239, 68, 68, 0.25);
  border-radius: 6px;
  font-size: 12px;
  color: #991b1b;
  letter-spacing: 0.02em;
}
.all-answered {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 16px 20px;
  background: rgba(16, 185, 129, 0.08);
  border: 1px solid rgba(16, 185, 129, 0.25);
  border-radius: 8px;
  color: #065f46;
  font-size: 13px;
  margin-top: 16px;
}
.submit-modal-foot {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 18px 32px;
  border-top: 1px solid var(--theme-border, #d9d4c3);
  background: var(--theme-surface-alt, #f8f6ee);
}
.primary-action-danger {
  background: #dc2626 !important;
  border-color: #dc2626 !important;
  color: #fff !important;
}
.primary-action-danger:hover {
  background: #b91c1c !important;
}
.submit-modal-enter-active,
.submit-modal-leave-active {
  transition: opacity 0.22s ease;
}
.submit-modal-enter-active .submit-modal,
.submit-modal-leave-active .submit-modal {
  transition: transform 0.22s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.22s;
}
.submit-modal-enter-from,
.submit-modal-leave-to { opacity: 0; }
.submit-modal-enter-from .submit-modal,
.submit-modal-leave-to .submit-modal {
  transform: translateY(12px) scale(0.98);
  opacity: 0;
}
:root[data-reduce-motion="true"] .submit-modal-enter-active,
:root[data-reduce-motion="true"] .submit-modal-leave-active,
:root[data-reduce-motion="true"] .submit-modal-enter-active .submit-modal,
:root[data-reduce-motion="true"] .submit-modal-leave-active .submit-modal {
  transition: none;
}

/* =========================================================
   移动端核心布局（< 768px）
   ========================================================= */
@media (max-width: 768px) {
  :root {
    --spring-ease: cubic-bezier(0.34, 1.56, 0.64, 1);
    --spring-duration: 200ms;
  }

  .desk-only { display: none !important; }
  .mob-only { display: unset; }
  .mob-sheet-backdrop.mob-only { display: flex; }
  .mob-audio-block.mob-only,
  .mob-audio-playing.mob-only { display: flex; }
  .mob-top {
    display: flex;
    padding: calc(env(safe-area-inset-top, 0px) + 10px) 4% 10px;
    min-height: 56px;
  }

  /* 顶部栏按钮 Spring 过渡 + :active 缩放 */
  .mob-top-btn {
    min-width: 44px;
    min-height: 44px;
    padding: 0 16px;
    border-radius: 22px;
    transition: all 0.3s var(--spring-ease);
  }
  .mob-top-btn:active:not(:disabled) {
    transform: scale(0.97);
    background: color-mix(in srgb, var(--theme-text, #27302b) 8%, transparent);
  }

  .mob-bottom-bar {
    display: flex;
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    height: 56px;
    background: var(--theme-surface, #fffdf8);
    border-top: 1px solid var(--theme-border, #e2ded3);
    z-index: 15;
    padding: 12px 4% calc(env(safe-area-inset-bottom, 0px) + 12px);
    gap: 12px;
    align-items: center;
    box-shadow: 0 -2px 8px rgba(0, 0, 0, 0.04);
  }
  .mob-bottom-btn {
    flex: 1;
    min-height: 48px;
    padding: 0 24px;
    border: none;
    background: transparent;
    color: var(--theme-text, #27302b);
    font: 500 15px/1 'Zen Kaku Gothic New', sans-serif;
    letter-spacing: 0.02em;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 4px;
    border-radius: 24px;
    transition: transform 0.3s var(--spring-ease);
  }
  .mob-bottom-btn:active:not(:disabled) {
    transform: scale(0.97);
    background: color-mix(in srgb, var(--theme-text, #27302b) 8%, transparent);
  }
  .mob-bottom-btn:disabled {
    opacity: 0.35;
    cursor: not-allowed;
  }
  .mob-sheet-btn {
    background: color-mix(in srgb, var(--season-accent, #57718c) 10%, transparent);
    color: var(--season-accent, #57718c);
    font-weight: 600;
  }

  /* 答题内容区留出底部栏空间 */
  .session-shell.is-active-session .session-body {
    padding-bottom: 68px;
  }

  /* 题目区域 */
  .question-container,
  .question-area,
  .question-panel {
    padding: 24px 0 32px;
  }

  /* 题目文字 */
  .question-text,
  .question-stem,
  .mob-question-text {
    font-size: 18px !important;
    line-height: 1.7 !important;
    margin-bottom: 32px !important;
  }

  .exam-layout {
    display: block;
    padding: 0 16px;
  }
  .exam-main {
    padding-top: 8px;
  }

  /* 选项大按钮 */
  .mob-options,
  .options,
  .answer-option {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  .mob-options button,
  .option-btn,
  .answer-option {
    display: flex !important;
    align-items: center;
    gap: 14px !important;
    min-height: 56px;
    padding: 16px 20px !important;
    border: 1.5px solid var(--theme-border, #d1ccb8) !important;
    background: var(--theme-surface, #fffdf8) !important;
    border-radius: 16px !important;
    margin-bottom: 0;
    text-align: left !important;
    cursor: pointer !important;
    font: 500 16px/1.5 'Zen Kaku Gothic New', sans-serif !important;
    color: var(--theme-text, #27302b) !important;
    transition: transform 0.3s var(--spring-ease), border-color 0.3s, background 0.3s !important;
  }
  .mob-options button:active:not(:disabled),
  .option-btn:active:not(:disabled),
  .answer-option:active:not(:disabled) {
    transform: scale(0.97);
  }
  .mob-options button.selected,
  .option-btn.selected,
  .answer-option.selected {
    border-width: 2px !important;
    border-color: #2563EB !important;
    background: color-mix(in srgb, #2563EB 8%, transparent) !important;
    transform: scale(0.98);
  }
  .mob-options button.correct {
    border-color: #10b981 !important;
    background: color-mix(in srgb, #10b981 10%, transparent) !important;
  }
  .mob-options button.wrong {
    border-color: #ef4444 !important;
    background: color-mix(in srgb, #ef4444 10%, transparent) !important;
  }
  .opt-letter {
    width: 28px;
    height: 28px;
    border-radius: 50%;
    background: color-mix(in srgb, var(--theme-text, #27302b) 8%, transparent);
    color: var(--theme-text, #27302b);
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 600;
    font-size: 13px;
    flex-shrink: 0;
  }
  .mob-options button.selected .opt-letter {
    background: #2563EB;
    color: #fff;
  }
  .opt-text {
    flex: 1;
    min-width: 0;
    word-break: break-word;
  }

  .blank-answer input {
    min-height: 48px;
    font-size: 16px;
    padding: 12px 14px;
    border-radius: 10px;
  }
  .blank-answer button {
    width: 100%;
    min-height: 48px;
  }

  .question-panel small {
    font-size: 12px;
    color: var(--theme-text-secondary, #67746a);
  }
  .source-caption {
    font-size: 12px;
    color: var(--theme-text-secondary, #8a9389);
    font-style: italic;
  }

  /* 骨架屏样式 */
  .mob-skeleton-shell {
    padding: 16px;
  }
  .mob-skeleton-question {
    display: flex;
    flex-direction: column;
    gap: 20px;
  }
  .mob-sk-q-meta {
    display: flex;
    gap: 12px;
    margin-bottom: 16px;
  }
  .mob-sk-pill {
    height: 20px;
    border-radius: 10px;
    width: 80px;
  }
  .mob-sk-pill.timer {
    width: 100px;
  }
  .mob-sk-q-text {
    display: flex;
    flex-direction: column;
    gap: 12px;
    margin-bottom: 24px;
  }
  .mob-sk-line {
    height: 18px;
    border-radius: 6px;
    width: 100%;
  }
  .mob-sk-line.long {
    width: 90%;
  }
  .mob-sk-line.medium {
    width: 70%;
  }
  .mob-sk-options {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  .mob-sk-option {
    display: flex;
    align-items: center;
    gap: 14px;
    padding: 14px 18px;
    border-radius: 12px;
    min-height: 52px;
  }
  .mob-sk-opt-letter {
    width: 28px;
    height: 28px;
    border-radius: 50%;
    background: rgba(0, 0, 0, 0.08);
    flex-shrink: 0;
  }
  .mob-sk-opt-text {
    flex: 1;
    height: 16px;
    border-radius: 6px;
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

  /* 答题卡抽屉 Spring 动画 */
  .sheet-enter-active .mob-sheet,
  .sheet-leave-active .mob-sheet {
    transition: transform 300ms var(--spring-ease), opacity 200ms ease;
  }
  .sheet-enter-from .mob-sheet,
  .sheet-leave-to .mob-sheet {
    transform: translateY(100%);
    opacity: 0;
  }
  .sheet-enter-active,
  .sheet-leave-active {
    transition: opacity 300ms ease;
  }
  .sheet-enter-from,
  .sheet-leave-to {
    opacity: 0;
  }

  /* 答题卡项目 :active 缩放 */
  .mob-sheet-item:active {
    transform: scale(0.94);
    transition: transform var(--spring-duration) var(--spring-ease);
  }
}

/* =========================================================
   平板（768 - 900）：保留原布局
   ========================================================= */
@media (min-width: 768px) and (max-width: 900px) {
  .exam-layout {
    grid-template-columns: 1fr;
    gap: 20px;
  }
  .exam-side {
    position: static;
    order: -1;
  }
}

/* =========================================================
   移动端（< 900px）其他调整
   ========================================================= */
@media (max-width: 900px) {
  .mode-banner {
    padding: 10px 5%;
    font-size: 12px;
  }
}
</style>
