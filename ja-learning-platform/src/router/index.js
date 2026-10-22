import { createRouter, createWebHistory } from 'vue-router'
import HomePage from '../pages/HomePage.vue'
import NovelPage from '../pages/NovelPage.vue'
import NovelDetailPage from '../pages/NovelDetailPage.vue'
import FunPage from '../pages/FunPage.vue'
import MaterialsPage from '../pages/MaterialsPage.vue'
import MaterialDetailPage from '../pages/MaterialDetailPage.vue'
import ExamPage from '../pages/ExamPage.vue'
import SessionPage from '../pages/SessionPage.vue'
import HistoryPage from '../pages/HistoryPage.vue'
import StatsPage from '../pages/StatsPage.vue'
import PracticeModePage from '../pages/PracticeModePage.vue'
import AccountPage from '../pages/AccountPage.vue'
import ReviewPage from '../pages/ReviewPage.vue'
import AdminPage from '../pages/AdminPage.vue'
import { useAuthStore } from '../store.js'

const routes = [
  { path: '/', component: HomePage },
  { path: '/account', component: AccountPage },
  { path: '/reset-password', component: AccountPage },
  { path: '/novel', component: NovelPage, meta: { requiresAuth: true } },
  { path: '/novel/:id', component: NovelDetailPage, meta: { requiresAuth: true } },
  { path: '/fun', component: FunPage, meta: { requiresAuth: true } },
  { path: '/materials', component: MaterialsPage, meta: { requiresAuth: true } },
  { path: '/materials/:id', component: MaterialDetailPage, meta: { requiresAuth: true } },
  { path: '/mock-exam', component: ExamPage, meta: { requiresAuth: true } },
  { path: '/sessions/:id', component: SessionPage, meta: { requiresAuth: true } },
  { path: '/history', component: HistoryPage, meta: { requiresAuth: true } },
  { path: '/stats', component: StatsPage, meta: { requiresAuth: true } },
  { path: '/practice', component: PracticeModePage, meta: { requiresAuth: true } },
  { path: '/review', component: ReviewPage, meta: { requiresAuth: true } },
  { path: '/admin', component: AdminPage, meta: { requiresAuth: true } }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior: () => ({ top: 0 })
})

router.beforeEach(async (to) => {
  if (!to.meta.requiresAuth) return true
  const auth = useAuthStore()
  // 若尚未初始化过用户状态，先调用 /auth/me 确认 cookie 是否有效
  if (!auth.checked) {
    try {
      await auth.check()
    } catch {
      // check 内部已捕获异常并置 user=null，此处忽略即可
    }
  }
  if (!auth.user) {
    // 保留用户想去的目标路径，登录后方便回跳
    return { path: '/account', query: to.path === '/' ? {} : { redirect: to.fullPath } }
  }
  return true
})

export default router
