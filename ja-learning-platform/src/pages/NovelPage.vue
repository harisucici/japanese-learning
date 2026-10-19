<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useLearningStore } from '../api'
const api = useLearningStore()
const data = ref(null), error = ref(''), loading = ref(true), query = ref(''), category = ref('全部')
async function load() { loading.value = true; error.value = ''; try { data.value = await api.request('novel-lessons') } catch (e) { error.value = e.message } finally { loading.value = false } }
onMounted(load)
const categories = computed(() => ['全部', ...new Set((data.value?.lessons || []).map(x => x.category))])
const lessons = computed(() => (data.value?.lessons || []).filter(x => (category.value === '全部' || x.category === category.value) && x.title.includes(query.value.trim())))
</script>
<template><div class="content-page"><div class="section-top"><p class="eyebrow">STORIES FROM THE LIBRARY</p><span>{{data?.lessons?.length || 0}} 篇</span></div><h2>看故事，<em>记住词语。</em></h2><p class="page-lead">按原文分章阅读，查看词卡与假名注释，再进入配套练习。</p><div v-if="loading" class="state-box">正在读取章节…</div><div v-else-if="error" class="state-box error">{{error}} <button @click="load">重试</button></div><template v-else><div class="source-note">来源：{{data.sourceTitle}} · {{data.sourcePages}} 页 · 原作者：{{data.attribution}}<br>资料标题中的等级为原作者标注；配套练习不是 JLPT 官方真题。</div><div class="controls"><input v-model="query" type="search" placeholder="搜索小说标题" aria-label="搜索小说标题"><div class="filters"><button v-for="c in categories" :key="c" :class="{chosen:category===c}" @click="category=c">{{c}}</button></div></div><div class="item-list"><RouterLink v-for="(item,i) in lessons" :key="item.id" :to="`/novel/${item.id}`" class="list-row"><span class="item-index">{{String(i+1).padStart(2,'0')}}</span><div><small>{{item.category}} · 第 {{item.startPage}}–{{item.endPage}} 页</small><h3>{{item.title}}</h3><p>{{item.questionCount}} 道练习 · {{item.vocabularyCount}} 个原文词卡</p></div><span class="row-action">阅读与练习 ↗</span></RouterLink><p v-if="!lessons.length" class="empty">没有找到对应篇目。</p></div></template></div></template>
