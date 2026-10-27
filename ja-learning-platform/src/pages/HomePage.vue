<script setup>
import { RouterLink } from 'vue-router'
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { requestResource } from '../store'

const lastSession = ref(null)
const dueReviews = ref(null)
const weakPoints = ref([])
const loading = ref(true)
const weakTypeLabels = { vocabulary: '词汇', kanji: '汉字', grammar: '语法', reading: '阅读', listening: '听力' }
const mobileWeakLabels = computed(() => [...new Set(weakPoints.value.map(point => {
  const name = point.knowledgePoint || point.type || '待复习'
  return weakTypeLabels[name] || name
}))].slice(0, 3))

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
      try {
        await requestResource('auth/me')
      } catch (e) {
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
  <div class="home-page">
  <section class="hero" :style="{ transform: `translateY(${scrollY * 0.25}px)` }"><div class="hero-art"><div class="sky"></div><div class="sun"></div><div class="mountain back"></div><div class="mountain middle"></div><div class="mountain front"></div><div class="water"></div><div class="reeds reeds-left"></div><div class="reeds reeds-right"></div></div><div class="hero-shade"></div><div class="hero-copy"><p class="eyebrow light">A PLACE TO READ, A WAY TO GROW</p><h1>在文字里<br>遇见<span>辽阔</span></h1><p>让阅读慢下来，让想象走得更远。</p><a href="#explore" class="text-link light-link">开启探索 <span>↗</span></a></div><div class="hero-bottom">读一页书，走一段路。<span>山間の書院 · THE READING RETREAT</span></div></section>
  
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
            <span v-for="(point, idx) in weakPoints" :key="idx" class="weak-item desktop-weak-item">
              {{ point.knowledgePoint || point.type }}
            </span>
            <span v-for="label in mobileWeakLabels" :key="label" class="weak-item mobile-weak-item">{{ label }}</span>
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
  </div>
</template>

<style scoped>
.home-page { display: contents; }
.mobile-weak-item { display: none; }
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
  font: 18px var(--app-font-family);
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
    min-height: 280px !important;
    height: 280px !important;
    max-height: 280px !important;
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
    display: none;
  }

  /* ---- Explore + module grid: 2x2, touch-friendly cards ---- */
  .explore {
    padding: 12px 0 28px !important;
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
    padding: 10px 10px 12px;
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
    padding: 18px 5.7%;
  }
  .personalized-grid {
    grid-template-columns: 1fr !important;
    gap: 8px;
  }
  .personal-card {
    padding: 12px;
    min-height: 76px;
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
    width: 36px;
    height: 36px;
    font-size: 18px;
  }
  .card-content h3 {
    font-size: 15px;
    margin-bottom: 3px;
  }
  .card-content p {
    margin-bottom: 3px;
  }
  .personal-card .card-cta { border: 0; margin: 3px 0 0; padding: 0; }
  .personal-card .weak-list { gap: 4px; margin-bottom: 3px; }
  .personal-card .weak-item { padding: 3px 7px; }

  /* ---- Quote section ---- */
  .quote {
    display: none;
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

@media (max-width: 640px) {
  .hero { min-height: 212px !important; height: 212px !important; max-height: 212px !important; }
  .hero-art { opacity: .52; }
  .hero-copy { top: 57% !important; }
  .hero-copy > .eyebrow { font-size: 9px; }
  .hero-copy h1 { font-size: 29px !important; line-height: 1.25; margin: 7px 0 8px !important; }
  .hero-copy .text-link { width: auto; max-width: none; height: 36px; min-height: 36px; display: inline-flex; margin-top: 8px; padding: 0 15px; border-radius: 999px; font-size: 11px; background: #fffdf81f; }
  .personalized { padding: 14px 5% 4px !important; }
  .personalized .section-top { padding-bottom: 8px; }
  .personalized-grid { margin-top: 8px !important; }
  .personal-card { min-height: 64px; padding: 10px 12px !important; align-items: center; border-radius: 12px; }
  .personal-card .card-icon { width: 32px; height: 32px; }
  .personal-card .card-content h3 { font-size: 14px; }
  .personal-card .card-content p { font-size: 11px; line-height: 1.4; }
  .personal-card .card-cta { font-size: 11px; }
  .personal-card .weak-list { max-height: 24px; overflow: hidden; }
  .explore { padding: 12px 0 18px !important; }
  .explore-title { margin: 10px 0 12px !important; }
  .explore-title h2 { font-size: 22px; margin: 0; }
  .explore-title p { display: none; }
  .module-grid { gap: 8px !important; }
  .module-card { padding: 7px !important; border-radius: 13px; }
  .module-card .card-visual { height: 55px !important; border-radius: 8px; }
  .module-card .card-orb { width: 70px; height: 70px; }
  .module-card .card-symbol { font-size: 27px; }
  .module-card .card-info { padding: 7px 3px 3px; }
  .module-card .card-top { font-size: 9px; }
  .module-card .card-info h3 { font-size: 14px; margin: 3px 0 0; }
  .module-card .card-cta { margin-top: 4px; padding-top: 3px; font-size: 10px; }
}

/* Mobile shikishi: keep the original landscape, refine its color and motion. */
@media (max-width: 640px) {
  .hero { background: #233d36; }
  .hero-art { opacity: .78; filter: saturate(.52) sepia(.08); }
  .hero-shade { background: linear-gradient(90deg, #172b26bb 0%, #172b2680 54%, #172b2600 100%) !important; }
  .hero-copy h1 { font-weight: 500; letter-spacing: .14em !important; text-shadow: 0 2px 14px #13271f55; }
  .hero-copy .text-link { background: #f6f1e8ee; color: #28453b !important; border-color: #f6f1e8ee; box-shadow: 0 5px 14px #152b2040; font-weight: 600; }
  .hero-copy .text-link:active { background: #e5d6b9; transform: scale(.94); }

  .personalized, .explore { background: #f2eee4; }
  .personalized .section-top, .explore .section-top { border-color: #b9aa8d80; }
  .personalized .eyebrow, .explore .eyebrow { color: #86694d; }
  .personal-card { background: #faf7ef; border: 1px solid #cbbfa98c; box-shadow: 0 5px 18px #283a2a0c; }
  .personal-card .card-icon { background: #3b5c4a; border: 1px solid #e3dfce80; box-shadow: inset 0 0 0 2px #ffffff30; }
  .personal-card.weak .card-icon { background: #957044; }
  .personal-card .card-content h3 { color: #2e4236; font-weight: 600; }
  .personal-card .card-cta { color: #4a6954; }
  .personal-card .weak-item { background: #ece6da; border-color: #d5c9b8; color: #6d5c4d; }

  .explore-title h2 { font-weight: 500; color: #263c32; letter-spacing: .07em; }
  .explore-title h2 em { color: #8b6f55; font-style: normal; }
  .module-grid { perspective: 900px; }
  .module-card {
    --card-accent: #8a6e55;
    position: relative;
    opacity: 1;
    transform: none;
    background: #fbf8f0;
    border: 1px solid #b7aa91a8;
    border-radius: 7px !important;
    box-shadow: 0 3px 0 #d4c7ae80, 0 9px 20px #26382a12;
    overflow: hidden;
    animation: shikishi-enter .65s cubic-bezier(.2,.8,.25,1) backwards;
    transition: transform .34s cubic-bezier(.22,1,.36,1), box-shadow .34s cubic-bezier(.22,1,.36,1), border-color .25s;
  }
  .module-card:nth-child(2) { animation-delay: .11s; }
  .module-card:nth-child(3) { animation-delay: .22s; }
  .module-card:nth-child(4) { animation-delay: .33s; }
  .module-card.story { --card-accent: #9a6876; --landscape-sky: linear-gradient(135deg,#efe9e2,#d4aeb8); --landscape-hill:#896875; --landscape-sun:#f5e9dd; }
  .module-card.challenge { --card-accent: #597c67; --landscape-sky: linear-gradient(135deg,#e9eee3,#a8c4ad); --landscape-hill:#4e7363; --landscape-sun:#f4e8ca; }
  .module-card.library { --card-accent: #9a7652; --landscape-sky: linear-gradient(135deg,#f3ead8,#d7b78c); --landscape-hill:#96765b; --landscape-sun:#f9edce; }
  .module-card.exam { --card-accent: #64818a; --landscape-sky: linear-gradient(135deg,#edf1ec,#b0c9c8); --landscape-hill:#637f87; --landscape-sun:#f5f2df; }
  .module-card::before { content: ''; position: absolute; z-index: 3; top: 0; left: 0; width: 100%; height: 2px; background: var(--card-accent); transform-origin: left; animation: shikishi-line .75s cubic-bezier(.22,1,.36,1) .4s both; }
  .module-card .card-visual { height: 78px !important; border-radius: 3px 3px 0 0; isolation: isolate; filter: saturate(.75); }
  .module-card .card-visual::after { content: ''; position: absolute; z-index: 1; inset: 0; background: linear-gradient(105deg,transparent 15%,#fffdf851 48%,transparent 75%); transform: translateX(-120%); animation: shikishi-mist 8s ease-in-out infinite; }
  .module-card .card-orb { width: 64px; height: 64px; top: 2px; opacity: .72; animation: shikishi-sun 5.5s ease-in-out infinite alternate; }
  .module-card .card-shape { inset: 48% -20% -20%; animation: shikishi-hill 9s ease-in-out infinite alternate; }
  .module-card .card-symbol { z-index: 2; right: 9px; bottom: 4px; font-size: 29px; color: #fff9e9a8; transition: transform .4s cubic-bezier(.22,1,.36,1), opacity .4s; }
  .module-card .card-info { padding: 9px 8px 8px; }
  .module-card .card-top { color: var(--card-accent); font-size: 9px; font-weight: 600; }
  .module-card .card-top span:last-child { font-size: 15px; transition: transform .3s; }
  .module-card .card-info h3 { font-weight: 600; color: #273a30; font-size: 14px; letter-spacing: .02em; }
  .module-card .card-cta { display: flex; justify-content: space-between; align-items: center; color: var(--card-accent); border-top: 1px solid #b9ad9680; letter-spacing: .08em; }
  .module-card:hover, .module-card:focus-visible { transform: translateY(-5px) rotate(-.6deg); border-color: var(--card-accent); box-shadow: 0 6px 0 #d0c2aa80, 0 16px 30px #26382a23; }
  .module-card:hover .card-symbol, .module-card:focus-visible .card-symbol { transform: translateY(-6px) scale(1.18); }
  .module-card:hover .card-top span:last-child, .module-card:focus-visible .card-top span:last-child { transform: translate(3px,-3px); }
  .module-card:active { transform: translateY(2px) scale(.955) rotate(.5deg) !important; box-shadow: 0 1px 0 #d0c2aa80, inset 0 2px 12px #26382a19; }
  .module-card:active .card-visual { filter: saturate(1.05) brightness(.92); }
  @keyframes shikishi-enter { from { opacity: 0; transform: translateY(22px) rotate(2deg) scale(.96); } to { opacity: 1; transform: translateY(0) rotate(0) scale(1); } }
  @keyframes shikishi-line { from { transform: scaleX(0); } to { transform: scaleX(1); } }
  @keyframes shikishi-mist { 0%,20% { transform: translateX(-120%); opacity: 0; } 42% { opacity: .7; } 65%,100% { transform: translateX(130%); opacity: 0; } }
  @keyframes shikishi-sun { to { transform: translateX(-50%) translateY(5px) scale(1.09); opacity: .95; } }
  @keyframes shikishi-hill { to { transform: rotate(-9deg) translateX(-5px); } }
}

@media (max-width: 640px) and (prefers-reduced-motion: reduce) {
  .module-card, .module-card::before, .module-card .card-visual::after, .module-card .card-orb, .module-card .card-shape { animation: none !important; }
}

@media (max-width: 640px) {
  :root[data-theme="dark"] .personalized, :root[data-theme="dark"] .explore { background: #121e19; }
  :root[data-theme="dark"] .personal-card, :root[data-theme="dark"] .module-card { background: #1d2a23; border-color: #516053; }
  :root[data-theme="dark"] .personal-card .card-content h3, :root[data-theme="dark"] .explore-title h2, :root[data-theme="dark"] .module-card .card-info h3 { color: #ebe8db; }
  :root[data-theme="dark"] .personal-card .card-cta, :root[data-theme="dark"] .module-card .card-cta { color: #c7ad87; }
  :root[data-theme="dark"] .module-card .card-visual { filter: saturate(.55) brightness(.8); }
}

@media (max-width: 640px) {
  .home-page { display: flex; flex-direction: column; min-width: 0; }
  .desktop-weak-item { display: none; }
  .mobile-weak-item { display: inline-flex; }
  .hero { order: 0; width: 100%; transform: none !important; }
  .hero-copy .text-link { height: 44px; min-height: 44px; }
  .mobile-skeleton { display: none !important; }
  .explore { order: 1; width: 90%; margin: 0 auto; padding: 18px 0 8px !important; }
  .explore .section-top { display: none; }
  .explore-title { margin: 0 0 13px !important; }
  .explore-title h2 { font-size: 21px; line-height: 1.3; }
  .module-grid { gap: 9px !important; }
  .module-card { min-height: 0 !important; padding: 6px !important; }
  .module-card .card-visual { height: 72px !important; }
  .module-card .card-info { padding: 8px 5px 5px; }
  .module-card .card-info h3 { font-size: 15px; margin: 4px 0 0; }
  .module-card .card-cta { margin-top: 7px; padding-top: 6px; font-size: 11px; }
  .personalized { order: 2; width: 100%; margin: 18px 0 0; padding: 16px 5% 20px !important; border-top: 1px solid #b9aa8d80; }
  .personalized .section-top { border: 0; padding-top: 0; padding-bottom: 8px; }
  .personalized-grid { margin-top: 2px !important; }
  .intro { order: 3; }
  .quote { order: 4; }
}
</style>
