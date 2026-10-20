<script setup>
import { onMounted, ref, watch } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import { assetUrl, useLearningStore } from '../store'
const route = useRoute(), api = useLearningStore(), item = ref(null), error = ref(''), loading = ref(true)
async function load() { loading.value = true; error.value = ''; try { item.value = await api.request(`materials/${encodeURIComponent(route.params.id)}`) } catch (e) { error.value = e.message } finally { loading.value = false } }
onMounted(load); watch(() => route.params.id, load)
</script>
<template>
  <div class="content-page detail-page">
    <RouterLink class="back-dark" to="/materials">← 返回素材阅读馆</RouterLink>
    <div v-if="loading" class="state-box">正在读取文章…</div>
    <div v-else-if="error" class="state-box error">{{ error }} <button @click="load">重试</button></div>
    <template v-else>
      <div class="section-top"><p class="eyebrow">LIBRARY / {{ item.collection }}</p><span>{{ item.audios?.length ? '可听读' : '暂无音频' }}</span></div>
      <h2>{{ item.title }}</h2>
      <p class="page-lead">在文字与声音之间，慢慢读完这一篇。</p>
      <div v-if="item.audios?.length" class="media-panel"><h3>文章配套音频</h3><div v-for="audio in item.audios" :key="audio.id"><p>{{ audio.title }}</p><audio controls preload="metadata" :src="assetUrl(audio.url)">浏览器不支持音频播放。</audio></div></div>
      <div v-else class="source-note">这篇文章目前没有配套音频。</div>
      <article v-if="item.japanese" class="reader-page"><div class="reader-label">日语原文</div><p class="reading-text">{{ item.japanese }}</p></article>
      <div v-else class="source-note">正文待整理。当前可先收听配套音频；未经核对的扫描文字不会作为原文展示。</div>
      <details v-if="item.translation" class="vocab-panel"><summary>展开中文译文</summary><p class="reading-text">{{ item.translation }}</p></details>
      <RouterLink v-if="item.textStatus === 'novel_lessons'" class="secondary-action" to="/novel">进入小说词汇</RouterLink>
      <p v-if="item.metadata?.attribution" class="source-caption">原作者：{{ item.metadata.attribution }}</p>
    </template>
  </div>
</template>
