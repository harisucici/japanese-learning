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

/**
 * 按题型练习
 * 调用 /practice/by-type
 */
async function startByType(type) {
  loading.value = true
  error.value = ''
  try {
    await api.ensureGuest()
    const session = await api.request('sessions', { level: 'n5', mode: 'practice', type: type === 'vocab' ? 'vocabulary' : type === 'listening' ? 'listening' : type === 'reading' ? 'reading' : 'grammar' }, true)
    router.push(`/sessions/${session.id}`)
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

/**
 * 按语法练习
 * 调用 /practice/by-grammar
 */
async function startByGrammar(grammarId) {
  loading.value = true
  error.value = ''
  try {
    await api.ensureGuest()
    const session = await api.request('sessions', { level: 'n5', mode: 'practice', type: 'grammar' }, true)
    router.push(`/sessions/${session.id}`)
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

/**
 * 错题重练
 * 调用 /practice/mistakes
 */
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

/**
 * 随机练习
 * 调用 /practice/random
 */
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

// 题型列表
const questionTypes = [
  { id: 'vocab', name: '词汇', desc: '单词、读音、用法', icon: '辞' },
  { id: 'grammar', name: '语法', desc: '句型、助词、接续', icon: '文' },
  { id: 'reading', name: '阅读', desc: '短文、长文理解', icon: '読' },
  { id: 'listening', name: '听力', desc: '对话、新闻理解', icon: '聴' }
]

// 常用语法分类
const grammarCategories = [
  { id: 'particles', name: '助词', desc: 'は、が、を、に、で...' },
  { id: 'conjugation', name: '动词变形', desc: 'ます形、て形、た形...' },
  { id: 'adjectives', name: '形容词', desc: 'い形容词、な形容词' },
  { id: 'patterns', name: '句型', desc: '～たい、～なければならない...' }
]
</script>

<template>
  <div class="practice-page">
    <section class="hero-simple">
      <div class="hero-copy">
        <p class="eyebrow light">PRACTICE MODE</p>
        <h1>练习模式</h1>
        <p>选择适合你的练习方式</p>
      </div>
    </section>

    <section class="practice-main section-wrap">
      <div v-if="error" class="state-box error">{{ error }}</div>

      <!-- 按题型练习 -->
      <h2 class="section-title">按题型练习</h2>
      <p class="section-desc">选择你想练习的题型，系统会为你生成对应的题目</p>
      <div class="type-grid">
        <button 
          v-for="type in questionTypes" 
          :key="type.id" 
          class="type-card"
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
      <div class="grammar-grid">
        <button 
          v-for="grammar in grammarCategories" 
          :key="grammar.id" 
          class="grammar-card"
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
      <button class="mistakes-btn" @click="startMistakes" :disabled="loading">
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
      <div class="random-settings">
        <div class="setting-group">
          <label>难度等级</label>
          <select v-model="randomLevel" :disabled="loading">
            <option value="n5">N5 - 入门</option>
            <option value="n4">N4 - 基础</option>
            <option value="n3">N3 - 中级</option>
            <option value="n2">N2 - 中高级</option>
            <option value="n1">N1 - 高级</option>
          </select>
        </div>
        <div class="setting-group">
          <label>题目数量</label>
          <select v-model="randomCount" :disabled="loading">
            <option :value="5">5 题</option>
            <option :value="10">10 题</option>
            <option :value="15">15 题</option>
            <option :value="20">20 题</option>
            <option :value="30">30 题</option>
          </select>
        </div>
        <button class="random-start" @click="startRandom" :disabled="loading">
          开始随机练习 →
        </button>
      </div>

      <div v-if="loading" class="loading-overlay">
        <div class="loading-text">正在生成练习…</div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.hero-simple {
  height: 300px;
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
  padding: 0 5.7%;
}

.practice-main {
  padding-top: 60px;
  padding-bottom: 60px;
  position: relative;
}

.section-title {
  font: 24px 'Zen Kaku Gothic New', sans-serif;
  margin: 0 0 12px;
  color: #27302b;
}

.section-desc {
  font-size: 14px;
  line-height: 1.8;
  color: #67746a;
  margin: 0 0 30px;
}

.type-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
  margin: 0 0 60px;
}

.type-card {
  background: #fffdf8;
  padding: 30px;
  border: 1px solid #e3e0d4;
  display: flex;
  align-items: center;
  gap: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  text-align: left;
}

.type-card:hover:not(:disabled) {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px -12px rgba(37, 99, 235, 0.15);
  border-color: #2563EB;
}

.type-card:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.type-icon {
  width: 60px;
  height: 60px;
  background: #2563EB;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font: 28px 'Zen Kaku Gothic New', sans-serif;
  flex-shrink: 0;
}

.type-info {
  flex: 1;
}

.type-info h3 {
  font: 18px 'Zen Kaku Gothic New', sans-serif;
  color: #27302b;
  margin: 0 0 8px;
}

.type-info p {
  font-size: 13px;
  color: #67746a;
  margin: 0;
}

.type-arrow {
  font-size: 24px;
  color: #2563EB;
  transition: transform 0.3s ease;
}

.type-card:hover:not(:disabled) .type-arrow {
  transform: translateX(6px);
}

.grammar-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
  margin: 0 0 60px;
}

.grammar-card {
  background: #fffdf8;
  padding: 30px;
  border: 1px solid #e3e0d4;
  cursor: pointer;
  transition: all 0.3s ease;
  text-align: left;
}

.grammar-card:hover:not(:disabled) {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px -12px rgba(5, 150, 105, 0.15);
  border-color: #059669;
}

.grammar-card:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.grammar-card h3 {
  font: 18px 'Zen Kaku Gothic New', sans-serif;
  color: #27302b;
  margin: 0 0 10px;
}

.grammar-card p {
  font-size: 13px;
  color: #67746a;
  line-height: 1.6;
  margin: 0 0 16px;
}

.grammar-arrow {
  font-size: 13px;
  color: #059669;
  letter-spacing: 0.05em;
}

.mistakes-btn {
  width: 100%;
  background: #fffdf8;
  padding: 30px;
  border: 1px solid #e3e0d4;
  display: flex;
  align-items: center;
  gap: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  text-align: left;
  margin: 0 0 60px;
}

.mistakes-btn:hover:not(:disabled) {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px -12px rgba(217, 119, 6, 0.15);
  border-color: #d97706;
}

.mistakes-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.mistakes-icon {
  width: 60px;
  height: 60px;
  background: #d97706;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  flex-shrink: 0;
}

.mistakes-info {
  flex: 1;
}

.mistakes-info h3 {
  font: 18px 'Zen Kaku Gothic New', sans-serif;
  color: #27302b;
  margin: 0 0 8px;
}

.mistakes-info p {
  font-size: 13px;
  color: #67746a;
  margin: 0;
}

.mistakes-arrow {
  font-size: 13px;
  color: #d97706;
  letter-spacing: 0.05em;
}

.random-settings {
  background: #fffdf8;
  padding: 40px;
  border: 1px solid #e3e0d4;
  display: flex;
  gap: 30px;
  align-items: flex-end;
  flex-wrap: wrap;
}

.setting-group {
  flex: 1;
  min-width: 200px;
}

.setting-group label {
  display: block;
  font: 14px 'Zen Kaku Gothic New', sans-serif;
  color: #27302b;
  margin-bottom: 10px;
}

.setting-group select {
  width: 100%;
  padding: 12px 14px;
  border: 1px solid #c9c9bd;
  background: #fff;
  font: 14px 'Zen Kaku Gothic New', sans-serif;
  color: #27302b;
  cursor: pointer;
}

.setting-group select:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.random-start {
  padding: 14px 30px;
  background: #2563EB;
  color: white;
  border: none;
  font: 14px 'Zen Kaku Gothic New', sans-serif;
  letter-spacing: 0.08em;
  cursor: pointer;
  transition: all 0.3s ease;
}

.random-start:hover:not(:disabled) {
  background: #1d4ed8;
  transform: translateY(-2px);
  box-shadow: 0 8px 16px -8px rgba(37, 99, 235, 0.4);
}

.random-start:disabled {
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
  font: 18px 'Zen Kaku Gothic New', sans-serif;
  color: #27302b;
  letter-spacing: 0.1em;
}

@media (max-width: 968px) {
  .type-grid,
  .grammar-grid {
    grid-template-columns: 1fr;
  }
  
  .random-settings {
    flex-direction: column;
    align-items: stretch;
  }
  
  .random-start {
    width: 100%;
  }
}

@media (max-width: 640px) {
  .type-card,
  .grammar-card,
  .mistakes-btn {
    padding: 24px;
  }
}
</style>
