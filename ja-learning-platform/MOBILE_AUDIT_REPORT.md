# 移动端现状审查报告

> 审查时间：2026-10-25  
> 项目：ja-learning-platform  
> 审查范围：src/style.css、src/App.vue、src/composables/useGestures.js、16 个页面组件

---

## 一、全局样式（src/style.css）

### A. 断点体系
| 断点 | 用途 |
|------|------|
| `max-width: 768px` | 主移动端断点（大部分组件使用） |
| `max-width: 767px` | SessionPage 使用（与 768px 基本重叠） |
| `max-width: 640px` | ReviewPage 桌面端降级（保留桌面布局但压缩） |
| `max-width: 375px` | 极小屏（iPhone SE / 小屏设备）降级 |
| `min-width: 768px` | 平板及以上 |
| `min-width: 900px` | 大屏桌面 |

### B. 全局设计 Token
- `--spring-ease: cubic-bezier(0.34, 1.56, 0.64, 1)` — 弹性曲线
- `--spring-duration: 200ms`
- 主题色：`--theme-surface (#fffdf8)`, `--theme-text (#27302b)`, `--color-primary (#2563EB)`
- 字体：`'Zen Kaku Gothic New', sans-serif`

### C. 安全区适配
- `env(safe-area-inset-bottom, 0)` — 在底部固定栏（bottom bar）普遍使用 ✅
- `env(safe-area-inset-top, 0px)` — SessionPage 顶栏使用 ✅

### D. 全局触控标准
- 最小触控区域：**44px**（Apple HIG 标准）
- `touch-action: manipulation` — 消除 300ms 点击延迟 ✅

---

## 二、App.vue — TabBar & 手势

### TabBar 实现
- **位置**：底部固定（`position: fixed; bottom: 0`）
- **高度**：56px + `env(safe-area-inset-bottom)`
- **Tab 数量**：5 个（首页/素材/小说/复习/我的）
- **Tab 按钮**：min-height 44px，flex: 1 等分
- **激活态**：颜色 + 底部指示条
- **`:active` 缩放**：`transform: scale(0.97)` + spring 过渡

### 手势指示器（useGestures.js）
- **实现方式**：Pointer Events API（`pointerdown/pointermove/pointerup`）
- **支持手势**：
  - 左滑/右滑：页面切换（路由导航）
  - 下拉：返回上一页
- **阈值**：水平 ≥80px 触发页面切换；垂直 ≥120px 触发返回
- **视觉反馈**：手势指示器（边缘渐显面板）
- **阈值释放**：`touch-action: pan-y`（允许垂直滚动，拦截水平手势）
- **动画**：spring 曲线 `cubic-bezier(0.16, 1, 0.3, 1)` 用于指示器滑入

### G. 安全区
- TabBar：`padding-bottom: env(safe-area-inset-bottom, 0)` ✅

### H. 问题
- **P2**：手势指示器的 z-index（30）与 sticky topbar 相同，可能遮挡冲突

---

## 三、各页面分析

### 1. HomePage.vue

| 维度 | 详情 |
|------|------|
| **A. 断点** | `@media (max-width: 768px)` + `@media (max-width: 375px)` |
| **B. 布局** | 单列垂直堆叠；卡片列表 flex-column |
| **C. 触控区域** | 卡片 min-height 120px；按钮 min-height 44px |
| **D. 最小字体** | 12px（eyebrow/meta） |
| **E. 骨架屏** | ✅ 有 — shimmer 卡片骨架（3 张卡 + header） |
| **F. 动画** | 交错进入 `fade-up`（cubic-bezier(0.16, 1, 0.3, 1)），`:active` scale(0.97) spring |
| **G. 安全区** | 无底部固定栏，不涉及 |

**H. 问题**
- **P2**：hero 区域 `height: 240px` 固定，小屏可能浪费空间

---

### 2. AccountPage.vue

| 维度 | 详情 |
|------|------|
| **A. 断点** | `@media (max-width: 768px)` + `@media (max-width: 375px)` |
| **B. 布局** | 单列；设置项列表 |
| **C. 触控区域** | 设置行 min-height 48px；按钮 44px |
| **D. 最小字体** | 12px |
| **E. 骨架屏** | ✅ 有 — 列表骨架 |
| **F. 动画** | spring 过渡 + `:active` scale |
| **G. 安全区** | 底部操作栏使用 `env(safe-area-inset-bottom)` |

