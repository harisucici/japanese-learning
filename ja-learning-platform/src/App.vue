<script setup>
import { computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import { useAppStore, useAuthStore } from './store'
import ThemeContext from './components/ThemeContext.vue'
import { useGestures } from './composables/useGestures'
import yamaSeal from './assets/yama-seal.png'
const route = useRoute()
const store = useAppStore()
const auth = useAuthStore()
auth.check()
const { gestureState } = useGestures()
watch(() => route.path, () => store.closeMenu())
const modules = [
  { num:'01', title:'趣味阅读', en:'STORIES', path:'/novel', desc:'从一个故事开始，让好奇心带你走得更远。', class:'story', cta:'走进故事' },
  { num:'02', title:'趣味闯关', en:'CHALLENGES', path:'/fun', desc:'把知识变成一次次轻盈而有趣的探索。', class:'challenge', cta:'开启挑战' },
  { num:'03', title:'素材阅读馆', en:'LIBRARY', path:'/materials', desc:'收藏值得细读的文字，积累自己的表达。', class:'library', cta:'探索馆藏' },
  { num:'04', title:'模拟考试', en:'PRACTICE', path:'/mock-exam', desc:'在安静的练习里，遇见更从容的自己。', class:'exam', cta:'开始练习' }
]
const isSession = computed(() => route.path.startsWith('/sessions/') || route.path === '/sessions')
const isMobileHidden = computed(() => isSession.value || route.path === '/admin')
const mobileNav = [
  { path: '/', label: '首页', mark: '山' },
  { path: '/novel', label: '阅读', mark: '読' },
  { path: '/materials', label: '素材', mark: '文' },
  { path: '/review', label: '复习', mark: '習' },
  { path: '/account', label: '我的', mark: '私' }
]
const showMobileNav = computed(() => !isSession.value && route.path !== '/admin' && !/^\/(novel|materials)\//.test(route.path))
const mobileContentFirst = computed(() => ['/novel', '/materials', '/fun', '/mock-exam', '/review', '/history', '/stats', '/practice', '/admin'].includes(route.path)
  || /^\/(novel|materials)\//.test(route.path))
const mobileDetailPage = computed(() => /^\/(novel|materials)\//.test(route.path))
const detailBack = computed(() => route.path.startsWith('/novel/') ? '/novel' : route.path.startsWith('/materials/') ? '/materials' : null)
const navActive = (path) => path === '/' ? route.path === '/' : route.path === path || route.path.startsWith(`${path}/`)
const closeMenu = () => { if (window.innerWidth <= 768) store.closeMenu() }
const onKeydown = (event) => { if (event.key === 'Escape') closeMenu() }
onMounted(() => window.addEventListener('keydown', onKeydown))
onUnmounted(() => window.removeEventListener('keydown', onKeydown))
const active = computed(() => {
  if (route.path === '/history') return {num:'05',title:'学习记录',en:'YOUR JOURNEY',class:'library'}
  if (route.path === '/stats') return {num:'06',title:'学习档案',en:'MY STATISTICS',class:'exam'}
  if (route.path === '/practice') return {num:'07',title:'练习模式',en:'PRACTICE MODE',class:'challenge'}
  if (route.path === '/account' || route.path === '/reset-password') return {num:'08',title:'我的账户',en:'YOUR ACCOUNT',class:'library',desc:'在这里继续你的学习旅程。'}
  if (route.path === '/review') return {num:'09',title:'错题复习',en:'REVIEW',class:'story',desc:'把曾经困惑的地方，慢慢变成自己的知识。'}
  if (route.path === '/admin') return {num:'10',title:'题库管理',en:'CONTENT DESK',class:'exam',desc:'核对来源、答案与解析，再将内容交给学习者。'}
  return modules.find(m => route.path === m.path || route.path.startsWith(`${m.path}/`))
})
</script>

<template>
  <!-- 主题上下文包裹层：提供主题、字号、动效等全局设置 -->
  <ThemeContext>
  <!-- Skip Link for accessibility -->
  <a href="#main-content" class="skip-link">跳转到主要内容</a>
  <header v-if="!isSession" class="site-header" :class="{'on-page':active, 'mobile-compact': !isMobileHidden, 'reader-header-hidden': route.path.startsWith('/novel/')}">
    <RouterLink v-if="detailBack" class="mobile-detail-back" :to="detailBack" aria-label="返回列表">‹</RouterLink>
    <RouterLink class="brand" to="/" aria-label="山间书院，返回首页"><img class="brand-mark" :src="yamaSeal" alt="山间书院标志"><span class="brand-name">山间书院<small>THE READING RETREAT</small></span></RouterLink>
    <nav class="desktop-nav" aria-label="主导航"><RouterLink v-for="m in modules" :key="m.path" :to="m.path">{{m.title}}</RouterLink><RouterLink to="/review">错题复习</RouterLink><RouterLink v-if="auth.user?.role==='admin'" to="/admin">题库管理</RouterLink><RouterLink to="/account">{{auth.user?.nickname || '我的账户'}}</RouterLink></nav>
    <button class="menu-button" type="button" @click="store.toggleMenu" :aria-expanded="store.menuOpen" :aria-label="store.menuOpen ? '关闭菜单' : '打开菜单'"><span></span><span></span></button>
  </header>
  <!-- 菜单侧滑层 -->
  <Transition name="mobile-menu"><div v-if="store.menuOpen && !isSession" class="menu-overlay open" @click.self="closeMenu"><div class="menu-inner" role="dialog" aria-modal="true" aria-label="探索书院"><button class="mobile-menu-close" type="button" aria-label="关闭菜单" @click="closeMenu">×</button><p class="eyebrow">EXPLORE THE RETREAT</p><RouterLink v-for="m in modules" :key="m.path" :to="m.path"><span>{{m.num}}</span>{{m.title}}<i>↗</i></RouterLink><RouterLink to="/review"><span>05</span>错题复习<i>↗</i></RouterLink><RouterLink to="/account"><span>06</span>{{ auth.user?.nickname || '我的账户' }}<i>↗</i></RouterLink><RouterLink v-if="auth.user?.role==='admin'" to="/admin"><span>07</span>题库管理<i>↗</i></RouterLink></div></div></Transition>

  <main id="main-content" class="app-main" :class="{ 'mobile-nav-space': showMobileNav }">
  <router-view v-slot="{ Component }">
    <Transition name="mobile-page" mode="out-in"><div :key="route.fullPath" class="route-stage">
    <div v-if="route.path === '/'">
      <component :is="Component" />
    </div>
    <div v-else-if="active && !isSession" class="interior" :class="[active.class, { 'mobile-content-first': mobileContentFirst, 'mobile-detail-page': mobileDetailPage, 'novel-reader': route.path.startsWith('/novel/') }]">
      <div class="interior-hero" :class="active.class">
        <div class="interior-art"><div class="interior-orb"></div><div class="interior-hill"></div></div>
        <div class="interior-head">
          <p class="eyebrow light">{{active.en}} / {{active.num}}</p>
          <h1>{{active.title}}</h1>
          <p>{{active.desc}}</p>
          <RouterLink v-if="route.path!=='/history'" class="history-link" to="/history">查看学习记录 ↗</RouterLink>
        </div>
      </div>
      <section class="interior-content section-wrap">
        <component :is="Component" />
      </section>
    </div>
    <div v-else>
      <component :is="Component" />
    </div>
    </div></Transition>
  </router-view>
  </main>

  <nav v-if="showMobileNav" class="mobile-dock" aria-label="移动端主导航">
    <RouterLink v-for="item in mobileNav" :key="item.path" :to="item.path" class="mobile-dock-item" :class="{ 'is-active': navActive(item.path) }" :aria-current="navActive(item.path) ? 'page' : undefined">
      <span class="mobile-dock-mark" aria-hidden="true">{{ item.mark }}</span><span class="mobile-dock-label">{{ item.label }}</span>
    </RouterLink>
  </nav>

  <!-- 手势视觉反馈层 -->
  <div v-if="gestureState.backArrow" class="gesture-back-arrow" :style="{opacity: gestureState.backOpacity}">
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <polyline points="15 18 9 12 15 6"></polyline>
    </svg>
  </div>
  
  <div v-if="gestureState.refreshing" class="gesture-refresh-indicator">
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.3"/>
    </svg>
  </div>
  
  <div v-if="gestureState.fontSizeHint" class="gesture-fontsize-hint">
    {{ gestureState.fontSize }}px
  </div>

  <footer v-if="!isSession" :class="{ 'mobile-auth-footer': route.path === '/account' || route.path === '/reset-password' }"><div class="footer-top"><div><img class="footer-mark" :src="yamaSeal" alt="山间书院标志"><strong>山间书院</strong><p>在文字里遇见辽阔。</p></div><div class="footer-links"><RouterLink v-for="m in modules" :key="m.path" :to="m.path">{{m.title}}</RouterLink><RouterLink to="/review">错题复习</RouterLink><RouterLink to="/account">我的账户</RouterLink></div></div><div class="footer-bottom"><span>© 2026 山间书院</span><span>READ · EXPLORE · GROW</span></div></footer>
  </ThemeContext>
</template>
