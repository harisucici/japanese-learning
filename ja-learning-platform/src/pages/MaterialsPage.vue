<script setup>
import { computed,onMounted,ref,watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useLearningStore } from '../api'
const api=useLearningStore(),data=ref(null),error=ref(''),loading=ref(true),query=ref(''),collection=ref('全部'),visibleCount=ref(24)
async function load(){loading.value=true;error.value='';try{data.value=await api.request('materials')}catch(e){error.value=e.message}finally{loading.value=false}}
onMounted(load)
const collections=computed(()=>['全部',...new Set((data.value?.items||[]).map(x=>x.collection))])
const items=computed(()=>(data.value?.items||[]).filter(x=>(collection.value==='全部'||x.collection===collection.value)&&`${x.title} ${x.filename}`.toLowerCase().includes(query.value.trim().toLowerCase())))
const visibleItems=computed(()=>items.value.slice(0,visibleCount.value))
watch([query,collection],()=>{visibleCount.value=24})
</script>
<template><div class="content-page"><div class="section-top"><p class="eyebrow">THE READING LIBRARY</p><span>{{data?.total||0}} 份素材</span></div><h2>在素材里，<em>遇见新知。</em></h2><p class="page-lead">查找原始资料，阅读正文与译文，播放配套音视频。</p><div v-if="loading" class="state-box">正在读取素材…</div><div v-else-if="error" class="state-box error">{{error}} <button @click="load">重试</button></div><template v-else><div class="source-note">{{data.total}} 份原始 PDF · {{data.audioCount}} 份配套音频 · {{data.videoCount}} 份视频</div><div class="controls"><input v-model="query" type="search" placeholder="搜索标题或原文件名" aria-label="搜索素材"><div class="filters"><button v-for="c in collections" :key="c" :class="{chosen:collection===c}" @click="collection=c">{{c}}</button></div></div><p class="result-count">当前显示 {{items.length}} 份</p><div class="item-list"><RouterLink v-for="(m,i) in visibleItems" :key="m.id" :to="`/materials/${m.id}`" class="list-row"><span class="item-index">{{String(i+1).padStart(2,'0')}}</span><div><small>{{m.collection}} · {{m.pages}} 页 {{m.audioUrl?'· 音频':''}} {{m.videoUrl?'· 视频':''}}</small><h3>{{m.title}}</h3><p>{{m.filename}} · {{m.textStatus==='text_extracted'?'已提取原文':m.textStatus==='scan_only'?'扫描原件':'可查看原件'}}</p></div><span class="row-action">阅读 ↗</span></RouterLink><p v-if="!items.length" class="empty">没有找到对应素材。</p></div><button v-if="visibleCount<items.length" class="load-more" @click="visibleCount+=24">加载更多 · 已显示 {{visibleItems.length}} / {{items.length}} ↘</button></template></div></template>