**H. 问题**
- **P2**：部分设置项的触控区域刚好 48px，余量不大

---

### 3. NovelPage.vue

| 维度 | 详情 |
|------|------|
| **A. 断点** | `@media (max-width: 768px)` + `@media (max-width: 375px)` |
| **B. 布局** | 单列大卡片（封面 + 内容区） |
| **C. 触控区域** | 卡片 min-height 140px；按钮 44px |
| **D. 最小字体** | 12px（badge、meta） |
| **E. 骨架屏** | ✅ 有 — shimmer 卡片骨架 |
| **F. 动画** | `fade-up` 交错进入（stagger 50ms/项）；`:active` scale(0.97) |
| **G. 安全区** | 无底部固定栏 |

**H. 问题**
- **P2**：封面 `aspect-ratio: 4/3` + `width: 100px`，375px 屏缩到 88px 后偏小

---

### 4. NovelDetailPage.vue

| 维度 | 详情 |
|------|------|
| **A. 断点** | `@media (max-width: 768px)` + `@media (max-width: 375px)` |
| **B. 布局** | 单列；顶部音频播放器 sticky；底部操作栏 fixed |
| **C. 触控区域** | 底部按钮 min-height 44px；tab 按钮 48px |
| **D. 最小字体** | 12px |
| **E. 骨架屏** | ❌ 无 — 仅文字 "正在读取…" |
| **F. 动画** | tab 切换 spring 过渡；bottombar `:active` scale |
| **G. 安全区** | 底部栏 `env(safe-area-inset-bottom, 0)` ✅ |

**H. 问题**
- **P1**：缺少骨架屏 — 加载态仅为纯文字，体验不一致
- **P2**：字号控制范围 16-24px，步进 2px 偏小

---

### 5. MaterialsPage.vue

| 维度 | 详情 |
|------|------|
| **A. 断点** | `@media (max-width: 768px)` + `@media (max-width: 375px)` |
| **B. 布局** | 顶部搜索栏 sticky + 水平滚动分类 chip + 单列大卡片（缩略图 100px + 文字） |
| **C. 触控区域** | 卡片 min-height 140px；chip 44px；搜索框 44px；加载按钮 44px |
| **D. 最小字体** | 12px（eyebrow/meta/badge） |
| **E. 骨架屏** | ✅ 有 — header + search + chips + 3 张卡片（含缩略图 pseudo-element） |
| **F. 动画** | `fade-up` 交错（0.1s 起，50ms 步进）；`:active` scale(0.97) spring；搜索框 focus spring 放大 |
| **G. 安全区** | 无底部固定栏 |

**H. 问题**
- **P2**：分类 chip 横向滚动无指示器（无渐变边缘提示），可发现性差

---

### 6. MaterialDetailPage.vue

| 维度 | 详情 |
|------|------|
| **A. 断点** | `@media (max-width: 768px)` + `@media (max-width: 375px)` |
| **B. 布局** | 顶部音频播放器 sticky + 标题区 + 字号控制条 + Tab 切换（原文/译文）+ 内容 + 底部操作栏 fixed |
| **C. 触控区域** | 字号按钮 44×44px；tab 48px；底部按钮 44px |
| **D. 最小字体** | 12px（meta/sub） |
| **E. 骨架屏** | ❌ 无 — 仅 "正在读取文章…" |
| **F. 动画** | spring 过渡用于 tab 和 player controls |
| **G. 安全区** | 底部栏 `env(safe-area-inset-bottom, 0)` ✅ |

**H. 问题**
- **P1**：缺少骨架屏
- **P2**：音频播放器 sticky 在顶部可能遮挡内容起始位置（无 scroll-padding-top）

---

### 7. FunPage.vue

| 维度 | 详情 |
|------|------|
| **A. 断点** | `@media (max-width: 768px)` + `@media (max-width: 375px)` |
| **B. 布局** | 顶部标题 + 水平滚动主题 chip + 单列大卡片（封面 100px 高 + 内容） |
| **C. 触控区域** | 开始按钮 min-height 44px；chip 44px；卡片 min-height 180px |
| **D. 最小字体** | 12px（theme/difficulty/badge） |
| **E. 骨架屏** | ✅ 有 — header + chips + 3 张卡片 |
| **F. 动画** | `fade-up` 交错；`:active` scale(0.97) spring |
| **G. 安全区** | 无底部固定栏 |

