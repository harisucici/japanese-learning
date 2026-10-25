<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { requestResource, useLearningStore } from '../store'

const router = useRouter()
const learning = useLearningStore()
const due = ref([])
const mistakes = ref([])
const loading = ref(true)
const busyId = ref('')
const error = ref('')
const tab = ref('due')
let loadRequestId = 0
const entries = computed(() => tab.value === 'due' ? due.value : mistakes.value)
const labels = { vocabulary: '词汇', kanji: '汉字', grammar: '语法', reading: '阅读', listening: '听力' }

// Count-up animation for stats
const animatedDueCount = ref(0)
const animatedMistakesCount = ref(0)

function animateCount(target, currentValue, updateFn, duration = 500) {
  const startTime = performance.now()
  const startValue = currentValue
  
  function update(currentTime) {
    const elapsed = currentTime - startTime
    const progress = Math.min(elapsed / duration, 1)
    // Ease out cubic for smooth ending
    const easeOut = 1 - Math.pow(1 - progress, 3)
    updateFn(Math.round(startValue + (target - startValue) * easeOut))
    
    if (progress < 1) {
      requestAnimationFrame(update)
    }
  }
  
  requestAnimationFrame(update)
}

watch([() => due.value.length, () => mistakes.value.length], ([newDue, newMistakes]) => {
  animateCount(newDue, animatedDueCount.value, (val) => animatedDueCount.value = val)
  animateCount(newMistakes, animatedMistakesCount.value, (val) => animatedMistakesCount.value = val)
}, { immediate: true })

async function load() {
  const requestId = ++loadRequestId
  loading.value = true
  error.value = ''
  try {
    await learning.ensureGuest()
    const [review, wrong] = await Promise.all([
      requestResource('review/due'),
      learning.request('mistakes', undefined, true)
    ])
    if (requestId !== loadRequestId) return
    due.value = Array.isArray(review) ? review : review.items || []
    mistakes.value = Array.isArray(wrong) ? wrong : (wrong.items || wrong.mistakes || [])
  } catch (e) {
    if (requestId !== loadRequestId) return
    error.value = e.message
  }
  finally {
    if (requestId === loadRequestId) loading.value = false
  }
}

async function retry(item) {
  busyId.value = item.id
  error.value = ''
  try {
    const result = await requestResource(`review/${encodeURIComponent(item.id)}/retry-original`, {})
    await router.push(`/sessions/${encodeURIComponent(result.sessionId)}?mode=practice`)
  } catch (e) { error.value = e.message }
  finally { busyId.value = '' }
}

async function enterReview(item) {
  if (tab.value === 'due') {
    await retry(item)
  } else if (item.sessionId) {
    await router.push(`/sessions/${item.sessionId}?mode=practice`)
  }
}

function formatDate(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  if (isNaN(d.getTime())) return ''
  const now = new Date()
  const diff = now - d
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return '刚刚'
  if (mins < 60) return `${mins} 分钟前`
  const hours = Math.floor(mins / 60)
  if (hours < 24) return `${hours} 小时前`
  const days = Math.floor(hours / 24)
  if (days < 7) return `${days} 天前`
  return d.toLocaleDateString('zh-CN')
}

function getReviewCount(item) {
  return item.reviewCount || item.attempts || 0
}

onMounted(load)
</script>

