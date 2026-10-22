<script setup>
import { RouterLink } from 'vue-router'
import { onMounted, ref } from 'vue'
import { requestResource } from '../store'

const lastSession = ref(null)
const dueReviews = ref(null)
const weakPoints = ref([])

const modules = [
  { num:'01', title:'趣味阅读', en:'STORIES', path:'/novel', desc:'从一个故事开始，让好奇心带你走得更远。', class:'story', cta:'走进故事' },
  { num:'02', title:'趣味闯关', en:'CHALLENGES', path:'/fun', desc:'把知识变成一次次轻盈而有趣的探索。', class:'challenge', cta:'开启挑战' },
  { num:'03', title:'素材阅读馆', en:'LIBRARY', path:'/materials', desc:'收藏值得细读的文字，积累自己的表达。', class:'library', cta:'探索馆藏' },
  { num:'04', title:'模拟考试', en:'PRACTICE', path:'/mock-exam', desc:'在安静的练习里，遇见更从容的自己。', class:'exam', cta:'开始练习' }
]

/**
 * 加载个性化数据
 */
async function loadPersonalization() {
  try {
    // 加载最近会话 — /stats/me 不返回 lastSession，先静默获取；
    // 若后续后端扩展该字段可直接使用。
    try {
      // 检查用户是否已登录
      const authResponse = await fetch('/api/reading/auth/me', {
        credentials: 'include',
        method: 'GET'
      })
      if (!authResponse.ok) {
        console.log('用户未登录，跳过个性化数据加载')
        return
      }
      const stats = await requestResource('stats/me')
      if (stats?.lastSession) {
        lastSession.value = stats.lastSession
      }
    } catch (e) {
      console.warn('stats/me 未就绪，跳过', e)
    }

    // 加载今天到期复习 — /review/due 直接返回数组
    try {
      const reviews = await requestResource('review/due')
      if (Array.isArray(reviews) && reviews.length > 0) {
        dueReviews.value = reviews
      }
    } catch (e) {
      console.warn('review/due 未就绪，跳过', e)
    }

    // 加载薄弱点 — /stats/mistakes-detail 返回 { items, ... }
    try {
      const mistakes = await requestResource('stats/mistakes-detail')
      const list = Array.isArray(mistakes) ? mistakes : (mistakes?.items || [])
      if (list.length > 0) {
        weakPoints.value = list.slice(0, 3)
      }
    } catch (e) {
      console.warn('stats/mistakes-detail 未就绪，跳过', e)
    }
  } catch (e) {
    console.error('加载个性化数据失败:', e)
  }
}

onMounted(loadPersonalization)
</script>

