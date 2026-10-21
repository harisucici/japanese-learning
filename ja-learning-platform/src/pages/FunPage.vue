<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter, RouterLink } from 'vue-router'
import { useLearningStore } from '../store'
const api=useLearningStore(), router=useRouter()
const data=ref(null),error=ref(''),loading=ref(true),starting=ref(''),theme=ref('全部')
async function load(){loading.value=true;error.value='';try{data.value=await api.request('fun-papers')}catch(e){error.value=e.message}finally{loading.value=false}}
onMounted(load)
const themes=computed(()=>['全部',...new Set((data.value?.papers||[]).map(x=>x.theme))])
const papers=computed(()=>(data.value?.papers||[]).filter(x=>theme.value==='全部'||x.theme===theme.value))
async function start(id){starting.value=id;error.value='';try{const s=await api.startFun(id);router.push(`/sessions/${s.id}`)}catch(e){error.value=e.message}finally{starting.value=''}}
</script>
<template><div class="content-page"><div class="section-top"><p class="eyebrow">LEARN BY PLAYING</p><span>{{data?.papers?.length || 0}} 组</span></div><h2>趣味闯关，<em>从原文出发。</em></h2><p class="page-lead">答对自动前进；答错查看讲解后继续。首次作答保存在后端。</p><div v-if="loading" class="state-box">正在读取题组…</div><div v-else-if="error" class="state-box error">{{error}} <button @click="load">重新加载</button></div><template v-if="data"><div class="source-note">{{data.label}}</div><div class="filters"><button v-for="t in themes" :key="t" :class="{chosen:theme===t}" @click="theme=t">{{t}}</button></div><div class="activity-grid"><article v-for="p in papers" :key="p.id" class="activity-card"><small>{{p.theme}}</small><h3>{{p.title}}</h3><p>{{p.description}}</p><div class="activity-meta">{{p.questionCount}} 题 · {{p.ready?'可以开始':'题组尚未完整入库'}}</div><div class="activity-actions"><button class="primary-action" :disabled="!p.ready||!!starting" @click="start(p.id)">{{starting===p.id?'正在准备…':'开始闯关 ↗'}}</button><RouterLink v-if="p.reading_lesson_id" :to="`/novel/${p.reading_lesson_id}`" class="secondary-action">先读原文</RouterLink><RouterLink v-else-if="p.material_ids?.length" :to="`/materials/${p.material_ids[0]}`" class="secondary-action">先读原文</RouterLink></div></article></div><p v-if="!papers.length" class="empty">当前主题暂无题组。</p></template></div></template>
