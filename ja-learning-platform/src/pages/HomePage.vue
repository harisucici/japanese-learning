<script setup>
import { RouterLink } from 'vue-router'
import { onMounted, onUnmounted, ref } from 'vue'
import { requestResource } from '../store'

const lastSession = ref(null)
const dueReviews = ref(null)
const weakPoints = ref([])
const loading = ref(true)

const scrollY = ref(0)
const handleScroll = () => {
  scrollY.value = window.scrollY
}

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
  loading.value = true
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
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadPersonalization()
  window.addEventListener('scroll', handleScroll, { passive: true })
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
})
</script>

<template>
  <section class="hero" :style="{ transform: `translateY(${scrollY * 0.25}px)` }"><div class="hero-art"><div class="sky"></div><div class="sun"></div><div class="mountain back"></div><div class="mountain middle"></div><div class="mountain front"></div><div class="water"></div><div class="reeds reeds-left"></div><div class="reeds reeds-right"></div></div><div class="hero-shade"></div><div class="hero-copy"><p class="eyebrow light">A PLACE TO READ, A WAY TO GROW</p><h1>在文字里<br>遇见<span>辽阔</span></h1><p>让阅读慢下来，让想象走得更远。</p><a href="#explore" class="text-link light-link">开启探索 <span>↗</span></a></div><div class="hero-bottom">读一页书，走一段路。<span>山间书院 · THE READING RETREAT</span></div></section>
  
  <!-- 骨架屏：加载完成前显示 -->
  <div v-if="loading" class="mobile-skeleton section-wrap" aria-hidden="true">
    <div class="skeleton-hero-section">
      <div class="skeleton skeleton-hero-title"></div>
      <div class="skeleton skeleton-hero-subtitle"></div>
      <div class="skeleton skeleton-hero-cta"></div>
    </div>
    <div class="skeleton-modules-grid">
      <div class="skeleton skeleton-module-card"></div>
      <div class="skeleton skeleton-module-card"></div>
      <div class="skeleton skeleton-module-card"></div>
      <div class="skeleton skeleton-module-card"></div>
    </div>
    <div class="skeleton-recommend-list">
      <div class="skeleton skeleton-recommend-card"></div>
      <div class="skeleton skeleton-recommend-card"></div>
      <div class="skeleton skeleton-recommend-card"></div>
    </div>
  </div>

  <!-- 个性化推荐区域 - 最上方 -->
  <Transition name="skeleton-fade">
  <section v-if="!loading && (lastSession || dueReviews || weakPoints.length > 0)" class="personalized section-wrap">
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
  </Transition>
  
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

/* ===== Tablet: personalized single column ===== */
@media (max-width: 968px) {
  .personalized-grid {
    grid-template-columns: 1fr;
  }
}

/* ===== Mobile overrides (≤ 640px) =====
 * Override style.css global rules so the page
 * works well on small screens. Scoped selectors
 * carry [data-v-*] and beat the bare global rules. */
