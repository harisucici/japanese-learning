<script setup>
import { onMounted, ref, watch, computed } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import { assetUrl, useLearningStore } from '../store'
import ReadingText from '../components/ReadingText.vue'
const route = useRoute(), api = useLearningStore(), item = ref(null), error = ref(''), loading = ref(true)
const activeTab = ref('original')
const fontSize = ref(18)
async function load() { loading.value = true; error.value = ''; try { item.value = await api.request(`materials/${encodeURIComponent(route.params.id)}`) } catch (e) { error.value = e.message } finally { loading.value = false } }
onMounted(load); watch(() => route.params.id, load)
function adjustFont(delta) {
  fontSize.value = Math.max(16, Math.min(24, fontSize.value + delta))
}
const firstAudio = computed(() => item.value?.audios?.[0] || null)
</script>

<template>
  <div class="content-page detail-page material-detail">
    <!-- 桌面端：保持原有布局 -->
    <div class="desktop-only">
      <RouterLink class="back-dark" to="/materials">← 返回素材阅读馆</RouterLink>
      <div v-if="loading" class="state-box">正在读取文章…</div>
      <div v-else-if="error" class="state-box error">{{ error }} <button @click="load">重试</button></div>
      <template v-else>
        <div class="section-top"><p class="eyebrow">LIBRARY / {{ item.collection }}</p><span>{{ item.audios?.length ? '可听读' : '暂无音频' }}</span></div>
        <h2>{{ item.title }}</h2>
        <p class="page-lead">在文字与声音之间，慢慢读完这一篇。</p>
        <div v-if="item.audios?.length" class="media-panel"><h3>文章配套音频</h3><div v-for="audio in item.audios" :key="audio.id"><p>{{ audio.title }}</p><audio controls preload="metadata" :src="assetUrl(audio.url)">浏览器不支持音频播放。</audio></div></div>
        <div v-else class="source-note">这篇文章目前没有配套音频。</div>
        <ReadingText v-if="item.japanese" :text="item.japanese" title="日语原文" :collapsible="false" :default-open="true" />
        <div v-else class="source-note">正文待整理。当前可先收听配套音频；未经核对的扫描文字不会作为原文展示。</div>
        <details v-if="item.translation" class="vocab-panel"><summary>展开中文译文</summary><p class="reading-text">{{ item.translation }}</p></details>
        <RouterLink v-if="item.textStatus === 'novel_lessons'" class="secondary-action" to="/novel">进入小说词汇</RouterLink>
        <p v-if="item.metadata?.attribution" class="source-caption">原作者：{{ item.metadata.attribution }}</p>
      </template>
    </div>

    <!-- 移动端改造 -->
    <div class="mobile-only">
      <!-- 骨架屏加载状态 -->
      <div v-if="loading" class="material-skeleton">
        <div class="skeleton-player">
          <div class="skeleton shimmer" style="width: 36px; height: 36px; border-radius: 50%;"></div>
          <div class="skeleton-content">
            <div class="skeleton shimmer" style="width: 60%; height: 16px; border-radius: 8px;"></div>
            <div class="skeleton shimmer" style="width: 40%; height: 12px; border-radius: 6px; margin-top: 8px;"></div>
          </div>
        </div>
        <div class="skeleton-detail">
          <div class="skeleton shimmer" style="width: 90%; height: 20px; border-radius: 8px; margin-bottom: 12px;"></div>
          <div class="skeleton shimmer" style="width: 100%; height: 14px; border-radius: 6px; margin-bottom: 8px;"></div>
          <div class="skeleton shimmer" style="width: 80%; height: 14px; border-radius: 6px; margin-bottom: 8px;"></div>
          <div class="skeleton shimmer" style="width: 95%; height: 14px; border-radius: 6px; margin-bottom: 8px;"></div>
          <div class="skeleton shimmer" style="width: 70%; height: 14px; border-radius: 6px;"></div>
        </div>
      </div>
      <div v-else-if="error" class="state-box error">{{ error }} <button @click="load">重试</button></div>
      <template v-else>
        <!-- 顶部音频播放器（固定） -->
        <div v-if="firstAudio" class="mobile-audio-player">
          <div class="player-info">
            <span class="player-icon">♪</span>
            <div class="player-text">
              <p class="player-title">{{ firstAudio.title || '配套音频' }}</p>
              <p class="player-sub">点击播放按钮收听</p>
            </div>
          </div>
          <audio 
            ref="audioEl" 
            controls 
            preload="metadata" 
            :src="assetUrl(firstAudio.url)"
            class="player-controls"
          >浏览器不支持音频播放。</audio>
        </div>
        <div v-else class="mobile-no-audio">
          <span class="no-audio-icon">🔇</span>
          <p>这篇文章暂无配套音频</p>
        </div>

        <!-- 顶部标题区 -->
        <div class="mobile-header">
          <RouterLink class="mobile-back" to="/materials">← 返回素材馆</RouterLink>
          <div class="mobile-meta">{{ item.collection }} · {{ item.audios?.length ? '可听读' : '暂无音频' }}</div>
          <h2 class="mobile-title">{{ item.title }}</h2>
          <div v-if="item.metadata?.attribution" class="mobile-author">原作者：{{ item.metadata.attribution }}</div>
        </div>

        <!-- 字体大小控制 -->
        <div class="mobile-font-control">
          <span class="font-label">字号</span>
          <div class="font-buttons">
            <button type="button" @click="adjustFont(-2)" aria-label="减小字号">A-</button>
            <span class="font-size">{{ fontSize }}px</span>
            <button type="button" @click="adjustFont(2)" aria-label="增大字号">A+</button>
          </div>
        </div>

        <!-- 原文/译文 Tab 切换 -->
        <div class="mobile-tabs">
          <button 
            type="button" 
            :class="['tab-btn', { active: activeTab === 'original' }]" 
            @click="activeTab = 'original'"
            :aria-pressed="activeTab === 'original'"
          >日语原文</button>
          <button 
            v-if="item.translation"
            type="button" 
            :class="['tab-btn', { active: activeTab === 'translation' }]" 
            @click="activeTab = 'translation'"
            :aria-pressed="activeTab === 'translation'"
          >中文译文</button>
        </div>

        <!-- 内容区 -->
        <div class="mobile-content" :style="{ '--reading-font-size': fontSize + 'px' }">
          <div v-if="activeTab === 'original'" class="tab-panel">
            <div v-if="item.japanese" class="reading-text-wrap">
              <ReadingText :text="item.japanese" title="" :collapsible="false" :default-open="true" />
            </div>
            <div v-else class="empty-notice">
              正文待整理。当前可先收听配套音频；未经核对的扫描文字不会作为原文展示。
            </div>
          </div>
          <div v-if="activeTab === 'translation'" class="tab-panel">
            <p class="translation-text">{{ item.translation }}</p>
          </div>
        </div>

        <!-- 底部固定操作栏 -->
        <nav class="mobile-bottombar">
          <RouterLink v-if="item.textStatus === 'novel_lessons'" class="bottom-btn" to="/novel">小说词汇</RouterLink>
          <button v-else type="button" class="bottom-btn" disabled>词汇</button>
          <RouterLink class="bottom-btn primary" :to="`/materials/${item.id}`">听读</RouterLink>
          <button type="button" class="bottom-btn" @click="activeTab = activeTab === 'original' ? 'translation' : 'original'">
            {{ activeTab === 'original' ? '看译文' : '看原文' }}
          </button>
        </nav>
      </template>
    </div>
  </div>
