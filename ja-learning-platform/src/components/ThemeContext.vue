<script setup lang="ts">
// 主题上下文组件：提供全局主题状态、设置面板入口
import { ref, computed, onMounted, onUnmounted, provide, watch } from 'vue'
import {
  loadSettings,
  saveSettings,
  applyThemeToRoot,
  resolveTheme,
  watchSystemTheme,
  DEFAULT_SETTINGS,
  type ThemeMode,
  type ThemeSettings,
  type FontSize,
  type LineHeight,
  type RubySize
} from '../utils/theme'

// 当前主题设置
const settings = ref<ThemeSettings>({ ...DEFAULT_SETTINGS })
// 设置面板是否打开
const panelOpen = ref(false)

// 实际生效的主题（light/dark）
const resolvedTheme = computed(() => resolveTheme(settings.value.mode))

// 监听 mode 为 system 时，系统主题变化
let stopWatchSystem: (() => void) | null = null

// 更新并持久化设置
function update<K extends keyof ThemeSettings>(key: K, value: ThemeSettings[K]) {
  settings.value[key] = value
  saveSettings(settings.value)
  applyThemeToRoot(settings.value)
}

// 设置面板的字号选项
const fontSizeOptions: { value: FontSize; label: '小' | '中' | '大' | '特大' }[] = [
  { value: 'small', label: '小' },
  { value: 'medium', label: '中' },
  { value: 'large', label: '大' },
  { value: 'xlarge', label: '特大' }
]

const lineHeightOptions: { value: LineHeight; label: '紧凑' | '标准' | '宽松' }[] = [
  { value: 'compact', label: '紧凑' },
  { value: 'normal', label: '标准' },
  { value: 'relaxed', label: '宽松' }
]

const rubySizeOptions: { value: RubySize; label: '小' | '中' | '大' }[] = [
  { value: 'small', label: '小' },
  { value: 'medium', label: '中' },
  { value: 'large', label: '大' }
]

const themeModeOptions: { value: ThemeMode; label: '浅色' | '深色' | '跟随系统' }[] = [
  { value: 'light', label: '浅色' },
  { value: 'dark', label: '深色' },
  { value: 'system', label: '跟随系统' }
]

// 提供给子组件的主题上下文
provide('theme', {
  settings,
  resolvedTheme,
  update
})

onMounted(() => {
  settings.value = loadSettings()
  applyThemeToRoot(settings.value)
  stopWatchSystem = watchSystemTheme(() => {
    if (settings.value.mode === 'system') applyThemeToRoot(settings.value)
  })
})

onUnmounted(() => {
  stopWatchSystem?.()
})

function togglePanel() {
  panelOpen.value = !panelOpen.value
}

function closePanel() {
  panelOpen.value = false
}
</script>

<template>
  <div class="theme-root">
    <slot />

    <!-- 主题切换悬浮按钮 -->
    <button
      class="theme-fab"
      type="button"
      aria-label="显示设置"
      @click="togglePanel"
    >
      <svg v-if="resolvedTheme === 'dark'" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
        <circle cx="12" cy="12" r="4" />
        <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41" />
      </svg>
      <svg v-else width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
        <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
      </svg>
    </button>

    <!-- 设置面板 -->
    <Transition name="theme-panel">
      <div v-if="panelOpen" class="theme-panel-backdrop" @click.self="closePanel">
        <div class="theme-panel" role="dialog" aria-label="显示与阅读设置">
          <header class="theme-panel-head">
            <div>
              <p class="theme-panel-eyebrow">DISPLAY SETTINGS</p>
              <h2>显示设置</h2>
            </div>
            <button class="theme-panel-close" type="button" @click="closePanel" aria-label="关闭">×</button>
          </header>

          <section class="theme-section">
            <label class="theme-label">主题</label>
            <div class="theme-options">
              <button
                v-for="opt in themeModeOptions"
                :key="opt.value"
                type="button"
                :class="{ active: settings.mode === opt.value }"
                @click="update('mode', opt.value)"
              >{{ opt.label }}</button>
            </div>
          </section>

          <section class="theme-section">
            <label class="theme-label">字号</label>
            <div class="theme-options">
              <button
                v-for="opt in fontSizeOptions"
                :key="opt.value"
                type="button"
                :class="{ active: settings.fontSize === opt.value }"
                @click="update('fontSize', opt.value)"
              >{{ opt.label }}</button>
            </div>
          </section>

          <section class="theme-section">
            <label class="theme-label">行距</label>
            <div class="theme-options">
              <button
                v-for="opt in lineHeightOptions"
                :key="opt.value"
                type="button"
                :class="{ active: settings.lineHeight === opt.value }"
                @click="update('lineHeight', opt.value)"
              >{{ opt.label }}</button>
            </div>
          </section>

          <section class="theme-section">
            <label class="theme-label">假名注音大小</label>
            <div class="theme-options">
              <button
                v-for="opt in rubySizeOptions"
                :key="opt.value"
                type="button"
                :class="{ active: settings.rubySize === opt.value }"
                @click="update('rubySize', opt.value)"
              >{{ opt.label }}</button>
            </div>
          </section>

          <section class="theme-section theme-section-toggle">
            <label class="theme-label">减少动画</label>
            <p class="theme-hint">关闭所有过渡和动画效果</p>
            <button
              type="button"
              class="theme-switch"
              :class="{ on: settings.reduceMotion }"
              :aria-pressed="settings.reduceMotion"
              @click="update('reduceMotion', !settings.reduceMotion)"
            >
              <span></span>
            </button>
          </section>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.theme-fab {
  position: fixed;
  right: 24px;
  bottom: 24px;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: #2563EB;
  color: #fff;
  border: 0;
  cursor: pointer;
  z-index: 60;
  display: grid;
  place-items: center;
  box-shadow: 0 8px 24px -6px rgba(37, 99, 235, 0.45);
  transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.25s;
}
.theme-fab:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 28px -6px rgba(37, 99, 235, 0.55);
}
.theme-fab:active {
  transform: translateY(0) scale(0.96);
}