<template>
  <div class="content-page review-page">
    <!-- 桌面端：保持原有布局 -->
    <div class="desktop-only">
      <div class="section-top"><p class="eyebrow">A LITTLE, EVERY DAY</p><span>你的个人复习清单</span></div>
      <h2>温故，<em>而知新。</em></h2>
      <p class="page-lead">先复习今天到期的内容，再回看做错的题。每次重练都会保存为新的作答记录。</p>
      <div class="review-switch" role="tablist" aria-label="复习分类">
        <button :aria-selected="tab === 'due'" @click="tab = 'due'">今日到期 <span>{{ due.length }}</span></button>
        <button :aria-selected="tab === 'mistakes'" @click="tab = 'mistakes'">错题记录 <span>{{ mistakes.length }}</span></button>
      </div>
      <div v-if="loading" class="state-box">正在整理你的复习内容…</div>
      <div v-else-if="error" class="state-box error" role="alert">{{ error }} <button @click="load">重试</button></div>
      <div v-else-if="!entries.length" class="review-empty">
        <span>〇</span>
        <h3>{{ tab === 'due' ? '今天的复习已完成' : '还没有错题记录' }}</h3>
        <p>继续做题，新的学习记录会出现在这里。</p>
        <RouterLink class="primary-action" to="/practice">开始练习 ↗</RouterLink>
      </div>
      <div v-else class="review-list">
        <article v-for="item in entries" :key="item.id" class="review-item">
          <div class="review-index">{{ (item.question?.level || item.level || 'N').toUpperCase() }}</div>
          <div class="review-copy">
            <small>{{ labels[item.question?.type || item.type] || item.question?.type || item.type || '练习' }} · {{ tab === 'due' ? `已复习 ${item.reviewCount || 0} 次` : new Date(item.answeredAt).toLocaleDateString('zh-CN') }}</small>
            <h3>{{ item.question?.content || '题目暂不可用' }}</h3>
            <p v-if="tab === 'mistakes' && item.explanation?.translation">{{ item.explanation.translation }}</p>
          </div>
          <button v-if="tab === 'due' && item.question" class="secondary-action" :disabled="busyId === item.id" @click="retry(item)">{{ busyId === item.id ? '正在准备…' : '再练一次 ↗' }}</button>
          <RouterLink v-else-if="tab === 'mistakes'" class="secondary-action" :to="`/sessions/${item.sessionId}?mode=practice`">回看作答 ↗</RouterLink>
        </article>
      </div>
    </div>

    <!-- 移动端改造 -->
    <div class="mobile-only">
      <!-- 顶部统计区：今日到期数量 -->
      <div class="mobile-stats">
        <div class="stats-header">
          <p class="stats-eyebrow">今日复习</p>
          <h2 class="stats-title">温故，而知新</h2>
        </div>
        <div class="stats-cards">
          <div class="stat-card due-card">
            <div class="stat-number">{{ animatedDueCount }}</div>
            <div class="stat-label">今日到期</div>
          </div>
          <div class="stat-card mistakes-card">
            <div class="stat-number">{{ animatedMistakesCount }}</div>
            <div class="stat-label">错题记录</div>
          </div>
        </div>
      </div>

      <!-- Tab 切换 -->
      <div class="mobile-tabs">
        <button
          type="button"
          :class="['mobile-tab', { active: tab === 'due' }]"
          @click="tab = 'due'"
          :aria-pressed="tab === 'due'"
        >
          今日到期
          <span class="tab-badge">{{ due.length }}</span>
        </button>
        <button
          type="button"
          :class="['mobile-tab', { active: tab === 'mistakes' }]"
          @click="tab = 'mistakes'"
          :aria-pressed="tab === 'mistakes'"
        >
          错题记录
          <span class="tab-badge">{{ mistakes.length }}</span>
        </button>
      </div>

      <!-- 内容区 -->
      <div class="mobile-body">
        <!-- 骨架屏 -->
        <div v-if="loading" class="mobile-review-skeleton" aria-hidden="true">
          <div class="sk-stats">
            <div v-for="n in 2" :key="n" class="sk-stat-card">
              <div class="skeleton sk-stat-number"></div>
              <div class="skeleton sk-stat-label"></div>
            </div>
          </div>
          <div class="sk-tabs">
            <div v-for="n in 2" :key="n" class="skeleton sk-tab"></div>
          </div>
          <div class="sk-list">
            <div v-for="n in 3" :key="n" class="sk-review-card">
              <div class="sk-card-left">
                <div class="skeleton sk-card-level"></div>
                <div class="skeleton sk-card-type"></div>
              </div>
              <div class="sk-card-center">
                <div class="skeleton sk-question"></div>
                <div class="skeleton sk-meta"></div>
              </div>
              <div class="sk-card-right">
                <div class="skeleton sk-arrow"></div>
              </div>
            </div>
          </div>
        </div>
        <div v-else-if="error" class="state-box error" role="alert">{{ error }} <button @click="load">重试</button></div>
        
        <!-- 空状态 -->
        <div v-else-if="!entries.length" class="mobile-empty">
          <div class="empty-icon">✓</div>
          <h3>{{ tab === 'due' ? '今天已完成复习' : '还没有错题记录' }}</h3>
          <p>{{ tab === 'due' ? '继续保持，明天再来复习吧' : '做题时认真思考，错误会变成成长' }}</p>
          <RouterLink class="empty-action" to="/practice">开始练习 ↗</RouterLink>
        </div>

        <!-- 列表 -->
        <div v-else class="mobile-list">
          <article
            v-for="item in entries"
            :key="item.id"
            class="review-card"
            role="button"
            tabindex="0"
            :aria-label="`进入复习：${item.question?.content || '题目'}`"
            @click="enterReview(item)"
            @keydown.enter.prevent="enterReview(item)"
            @keydown.space.prevent="enterReview(item)"
          >
            <div class="card-left">
              <div class="card-level">{{ (item.question?.level || item.level || 'N').toUpperCase() }}</div>
              <div class="card-type">{{ labels[item.question?.type || item.type] || item.question?.type || item.type || '练习' }}</div>
            </div>
            <div class="card-center">
              <p class="card-question">{{ item.question?.content || '题目暂不可用' }}</p>
              <div class="card-meta">
                <template v-if="tab === 'due'">
                  <span class="meta-item">已复习 {{ getReviewCount(item) }} 次</span>
                </template>
                <template v-else>
                  <span class="meta-item">错 {{ item.wrongCount || 1 }} 次</span>
                  <span class="meta-sep">·</span>
                  <span class="meta-item">{{ formatDate(item.answeredAt) }}</span>
                </template>
              </div>
              <p v-if="tab === 'mistakes' && item.explanation?.translation" class="card-hint">{{ item.explanation.translation }}</p>
            </div>
            <div class="card-right">
              <span class="card-arrow">›</span>
            </div>
          </article>
        </div>
      </div>

      <!-- 底部固定操作栏 -->
      <nav class="mobile-bottombar">
        <RouterLink class="bottom-link" to="/practice">练习</RouterLink>
        <RouterLink class="bottom-link" to="/stats">统计</RouterLink>
        <button
          v-if="tab === 'due' && due.length > 0"
          type="button"
          class="bottom-primary"
          @click="due[0] && enterReview(due[0])"
          :disabled="busyId"
        >
          开始复习 ({{ due.length }})
        </button>
        <RouterLink v-else class="bottom-primary" to="/practice">
          开始练习 ↗
        </RouterLink>
      </nav>
    </div>
  </div>
