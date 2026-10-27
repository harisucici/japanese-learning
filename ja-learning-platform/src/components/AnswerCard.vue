<script setup>
// 答题卡组件：显示题号网格，颜色区分状态，支持跳转、标记
import { computed } from 'vue'

const props = defineProps({
  // 题目总数
  total: { type: Number, required: true },
  // 已答题号数组（1-indexed）
  answered: { type: Array, default: () => [] },
  // 标记题号数组
  marked: { type: Array, default: () => [] },
  // 当前题号（1-indexed）
  current: { type: Number, default: 1 },
  // 当前科目名
  sectionTitle: { type: String, default: '' },
  // 当前 section 在整个考试中的序号
  sectionIndex: { type: Number, default: 0 },
  // 总 section 数
  sectionTotal: { type: Number, default: 1 }
})

const emit = defineEmits(['jump', 'toggle-mark'])

// 计算每个题号的状态
const items = computed(() => {
  const answeredSet = new Set(props.answered)
  const markedSet = new Set(props.marked)
  return Array.from({ length: props.total }, (_, i) => {
    const num = i + 1
    const isAnswered = answeredSet.has(num)
    const isMarked = markedSet.has(num)
    const isCurrent = num === props.current
    return { num, isAnswered, isMarked, isCurrent }
  })
})

// 状态分组统计
const stats = computed(() => {
  const answered = items.value.filter(i => i.isAnswered).length
  const marked = items.value.filter(i => i.isMarked && !i.isAnswered).length
  return { answered, marked, total: props.total }
})

function itemClass(item) {
  return {
    'ac-item': true,
    'ac-current': item.isCurrent,
    'ac-answered': item.isAnswered && !item.isCurrent,
    'ac-marked': item.isMarked && !item.isAnswered,
    'ac-unanswered': !item.isAnswered && !item.isMarked && !item.isCurrent
  }
}

function jump(num) {
  emit('jump', num)
}

function toggleMark(num) {
  emit('toggle-mark', num)
}

function onContextMenu(e, num) {
  e.preventDefault()
  toggleMark(num)
}
</script>

<template>
  <aside class="answer-card" aria-label="答题卡">
    <header class="ac-head">
      <p class="ac-eyebrow">ANSWER SHEET</p>
      <h3 class="ac-title">{{ sectionTitle || '答题卡' }}</h3>
      <p v-if="sectionTotal > 1" class="ac-subtitle">科目 {{ sectionIndex + 1 }} / {{ sectionTotal }}</p>
    </header>

    <div class="ac-grid" role="grid">
      <button
        v-for="item in items"
        :key="item.num"
        :class="itemClass(item)"
        type="button"
        :aria-label="`第 ${item.num} 题${item.isAnswered ? '，已答' : ''}${item.isMarked ? '，已标记' : ''}${item.isCurrent ? '，当前' : ''}`"
        @click="jump(item.num)"
        @contextmenu="onContextMenu($event, item.num)"
      >
        <span class="ac-num">{{ item.num }}</span>
        <span v-if="item.isMarked && !item.isAnswered" class="ac-mark-dot" aria-hidden="true">★</span>
      </button>
    </div>

    <div class="ac-stats">
      <div class="ac-stat">
        <span class="ac-dot ac-dot-answered"></span>
        <span>已答 {{ stats.answered }}</span>
      </div>
      <div class="ac-stat">
        <span class="ac-dot ac-dot-marked"></span>
        <span>标记 {{ stats.marked }}</span>
      </div>
      <div class="ac-stat">
        <span class="ac-dot ac-dot-unanswered"></span>
        <span>未答 {{ stats.total - stats.answered }}</span>
      </div>
    </div>

    <div class="ac-legend-hint">点击题号可跳转；右键题号可标记/取消标记</div>
  </aside>
</template>

<style scoped>
.answer-card {
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--theme-border, #d1ccb8);
  border-radius: 12px;
  padding: 20px 22px;
  position: sticky;
  top: 110px;
}

.ac-head {
  margin-bottom: 18px;
  padding-bottom: 14px;
  border-bottom: 1px solid var(--theme-border, #e2ded3);
}
.ac-eyebrow {
  font-size: 9px;
  font-weight: 600;
  letter-spacing: 0.26em;
  color: #2563EB;
  margin: 0 0 4px;
}
.ac-title {
  font: 500 16px var(--app-font-family);
  letter-spacing: 0.05em;
  margin: 0;
  color: var(--theme-text, #27302b);
}
.ac-subtitle {
  font-size: 11px;
  color: var(--theme-text-secondary, #8a9389);
  margin: 4px 0 0;
  letter-spacing: 0.05em;
}

.ac-grid {
  display: grid;
  grid-template-columns: repeat(8, 1fr);
  gap: 6px;
  margin-bottom: 18px;
}

.ac-item {
  aspect-ratio: 1;
  border: 1px solid var(--theme-border, #d1ccb8);
  background: transparent;
  cursor: pointer;
  border-radius: 6px;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  font: 12px var(--app-font-family);
  color: var(--theme-text, #547264);
  transition: all 0.15s;
  padding: 0;
}
.ac-item:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 10px -3px rgba(0, 0, 0, 0.12);
}
.ac-item:active {
  transform: translateY(0) scale(0.96);
}

.ac-current {
  background: #2563EB;
  color: #fff;
  border-color: #2563EB;
  box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
  font-weight: 600;
}
.ac-answered {
  background: #10b981;
  color: #fff;
  border-color: #10b981;
}
.ac-marked {
  background: #f59e0b;
  color: #fff;
  border-color: #f59e0b;
}
.ac-unanswered {
  background: var(--theme-surface-alt, #f5f2e9);
  color: var(--theme-text-secondary, #8a9389);
}

.ac-mark-dot {
  position: absolute;
  top: -4px;
  right: -4px;
  font-size: 10px;
  line-height: 1;
}

.ac-stats {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding-top: 12px;
  border-top: 1px solid var(--theme-border, #e2ded3);
}
.ac-stat {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  color: var(--theme-text-secondary, #67746a);
}
.ac-dot {
  width: 10px;
  height: 10px;
  border-radius: 3px;
}
.ac-dot-answered { background: #10b981; }
.ac-dot-marked { background: #f59e0b; }
.ac-dot-unanswered { background: #d1ccb8; }

.ac-legend-hint {
  font-size: 10px;
  color: var(--theme-text-secondary, #9a9486);
  line-height: 1.6;
  margin-top: 12px;
  padding-top: 10px;
  border-top: 1px dashed var(--theme-border, #e2ded3);
}

@media (max-width: 900px) {
  .answer-card {
    position: static;
    padding: 16px;
  }
  .ac-grid {
    grid-template-columns: repeat(10, 1fr);
    gap: 5px;
  }
}

@media (max-width: 640px) {
  .ac-grid {
    grid-template-columns: repeat(8, 1fr);
  }
}
</style>
