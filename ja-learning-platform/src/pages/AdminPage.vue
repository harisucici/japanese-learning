<script setup>
import { onMounted, reactive, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { requestResource, useAuthStore } from '../store'

const auth = useAuthStore()
const filters = reactive({ level: '', status: '' })
const items = ref([])
const total = ref(0)
const offset = ref(0)
const selected = ref(null)
const loading = ref(false)
const busy = ref(false)
const error = ref('')
const notice = ref('')
const importText = ref('')
let loadRequestId = 0
function readyForPublish(question) {
  const options = Array.isArray(question.options) ? question.options : []
  const analyses = Array.isArray(question.explanation?.optionAnalysis) ? question.explanation.optionAnalysis : []
  return options.length > 0 && options.some(option => option.id === question.answer)
    && Boolean(question.explanation?.translation && question.explanation?.sentenceStructure)
    && options.every(option => analyses.some(analysis => analysis.optionId === option.id && analysis.reason))
    && (!['official', 'pastExam'].includes(question.source) || Boolean(question.provenance))
}

async function load() {
  if (auth.user?.role !== 'admin') return
  const requestId = ++loadRequestId
  loading.value = true
  error.value = ''
  try {
    const query = new URLSearchParams({ limit: '20', offset: String(offset.value) })
    if (filters.level) query.set('level', filters.level)
    if (filters.status) query.set('status', filters.status)
    const data = await requestResource(`admin/questions?${query}`)
    // 只接受最新请求的结果
    if (requestId !== loadRequestId) return
    items.value = data.items || []
    total.value = data.total || 0
  } catch (e) {
    if (requestId !== loadRequestId) return
    error.value = e.message
  }
  finally {
    if (requestId === loadRequestId) loading.value = false
  }
}

async function inspect(id) {
  error.value = ''
  try { selected.value = await requestResource(`admin/questions/${encodeURIComponent(id)}`) }
  catch (e) { error.value = e.message }
}

async function setPublished(item, publish) {
  busy.value = true
  error.value = ''
  notice.value = ''
  try {
    await requestResource(`admin/questions/${encodeURIComponent(item.id)}/${publish ? 'publish' : 'unpublish'}`, {})
    notice.value = publish ? '题目已发布。' : '题目已撤回。'
    await load()
    if (selected.value?.id === item.id) await inspect(item.id)
  } catch (e) { error.value = e.message }
  finally { busy.value = false }
}

async function importQuestions() {
  busy.value = true
  error.value = ''
  notice.value = ''
  try {
    const parsed = JSON.parse(importText.value)
    const data = await requestResource('admin/import/questions', { items: Array.isArray(parsed) ? parsed : parsed.items })
    notice.value = data.message || '导入完成。'
    importText.value = ''
    await load()
  } catch (e) { error.value = e instanceof SyntaxError ? 'JSON 格式有误，请检查后重试。' : e.message }
  finally { busy.value = false }
}

watch(() => [filters.level, filters.status], () => { offset.value = 0; load() })
onMounted(async () => { await auth.check(); await load() })
</script>

<template>
  <div class="content-page admin-page"><div class="section-top"><p class="eyebrow">CONTENT REVIEW</p><span>仅管理员可访问</span></div>
    <div v-if="auth.loading" class="state-box">正在核对管理权限…</div>
    <div v-else-if="auth.user?.role!=='admin'" class="state-box error">此页面需要管理员账户。<RouterLink to="/account">返回我的账户 ↗</RouterLink></div>
    <template v-else><div v-if="error" class="state-box error" role="alert">{{error}} <button @click="load">重试</button></div><div v-if="notice" class="admin-notice" role="status">{{notice}}</div>
      <div class="admin-toolbar"><div><label>等级<select v-model="filters.level"><option value="">全部等级</option><option v-for="level in ['n5','n4','n3','n2','n1']" :key="level" :value="level">{{level.toUpperCase()}}</option></select></label><label>状态<select v-model="filters.status"><option value="">全部状态</option><option value="draft">草稿</option><option value="published">已发布</option><option value="archived">已归档</option></select></label></div><span>共 {{total}} 道题</span></div>
      <div v-if="loading" class="state-box">正在读取题库…</div><div v-else-if="!items.length" class="state-box">当前筛选下没有题目。</div><div v-else class="admin-list"><article v-for="item in items" :key="item.id" class="admin-row"><div><small>{{item.level?.toUpperCase()}} · {{item.type}} · {{item.source}} · {{item.status}}</small><h3>{{item.content}}</h3><p>ID {{item.id}}</p></div><button class="secondary-action" @click="inspect(item.id)">查看与审核 ↗</button></article></div>
      <div class="admin-pages"><button :disabled="offset===0" @click="offset-=20;load()">← 上一页</button><span>{{offset+1}}–{{Math.min(offset+20,total)}} / {{total}}</span><button :disabled="offset+20>=total" @click="offset+=20;load()">下一页 →</button></div>
      <details class="admin-import"><summary>导入结构化题目</summary><p>粘贴题目数组或含 items 数组的 JSON。导入结果需要人工核对来源、答案和解析，再决定是否发布。</p><textarea v-model="importText" rows="8" spellcheck="false" placeholder='[{"level":"n5","type":"grammar",...}]'></textarea><button class="primary-action" :disabled="busy || !importText.trim()" @click="importQuestions">检查并导入</button></details>
      <div v-if="selected" class="admin-shade" @click.self="selected=null"><section class="admin-detail" role="dialog" aria-modal="true" aria-label="题目审核"><button class="admin-close" aria-label="关闭" @click="selected=null">×</button><p class="eyebrow">QUESTION / {{selected.level?.toUpperCase()}}</p><h2>{{selected.content}}</h2><p class="admin-meta">{{selected.type}} · {{selected.source}} · {{selected.status}}</p><h3>选项与答案</h3><ul><li v-for="option in selected.options || []" :key="option.id" :class="{correct:option.id===selected.answer}">{{option.content}} <span v-if="option.id===selected.answer">✓ 标准答案</span></li></ul><h3>来源与解析</h3><pre>{{JSON.stringify(selected.provenance || {},null,2)}}</pre><p>{{selected.explanation?.translation || '尚无翻译与解析。'}}</p><p v-if="!readyForPublish(selected)" class="admin-warning">答案、来源、句子结构或逐项解析尚未齐全，暂不能发布。</p><button v-if="selected.status==='published'" class="secondary-action" :disabled="busy" @click="setPublished(selected,false)">撤回题目</button><button v-else class="primary-action" :disabled="busy || !readyForPublish(selected)" @click="setPublished(selected,true)">发布题目</button></section></div>
    </template>
  </div>
</template>

<style scoped>
.admin-page{padding-bottom:90px}.admin-toolbar{display:flex;justify-content:space-between;align-items:end;gap:20px;margin:38px 0 18px}.admin-toolbar>div{display:flex;gap:15px}.admin-toolbar label{font-size:11px;color:#6f7b70}.admin-toolbar select{display:block;background:#fffdf8;border:1px solid #d0cec2;padding:10px 14px;color:#355247;margin-top:7px}.admin-toolbar>span,.admin-meta{font-size:12px;color:#748074}.admin-row{display:flex;justify-content:space-between;align-items:center;gap:20px;border-top:1px solid #d7d4c8;padding:24px 0}.admin-row:last-child{border-bottom:1px solid #d7d4c8}.admin-row>div{min-width:0}.admin-row small{color:#9a815f;font-size:11px}.admin-row h3{font:18px/1.6 'Zen Kaku Gothic New',sans-serif;margin:7px 0}.admin-row p{font-size:10px;color:#899188;overflow-wrap:anywhere}.admin-pages{display:flex;align-items:center;justify-content:center;gap:20px;margin:25px}.admin-pages button{border:0;background:none;color:#355247;cursor:pointer}.admin-pages button:disabled{opacity:.3;cursor:default}.admin-pages span{font-size:12px;color:#7c8579}.admin-import{margin-top:55px;background:#fffdf8;padding:25px}.admin-import summary{cursor:pointer;font-size:20px}.admin-import p{font-size:12px;color:#748074;line-height:1.9}.admin-import textarea{display:block;width:100%;resize:vertical;border:1px solid #cac9bd;padding:15px;background:#fdfbf5;margin:20px 0;font:12px/1.6 monospace}.admin-notice{background:#e5eee5;padding:14px 20px;color:#355247}.admin-shade{position:fixed;inset:0;background:#15241dcc;z-index:100;display:flex;justify-content:flex-end}.admin-detail{width:min(560px,100vw);height:100%;overflow:auto;background:#fffdf8;padding:40px}.admin-close{float:right;border:0;background:none;font-size:28px;cursor:pointer}.admin-detail h2{font:26px/1.6 'Zen Kaku Gothic New',sans-serif}.admin-detail h3{font-size:16px;margin-top:30px}.admin-detail li{padding:11px;border-bottom:1px solid #ddd9ce}.admin-detail li.correct{color:#355e45;font-weight:700}.admin-detail li span{font-size:11px;margin-left:8px}.admin-detail pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f4f0e6;padding:16px;font-size:11px}.admin-detail p{line-height:1.8}.admin-warning{color:#a15a4e}.admin-detail .primary-action,.admin-detail .secondary-action{margin-top:25px}@media(max-width:700px){.admin-toolbar,.admin-row{align-items:flex-start;flex-direction:column}.admin-row .secondary-action{margin-top:0}.admin-detail{padding:25px}}
</style>
