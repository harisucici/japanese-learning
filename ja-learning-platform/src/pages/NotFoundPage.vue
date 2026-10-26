<script setup>
import { RouterLink } from 'vue-router'
</script>

<template>
  <div class="not-found-page content-page">
    <div class="section-top">
      <p class="eyebrow">404</p>
      <span>页面未找到</span>
    </div>
    <div class="not-found-content">
      <h2>抱歉，这个页面不存在</h2>
      <p>你访问的页面可能已被移除或地址有误。</p>
      <RouterLink to="/" class="primary-action">返回首页</RouterLink>
    </div>
  </div>
</template>

<style scoped>
.not-found-page {
  min-height: 60vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 80px 20px;
}

.not-found-content {
  margin-top: 32px;
}

.not-found-content h2 {
  font-size: 24px;
  font-weight: 600;
  margin-bottom: 16px;
  color: var(--theme-text, #27302b);
}

.not-found-content p {
  font-size: 16px;
  line-height: 1.6;
  color: var(--theme-text-secondary, #67746a);
  margin-bottom: 32px;
}

.primary-action {
  display: inline-block;
  padding: 12px 32px;
  background: var(--color-primary, #3a5d4d);
  color: #fffdf8;
  border-radius: 8px;
  text-decoration: none;
  font-weight: 500;
  transition: background 0.2s;
}

.primary-action:hover {
  background: var(--color-primary-hover, #294638);
}

.section-top {
  margin-bottom: 16px;
}

.section-top .eyebrow {
  font-size: 14px;
  letter-spacing: 0.1em;
  color: var(--color-primary, #3a5d4d);
  margin-bottom: 8px;
}

.section-top span {
  font-size: 18px;
  color: var(--theme-text-secondary, #67746a);
}

@media (max-width: 768px) {
  .not-found-page {
    padding: 60px 16px;
  }

  .not-found-content h2 {
    font-size: 20px;
  }

  .not-found-content p {
    font-size: 14px;
  }
}
</style>