</template>

<style scoped>
.review-page {
  padding-bottom: 90px;
}

.desktop-only { display: block; }
.mobile-only { display: none; }

/* 桌面端：保留原有样式 */
.review-switch { display: flex; gap: 28px; border-bottom: 1px solid #d7d4c8; margin: 38px 0 28px; }
.review-switch button { border: 0; background: transparent; padding: 13px 2px; color: #758177; cursor: pointer; }
.review-switch button[aria-selected=true] { color: #355247; border-bottom: 2px solid #355247; }
.review-switch span { font-size: 12px; margin-left: 8px; }
.review-empty { text-align: center; background: #fffdf8; padding: 60px 25px; }
.review-empty > span { font: 54px 'Zen Kaku Gothic New', sans-serif; color: #96795c; }
.review-empty h3 { font-size: 23px; }
.review-empty p { font-size: 13px; color: #748074; }
.review-empty .primary-action { margin-top: 20px; }
.review-item { display: flex; align-items: center; gap: 25px; padding: 26px 0; border-bottom: 1px solid #d7d4c8; }
.review-index { width: 58px; height: 58px; flex: none; border: 1px solid #a6b6a6; border-radius: 50%; display: grid; place-items: center; color: #355247; font-size: 13px; }
.review-copy { flex: 1; min-width: 0; }
.review-copy small { color: #9a815f; font-size: 12px; letter-spacing: .08em; }
.review-copy h3 { font: 19px/1.6 'Zen Kaku Gothic New', sans-serif; margin: 9px 0; }
.review-copy p { color: #748074; font-size: 12px; line-height: 1.8; margin: 0; }
.review-item .secondary-action { flex: none; }
@media (max-width: 640px) {
  .review-item { align-items: flex-start; flex-wrap: wrap; }
  .review-index { width: 45px; height: 45px; }
  .review-copy { width: calc(100% - 70px); }
  .review-item .secondary-action { margin-left: 70px; }
}

/* 移动端改造 */
@media (max-width: 768px) {
  .desktop-only { display: none; }
  .mobile-only { display: block; }

  .review-page {
    padding-bottom: 80px;
    background: var(--theme-bg, #f5f2e9);
  }

  /* 顶部统计区 */
  .mobile-stats {
    background: linear-gradient(145deg, #355247 0%, #2a4238 100%);
    color: #fffdf8;
    padding: 20px 16px 24px;
    border-radius: 0 0 20px 20px;
  }
  .stats-header {
    margin-bottom: 16px;
  }
  .stats-eyebrow {
    font-size: 12px;
    letter-spacing: 0.2em;
    color: rgba(255, 253, 248, 0.7);
    margin: 0 0 6px;
    font-weight: 600;
  }
  .stats-title {
    font: 700 22px/1.3 'Zen Kaku Gothic New', sans-serif;
    margin: 0;
    color: #fffdf8;
  }
  .stats-cards {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 10px;
  }
  .stat-card {
    background: rgba(255, 253, 248, 0.12);
    border: 1px solid rgba(255, 253, 248, 0.18);
    border-radius: 12px;
    padding: 14px;
    backdrop-filter: blur(8px);
  }
  .stat-number {
    font: 700 32px/1 'Zen Kaku Gothic New', sans-serif;
    color: #fffdf8;
    font-variant-numeric: tabular-nums;
  }
  .stat-label {
    font-size: 12px;
    color: rgba(255, 253, 248, 0.8);
    margin-top: 6px;
    letter-spacing: 0.04em;
  }

  /* Tab 切换 */
  .mobile-tabs {
    display: flex;
    gap: 4px;
    padding: 12px 16px;
    background: var(--theme-surface, #fffdf8);
    border-bottom: 1px solid var(--theme-border-soft, #e2ded3);
    position: sticky;
    top: 0;
    z-index: 20;
  }
  .mobile-tab {
    flex: 1;
    min-height: 44px;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    background: transparent;
    border: 1px solid var(--theme-border, #d1ccb8);
    border-radius: 10px;
    padding: 10px 14px;
    font-size: 14px;
    font-weight: 500;
    color: var(--theme-text-secondary, #67746a);
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  }
  .mobile-tab:active {
    transform: scale(0.97);
  }
  .mobile-tab.active {
    background: var(--theme-text, #27302b);
    color: var(--theme-surface, #fffdf8);
    border-color: var(--theme-text, #27302b);
    font-weight: 600;
  }
  .tab-badge {
    font-size: 12px;
    padding: 2px 8px;
    border-radius: 10px;
    background: rgba(0, 0, 0, 0.08);
    font-weight: 600;
    font-variant-numeric: tabular-nums;
  }
  .mobile-tab.active .tab-badge {
    background: rgba(255, 253, 248, 0.25);
  }

  /* 内容区 */
  .mobile-body {
    padding: 12px 0;
    min-height: 300px;
  }

  /* 空状态 */
  .mobile-empty {
    text-align: center;
    padding: 60px 24px;
    background: var(--theme-surface, #fffdf8);
    margin: 0 16px;
    border-radius: 14px;
    border: 1px solid var(--theme-border-soft, #e2ded3);
  }
  .empty-icon {
    width: 64px;
    height: 64px;
    margin: 0 auto 16px;
    background: #10b981;
    color: #fff;
    border-radius: 50%;
    display: grid;
    place-items: center;
    font-size: 32px;
    font-weight: 600;
  }
  .mobile-empty h3 {
    font: 700 18px/1.3 'Zen Kaku Gothic New', sans-serif;
    margin: 0 0 8px;
    color: var(--theme-text, #27302b);
  }
  .mobile-empty p {
    font-size: 13px;
    color: var(--theme-text-secondary, #67746a);
    margin: 0 0 20px;
    line-height: 1.6;
  }
  .empty-action {
    display: inline-block;
    min-height: 44px;
    padding: 12px 24px;
    background: var(--color-primary, #2563EB);
    color: #fff;
    text-decoration: none;
    border-radius: 10px;
    font-size: 14px;
    font-weight: 600;
    line-height: 1;
  }

  /* 列表 */
  .mobile-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
    padding: 0 16px;
  }

  /* 复习卡片 */
  .review-card {
    display: flex;
    gap: 12px;
    padding: 14px;
    min-height: 88px;
    background: var(--theme-surface, #fffdf8);
    border: 1px solid var(--theme-border-soft, #e2ded3);
    border-radius: 12px;
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
    touch-action: manipulation;
  }
  .review-card:active {
    transform: scale(0.97);
    box-shadow: 0 4px 12px -6px rgba(0, 0, 0, 0.12);
  }
  .review-card:focus-visible {
    outline: 2px solid var(--color-primary, #2563EB);
    outline-offset: 2px;
  }

  .card-left {
    flex: none;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    min-width: 48px;
  }
  .card-level {
    width: 44px;
    height: 44px;
    border: 1px solid var(--theme-border, #d1ccb8);
    border-radius: 50%;
    display: grid;
    place-items: center;
    color: var(--theme-text, #27302b);
    font: 700 13px/1 'Zen Kaku Gothic New', sans-serif;
    background: var(--theme-surface-alt, #f5f2e9);
  }
  .card-type {
    font-size: 12px;
    color: var(--theme-text-muted, #9a9486);
    letter-spacing: 0.04em;
    text-align: center;
    margin-top: 2px;
  }

  .card-center {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
    gap: 4px;
  }
  .card-question {
    font: 500 15px/1.45 'Zen Kaku Gothic New', sans-serif;
    margin: 0;
    color: var(--theme-text, #27302b);
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
    word-break: break-word;
  }
  .card-meta {
    display: flex;
    align-items: center;
    gap: 6px;
    flex-wrap: wrap;
  }
  .meta-item {
    font-size: 12px;
    color: var(--theme-text-secondary, #67746a);
    font-variant-numeric: tabular-nums;
  }
  .meta-sep {
    color: var(--theme-border, #d1ccb8);
    font-size: 12px;
  }
  .card-hint {
    font-size: 12px;
    color: var(--theme-text-secondary, #67746a);
    margin: 2px 0 0;
    line-height: 1.5;
    display: -webkit-box;
    -webkit-line-clamp: 1;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .card-right {
    flex: none;
    display: grid;
    place-items: center;
    min-width: 24px;
    align-self: center;
  }
  .card-arrow {
    font-size: 28px;
    color: var(--theme-text-muted, #9a9486);
    font-weight: 300;
    line-height: 1;
  }

  /* 底部固定操作栏 */
  .mobile-bottombar {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    height: 56px;
    background: var(--theme-surface, #fffdf8);
    border-top: 1px solid var(--theme-border, #d1ccb8);
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 0 12px;
    padding-bottom: env(safe-area-inset-bottom, 0);
    z-index: 30;
  }
  .bottom-link {
    flex: none;
    min-height: 44px;
    padding: 0 14px;
    display: grid;
    place-items: center;
    background: transparent;
    border: 1px solid var(--theme-border, #d1ccb8);
    border-radius: 10px;
    color: var(--theme-text, #27302b);
    text-decoration: none;
    font-size: 14px;
    font-weight: 500;
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  }
  .bottom-link:active {
    background: var(--theme-surface-alt, #f5f2e9);
    transform: scale(0.97);
  }
  .bottom-primary {
    flex: 1;
    min-height: 44px;
    padding: 0 16px;
    background: var(--color-primary, #2563EB);
    color: #fff;
    border: none;
    border-radius: 10px;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
    text-decoration: none;
    display: grid;
    place-items: center;
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  }
  .bottom-primary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
  .bottom-primary:not(:disabled):active {
    background: #1d4ed8;
    transform: scale(0.97);
  }
}

/* 极小屏 */
@media (max-width: 375px) {
  .stats-title {
    font-size: 20px;
  }
  .stat-number {
    font-size: 28px;
  }
  .card-question {
    font-size: 14px;
  }
}

/* ===== 骨架屏（移动端复习页） ===== */
.mobile-review-skeleton {
  padding: 0 16px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.sk-stats {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}
.sk-stat-card {
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--theme-border-soft, #e2ded3);
  border-radius: 12px;
  padding: 14px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.sk-stat-number {
  width: 50%;
  height: 28px;
  border-radius: 6px;
}
.sk-stat-label {
  width: 70%;
  height: 14px;
}
.sk-tabs {
  display: flex;
  gap: 4px;
  padding: 8px 0;
}
.sk-tab {
  flex: 1;
  height: 44px;
  border-radius: 10px;
}
.sk-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.sk-review-card {
  display: flex;
  gap: 12px;
  padding: 14px;
  min-height: 88px;
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--theme-border-soft, #e2ded3);
  border-radius: 12px;
}
.sk-card-left {
  flex: none;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  min-width: 48px;
}
.sk-card-level {
  width: 44px;
  height: 44px;
  border-radius: 50%;
}
.sk-card-type {
  width: 36px;
  height: 12px;
  border-radius: 3px;
}
.sk-card-center {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
  justify-content: center;
}
.sk-question {
  width: 100%;
  height: 16px;
  border-radius: 4px;
}
.sk-meta {
  width: 60%;
  height: 12px;
  border-radius: 3px;
}
.sk-card-right {
  flex: none;
  display: grid;
  place-items: center;
  min-width: 24px;
  align-self: center;
}
.sk-arrow {
  width: 20px;
  height: 20px;
  border-radius: 50%;
}

/* 交错进入动画 */
@media (max-width: 768px) {
  .review-card {
    opacity: 0;
    transform: translateY(20px);
    animation: fade-up 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  }

  .review-card:nth-child(1) { animation-delay: 0.1s; }
  .review-card:nth-child(2) { animation-delay: 0.15s; }
  .review-card:nth-child(3) { animation-delay: 0.2s; }
  .review-card:nth-child(4) { animation-delay: 0.25s; }
  .review-card:nth-child(5) { animation-delay: 0.3s; }
  .review-card:nth-child(6) { animation-delay: 0.35s; }
  .review-card:nth-child(7) { animation-delay: 0.4s; }
  .review-card:nth-child(8) { animation-delay: 0.45s; }

  @keyframes fade-up {
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
}
</style>
