<script setup>
import { RouterLink } from 'vue-router'
const modules = [
  { num:'01', title:'趣味阅读', en:'STORIES', path:'/novel', desc:'从一个故事开始，让好奇心带你走得更远。', class:'story', cta:'走进故事' },
  { num:'02', title:'趣味闯关', en:'CHALLENGES', path:'/fun', desc:'把知识变成一次次轻盈而有趣的探索。', class:'challenge', cta:'开启挑战' },
  { num:'03', title:'素材阅读馆', en:'LIBRARY', path:'/materials', desc:'收藏值得细读的文字，积累自己的表达。', class:'library', cta:'探索馆藏' },
  { num:'04', title:'模拟考试', en:'PRACTICE', path:'/mock-exam', desc:'在安静的练习里，遇见更从容的自己。', class:'exam', cta:'开始练习' }
]
</script>

<template>
  <section class="hero"><div class="hero-art"><div class="sky"></div><div class="sun"></div><div class="mountain back"></div><div class="mountain middle"></div><div class="mountain front"></div><div class="water"></div><div class="reeds reeds-left"></div><div class="reeds reeds-right"></div></div><div class="hero-shade"></div><div class="hero-copy"><p class="eyebrow light">A PLACE TO READ, A WAY TO GROW</p><h1>在文字里<br>遇见<span>辽阔</span></h1><p>让阅读慢下来，让想象走得更远。</p><a href="#explore" class="text-link light-link">开启探索 <span>↗</span></a></div><div class="hero-side">SCROLL TO EXPLORE <span>—</span> 01 / 04</div><div class="hero-bottom">读一页书，走一段路。<span>山间书院 · THE READING RETREAT</span></div></section>
  <section class="intro section-wrap"><div class="intro-heading"><p class="eyebrow">AN INVITATION TO EXPLORE</p><h2>在好奇心里，<br><em>找到自己的节奏。</em></h2></div><div class="intro-body"><span class="line"></span><p>故事、游戏、素材与练习，是通向阅读的四条小径。无论你从哪里出发，都可以在这里停一停，看见新的风景。</p><span class="seal">讀<br>·<br>想</span></div></section>
  <section id="explore" class="explore section-wrap"><div class="section-top"><p class="eyebrow">FOUR WAYS TO BEGIN</p><span>01 — 04</span></div><div class="explore-title"><h2>循着兴趣，<em>向前走。</em></h2><p>选择一条小径，开始今天的探索。</p></div><div class="module-grid"><RouterLink v-for="m in modules" :key="m.path" :to="m.path" class="module-card" :class="m.class"><div class="card-visual"><div class="card-orb"></div><div class="card-shape"></div><div class="card-symbol">{{m.num}}</div></div><div class="card-info"><div class="card-top"><span>{{m.en}}</span><span>↗</span></div><h3>{{m.title}}</h3><p>{{m.desc}}</p><span class="card-cta">{{m.cta}} <b>—</b></span></div></RouterLink></div></section>
  <section class="quote"><div class="quote-landscape"><div class="quote-hill"></div></div><div class="quote-content"><p class="eyebrow">A MOMENT TO PAUSE</p><p class="big-quote">"每一次翻页，<br>都是一次新的出发。"</p><p>留一点时间给阅读，也留一点空间给自己。</p><RouterLink to="/novel" class="text-link">从故事开始 <span>↗</span></RouterLink></div></section>
</template>