@media (max-width: 640px) {
  /* ---- Hero: compact banner, big CTA ---- */
  .hero {
    min-height: 360px !important;
    height: 54svh !important;
  }

  /* Fade landscape art so CTA + title stay readable */
  .hero-art {
    opacity: 0.35;
  }
  .sun { display: none; }
  .reeds { display: none; }

  .hero-copy {
    left: 6% !important;
    right: 6%;
    top: 50% !important;
    transform: translateY(-50%);
  }
  .hero-copy > .eyebrow,
  .hero-copy h1,
  .hero-copy > p:not(.eyebrow) {
    top: 0 !important;
  }
  .hero-copy h1 {
    font-size: clamp(32px, 6vw, 48px) !important;
    letter-spacing: 0.08em !important;
    margin: 12px 0 14px !important;
  }
  /* Hide subtitle on mobile to save vertical space */
  .hero-copy > p:not(.eyebrow) {
    display: none;
  }
  /* CTA becomes a full-width touch-friendly button */
  .hero-copy .text-link {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 100%;
    max-width: 360px;
    height: 52px;
    margin-top: 18px;
    padding: 0 24px;
    gap: 12px;
    background: rgba(255, 255, 255, 0.14);
    border: 1px solid #fff;
    border-radius: 10px;
    font-size: 14px;
    letter-spacing: 0.12em;
    top: 0 !important;
  }
  .hero-copy .text-link span {
    font-size: 18px;
  }
  .hero-bottom {
    left: 6% !important;
    right: 6% !important;
    font-size: 12px;
  }

  /* ---- Skeleton mobile ---- */
  .mobile-skeleton {
    padding: 32px 5.7%;
  }
  .skeleton-hero-section {
    margin-bottom: 32px;
  }

  /* ---- Intro: tighten spacing ---- */
  .intro {
    padding: 32px 0 !important;
  }

  /* ---- Explore + module grid: 2x2, touch-friendly cards ---- */
  .explore {
    padding: 20px 0 60px !important;
  }
  .module-grid {
    grid-template-columns: repeat(2, 1fr) !important;
    gap: 12px !important;
  }
  .module-card {
    min-height: 120px;
    border-radius: 10px;
    overflow: hidden;
    transition: transform 0.3s var(--ease-spring), box-shadow 0.3s var(--ease-smooth);
  }
  .module-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 12px 24px -8px rgba(0, 0, 0, 0.15);
  }
  .module-card:active {
    transform: scale(0.97);
  }
  .module-card .card-visual {
    height: 72px !important;
  }
  .module-card .card-orb {
    width: 90px;
    height: 90px;
    top: 18%;
  }
  .module-card .card-symbol {
    font-size: 36px;
    bottom: 8px;
    right: 12px;
  }
  .module-card .card-info {
    padding: 14px 14px 16px;
  }
  .module-card .card-info h3 {
    font-size: 15px;
    margin: 4px 0 6px;
  }
  /* Hide long description on mobile cards; keep icon + title + CTA */
  .module-card .card-info p {
    display: none;
  }
  .module-card .card-top {
    font-size: 12px;
  }
  .module-card .card-cta {
    font-size: 12px;
    margin-top: 4px;
  }
  
  /* Spring 动画和触控反馈 */
  .module-card {
    transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1), 
                box-shadow 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  }
  .module-card:active {
    transform: scale(0.97);
  }
  
  .text-link {
    transition: color 0.2s cubic-bezier(0.34, 1.56, 0.64, 1),
                transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1);
  }
  .text-link:active {
    transform: scale(0.97);
  }

  /* ---- Personalized section ---- */
  .personalized {
    padding: 40px 5.7%;
  }
  .personalized-grid {
    grid-template-columns: 1fr !important;
    gap: 14px;
  }
  .personal-card {
    padding: 20px;
    min-height: 120px;
    border-radius: 10px;
    transition: transform 0.3s var(--ease-spring), box-shadow 0.3s var(--ease-smooth);
  }
  .personal-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 20px -8px rgba(37, 99, 235, 0.2);
  }
  .personal-card:active {
    transform: scale(0.97);
  }
  .card-icon {
    width: 44px;
    height: 44px;
    font-size: 22px;
  }
  .card-content h3 {
    font-size: 16px;
    margin-bottom: 8px;
  }
  .card-content p {
    margin-bottom: 12px;
  }

  /* ---- Quote section ---- */
  .quote {
    padding: 56px 0;
  }
  .big-quote {
    font-size: 22px !important;
  }
}

/* ===== Very small screens (≤ 380px) ===== */
@media (max-width: 380px) {
  .hero-copy h1 {
    font-size: 30px !important;
  }
  .module-card .card-info {
    padding: 10px 10px 14px;
  }
  .module-card .card-info h3 {
    font-size: 14px;
  }
}
</style>
