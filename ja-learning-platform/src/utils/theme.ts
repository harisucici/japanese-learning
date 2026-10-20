// 主题工具函数：提供主题切换、持久化、CSS 变量注入

// 主题类型
export type ThemeMode = 'light' | 'dark' | 'system'
export type FontSize = 'small' | 'medium' | 'large' | 'xlarge'
export type LineHeight = 'compact' | 'normal' | 'relaxed'
export type RubySize = 'small' | 'medium' | 'large'

export interface ThemeSettings {
  mode: ThemeMode
  fontSize: FontSize
  lineHeight: LineHeight
  rubySize: RubySize
  reduceMotion: boolean
}

// 默认设置
export const DEFAULT_SETTINGS: ThemeSettings = {
  mode: 'system',
  fontSize: 'medium',
  lineHeight: 'normal',
  rubySize: 'medium',
  reduceMotion: false
}

// 持久化 key
const STORAGE_KEY = 'ja-theme-settings'

// 读取本地存储的主题设置
export function loadSettings(): ThemeSettings {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return { ...DEFAULT_SETTINGS }
    return { ...DEFAULT_SETTINGS, ...JSON.parse(raw) }
  } catch {
    return { ...DEFAULT_SETTINGS }
  }
}

// 保存主题设置
export function saveSettings(settings: ThemeSettings): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(settings))
  } catch {
    // 存储可能不可用（隐私模式等）
  }
}

// 解析实际生效主题（考虑 system 模式）
export function resolveTheme(mode: ThemeMode): 'light' | 'dark' {
  if (mode === 'system') {
    if (typeof window === 'undefined' || !window.matchMedia) return 'light'
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
  }
  return mode
}

// 字号到 CSS 数值的映射
const FONT_SIZE_MAP: Record<FontSize, string> = {
  small: '15px',
  medium: '17px',
  large: '19px',
  xlarge: '22px'
}

const LINE_HEIGHT_MAP: Record<LineHeight, string> = {
  compact: '1.9',
  normal: '2.2',
  relaxed: '2.6'
}

const RUBY_SIZE_MAP: Record<RubySize, string> = {
  small: '9px',
  medium: '11px',
  large: '13px'
}

// 把设置应用到 document.documentElement 的 CSS 变量上
export function applyThemeToRoot(settings: ThemeSettings): void {
  if (typeof document === 'undefined') return
  const root = document.documentElement
  const resolved = resolveTheme(settings.mode)

  root.setAttribute('data-theme', resolved)
  root.setAttribute('data-font-size', settings.fontSize)
  root.setAttribute('data-line-height', settings.lineHeight)
  root.setAttribute('data-ruby-size', settings.rubySize)
  root.setAttribute('data-reduce-motion', settings.reduceMotion ? 'true' : 'false')

  root.style.setProperty('--base-font-size', FONT_SIZE_MAP[settings.fontSize])
  root.style.setProperty('--base-line-height', LINE_HEIGHT_MAP[settings.lineHeight])
  root.style.setProperty('--ruby-font-size', RUBY_SIZE_MAP[settings.rubySize])
}

// 监听系统主题变化
export function watchSystemTheme(callback: (theme: 'light' | 'dark') => void): () => void {
  if (typeof window === 'undefined' || !window.matchMedia) return () => {}
  const mql = window.matchMedia('(prefers-color-scheme: dark)')
  const handler = (e: MediaQueryListEvent) => callback(e.matches ? 'dark' : 'light')
  mql.addEventListener('change', handler)
  return () => mql.removeEventListener('change', handler)
}