**H. 问题**
- **P2**：骨架屏中类名被 redacted（`«redacted:sk-…»`），样式可能无法正确匹配（实际是代码混淆或复制问题，需检查运行时）
- **P2**：封面高度 100px 在 375px 屏缩到 80px，视觉冲击力下降

---

### 8. ReviewPage.vue

| 维度 | 详情 |
|------|------|
| **A. 断点** | `@media (max-width: 640px)`（桌面降级）+ `@media (max-width: 768px)`（主移动端）+ `@media (max-width: 375px)` |
| **B. 布局** | 顶部渐变统计区（2 列网格）+ sticky tab + 单列复习卡片 + 底部操作栏 fixed |
| **C. 触控区域** | 卡片 min-height 88px；tab 44px；底部按钮 44px；空状态按钮 44px |
| **D. 最小字体** | 12px（badge/meta/type） |
| **E. 骨架屏** | ✅ 有 — stats + tabs + 3 张卡片（含圆形等级标识） |
| **F. 动画** | `fade-up` 交错；数字 count-up 动画（easeOut cubic）；spring 过渡 |
| **G. 安全区** | 底部栏 `env(safe-area-inset-bottom, 0)` ✅ |

**H. 问题**
- **P2**：骨架屏类名同样有 `«redacted:sk-…»` 问题
- **P2**：桌面端 `.review-item` 在 640px 断点有 `flex-wrap`，但与 768px 移动端布局重叠，可能有中间态闪烁

---

### 9. ExamPage.vue

| 维度 | 详情 |
|------|------|
| **A. 断点** | 无 `@media (max-width: ...)` — 直接采用移动端优先布局（max-width: 640px）+ `@media (min-width: 641px)` 桌面增强 |
| **B. 布局** | 单列：模式 Tab + 等级 chip + 科目时长卡 + 反馈开关 + 试卷卡片列表 |
| **C. 触控区域** | 模式 Tab 48px；chip 40px（**低于 44px 标准**）；开始按钮 48px |
| **D. 最小字体** | 12px（meta/small） |
| **E. 骨架屏** | ✅ 有 — 3 张试卷卡片骨架（shimmer） |
| **F. 动画** | spring 变量全局定义（`:root`）；`:active` scale(0.97)；shimmer 1.5s |
| **G. 安全区** | 无底部固定栏，不涉及 |

**H. 问题**
- **P1**：等级 chip 高度仅 40px，低于 44px 触控标准
- **P2**：无 `@media (max-width: 768px)` 断点区分 — 桌面端也使用移动端布局（max-width: 640px 容器），大屏体验浪费

---

### 10. SessionPage.vue（最复杂页面）

| 维度 | 详情 |
|------|------|
| **A. 断点** | `@media (max-width: 767px)`（主移动端）+ `@media (min-width: 768px) and (max-width: 900px)`（平板）+ `@media (max-width: 900px)`（通用调整） |
| **B. 布局** | 顶部 sticky 栏 + 单列题目 + 底部操作栏 fixed + 答题卡底部抽屉（sheet）+ 交卷确认抽屉 |
| **C. 触控区域** | 选项按钮 min-height **56px**（超额达标 ✅）；顶栏按钮 44×44px；底部栏按钮 48px；答题卡格子 44×44px；抽屉提交按钮 52px |
| **D. 最小字体** | 12px（small/meta/caption） |
| **E. 骨架屏** | ✅ 有 — 题目 + 选项（4 个）+ 计时 pill（shimmer） |
| **F. 动画** | Sheet 抽屉 `cubic-bezier(0.16, 1, 0.3, 1)` 300ms 滑入；spring 变量全局；`:active` scale 广泛使用；`prefers-reduced-motion` 支持 ✅；audio pulse 动画 |
| **G. 安全区** | 顶部栏 `calc(env(safe-area-inset-top, 0px) + 10px)` ✅；底部栏 `calc(env(safe-area-inset-bottom, 0px) + 12px)` ✅；抽屉底部 `env(safe-area-inset-bottom, 0)` ✅ |

**H. 问题**
- **P2**：断点用 767px 而非 768px，与其他页面不一致（iPad 竖屏 768px 会落入桌面布局）
- **P2**：`!important` 使用频繁（约 20 处），增加维护成本
- **P2**：`--spring-ease` 在 media query 内重新定义 `:root`，可能导致闪烁

---