<template>
  <section class="hero"><div class="hero-art"><div class="sky"></div><div class="sun"></div><div class="mountain back"></div><div class="mountain middle"></div><div class="mountain front"></div><div class="water"></div><div class="reeds reeds-left"></div><div class="reeds reeds-right"></div></div><div class="hero-shade"></div><div class="hero-copy"><p class="eyebrow light">A PLACE TO READ, A WAY TO GROW</p><h1>在文字里<br>遇见<span>辽阔</span></h1><p>让阅读慢下来，让想象走得更远。</p><a href="#explore" class="text-link light-link">开启探索 <span>↗</span></a></div><div class="hero-bottom">读一页书，走一段路。<span>山间书院 · THE READING RETREAT</span></div></section>
  
  <!-- 个性化推荐区域 - 最上方 -->
  <section class="personalized section-wrap" v-if="lastSession || dueReviews || weakPoints.length > 0">
    <div class="section-top"><p class="eyebrow">FOR YOU</p><span>个性化推荐</span></div>
    <div class="personalized-grid">
      <!-- 继续上次练习 -->
      <RouterLink v-if="lastSession" :to="'/sessions/' + lastSession.id" class="personal-card continue">
        <div class="card-icon">↻</div>
        <div class="card-content">
          <h3>继续上次练习</h3>
          <p>上次完成了 {{ lastSession.correctCount }} / {{ lastSession.totalQuestions }} 题</p>
          <span class="card-cta">继续学习 <b>—</b></span>
        </div>
      </RouterLink>
      
      <!-- 今天到期复习 -->
      <RouterLink v-if="dueReviews" to="/practice" class="personal-card review">
        <div class="card-icon">✓</div>
        <div class="card-content">
          <h3>今天到期复习</h3>
          <p>有 {{ dueReviews.length }} 个知识点需要复习</p>
          <span class="card-cta">开始复习 <b>—</b></span>
        </div>
      </RouterLink>
      
      <!-- 薄弱点推荐 -->
      <div v-if="weakPoints.length > 0" class="personal-card weak">
        <div class="card-icon">△</div>
        <div class="card-content">
          <h3>薄弱点推荐</h3>
          <div class="weak-list">
            <span v-for="(point, idx) in weakPoints" :key="idx" class="weak-item">
              {{ point.knowledgePoint || point.type }}
            </span>
          </div>
          <RouterLink to="/stats" class="card-cta">查看详情 <b>—</b></RouterLink>
        </div>
      </div>
    </div>
  </section>
  
  <!-- Intro section -->
  <section class="intro section-wrap"><div class="intro-heading"><p class="eyebrow">AN INVITATION TO EXPLORE</p><h2>在好奇心里，<br><em>找到自己的节奏。</em></h2></div><div class="intro-body"><span class="line"></span><p>故事、游戏、素材与练习，是通向阅读的四条小径。无论你从哪里出发，都可以在这里停一停，看见新的风景。</p><span class="seal">讀<br>·<br>想</span></div></section>
  
  <section id="explore" class="explore section-wrap"><div class="section-top"><p class="eyebrow">FOUR WAYS TO BEGIN</p><span>01 — 04</span></div><div class="explore-title"><h2>循着兴趣，<em>向前走。</em></h2><p>选择一条小径，开始今天的探索。</p></div><div class="module-grid"><RouterLink v-for="m in modules" :key="m.path" :to="m.path" class="module-card" :class="m.class"><div class="card-visual"><div class="card-orb"></div><div class="card-shape"></div><div class="card-symbol">{{m.num}}</div></div><div class="card-info"><div class="card-top"><span>{{m.en}}</span><span>↗</span></div><h3>{{m.title}}</h3><p>{{m.desc}}</p><span class="card-cta">{{m.cta}} <b>—</b></span></div></RouterLink></div></section>
  <section class="quote"><div class="quote-landscape"><div class="quote-hill"></div></div><div class="quote-content"><p class="eyebrow">A MOMENT TO PAUSE</p><p class="big-quote">\"每一次翻页，<br>都是一次新的出发。\"</p><p>留一点时间给阅读，也留一点空间给自己。</p><RouterLink to="/novel" class="text-link">从故事开始 <span>↗</span></RouterLink></div></section>
</template>

<style scoped>
.personalized {
  padding: 60px 5.7%;
  background: #f5f2e9;
}

.personalized-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
  margin-top: 40px;
}

.personal-card {
  background: #fffdf8;
  padding: 32px;
  border: 1px solid #e3e0d4;
  transition: all 0.3s ease;
  display: flex;
  gap: 20px;
  align-items: flex-start;
}

.personal-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px -12px rgba(37, 99, 235, 0.15);
  border-color: #2563EB;
}

.card-icon {
  width: 48px;
  height: 48px;
  background: #2563EB;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  flex-shrink: 0;
}

.personal-card.review .card-icon {
  background: #059669;
}

.personal-card.weak .card-icon {
  background: #d97706;
}

.card-content h3 {
  font: 18px 'Zen Kaku Gothic New', sans-serif;
  color: #27302b;
  margin: 0 0 12px;
}

.card-content p {
  font-size: 13px;
  line-height: 1.8;
  color: #5f6b60;
  margin: 0 0 16px;
}

.weak-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 16px;
}

.weak-item {
  font-size: 12px;
  padding: 6px 12px;
  background: #f5f2e9;
  border: 1px solid #e3e0d4;
  border-radius: 4px;
  color: #5f6b60;
}

.card-cta {
  font-size: 12px;
  color: #2563EB;
  letter-spacing: 0.08em;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.card-cta b {
  transition: transform 0.3s ease;
}

.personal-card:hover .card-cta b {
  transform: translateX(4px);
}

@media (max-width: 968px) {
  .personalized-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .personalized {
    padding: 40px 5.7%;
  }
  
  .personal-card {
    padding: 24px;
  }
}
</style>