</template>

<style scoped>
.material-detail {
  padding-bottom: 120px;
}

.desktop-only { display: block; }
.mobile-only { display: none; }

/* 移动端改造 */
@media (max-width: 768px) {
  .desktop-only { display: none; }
  .mobile-only { display: block; }

  .material-detail {
    padding: 0 0 140px;
  }

  /* 顶部音频播放器（固定） */
  .mobile-audio-player {
    position: sticky;
    top: 0;
    z-index: 30;
    background: var(--theme-surface, #fffdf8);
    border-bottom: 1px solid var(--theme-border, #d1ccb8);
    padding: 12px 16px;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }
  .player-info {
    display: flex;
    align-items: center;
    gap: 10px;
  }
  .player-icon {
    width: 36px;
    height: 36px;
    background: var(--color-primary, #2563EB);
    color: #fff;
    border-radius: 50%;
    display: grid;
    place-items: center;
    font-size: 18px;
    flex: none;
  }
  .player-text {
    flex: 1;
    min-width: 0;
  }
  .player-title {
    font: 600 14px/1.3 'Zen Kaku Gothic New', sans-serif;
    margin: 0;
    color: var(--theme-text, #27302b);
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .player-sub {
    font-size: 12px;
    color: var(--theme-text-secondary, #67746a);
    margin: 2px 0 0;
  }
  .player-controls {
    width: 100%;
    height: 40px;
    transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  }
  .player-controls:active {
    transform: scale(0.97);
  }

  .mobile-no-audio {
    padding: 16px;
    text-align: center;
    background: var(--theme-surface-alt, #f5f2e9);
    border-bottom: 1px solid var(--theme-border-soft, #e2ded3);
  }
  .no-audio-icon {
    font-size: 24px;
    margin-right: 8px;
  }
  .mobile-no-audio p {
    display: inline;
    font-size: 14px;
    color: var(--theme-text-secondary, #67746a);
    margin: 0;
  }

  /* 顶部标题区 */
  .mobile-header {
    padding: 16px 16px 12px;
    background: var(--theme-surface, #fffdf8);
  }
  .mobile-back {
    font-size: 13px;
    color: var(--color-primary, #2563EB);
    text-decoration: none;
    display: inline-block;
    margin-bottom: 10px;
    padding: 6px 0;
  }
  .mobile-meta {
    font-size: 12px;
    color: var(--theme-text-secondary, #67746a);
    letter-spacing: 0.04em;
    margin-bottom: 6px;
  }
  .mobile-title {
    font: 700 20px/1.35 'Zen Kaku Gothic New', sans-serif;
    margin: 0 0 4px;
    color: var(--theme-text, #27302b);
  }
  .mobile-author {
    font-size: 12px;
    color: var(--theme-text-muted, #9a9486);
    margin-top: 4px;
  }

  /* 字体大小控制 */
  .mobile-font-control {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 10px 16px;
    background: var(--theme-surface-alt, #f5f2e9);
    border-bottom: 1px solid var(--theme-border-soft, #e2ded3);
  }
  .font-label {
    font-size: 13px;
    color: var(--theme-text-secondary, #67746a);
    font-weight: 500;
  }
  .font-buttons {
    display: flex;
    align-items: center;
    gap: 10px;
  }
  .font-buttons button {
    min-width: 44px;
    min-height: 44px;
    background: var(--theme-surface, #fffdf8);
    border: 1px solid var(--theme-border, #d1ccb8);
    border-radius: 8px;
    font-size: 14px;
    font-weight: 600;
    color: var(--theme-text, #27302b);
    cursor: pointer;
  }
  .font-buttons button:active {
    background: var(--theme-border-soft, #e2ded3);
  }
  .font-size {
    font-size: 13px;
    color: var(--theme-text, #27302b);
    min-width: 48px;
    text-align: center;
    font-variant-numeric: tabular-nums;
  }

  /* Tab 切换 */
  .mobile-tabs {
    display: flex;
    gap: 0;
    border-bottom: 1px solid var(--theme-border, #d1ccb8);
    background: var(--theme-surface, #fffdf8);
    position: relative;
  }
  .tab-btn {
    flex: 1;
    min-height: 48px;
    background: transparent;
    border: none;
    border-bottom: 2px solid transparent;
    padding: 12px;
    font-size: 15px;
    font-weight: 500;
    color: var(--theme-text-secondary, #67746a);
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  }
  .tab-btn.active {
    color: var(--theme-text, #27302b);
    border-bottom-color: var(--theme-text, #27302b);
    font-weight: 600;
  }

  /* 内容区 */
  .mobile-content {
    padding: 16px;
  }
  .mobile-content :deep(.reading-text) {
    font-size: var(--reading-font-size, 18px);
    line-height: 1.8;
  }
  .mobile-content :deep(.rt-content) {
    font-size: var(--reading-font-size, 18px);
    line-height: 1.8;
  }
  .translation-text {
    font-size: var(--reading-font-size, 18px);
    line-height: 1.8;
    color: var(--theme-text, #27302b);
    white-space: pre-wrap;
    word-break: break-word;
    margin: 0;
  }

  .empty-notice {
    padding: 24px 16px;
    text-align: center;
    color: var(--theme-text-secondary, #67746a);
    font-size: 14px;
    line-height: 1.7;
    background: var(--theme-surface-alt, #f5f2e9);
    border-radius: 8px;
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
    align-items: stretch;
    gap: 0;
    padding: 0 8px;
    padding-bottom: env(safe-area-inset-bottom, 0);
    z-index: 30;
  }
  .bottom-btn {
    flex: 1;
    display: grid;
    place-items: center;
    padding: 0 12px;
    background: transparent;
    border: none;
    color: var(--theme-text, #27302b);
    text-decoration: none;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    border-radius: 8px;
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
    min-height: 44px;
  }
  .bottom-btn:disabled {
    opacity: 0.4;
    cursor: not-allowed;
  }
  .bottom-btn:not(:disabled):active {
    background: var(--theme-surface-alt, #f5f2e9);
    transform: scale(0.97);
  }
  .bottom-btn.primary {
    background: var(--color-primary, #2563EB);
    color: #fff;
    border-radius: 10px;
    font-weight: 600;
  }
  .bottom-btn.primary:active {
    background: #1d4ed8;
    transform: scale(0.97);
  }

  /* 骨架屏样式 */
  .material-skeleton {
    padding: 20px 4%;
  }
  .material-skeleton .skeleton-player {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 16px;
    background: rgba(245, 242, 233, 0.6);
    border-radius: 12px;
    margin-bottom: 20px;
  }
  .material-skeleton .skeleton-content {
    flex: 1;
  }
  .material-skeleton .skeleton-detail {
    padding: 0 4px;
  }
  .material-skeleton .skeleton {
    background: linear-gradient(90deg, #f5f2e9 25%, #fffdf8 50%, #f5f2e9 75%);
    background-size: 200% 100%;
    animation: material-shimmer 1.5s ease-in-out infinite;
  }
  @keyframes material-shimmer {
    0% { background-position: 200% 0; }
    100% { background-position: -200% 0; }
  }
}

/* 极小屏 */
@media (max-width: 375px) {
  .mobile-title {
    font-size: 17px;
    line-height: 1.3;
  }
  .mobile-meta {
    font-size: 11px;
  }
  .mobile-author {
    font-size: 11px;
  }
  .mobile-header {
    padding: 12px 12px 10px;
  }
  .mobile-back {
    font-size: 12px;
  }
  .player-controls {
    height: 34px;
  }
  .player-title {
    font-size: 13px;
  }
  .player-sub {
    font-size: 11px;
  }
  .mobile-audio-player {
    padding: 10px 12px;
  }
  .mobile-font-control {
    padding: 8px 12px;
  }
  .font-label {
    font-size: 12px;
  }
  .font-buttons button {
    min-width: 40px;
    min-height: 40px;
    font-size: 13px;
  }
  .font-size {
    font-size: 12px;
    min-width: 42px;
  }
  .tab-btn {
    font-size: 14px;
    min-height: 44px;
    padding: 10px;
  }
  .mobile-content {
    padding: 12px;
  }
  .mobile-content :deep(.reading-text),
  .mobile-content :deep(.rt-content) {
    font-size: var(--reading-font-size, 16px);
    line-height: 1.75;
  }
  .translation-text {
    font-size: var(--reading-font-size, 16px);
    line-height: 1.75;
  }
  .bottom-btn {
    font-size: 13px;
    padding: 0 8px;
  }
  .material-skeleton {
    padding: 16px 12px;
  }
  .material-skeleton .skeleton-player {
    padding: 12px;
    margin-bottom: 16px;
  }
}
</style>