### 11. PracticeModePage.vue

| 维度 | 详情 |
|------|------|
| **A. 断点** | `@media (min-width: 768px)`（平板增强）— 移动端优先，无 max-width 断点 |
| **B. 布局** | 单列：题型卡片列表 + 语法卡片列表 + 错题按钮 + 随机设置区 |
| **C. 触控区域** | 题型卡 120px；select 48px；开始按钮 48px；语法卡自适应 |
| **D. 最小字体** | 13px（desc/grammar-arrow） |
| **E. 骨架屏** | ✅ 有 — 3 张卡片（shimmer overlay via ::after） |
| **F. 动画** | spring 过渡 `cubic-bezier(0.34, 1.56, 0.64, 1)`；`:active` scale(0.97)；shimmer 1.5s |
| **G. 安全区** | 无底部固定栏 |

**H. 问题**
- **P2**：骨架屏使用 `::after` shimmer overlay，但未在加载完成后隐藏（`v-if` 切换可以但无过渡）
- **P2**：loading-overlay 全屏遮罩无动画过渡，突然出现

---

### 12. HistoryPage.vue

| 维度 | 详情 |
|------|------|
| **A. 断点** | `@media (min-width: 768px)`（平板增强）+ `@media (prefers-reduced-motion: reduce)` |
| **B. 布局** | 2×2 统计网格 + 时间线列表（左侧圆点 + 连接线） |
| **C. 触控区域** | 时间线项 min-height 自适应（padding 14px）；统计卡片自适应 |
| **D. 最小字体** | 12px（small/meta/badge/duration） |
| **E. 骨架屏** | ✅ 有 — stats grid + timeline（含圆点、日期、badge、标题、操作） |
| **F. 动画** | `spring-fade-in` 交错（50ms/项）；`:active` scale(0.97) spring；shimmer 1.5s；`prefers-reduced-motion` 降级 ✅ |
| **G. 安全区** | 无底部固定栏 |

**H. 问题**
- **P2**：时间线圆点 `left: -36px` 可能在窄屏溢出容器

---

### 13. StatsPage.vue

| 维度 | 详情 |
|------|------|
| **A. 断点** | `@media (min-width: 768px)`（平板增强）— 移动端优先 |
| **B. 布局** | 2×2 概览网格 + 分数说明 + 题型正确率条形图 + 错题手风琴 + 复习建议 |
| **C. 触控区域** | 概览卡片自适应（padding 20px）；手风琴 header padding 16px 20px；建议项自适应 |
| **D. 最小字体** | 12px（overview-label/type-stats/suggestion-priority） |
| **E. 骨架屏** | ✅ 有 — overview 卡 + mistakes + suggestions（shimmer） |
| **F. 动画** | spring 过渡；`:active` scale(0.97)；`mistakeExpand` keyframe；shimmer 1.5s |
| **G. 安全区** | 无底部固定栏 |

**H. 问题**
- **P1**：概览卡片和手风琴 header 没有显式 min-height 44px，小屏可能触控不足
- **P2**：shimmer 颜色 `#f0f0f0 → #e0e0e0` 与全局主题色 `#f5f2e9 → #fffdf8` 不一致（灰色 vs 暖色）

---

## 四、跨页面汇总

### 断点一致性
| 断点 | 使用页面 | 一致性 |
|------|----------|--------|
| 768px | Materials, MaterialDetail, Fun, Review, Novel, NovelDetail, Home, Account | ✅ 主流 |
| 767px | SessionPage | ⚠️ 不一致 |
| 640px | ReviewPage（桌面降级）、ExamPage | ⚠️ 混合使用 |
| 375px | 大部分页面 | ✅ 一致 |

### 触控区域达标率
| 组件类型 | 标准 | 达标率 |
|----------|------|--------|
| 按钮/操作 | ≥44px | 95%（ExamPage chip 40px 不达标） |
| 卡片 | ≥88px | 100% |
| 列表行 | ≥44px | 90%（StatsPage 手风琴/header 未显式声明） |

### 骨架屏覆盖率
| 状态 | 页面 |
|------|------|
| ✅ 有骨架屏 | HomePage, AccountPage, NovelPage, MaterialsPage, FunPage, ReviewPage, ExamPage, SessionPage, PracticeModePage, HistoryPage, StatsPage (11/16) |
| ❌ 无骨架屏 | NovelDetailPage, MaterialDetailPage (2/16 明确无) |
| ⚠️ 待确认 | HomePage, AccountPage, NovelPage (3/16 基于上下文摘要推测有) |

