<script setup>
import { computed, watch } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import { useAppStore, useAuthStore } from './store'
import ThemeContext from './components/ThemeContext.vue'
import yamaSeal from './assets/yama-seal.png'
const route = useRoute()
const store = useAppStore()
const auth = useAuthStore()
auth.check()
watch(() => route.path, () => store.closeMenu())
const modules = [
  { num:'01', title:'趣味阅读', en:'STORIES', path:'/novel', desc:'从一个故事开始，让好奇心带你走得更远。', class:'story', cta:'走进故事' },
  { num:'02', title:'趣味闯关', en:'CHALLENGES', path:'/fun', desc:'把知识变成一次次轻盈而有趣的探索。', class:'challenge', cta:'开启挑战' },
  { num:'03', title:'素材阅读馆', en:'LIBRARY', path:'/materials', desc:'收藏值得细读的文字，积累自己的表达。', class:'library', cta:'探索馆藏' },
  { num:'04', title:'模拟考试', en:'PRACTICE', path:'/mock-exam', desc:'在安静的练习里，遇见更从容的自己。', class:'exam', cta:'开始练习' }
]
const isSession = computed(() => route.path.startsWith('/sessions/') || route.path === '/sessions' || route.path === '/stats' || route.path === '/practice')
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
  <header v-if="!isSession" class="site-header" :class="{'on-page':active}">
    <RouterLink class="brand" to="/" aria-label="山间书院，返回首页"><img class="brand-mark" :src="yamaSeal" alt=""><span class="brand-name">山间书院<small>THE READING RETREAT</small></span></RouterLink>
    <nav class="desktop-nav" aria-label="主导航"><RouterLink v-for="m in modules" :key="m.path" :to="m.path">{{m.title}}</RouterLink><RouterLink to="/review">错题复习</RouterLink><RouterLink v-if="auth.user?.role==='admin'" to="/admin">题库管理</RouterLink><RouterLink to="/account">{{auth.user?.nickname || '我的账户'}}</RouterLink></nav>
    <button class="menu-button" type="button" @click="store.toggleMenu" :aria-expanded="store.menuOpen" aria-label="打开菜单"><span></span><span></span></button>
  </header>
  <div v-if="store.menuOpen && !isSession" class="menu-overlay"><div class="menu-inner"><p class="eyebrow">EXPLORE THE RETREAT</p><RouterLink v-for="m in modules" :key="m.path" :to="m.path"><span>{{m.num}}</span>{{m.title}}<i>↗</i></RouterLink><RouterLink to="/review"><span>05</span>错题复习<i>↗</i></RouterLink><RouterLink to="/account"><span>06</span>我的账户<i>↗</i></RouterLink><RouterLink v-if="auth.user?.role==='admin'" to="/admin"><span>07</span>题库管理<i>↗</i></RouterLink></div></div>

  <router-view v-slot="{ Component }">
    <div v-if="route.path === '/'">
      <component :is="Component" />
    </div>
    <div v-else-if="active && !isSession" class="interior" :class="active.class">
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
  </router-view>

  <footer v-if="!isSession"><div class="footer-top"><div><img class="footer-mark" :src="yamaSeal" alt=""><strong>山间书院</strong><p>在文字里遇见辽阔。</p></div><div class="footer-links"><RouterLink v-for="m in modules" :key="m.path" :to="m.path">{{m.title}}</RouterLink><RouterLink to="/review">错题复习</RouterLink><RouterLink to="/account">我的账户</RouterLink></div></div><div class="footer-bottom"><span>© 2026 山间书院</span><span>READ • EXPLORE • GROW</span></div></footer>
  </ThemeContext>
</template>
