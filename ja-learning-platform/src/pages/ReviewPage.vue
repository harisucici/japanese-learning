<script setup>
import { computed, onMounted, ref } from 'vue'
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
    // 只接受最新请求的结果
    if (requestId !== loadRequestId) return
    due.value = Array.isArray(review) ? review : review.items || []
    // Bug-F12: 确保 mistakes 数据格式正确
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

onMounted(load)
</script>

<template>
  <div class="content-page review-page"><div class="section-top"><p class="eyebrow">A LITTLE, EVERY DAY</p><span>你的个人复习清单</span></div><h2>温故，<em>而知新。</em></h2><p class="page-lead">先复习今天到期的内容，再回看做错的题。每次重练都会保存为新的作答记录。</p>
    <div class="review-switch" role="tablist" aria-label="复习分类"><button :aria-selected="tab==='due'" @click="tab='due'">今日到期 <span>{{due.length}}</span></button><button :aria-selected="tab==='mistakes'" @click="tab='mistakes'">错题记录 <span>{{mistakes.length}}</span></button></div>
    <div v-if="loading" class="state-box">正在整理你的复习内容…</div><div v-else-if="error" class="state-box error" role="alert">{{error}} <button @click="load">重试</button></div>
    <div v-else-if="!entries.length" class="review-empty"><span>〇</span><h3>{{tab==='due'?'今天的复习已完成':'还没有错题记录'}}</h3><p>继续做题，新的学习记录会出现在这里。</p><RouterLink class="primary-action" to="/practice">开始练习 ↗</RouterLink></div>
    <div v-else class="review-list"><article v-for="item in entries" :key="item.id" class="review-item"><div class="review-index">{{(item.question?.level || item.level || 'N').toUpperCase()}}</div><div class="review-copy"><small>{{labels[item.question?.type || item.type] || item.question?.type || item.type || '练习'}} · {{tab==='due' ? `已复习 ${item.reviewCount || 0} 次` : new Date(item.answeredAt).toLocaleDateString('zh-CN')}}</small><h3>{{item.question?.content || '题目暂不可用'}}</h3><p v-if="tab==='mistakes' && item.explanation?.translation">{{item.explanation.translation}}</p></div><button v-if="tab==='due' && item.question" class="secondary-action" :disabled="busyId===item.id" @click="retry(item)">{{busyId===item.id?'正在准备…':'再练一次 ↗'}}</button><RouterLink v-else-if="tab==='mistakes'" class="secondary-action" :to="`/sessions/${item.sessionId}?mode=practice`">回看作答 ↗</RouterLink></article></div>
  </div>
</template>

<style scoped>
.review-page{padding-bottom:90px}.review-switch{display:flex;gap:28px;border-bottom:1px solid #d7d4c8;margin:38px 0 28px}.review-switch button{border:0;background:transparent;padding:13px 2px;color:#758177;cursor:pointer}.review-switch button[aria-selected=true]{color:#355247;border-bottom:2px solid #355247}.review-switch span{font-size:11px;margin-left:8px}.review-empty{text-align:center;background:#fffdf8;padding:60px 25px}.review-empty>span{font:54px 'Zen Kaku Gothic New',sans-serif;color:#96795c}.review-empty h3{font-size:23px}.review-empty p{font-size:13px;color:#748074}.review-empty .primary-action{margin-top:20px}.review-item{display:flex;align-items:center;gap:25px;padding:26px 0;border-bottom:1px solid #d7d4c8}.review-index{width:58px;height:58px;flex:none;border:1px solid #a6b6a6;border-radius:50%;display:grid;place-items:center;color:#355247;font-size:13px}.review-copy{flex:1;min-width:0}.review-copy small{color:#9a815f;font-size:11px;letter-spacing:.08em}.review-copy h3{font:19px/1.6 'Zen Kaku Gothic New',sans-serif;margin:9px 0}.review-copy p{color:#748074;font-size:12px;line-height:1.8;margin:0}.review-item .secondary-action{flex:none}@media(max-width:640px){.review-item{align-items:flex-start;flex-wrap:wrap}.review-index{width:45px;height:45px}.review-copy{width:calc(100% - 70px)}.review-item .secondary-action{margin-left:70px}}
</style>
