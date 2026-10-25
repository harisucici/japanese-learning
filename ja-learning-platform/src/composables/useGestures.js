// 移动端手势操作：右滑返回、下拉刷新、双指缩放字号
import { reactive, computed, onMounted, onUnmounted, inject } from 'vue'
import { useRoute, useRouter } from 'vue-router'

export function useGestures() {
  const route = useRoute()
  const router = useRouter()
  const theme = inject('theme', null)

  // 手势视觉状态
  const gestureState = reactive({
    backArrow: false,
    backOpacity: 0,
    refreshing: false,
    fontSizeHint: false,
    fontSize: 17
  })

  // 手势内部追踪状态
  let touchStartX = 0
  let touchStartY = 0
  let lastTouchX = 0
  let gestureType = null // 'back' | 'pull' | 'pinch' | null
  let startDistance = 0
  let pullThresholdReached = false
  let fontSizeTimer = null
  let refreshTimer = null
  let refreshHoldTimer = null
  let lastPinchAdjust = 0

  // 当前路由是否为阅读详情页（小说/素材详情）
  const isDetailPage = computed(() => {
    return route.path.startsWith('/novel/') || route.path.startsWith('/materials/')
  })

  // 当前是否在答题会话中（需禁用手势）
  const isSessionPage = computed(() => {
    return route.path.startsWith('/sessions') || route.path === '/sessions'
  })

  // 字号档位
  const FONT_STEPS = [
    { value: 'small', px: 15 },
    { value: 'medium', px: 17 },
    { value: 'large', px: 19 },
    { value: 'xlarge', px: 22 }
  ]

  function getCurrentFontIndex() {
    if (!theme) return 1
    const idx = FONT_STEPS.findIndex(s => s.value === theme.settings.value.fontSize)
    return idx >= 0 ? idx : 1
  }

  function showFontSizeHint() {
    const idx = getCurrentFontIndex()
    gestureState.fontSize = FONT_STEPS[idx].px
    gestureState.fontSizeHint = true
    if (fontSizeTimer) clearTimeout(fontSizeTimer)
    fontSizeTimer = setTimeout(() => {
      gestureState.fontSizeHint = false
    }, 2000)
  }

  function adjustFont(direction) {
    if (!theme) return
    const idx = getCurrentFontIndex()
    const next = idx + direction
    if (next < 0 || next >= FONT_STEPS.length) return
    theme.update('fontSize', FONT_STEPS[next].value)
    showFontSizeHint()
  }

  function getScrollTop() {
    return window.scrollY || document.documentElement.scrollTop || 0
  }

  function isMobile() {
    return window.innerWidth < 768
  }

  function gesturesDisabled() {
    return !isMobile() || isSessionPage.value
  }

  function getTouchDistance(e) {
    const dx = e.touches[0].clientX - e.touches[1].clientX
    const dy = e.touches[0].clientY - e.touches[1].clientY
    return Math.sqrt(dx * dx + dy * dy)
  }

  function onTouchStart(e) {
    if (gesturesDisabled()) return
    if (e.touches.length === 0) return

    // 重置状态
    gestureType = null
    pullThresholdReached = false

    // 双指捏合（仅阅读详情页）
    if (e.touches.length === 2 && isDetailPage.value) {
      gestureType = 'pinch'
      startDistance = getTouchDistance(e)
      lastPinchAdjust = 0
      return
    }

    if (e.touches.length !== 1) return

    const x = e.touches[0].clientX
    const y = e.touches[0].clientY
    touchStartX = x
    touchStartY = y
    lastTouchX = x

    // 右滑返回：从屏幕左边缘开始
    if (x < 30) {
      gestureType = 'back'
      gestureState.backArrow = false
      gestureState.backOpacity = 0
    } else if (y < 20 && getScrollTop() <= 5) {
      // 下拉刷新：在页面顶部附近开始
      gestureType = 'pull'
      gestureState.refreshing = false
    }
  }

  function onTouchMove(e) {
    if (!gestureType || gesturesDisabled()) return

    if (gestureType === 'back') {
      const dx = e.touches[0].clientX - touchStartX
      const dy = Math.abs(e.touches[0].clientY - touchStartY)
      lastTouchX = e.touches[0].clientX

      // 如果垂直滑动更多，取消手势
      if (dy > dx && dx < 20) {
        gestureType = null
        gestureState.backArrow = false
        gestureState.backOpacity = 0
        return
      }
      if (dx > 0) {
        gestureState.backArrow = true
        // 距离 0~120px 映射到 opacity 0~0.9
        gestureState.backOpacity = Math.min(dx / 120, 0.9)
      }
      return
    }

    if (gestureType === 'pull') {
      const dy = e.touches[0].clientY - touchStartY
      // 往上滑取消
      if (dy < -5) {
        gestureType = null
        gestureState.refreshing = false
        return
      }
      // 下拉超过 60px 显示指示器
      if (dy > 60) {
        pullThresholdReached = true
        gestureState.refreshing = true
      } else {
        pullThresholdReached = false
        gestureState.refreshing = false
      }
      return
    }

    if (gestureType === 'pinch') {
      if (e.touches.length < 2) return
      const dist = getTouchDistance(e)
      const delta = dist - startDistance
      // 每 50px 的距离变化触发一次字号调整
      if (Math.abs(delta - lastPinchAdjust) > 50) {
        const direction = delta > lastPinchAdjust ? 1 : -1
        adjustFont(direction)
        lastPinchAdjust = delta
      }
      return
    }
  }

  function onTouchEnd() {
    if (!gestureType) return

    if (gestureType === 'back') {
      const dx = lastTouchX - touchStartX
      if (dx > 50) {
        // 执行返回
        if (window.history.length > 1) {
          router.back()
        } else {
          router.push('/')
        }
      }
      gestureState.backArrow = false
      gestureState.backOpacity = 0
    }

    if (gestureType === 'pull') {
      if (pullThresholdReached) {
        // 保持指示器显示 1 秒，然后刷新
        if (refreshTimer) clearTimeout(refreshTimer)
        if (refreshHoldTimer) clearTimeout(refreshHoldTimer)
        refreshTimer = setTimeout(() => {
          gestureState.refreshing = false
          window.location.reload()
        }, 800)
      } else {
        gestureState.refreshing = false
      }
      pullThresholdReached = false
    }

    gestureType = null
  }

  onMounted(() => {
    document.addEventListener('touchstart', onTouchStart, { passive: true })
    document.addEventListener('touchmove', onTouchMove, { passive: false })
    document.addEventListener('touchend', onTouchEnd, { passive: true })
    document.addEventListener('touchcancel', onTouchEnd, { passive: true })
  })

  onUnmounted(() => {
    document.removeEventListener('touchstart', onTouchStart)
    document.removeEventListener('touchmove', onTouchMove)
    document.removeEventListener('touchend', onTouchEnd)
    document.removeEventListener('touchcancel', onTouchEnd)
    if (fontSizeTimer) clearTimeout(fontSizeTimer)
    if (refreshTimer) clearTimeout(refreshTimer)
    if (refreshHoldTimer) clearTimeout(refreshHoldTimer)
  })

  return {
    gestureState
  }
}
