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
  // 如果是小说类型且有 lessonId，尝试获取带假名标注的文本
  if (q.provenance.collection === 'novel' && q.provenance.lessonId) {
    const lesson = novelLessonCache.value.get(q.provenance.lessonId)
    if (lesson && q.provenance.pdfPage != null) {
      const page = lesson.pages?.find(p => p.number === q.provenance.pdfPage)
      if (page?.readingTokens?.length) {
        // 从 readingTokens 构建带假名标注的文本
        // ReadingText.vue 会解析 [漢字:假名] 格式
        return page.readingTokens.map(token => {
          if (token.word && token.reading) {
            return `[${token.word}:${token.reading}]`
          }
          return token.text || ''
        }).join('')
      }
    }
  }
  // 回退：返回原始 passage
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
// 剩余秒数（给 TimeWarning 使用）
const remainingSeconds = computed(() => {
  if (!exam.value?.deadline) return null
  const deadlineMs = Date.parse(exam.value.deadline)
  if (isNaN(deadlineMs)) return null
  const offset = serverOffset.value
  return Math.max(0, Math.ceil((deadlineMs - now.value - offset) / 1000))
})

const wrong = computed(() => (session.value?.answers || []).filter(a => a.isCorrect === false))

// 已答题号列表（1-indexed）
const answeredNums = computed(() => {
  const answers = session.value?.answers || []
  const answeredIds = new Set(answers.map(a => a.questionId))
  return questions.value
    .map((q, i) => ({ id: q.id, num: i + 1 }))
    .filter(q => answeredIds.has(q.id))
    .map(q => q.num)
})

// 未答题号列表
const unansweredNums = computed(() => {
  const answeredSet = new Set(answeredNums.value)
  return questions.value
    .map((_, i) => i + 1)
    .filter(n => !answeredSet.has(n))
})

// 当前题号（1-indexed）
const currentNum = computed(() => (session.value?.currentIndex || 0) + 1)

function optionText(q, id) {
  return q?.options?.find(o => o.id === id)?.content || id || '—'
}

async function load() {
  if (loadingInProgress) return
  loadingInProgress = true
  // A newly started session already contains its questions. Render it while
  // refreshing instead of hiding it behind a second full-page loading state.
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

// 当题目变化时，预加载小说课程数据（用于假名标注）
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
    // Bug-F02/F06 fix: Clear the timer as soon as the deadline passes,
    // regardless of busy state, to prevent repeated deadline checks and
    // any downstream requests from firing indefinitely.
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
  if (audioLocked.value) return // 听力锁定时禁止答题
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

// 提前提交本科目：显示确认弹窗
function requestSubmitSection() {
  showSubmitConfirm.value = true
}

async function confirmSubmit() {
  showSubmitConfirm.value = false
  await act(() => api.section(route.params.id, 'submit'))
}

function cancelSubmit() {
  showSubmitConfirm.value = false
}

// 跳转到指定题号（1-indexed）
async function jumpToQuestion(num) {
  if (audioLocked.value) return // 听力锁定时禁止跳转
  const targetIndex = num - 1
  const currentIndex = session.value?.currentIndex || 0
  if (targetIndex === currentIndex) return

  const steps = targetIndex - currentIndex
  if (steps > 0) {
    // 向前跳转：逐步调用 next
    await act(async () => {
      for (let i = 0; i < steps; i++) {
        try {
          await api.next(route.params.id)
        } catch (e) {
          // 如果中途失败，停止跳转并抛出错误
          throw new Error(`跳转失败：${e.message}`)
        }
      }
    })
  } else {
    // 向后跳转：通过直接设置 currentIndex 实现
    await act(async () => {
      try {
        await api.jump(route.params.id, targetIndex)
      } catch (e) {
        throw new Error(`跳转失败：${e.message}`)
      }
    })
  }
}

// 切换标记
function toggleMark(num) {
  const idx = markedQuestions.value.indexOf(num)
  if (idx >= 0) {
    markedQuestions.value.splice(idx, 1)
  } else {
    markedQuestions.value.push(num)
  }
}

// 听力播放：锁定界面
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
    // 确保 duration 有效再设置 currentTime
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
</script>
<template>
  <div class="session-shell">
    <TimeWarning v-if="exam" :remaining-seconds="remainingSeconds" />

    <div class="session-top">
      <button @click="back" :disabled="audioLocked">← 返回学习页</button>
      <strong>山间书院 · {{ mode === 'practice' ? '练习模式' : '模拟考试' }}</strong>
      <button v-if="session" @click="showAnswered = !showAnswered">
        已答 {{ session.answers?.length || 0 }} 题
      </button>
    </div>

    <div v-if="mode === 'practice'" class="mode-banner">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
        <path d="M12 20h9" />
        <path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z" />
      </svg>
      <span>练习模式 · 答题后立即显示讲解，可随时暂停</span>
    </div>

    <div class="session-body">
      <div v-if="loading" class="state-box">正在读取练习… {{ loadingStep }} / {{ api.requestStage }}</div>
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
              <div class="session-progress">
                <span>{{ session.currentIndex + 1 }} / {{ questions.length }}</span>
                <div><span :style="{ width: `${(session.answers?.length || 0) / questions.length * 100}%` }"></span></div>
              </div>

              <div v-if="exam" class="exam-clock">
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

                <h1>{{ question.content }}</h1>
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

              <div v-else class="options">
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
                  <span>{{ String.fromCharCode(65 + i) }}</span>{{ o.content }}
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

            <aside class="exam-side">
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

    <Transition name="submit-modal">
      <div v-if="showSubmitConfirm" class="submit-modal-backdrop" @click.self="cancelSubmit">
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
  </div>
</template>

<style scoped>
.mode-banner {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 6%;
  background: rgba(37, 99, 235, 0.06);
  border-bottom: 1px solid rgba(37, 99, 235, 0.15);
  color: #2563EB;
  font-size: 12px;
  letter-spacing: 0.03em;
}
.mode-banner svg { flex: none; }

.exam-layout {
  display: grid;
  grid-template-columns: 1fr 280px;
  gap: 32px;
  align-items: start;
}
.exam-side {
  position: sticky;
  top: 110px;
}

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
.audio-pulse {
  animation: audioPulse 1.6s ease-in-out infinite;
}
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

@media (max-width: 900px) {
  .exam-layout {
    grid-template-columns: 1fr;
    gap: 20px;
  }
  .exam-side {
    position: static;
    order: -1;
  }
}
@media (max-width: 640px) {
  .submit-modal { padding: 0; border-radius: 12px; }
  .submit-modal-head,
  .submit-modal-body,
  .submit-modal-foot {
    padding-left: 22px;
    padding-right: 22px;
  }
  .mode-banner {
    padding: 10px 5%;
    font-size: 11px;
  }
}
</style>
