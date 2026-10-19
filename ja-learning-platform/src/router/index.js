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

const routes = [
  { path: '/', component: HomePage },
  { path: '/novel', component: NovelPage },
  { path: '/novel/:id', component: NovelDetailPage },
  { path: '/fun', component: FunPage },
  { path: '/materials', component: MaterialsPage },
  { path: '/materials/:id', component: MaterialDetailPage },
  { path: '/mock-exam', component: ExamPage },
  { path: '/sessions/:id', component: SessionPage },
  { path: '/history', component: HistoryPage }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior: () => ({ top: 0 })
})

export default router
