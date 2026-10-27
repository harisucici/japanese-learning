<script setup>
// 阅读文本组件：假名注音优化、折叠面板、禁止复制
import { ref, computed } from 'vue'
import { inject } from 'vue'

const props = defineProps({
  // 原文文本
  text: { type: String, default: '' },
  // 标题（可选）
  title: { type: String, default: '' },
  // 是否可折叠（默认折叠）
  collapsible: { type: Boolean, default: true },
  // 是否禁止复制（默认 true）
  noCopy: { type: Boolean, default: true },
  // 默认展开
  defaultOpen: { type: Boolean, default: false }
})

const open = ref(props.defaultOpen)

// 主题上下文
const theme = inject('theme', null)

// 解析带假名标注的文本：格式 [漢字:かんじ] 或直接使用 <ruby>
const parsed = computed(() => {
  if (!props.text) return ''
  // 移除纯假名「读み先」行（仅由平假名组成、无任何汉字/标点/括号），
  // 这些行是原始排版中位于标注行上方的注音预览，ruby 标签已包含注音信息
  const hiraganaOnly = /^[\u3040-\u309F]+$/
  const cleaned = props.text
    .split('\n')
    .filter(line => !hiraganaOnly.test(line))
    .join('\n')
  // 匹配 [漢字:假名] 格式
  return cleaned.replace(/\[([^\]]+?):([^\]]+?)\]/g, (_, base, ruby) => {
    return `<ruby>${escapeHtml(base)}<rp>(</rp><rt>${escapeHtml(ruby)}</rt><rp>)</rp></ruby>`
  })
})

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
}

function toggle() {
  if (props.collapsible) open.value = !open.value
}

// 阻止复制
function preventCopy(e) {
  if (props.noCopy) {
    e.preventDefault()
  }
}
</script>

<template>
  <div class="reading-text-wrap" :class="{ 'no-copy': noCopy }">
    <div v-if="title || collapsible" class="rt-header" @click="toggle">
      <div class="rt-title-area">
        <p class="rt-eyebrow">READING PASSAGE</p>
        <h4 v-if="title" class="rt-title">{{ title }}</h4>
        <p v-else class="rt-title">原文</p>
      </div>
      <button v-if="collapsible" type="button" class="rt-toggle" :aria-expanded="open">
        <svg
          width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
          :class="{ 'rt-toggle-open': open }"
        >
          <path d="M6 9l6 6 6-6" />
        </svg>
      </button>
    </div>

    <div v-show="!collapsible || open" class="rt-body" @copy="preventCopy" @selectstart="preventCopy">
      <!-- eslint-disable-next-line vue/no-v-html -->
      <div class="rt-content" v-html="parsed"></div>
      <p v-if="noCopy" class="rt-hint">※ 出于考试公平性，原文禁止复制</p>
    </div>
  </div>
</template>

<style scoped>
.reading-text-wrap {
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--theme-border, #d1ccb8);
  border-radius: 10px;
  margin: 20px 0;
  overflow: hidden;
}

.rt-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 22px;
  background: var(--theme-surface-alt, #f0eee5);
  border-bottom: 1px solid var(--theme-border, #e2ded3);
}

.rt-title-area {
  min-width: 0;
}

.rt-eyebrow {
  font-size: 9px;
  font-weight: 600;
  letter-spacing: 0.26em;
  color: #2563EB;
  margin: 0 0 6px;
}

.rt-title {
  font: 500 15px var(--app-font-family);
  letter-spacing: 0.04em;
  margin: 0;
  color: var(--theme-text, #27302b);
}

.rt-toggle {
  width: 28px;
  height: 28px;
  border: 1px solid var(--theme-border, #d1ccb8);
  background: transparent;
  border-radius: 50%;
  cursor: pointer;
  display: grid;
  place-items: center;
  color: var(--theme-text-secondary, #67746a);
  transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1), background 0.15s;
  flex: none;
}
.rt-toggle:hover {
  background: rgba(37, 99, 235, 0.08);
  color: #2563EB;
}
.rt-toggle svg {
  transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}
.rt-toggle-open {
  transform: rotate(180deg);
}

.rt-body {
  padding: 24px 26px;
}

.rt-content {
  font-size: var(--base-font-size, 17px);
  line-height: var(--base-line-height, 2.2);
  color: var(--theme-text, #27302b);
  white-space: pre-wrap;
  word-break: break-word;
  user-select: none;
  -webkit-user-select: none;
}

/* Ruby 注音优化：假名紧凑显示在汉字上方 */
.rt-content :deep(ruby) {
  ruby-position: over;
  line-height: calc(var(--base-line-height, 2.2) + 0.6);
}
.rt-content :deep(rt) {
  font-size: var(--ruby-font-size, 11px);
  color: #2563EB;
  font-weight: 500;
  line-height: 1;
  letter-spacing: 0.02em;
  user-select: none;
  -webkit-user-select: none;
}
.rt-content :deep(rp) {
  display: none;
}

.rt-hint {
  font-size: 11px;
  color: var(--theme-text-secondary, #9a9486);
  margin: 16px 0 0;
  letter-spacing: 0.04em;
  padding-top: 14px;
  border-top: 1px dashed var(--theme-border, #e2ded3);
}

/* 禁止复制：手机端额外处理 */
.no-copy {
  -webkit-user-select: none;
  -webkit-touch-callout: none;
}

:root[data-reduce-motion="true"] .rt-toggle svg {
  transition: none;
}

@media (max-width: 640px) {
  .rt-body {
    padding: 18px 18px;
  }
}
</style>
