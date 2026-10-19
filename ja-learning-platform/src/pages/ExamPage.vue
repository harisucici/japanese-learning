<script setup>
import { computed,onMounted,ref } from 'vue'
import { useRouter } from 'vue-router'
import { useLearningStore } from '../api'
const api=useLearningStore(),router=useRouter()
const data=ref(null),error=ref(''),loading=ref(true),level=ref('n5'),feedback=ref(false),starting=ref('')
async function load(){loading.value=true;error.value='';try{data.value=await api.request('exam-papers')}catch(e){error.value=e.message}finally{loading.value=false}}
onMounted(load)
const papers=computed(()=>(data.value?.papers||[]).filter(x=>x.level===level.value))
async function start(p){starting.value=p.id;error.value='';try{const s=await api.startExam(level.value,p.id,feedback.value);router.push(`/sessions/${s.id}`)}catch(e){error.value=e.message}finally{starting.value=''}}
</script>
<template><div class="content-page"><div class="section-top"><p class="eyebrow">JLPT EXAM PRACTICE</p><span>真题模拟</span></div><h2>把练习，<em>交给时间。</em></h2><p class="page-lead">仅开放已核验完整试卷。科目计时由后端保存，刷新不会重置。</p><div v-if="loading" class="state-box">正在读取试卷…</div><div v-else-if="error" class="state-box error">{{error}} <button @click="load">重试</button></div><template v-if="data"><div class="filters"><button v-for="l in ['n5','n4','n3','n2','n1']" :key="l" :class="{chosen:level===l}" @click="level=l">{{l.toUpperCase()}}</button></div><div class="exam-rules"><strong>官方科目时长</strong><span v-for="r in data.rules?.[level]||[]" :key="r.title">{{r.title}} · {{r.minutes}} 分钟</span><small>有考试年月的历年卷使用对应时期规则；科目之间不结转剩余时间。</small></div><label class="feedback-toggle"><input v-model="feedback" type="checkbox">答错后立即显示答案和讲解 <small>默认关闭，交卷后统一查看。</small></label><div class="item-list"><article v-for="(p,i) in papers" :key="p.id" class="list-row"><span class="item-index">{{String(i+1).padStart(2,'0')}}</span><div><small>{{p.level?.toUpperCase()}} · {{p.examYear||'官方问题集'}}</small><h3>{{p.title}}</h3><p>{{p.verificationNote}}</p></div><button class="primary-action" :disabled="!p.ready||!!starting" @click="start(p)">{{p.ready?(starting===p.id?'正在准备…':'开始考试'):'材料待完整入库'}}</button></article></div><p v-if="!papers.some(p=>p.ready)" class="source-note">当前没有通过完整性校验的整卷。缺少科目、标准答案或听力材料的资料不能开始考试。</p></template></div></template>
