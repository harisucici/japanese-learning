# 更新日志 (Changelog)

本项目遵循 [语义化版本 (Semantic Versioning)](https://semver.org/lang/zh-CN/) 和 [Keep a Changelog](https://keepachangelog.com/zh-CN/) 规范。

**版本格式**: `MAJOR.MINOR.PATCH`
- **MAJOR**: 不兼容的 API 变更
- **MINOR**: 向下兼容的功能新增
- **PATCH**: 向下兼容的问题修正

---

## [Unreleased]

### 新增
- 趣味阅读中点击带假名的词语时，使用浏览器端 Kokoro 日语语音模型播放读音，并显示加载、生成和播放状态。
- 按需加载语音模型与日语词典，缓存当前页面常用词语的发音；连续点击时停止上一段播放。

### 修复
- 趣味阅读注音词语下方的重复虚线改为一条稍远离文字的红色点状下划线。
- 修复显示设置中的假名注音字号无法应用到趣味阅读文章的问题。

### 计划添加
- Phase 2: 模拟考试系统（好友功能、排行榜）
- 移动端支持（iOS/Android）
- 离线学习模式

---

## [1.1.0] - 2026-10-19

### 概述
前后端数据模型统一修复，确保三端（前端 Dart 模型、后端 Prisma schema、Mock 数据）字段完全一致。

### 重大变更 (BREAKING CHANGES)
- **Question 模型重构**: `options[].text` → `options[].content`，移除 `isCorrect` 字段
- **Grammar 模型重构**: `conjugation` → `connection`，添加 `usage`、`exampleTranslation`、`similarGrammars`
- **JLPTLevel 枚举**: 大写 `N5/N4/N3/N2/N1` → 小写 `n5/n4/n3/n2/n1`
- **ReviewStatus 枚举**: `new` → `new_`（避免 SQL 关键字冲突）

### 新增
- Question: 添加 `contentReading`、`contentImageUrl`、`audioUrl`、`order` 字段
- Question.options: 添加 `index`、`hint`、`reading` 字段
- Grammar: 添加 `exampleSentence`、`usage`、`exampleTranslation`、`similarGrammars` 字段
- Explanation: 添加 `note` 字段（学习重点/备注）
- OptionAnalysis: 添加 `detail`、`pitfall` 字段
- ExtensionExercise: 完整重构，添加 `id`、`type`、`options[]`、`answer`、`explanation`、`relatedTags[]`

### 修复
- Prisma schema 添加 `explanationId` 字段（前端依赖）
- 修复重复数据 ID（q-n5-023、q-n5-024 重复项追加 `-dup` 后缀）
- 确保 50 条问题、50 条解析全部唯一 ID
- 验证所有 `question.explanationId` 和 `explanation.questionId` 引用有效

### 验证
- ✅ `prisma validate` 通过
- ✅ JSON 数据可解析
- ✅ 前后端字段名称完全一致

---

## [1.0.0] - 2026-10-19

### 概述
项目结构统一为 monorepo，前后端代码整合到同一仓库。

### 项目结构
```
japanese-learning/
├── ja-learning-backend/          # Node.js + Express + Prisma 后端
│   ├── src/                      # TypeScript 源码
│   │   ├── controllers/          # 控制器层
│   │   ├── services/             # 业务逻辑层
│   │   ├── routes/               # 路由定义
│   │   ├── middleware/           # 中间件
│   │   └── config/               # 配置文件
│   ├── prisma/                   # Prisma ORM
│   │   ├── schema.prisma         # 数据库模型
│   │   └── migrations/           # 数据库迁移
│   ├── scripts/                  # 数据导入/导出脚本
│   ├── data/                     # 原始数据文件
│   └── docs/                     # 后端文档
├── japanese-learning-platform/   # Flutter 3.27.4 Web 前端
│   ├── lib/                      # Dart 源码
│   │   ├── core/                 # 核心模块（音频、路由、主题、网络）
│   │   ├── features/             # 功能模块（首页、答题、考试、复习等）
│   │   ├── redux/                # 状态管理
│   │   ├── shared/               # 共享组件和模型
│   │   └── widgets/              # 复杂 UI 组件
│   ├── assets/                   # 静态资源（音频、字体、图片、数据）
│   ├── web/                      # Web 构建配置
│   └── test/                     # 测试文件
└── 日语N5-N1刷题与深度解析平台需求文档.md.md
```

### 后端功能 (ja-learning-backend)
- **技术栈**: Node.js + Express + TypeScript + Prisma + Turso (SQLite)
- **认证系统**: JWT 基础认证，用户注册/登录
- **题库管理**: 
  - 50 道 N5 级别题目（可扩展至 N1）
  - 题目类型：单选、多选
  - 支持题干图片、音频、读音标注
- **解析系统**:
  - 每题独立解析（Explanation）
  - 选项级别分析（OptionAnalysis）
  - 扩展练习（ExtensionExercise）
  - 语法点详解（GrammarPoint）
- **学习记录**:
  - 答题记录（Record）
  - 错题本（WrongBook）
  - 复习系统（Review）
- **统计系统**:
  - 做题统计（Statistics）
  - 正确率、用时、趋势分析
- **数据库迁移**:
  - 8 个迁移脚本（init → novel_lessons）
  - 支持 Turso 云端同步

### 前端功能 (japanese-learning-platform)
- **技术栈**: Flutter 3.27.4 + Redux + Dio
- **响应式设计**: 自适应 Web/Mobile 布局
- **核心功能**:
  - 首页：题目分类浏览（N5-N1）
  - 练习模式：逐题答题、即时反馈
  - 考试模式：模拟考试环境、计时、提交评分
  - 答题解析：详细解析、选项分析、扩展练习
  - 错题本：自动收集错题、复习功能
  - 复习系统：间隔重复、记忆曲线
  - 统计面板：学习数据可视化
  - 用户中心：个人信息、偏好设置
- **音频支持**:
  - 题干朗读
  - 例句发音
  - 听力练习
- **UI/UX**:
  - 深蓝主色 (#2563EB)
  - 日语字体优化（Noto Sans JP / Noto Serif JP）
  - 动画过渡效果
  - 骨架屏加载
  - 键盘快捷键（Web）
- **状态管理**: Redux（actions/reducers/repositories 三层架构）
- **网络层**: Dio HTTP 客户端，统一 API 服务

### 数据资产
- 5 套 JLPT 真题 PDF（N1-N5 词汇 + 答案）
- 2018 年 JLPT 词汇数据
- 官方解析编辑数据
- 音频样本（N5）
- 日语字体文件（4 个 TTF）

### 验证
- ✅ 项目结构统一完成
- ✅ Git 仓库初始化并推送到 GitHub
- ✅ 234 个文件，60,819 行代码

---

## 版本历史统计

| 版本 | 发布日期 | 提交数 | 文件数 | 代码行数 | 主要变更 |
|------|----------|--------|--------|----------|----------|
| 1.1.0 | 2026-10-19 | - | - | - | 前后端数据模型统一 |
| 1.0.0 | 2026-10-19 | 1 | 234 | 60,819 | 初始发布，项目结构统一 |

---

## 开发规范

### 提交信息格式
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type（必需）**:
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档变更
- `style`: 代码格式（不影响代码运行）
- `refactor`: 重构（既不是新增功能，也不是修改 bug）
- `perf`: 性能优化
- `test`: 增加测试
- `chore`: 构建过程或辅助工具变动

**Scope（可选）**: 影响范围，如 `backend`、`frontend`、`database`

**Breaking Changes**: 在 footer 中添加 `BREAKING CHANGE:` 说明

### 版本发布流程
1. 更新 `CHANGELOG.md`，将 `[Unreleased]` 内容移到新版本
2. 更新版本号：
   - 后端: `ja-learning-backend/package.json` → `version`
   - 前端: `japanese-learning-platform/pubspec.yaml` → `version`
3. Git 提交: `git commit -m "chore: release v1.2.0"`
4. Git 标签: `git tag -a v1.2.0 -m "Release v1.2.0"`
5. 推送: `git push && git push --tags`

---

[Unreleased]: https://github.com/harisucici/japanese-learning/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/harisucici/japanese-learning/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/harisucici/japanese-learning/releases/tag/v1.0.0
