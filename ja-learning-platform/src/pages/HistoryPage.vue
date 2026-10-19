<script setup>
import { onMounted,ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useLearningStore } from '../api'
const api=useLearningStore(),data=ref(null),error=ref(''),loading=ref(true)
async function load(){loading.value=true;error.value='';try{data.value=await api.request('dashboard',undefined,true)}catch(e){error.value=e.message}finally{loading.value=false}}
onMounted(load)
const format=(value)=>value?new Date(value).toLocaleString('zh-CN'):'—'
</script>
<template><div class="content-page"><div class="section-top"><p class="eyebrow">YOUR LEARNING RECORD</p><span>后端保存</span></div><h2>回望来路，<em>继续前行。</em></h2><p class="page-lead">作答记录与成绩来自后端数据库。当前浏览器通过 Cookie 关联服务端学习记录。</p><div v-if="loading" class="state-box">正在读取学习记录…</div><div v-if="error" class="state-box error">{{error}} <button @click="load">重试</button></div><template v-if="data"><div class="stats-grid"><div><strong>{{data.totalAnswered}}</strong><span>已答题数</span></div><div><strong>{{data.accuracy==null?'—':`${(data.accuracy*100).toFixed(1)}%`}}</strong><span>正确率</span></div><div><strong>{{data.completedSessions}}</strong><span>完成练习</span></div><div><strong>{{data.wrongCount}}</strong><span>答错次数</span></div></div><h3 class="subhead">学习记录</h3><div class="item-list"><RouterLink v-for="s in data.sessions||[]" :key="s.id" :to="`/sessions/${s.id}`" class="list-row"><span class="item-index">{{s.mode==='exam'?'試':'學'}}</span><div><small>{{format(s.createdAt)}} · {{s.completedAt?'已完成':'进行中'}}</small><h3>{{s.mode==='fun'?(s.activityTitle||'素材练习'):s.level?.toUpperCase()+' 模拟考试'}}</h3><p>已答 {{s.answeredCount}} / {{s.totalQuestions}} 题</p></div><span class="row-action">{{s.completedAt?`${s.score} 分`:'继续 ↗'}}</span></RouterLink><p v-if="!data.sessions?.length" class="empty">还没有练习记录。完成一次练习后，这里会显示真实成绩。</p></div></template></div></template>
