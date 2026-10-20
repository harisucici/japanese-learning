<script setup>
// 时间警告组件：临近结束显示警告条
import { computed } from 'vue'

const props = defineProps({
  // 剩余秒数（null 或 undefined 表示无计时）
  remainingSeconds: { type: Number, default: null }
})

// 最后 5 分钟：橙色警告；最后 1 分钟：红色闪烁
const level = computed(() => {
  if (props.remainingSeconds === null || props.remainingSeconds === undefined) return 'none'
  if (props.remainingSeconds <= 60) return 'critical'
  if (props.remainingSeconds <= 300) return 'warning'
  return 'none'
})

const formatted = computed(() => {
  if (props.remainingSeconds === null || props.remainingSeconds === undefined) return ''
  const s = Math.max(0, Math.floor(props.remainingSeconds))
  const m = Math.floor(s / 60)
  const sec = s % 60
  return `${m}:${String(sec).padStart(2, '0')}`
})

const message = computed(() => {
  if (level.value === 'critical') return `距离结束仅剩 ${formatted.value}，请检查答题卡`
  if (level.value === 'warning') return `剩余时间不足 5 分钟（${formatted.value}）`
  return ''
})
</script>

<template>
  <Transition name="tw-fade">
    <div
      v-if="level !== 'none'"
      class="time-warning"
      :class="{ 'tw-critical': level === 'critical', 'tw-warning': level === 'warning' }"
      role="alert"
      aria-live="polite"
    >
      <div class="tw-inner">
        <svg class="tw-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10" />
          <path d="M12 6v6l4 2" />
        </svg>
        <span class="tw-message">{{ message }}</span>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.time-warning {
  position: sticky;
  top: 0;
  z-index: 40;
  padding: 12px 0;
  font: 13px 'Zen Kaku Gothic New', sans-serif;
  letter-spacing: 0.04em;
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
}

.tw-warning {
  background: rgba(245, 158, 11, 0.15);
  border-bottom: 1px solid rgba(245, 158, 11, 0.4);
  color: #92400e;
}

.tw-critical {
  background: rgba(239, 68, 68, 0.15);
  border-bottom: 1px solid rgba(239, 68, 68, 0.4);
  color: #7f1d1d;
  animation: tw-pulse 1.2s ease-in-out infinite;
}

@keyframes tw-pulse {
  0%, 100% { background: rgba(239, 68, 68, 0.12); }
  50% { background: rgba(239, 68, 68, 0.28); }
}

.tw-inner {
  display: flex;
  align-items: center;
  gap: 10px;
  width: min(1200px, 88%);
  margin: 0 auto;
  justify-content: center;
}

.tw-icon {
  flex: none;
}

.tw-message {
  font-weight: 500;
}

/* 减少动效支持 */
:root[data-reduce-motion="true"] .tw-critical {
  animation: none;
}

.tw-fade-enter-active,
.tw-fade-leave-active {
  transition: opacity 0.25s ease;
}
.tw-fade-enter-from,
.tw-fade-leave-to {
  opacity: 0;
}

:root[data-reduce-motion="true"] .tw-fade-enter-active,
:root[data-reduce-motion="true"] .tw-fade-leave-active {
  transition: none;
}
</style>
