<script setup>
/**
 * 练习模式入口页面
 * 提供多种练习方式：按题型、按语法、错题重练、随机练习
 */
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useLearningStore } from '../store'

const router = useRouter()
const api = useLearningStore()
const loading = ref(false)
const error = ref('')

// 随机练习设置
const randomLevel = ref('n5')
const randomCount = ref(10)

async function startByType(type) {
  loading.value = true
  error.value = ''
  try {
    await api.ensureGuest()
    const session = await api.request('sessions', { 
      level: 'n5', 
      mode: 'practice', 
      type: type === 'vocab' ? 'vocabulary' : type === 'listening' ? 'listening' : type === 'reading' ? 'reading' : 'grammar' 
    }, true)
    router.push(`/sessions/${session.id}`)
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function startByGrammar(grammarId) {
  loading.value = true
  error.value = ''
  try {
    await api.ensureGuest()
    const session = await api.request('sessions', { 
      level: 'n5', 
      mode: 'practice', 
      type: 'grammar', 
      grammarId: grammarId 
    }, true)
    router.push(`/sessions/${session.id}`)
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function startMistakes() {
  loading.value = true
  error.value = ''
  try {
    await api.ensureGuest()
    router.push('/review')
    return
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function startRandom() {
  loading.value = true
  error.value = ''
  try {
    await api.ensureGuest()
    const session = await api.request('sessions', { 
      level: randomLevel.value, 
      mode: 'practice',
      limit: randomCount.value
    }, true)
    router.push(`/sessions/${session.id}`)
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

const questionTypes = [
  { id: 'vocab', name: '词汇', desc: '单词、读音、用法', icon: '辞' },
  { id: 'grammar', name: '语法', desc: '句型、助词、接续', icon: '文' },
  { id: 'reading', name: '阅读', desc: '短文、长文理解', icon: '読' },
  { id: 'listening', name: '听力', desc: '对话、新闻理解', icon: '聴' }
]

const grammarCategories = [
  { id: 'particles', name: '助词', desc: 'は、が、を、に、で...' },
  { id: 'conjugation', name: '动词变形', desc: 'ます形、て形、た形...' },
  { id: 'adjectives', name: '形容词', desc: 'い形容词、な形容词' },
  { id: 'patterns', name: '句型', desc: '～たい、～なければならない...' }
]
</script>

<template>
  <div class="practice-page mob-practice">
    <section class="hero-simple">
      <div class="hero-copy">
        <p class="eyebrow light">PRACTICE MODE</p>
        <h1>练习模式</h1>
        <p>选择适合你的练习方式</p>
      </div>
    </section>

    <section class="practice-main section-wrap">
      <!-- 骨架屏 -->
      <div v-if="loading" class="practice-skeleton">
        <div v-for="i in 3" :key="i" class="skeleton-practice-card"></div>
      </div>
      <div v-else-if="error" class="state-box error">{{ error }}</div>
      <template v-else>
        <!-- 按题型练习 -->
        <h2 class="section-title">按题型练习</h2>
        <p class="section-desc">选择你想练习的题型，系统会为你生成对应的题目</p>
      <div class="mob-type-grid">
        <button 
          v-for="type in questionTypes" 
          :key="type.id" 
          class="mob-type-card"
          @click="startByType(type.id)"
          :disabled="loading"
        >
          <div class="type-icon">{{ type.icon }}</div>
          <div class="type-info">
            <h3>{{ type.name }}</h3>
            <p>{{ type.desc }}</p>
          </div>
          <span class="type-arrow">→</span>
        </button>
      </div>

      <!-- 按语法练习 -->
      <h2 class="section-title">按语法练习</h2>
      <p class="section-desc">针对特定语法点进行专项练习</p>
      <div class="mob-grammar-grid">
        <button 
          v-for="grammar in grammarCategories" 
          :key="grammar.id" 
          class="mob-grammar-card"
          @click="startByGrammar(grammar.id)"
          :disabled="loading"
        >
          <h3>{{ grammar.name }}</h3>
          <p>{{ grammar.desc }}</p>
          <span class="grammar-arrow">开始练习 →</span>
        </button>
      </div>

      <!-- 错题重练 -->
      <h2 class="section-title">错题重练</h2>
      <p class="section-desc">重新练习之前做错的题目，巩固薄弱点</p>
      <button class="mob-mistakes-btn" @click="startMistakes" :disabled="loading">
        <div class="mistakes-icon">△</div>
        <div class="mistakes-info">
          <h3>错题重练</h3>
          <p>系统会根据你的错题记录生成练习</p>
        </div>
        <span class="mistakes-arrow">开始练习 →</span>
      </button>

      <!-- 随机练习 -->
      <h2 class="section-title">随机练习</h2>
      <p class="section-desc">设置等级和数量，开始随机练习</p>
      <div class="mob-random-settings">
        <div class="mob-setting-group">
          <label>难度等级</label>
          <select v-model="randomLevel" :disabled="loading">
            <option value="n5">N5 - 入门</option>
            <option value="n4">N4 - 基础</option>
            <option value="n3">N3 - 中级</option>
            <option value="n2">N2 - 中高级</option>
            <option value="n1">N1 - 高级</option>
          </select>
        </div>
        <div class="mob-setting-group">
          <label>题目数量</label>
          <select v-model="randomCount" :disabled="loading">
            <option :value="5">5 题</option>
            <option :value="10">10 题</option>
            <option :value="15">15 题</option>
            <option :value="20">20 题</option>
            <option :value="30">30 题</option>
          </select>
        </div>
        <button class="mob-random-start" @click="startRandom" :disabled="loading">
          开始随机练习 →
        </button>
      </div>
      </template>

      <div v-if="loading" class="loading-overlay">
        <div class="loading-text">正在生成练习…</div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.hero-simple {
  height: 240px;
  position: relative;
  overflow: hidden;
  background: #536b69;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
}

.hero-copy {
  padding: 0 20px;
}

.hero-copy h1 {
  font-size: 28px;
  margin: 8px 0;
}

.hero-copy p {
  font-size: 14px;
  opacity: 0.9;
}

.practice-main {
  padding: 40px 20px;
  max-width: 640px;
  margin: 0 auto;
}

.section-title {
  font: 600 20px var(--app-font-family);
  margin: 0 0 8px;
  color: #27302b;
}

.section-desc {
  font-size: 14px;
  line-height: 1.7;
  color: #67746a;
  margin: 0 0 24px;
}

/* 题型卡片 - 单列，120px 高 */
.mob-type-grid {
  display: flex;
  flex-direction: column;
  gap: 14px;
  margin-bottom: 40px;
}

.mob-type-card {
  background: #fffdf8;
  padding: 20px 24px;
  border: 1px solid #e3e0d4;
  border-radius: 12px;
  display: flex;
  align-items: center;
  gap: 16px;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  text-align: left;
  min-height: 120px;
  touch-action: manipulation;
}

.mob-type-card:hover:not(:disabled) {
  border-color: #2563EB;
  box-shadow: 0 4px 12px -4px rgba(37, 99, 235, 0.15);
}

.mob-type-card:active:not(:disabled) {
  transform: scale(0.97);
}

.mob-type-card:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.type-icon {
  width: 52px;
  height: 52px;
  background: #2563EB;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font: 24px var(--app-font-family);
  flex-shrink: 0;
}

.type-info {
  flex: 1;
  min-width: 0;
}

.type-info h3 {
  font: 600 16px var(--app-font-family);
  color: #27302b;
  margin: 0 0 6px;
}

.type-info p {
  font-size: 13px;
  color: #67746a;
  margin: 0;
  line-height: 1.5;
}

.type-arrow {
  font-size: 20px;
  color: #2563EB;
  flex-shrink: 0;
}

/* 语法卡片 - 单列 */
.mob-grammar-grid {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 40px;
}

.mob-grammar-card {
  background: #fffdf8;
  padding: 20px 24px;
  border: 1px solid #e3e0d4;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  text-align: left;
  touch-action: manipulation;
}

.mob-grammar-card:hover:not(:disabled) {
  border-color: #059669;
  box-shadow: 0 4px 12px -4px rgba(5, 150, 105, 0.15);
}

.mob-grammar-card:active:not(:disabled) {
  transform: scale(0.97);
}

.mob-grammar-card:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.mob-grammar-card h3 {
  font: 600 16px var(--app-font-family);
  color: #27302b;
  margin: 0 0 6px;
}

.mob-grammar-card p {
  font-size: 13px;
  color: #67746a;
  line-height: 1.5;
  margin: 0 0 10px;
}

.grammar-arrow {
  font-size: 13px;
  color: #059669;
  letter-spacing: 0.03em;
}

/* 错题重练按钮 */
.mob-mistakes-btn {
  width: 100%;
  background: #fffdf8;
  padding: 20px 24px;
  border: 1px solid #e3e0d4;
  border-radius: 12px;
  display: flex;
  align-items: center;
  gap: 16px;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  text-align: left;
  margin-bottom: 40px;
  touch-action: manipulation;
}

.mob-mistakes-btn:hover:not(:disabled) {
  border-color: #d97706;
  box-shadow: 0 4px 12px -4px rgba(217, 119, 6, 0.15);
}

.mob-mistakes-btn:active:not(:disabled) {
  transform: scale(0.97);
}

.mob-mistakes-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.mistakes-icon {
  width: 52px;
  height: 52px;
  background: #d97706;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  flex-shrink: 0;
}

.mistakes-info {
  flex: 1;
  min-width: 0;
}

.mistakes-info h3 {
  font: 600 16px var(--app-font-family);
  color: #27302b;
  margin: 0 0 6px;
}

.mistakes-info p {
  font-size: 13px;
  color: #67746a;
  margin: 0;
}

.mistakes-arrow {
  font-size: 13px;
  color: #d97706;
  letter-spacing: 0.03em;
  flex-shrink: 0;
}

/* 随机练习设置 */
.mob-random-settings {
  background: #fffdf8;
  padding: 24px;
  border: 1px solid #e3e0d4;
  border-radius: 12px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.mob-setting-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.mob-setting-group label {
  font: 500 14px var(--app-font-family);
  color: #27302b;
}

.mob-setting-group select {
  width: 100%;
  padding: 14px 16px;
  border: 1px solid #c9c9bd;
  border-radius: 10px;
  background: #fff;
  font: 15px var(--app-font-family);
  color: #27302b;
  cursor: pointer;
  min-height: 48px;
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%2367746a' d='M6 8L1 3h10z'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 16px center;
  padding-right: 40px;
}

.mob-setting-group select:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.mob-random-start {
  width: 100%;
  padding: 16px;
  background: #2563EB;
  color: white;
  border: none;
  border-radius: 12px;
  font: 600 15px var(--app-font-family);
  letter-spacing: 0.06em;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  min-height: 48px;
  touch-action: manipulation;
}

.mob-random-start:hover:not(:disabled) {
  background: #1d4ed8;
}

.mob-random-start:active:not(:disabled) {
  transform: scale(0.97);
}

.mob-random-start:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(245, 242, 233, 0.9);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}

.loading-text {
  font: 18px var(--app-font-family);
  color: #27302b;
  letter-spacing: 0.1em;
}

/* 骨架屏样式 */
.practice-skeleton {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.skeleton-practice-card {
  background: #fffdf8;
  border: 1px solid #e3e0d4;
  border-radius: 12px;
  min-height: 120px;
  position: relative;
  overflow: hidden;
}

.skeleton-practice-card::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(
    90deg,
    transparent,
    rgba(245, 242, 233, 0.4),
    transparent
  );
  animation: shimmer 1.5s infinite;
}

@keyframes shimmer {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}

/* 平板及以上桌面端样式 */
@media (min-width: 768px) {
  .practice-main {
    padding: 60px 40px;
    max-width: 900px;
  }

  .section-title {
    font-size: 24px;
    margin-bottom: 12px;
  }

  .section-desc {
    margin-bottom: 30px;
  }

  .mob-type-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 20px;
  }

  .mob-grammar-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 20px;
  }

  .mob-random-settings {
    flex-direction: row;
    align-items: flex-end;
    gap: 20px;
    padding: 30px;
  }

  .mob-setting-group {
    flex: 1;
  }

  .mob-random-start {
    width: auto;
    min-width: 180px;
  }
}

/* 交错进入动画 */
@media (max-width: 768px) {
  .mob-grammar-card,
  .mob-mistakes-btn {
    opacity: 0;
    transform: translateY(16px);
    animation: item-enter 0.45s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  }
  .mob-grammar-card:nth-child(1),
  .mob-mistakes-btn:nth-child(1) { animation-delay: 0.05s; }
  .mob-grammar-card:nth-child(2),
  .mob-mistakes-btn:nth-child(2) { animation-delay: 0.1s; }
  .mob-grammar-card:nth-child(3),
  .mob-mistakes-btn:nth-child(3) { animation-delay: 0.15s; }
  .mob-grammar-card:nth-child(4),
  .mob-mistakes-btn:nth-child(4) { animation-delay: 0.2s; }
  .mob-grammar-card:nth-child(5),
  .mob-mistakes-btn:nth-child(5) { animation-delay: 0.25s; }

  @keyframes item-enter {
    to { opacity: 1; transform: translateY(0); }
  }
}
</style>
