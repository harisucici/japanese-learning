<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useLearningStore } from '../api'
const api = useLearningStore(), data = ref(null), error = ref(''), loading = ref(true), query = ref(''), collection = ref('全部'), visibleCount = ref(24)
async function load() { loading.value = true; error.value = ''; try { data.value = await api.request('materials') } catch (e) { error.value = e.message } finally { loading.value = false } }
onMounted(load)
const collections = computed(() => ['全部', ...new Set((data.value?.items || []).map(x => x.collection))])
const items = computed(() => (data.value?.items || []).filter(x => (collection.value === '全部' || x.collection === collection.value) && x.title.toLowerCase().includes(query.value.trim().toLowerCase())))
const visibleItems = computed(() => items.value.slice(0, visibleCount.value))
watch([query, collection], () => { visibleCount.value = 24 })
</script>
<template>
  <div class="content-page">
    <div class="section-top"><p class="eyebrow">THE READING LIBRARY</p><span>{{ data?.total || 0 }} 篇文章</span></div>
    <h2>在素材里，<em>遇见新知。</em></h2>
    <p class="page-lead">从一篇文章开始，跟着声音读日语。</p>
    <div v-if="loading" class="state-box">正在读取文章…</div>
    <div v-else-if="error" class="state-box error">{{ error }} <button @click="load">重试</button></div>
    <template v-else>
      <div class="source-note">{{ data.total }} 篇文章 · {{ data.audioCount }} 篇配有音频</div>
      <div class="controls"><input v-model="query" type="search" placeholder="搜索文章标题" aria-label="搜索文章"><div class="filters"><button v-for="c in collections" :key="c" :class="{ chosen: collection === c }" @click="collection = c">{{ c }}</button></div></div>
      <p class="result-count">当前显示 {{ items.length }} 篇</p>
      <div class="item-list"><RouterLink v-for="(m, i) in visibleItems" :key="m.id" :to="`/materials/${m.id}`" class="list-row"><span class="item-index">{{ String(i + 1).padStart(2, '0') }}</span><div><small>{{ m.collection }} · {{ m.audios?.length ? '配套音频' : '暂无音频' }}</small><h3>{{ m.title }}</h3><p>{{ m.hasText ? '阅读原文与听读' : '正文待整理 · 可先听读' }}</p></div><span class="row-action">进入 ↗</span></RouterLink><p v-if="!items.length" class="empty">没有找到对应文章。</p></div>
      <button v-if="visibleCount < items.length" class="load-more" @click="visibleCount += 24">加载更多 · 已显示 {{ visibleItems.length }} / {{ items.length }} ↘</button>
    </template>
  </div>
</template>