.theme-panel-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(20, 32, 28, 0.35);
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}
.theme-panel {
  background: var(--theme-surface, #fffdf8);
  color: var(--theme-text, #27302b);
  border-radius: 16px;
  width: min(480px, 100%);
  max-height: 85vh;
  overflow-y: auto;
  padding: 36px 40px;
  box-shadow: 0 30px 60px -20px rgba(0, 0, 0, 0.25);
  border: 1px solid var(--theme-border, rgba(0, 0, 0, 0.08));
}
.theme-panel-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 28px;
  padding-bottom: 20px;
  border-bottom: 1px solid var(--theme-border, #d9d4c3);
}
.theme-panel-head h2 {
  font: 500 22px 'Zen Kaku Gothic New', sans-serif;
  letter-spacing: 0.08em;
  margin: 6px 0 0;
}
.theme-panel-eyebrow {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.26em;
  color: #2563EB;
  margin: 0;
}
.theme-panel-close {
  width: 32px;
  height: 32px;
  border: 0;
  background: transparent;
  color: inherit;
  cursor: pointer;
  font-size: 22px;
  line-height: 1;
  opacity: 0.6;
}
.theme-panel-close:hover { opacity: 1; }

.theme-section {
  margin-bottom: 26px;
}
.theme-label {
  display: block;
  font-size: 13px;
  font-weight: 500;
  letter-spacing: 0.04em;
  color: var(--theme-text-secondary, #67746a);
  margin-bottom: 12px;
}
.theme-options {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}
.theme-options button {
  padding: 10px 8px;
  border: 1px solid var(--theme-border, #d1ccb8);
  background: transparent;
  color: inherit;
  cursor: pointer;
  font: 13px 'Zen Kaku Gothic New', sans-serif;
  letter-spacing: 0.05em;
  transition: all 0.18s;
  border-radius: 6px;
}
.theme-options button:hover {
  border-color: #2563EB;
  color: #2563EB;
}
.theme-options button.active {
  background: #2563EB;
  color: #fff;
  border-color: #2563EB;
}

.theme-section-toggle {
  display: grid;
  grid-template-columns: 1fr auto;
  grid-template-rows: auto auto;
  align-items: center;
  gap: 4px 12px;
}
.theme-section-toggle .theme-label { margin: 0; grid-column: 1; }
.theme-hint {
  font-size: 11px;
  color: var(--theme-text-secondary, #9a9486);
  margin: 0;
  grid-column: 1;
  grid-row: 2;
}
.theme-switch {
  grid-column: 2;
  grid-row: 1 / 3;
  width: 48px;
  height: 28px;
  border-radius: 14px;
  border: 1px solid var(--theme-border, #d1ccb8);
  background: var(--theme-surface-alt, #eee9d8);
  cursor: pointer;
  position: relative;
  transition: all 0.2s;
  padding: 0;
}
.theme-switch span {
  position: absolute;
  top: 3px;
  left: 3px;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #fff;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.15);
  transition: transform 0.2s;
}
.theme-switch.on {
  background: #2563EB;
  border-color: #2563EB;
}
.theme-switch.on span {
  transform: translateX(20px);
}

/* 面板过渡 */
.theme-panel-enter-active,
.theme-panel-leave-active {
  transition: opacity 0.25s ease;
}
.theme-panel-enter-active .theme-panel,
.theme-panel-leave-active .theme-panel {
  transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.25s;
}
.theme-panel-enter-from,
.theme-panel-leave-to {
  opacity: 0;
}
.theme-panel-enter-from .theme-panel,
.theme-panel-leave-to .theme-panel {
  transform: translateY(12px) scale(0.98);
  opacity: 0;
}

@media (max-width: 640px) {
  .theme-fab {
    right: 16px;
    bottom: 16px;
  }
  .theme-panel {
    padding: 28px 24px;
  }
  .theme-options {
    grid-template-columns: repeat(3, 1fr);
  }
}
</style>
