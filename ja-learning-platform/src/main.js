import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import './style.css'

const routes = [
  { path: '/', component: App },
  { path: '/novel', component: App },
  { path: '/novel/:id', component: App },
  { path: '/fun', component: App },
  { path: '/materials', component: App },
  { path: '/materials/:id', component: App },
  { path: '/mock-exam', component: App },
  { path: '/sessions/:id', component: App },
  { path: '/history', component: App }
]
const router = createRouter({ history: createWebHistory(), routes, scrollBehavior: () => ({ top: 0 }) })
createApp(App).use(createPinia()).use(router).mount('#app')