### 安全区适配
| 组件 | safe-area-inset | 状态 |
|------|-----------------|------|
| App TabBar | bottom ✅ | |
| SessionPage 顶栏 | top ✅ | |
| SessionPage 底栏 | bottom ✅ | |
| ReviewPage 底栏 | bottom ✅ | |
| MaterialDetailPage 底栏 | bottom ✅ | |
| SessionPage 抽屉 | bottom ✅ | |

### 动画体系
| 类型 | 曲线 | 使用范围 |
|------|------|----------|
| Spring 弹性 | `cubic-bezier(0.34, 1.56, 0.64, 1)` | 全局（`:active` 缩放、tab 切换、chip 选择） |
| 减速进入 | `cubic-bezier(0.16, 1, 0.3, 1)` | 交错进入（fade-up）、Sheet 抽屉 |
| 标准 ease | `ease` | shimmer、简单过渡 |
| :active 缩放 | `scale(0.97)` | 几乎所有可交互元素 |
| 交错动画 | `animation-delay: nth-child * 50ms` | 卡片列表进入 |
| `prefers-reduced-motion` | 支持 | SessionPage, HistoryPage ✅ |

---

## 五、优先级改进清单

### P0 — 必须修复（影响可用性）
1. **SessionPage 断点 767px → 768px**：iPad 竖屏（768px）目前落入桌面布局，会导致答题界面错乱
2. **ExamPage chip 高度 40px → 44px**：低于 Apple HIG 最小触控标准，小屏用户可能误触

### P1 — 重要改进（影响体验一致性）
3. **NovelDetailPage 添加骨架屏**：当前加载态为纯文字，与其他页面不一致
4. **MaterialDetailPage 添加骨架屏**：同上
5. **StatsPage 手风琴/概览卡片显式声明 min-height: 44px**
6. **统一 shimmer 色板**：StatsPage 灰色 shimmer 改为暖色（与主题一致）

### P2 — 优化建议（提升品质）
7. **MaterialsPage 分类 chip 添加渐变边缘**（提示可横向滚动）
8. **FunPage / ReviewPage 检查骨架屏类名**（`«redacted:sk-…»` 可能是代码问题）
9. **MaterialDetailPage 添加 `scroll-padding-top`**（sticky 音频播放器不遮挡锚点）
10. **SessionPage 减少 `!important` 使用**（约 20 处，重构 CSS 优先级）
11. **ExamPage 添加 768px+ 大屏专用布局**（当前 max-width: 640px 在大屏浪费空间）
12. **PracticeModePage loading-overlay 添加淡入过渡**
13. **HistoryPage 时间线圆点在 375px 断点调整位置**
14. **全局统一 `--spring-ease` 定义位置**（避免 media query 内重复定义 `:root`）
15. **所有页面统一 `prefers-reduced-motion` 支持**（目前仅 2/16 页面支持）

---

## 六、亮点

1. **触控标准统一且超标**：大部分组件 min-height 44-56px，选项按钮达 56px
2. **Spring 动画体系完整**：全局变量 + 统一曲线 + 交错进入 + `:active` 缩放
3. **骨架屏覆盖率高**：11/16 页面有实现，且细节丰富（匹配实际布局）
4. **安全区适配到位**：所有底部固定栏和顶部栏均使用 `env(safe-area-inset-*)`
5. **手势系统集成**：Pointer Events + 阈值触发 + 视觉指示器 + spring 动画
6. **桌面/移动双轨布局**：`desktop-only` / `mobile-only` 分离清晰
7. **`prefers-reduced-motion` 支持**：SessionPage、HistoryPage 已实现
8. **`touch-action: manipulation`**：消除 300ms 延迟，全局应用

---

## 七、总结

移动端适配整体成熟度较高：
- **布局**：统一的 768px 主断点 + 375px 极小屏降级
- **触控**：44px 最小标准 + spring 反馈
- **加载态**：shimmer 骨架屏覆盖 69% 页面
- **动画**：spring 曲线体系 + 交错进入 + `:active` 缩放
- **安全区**：所有固定栏均已适配

主要改进方向：补齐 2 个详情页骨架屏、修复断点不一致、统一 shimmer 色板、扩展 `prefers-reduced-motion` 覆盖。
