# 日语 N5-N1 刷题与深度解析平台

> 商业级日语能力考试备考平台，支持 Web/Mobile，提供完整的题库管理、模拟考试、智能解析、错题本和复习系统。

![Version](https://img.shields.io/badge/version-1.1.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.27.4-02569B)
![Node.js](https://img.shields.io/badge/Node.js-18+-339933)
![Prisma](https://img.shields.io/badge/Prisma-5.x-2D3748)
![License](https://img.shields.io/badge/license-Proprietary-red)

## 项目概览

本项目是一个完整的日语学习平台，包含:

- **5 个 JLPT 级别**: N5、N4、N3、N2、N1
- **完整题库系统**: 支持单选、多选、听力、阅读等题型
- **深度解析**: 每题配有详细解析、选项分析、扩展练习
- **学习追踪**: 答题记录、错题本、间隔重复复习
- **数据可视化**: 学习统计、正确率趋势、知识点掌握度
- **音频支持**: 题干朗读、例句发音、听力练习
- **响应式设计**: Web 优化布局，支持 iOS/Android（Flutter）

## 技术架构

### 前端 (japanese-learning-platform)
- **框架**: Flutter 3.27.4
- **状态管理**: Redux (三层架构: actions/reducers/repositories)
- **网络层**: Dio HTTP 客户端
- **UI/UX**: 自定义主题系统、动画过渡、骨架屏
- **音频**: just_audio + audio_session
- **字体**: Noto Sans JP / Noto Serif JP

### 后端 (ja-learning-backend)
- **运行时**: Node.js 18+
- **框架**: Express.js + TypeScript
- **ORM**: Prisma 5.x
- **数据库**: SQLite + Turso 云端同步
- **认证**: JWT
- **验证**: Zod

### 数据库
- **本地开发**: SQLite (轻量、零配置)
- **生产环境**: Turso (边缘 SQLite，支持云端同步)
- **迁移管理**: Prisma Migrate (8 个迁移脚本)

## 快速开始

### 环境要求
- Node.js 18+ & npm
- Flutter 3.27.4+
- Git

### 后端启动

```bash
# 进入后端目录
cd ja-learning-backend

# 安装依赖
npm install

# 数据库迁移
npx prisma migrate deploy

# 导入示例数据 (可选)
npm run import:official

# 启动开发服务器
npm run dev
```

后端默认运行在 `http://localhost:3000`

### 前端启动

```bash
# 进入前端目录
cd japanese-learning-platform

# 安装依赖
flutter pub get

# Web 模式运行
flutter run -d chrome

# 或构建 Web 版本
flutter build web
```

前端默认运行在 `http://localhost:8080`

## 项目结构

```
japanese-learning/
├── ja-learning-backend/          # Node.js 后端
│   ├── src/                      # TypeScript 源码
│   │   ├── controllers/          # 控制器层
│   │   ├── services/             # 业务逻辑层
│   │   ├── routes/               # 路由定义
│   │   ├── middleware/           # 中间件 (认证等)
│   │   └── config/               # 配置
│   ├── prisma/                   # 数据库
│   │   ├── schema.prisma         # 数据模型
│   │   └── migrations/           # 迁移脚本
│   ├── scripts/                  # 数据导入脚本
│   ├── data/                     # 原始数据 (PDF/JSON)
│   └── docs/                     # 后端文档
│
├── japanese-learning-platform/   # Flutter 前端
│   ├── lib/                      # Dart 源码
│   │   ├── core/                 # 核心模块
│   │   ├── features/             # 功能模块
│   │   ├── redux/                # 状态管理
│   │   ├── shared/               # 共享组件
│   │   └── widgets/              # 复杂 UI
│   ├── assets/                   # 静态资源
│   ├── web/                      # Web 配置
│   └── test/                     # 测试
│
├── CHANGELOG.md                  # 更新日志
├── VERSIONING.md                 # 版本管理指南
└── README.md                     # 本文件
```

## 核心功能

### 1. 题库管理
- 50 道 N5 级别题目（可扩展至 N1-N5 共 5 级）
- 支持题干图片、音频、读音标注
- 题目类型：单选、多选
- 题目排序、分类、标签

### 2. 练习模式
- 逐题答题，即时反馈
- 答案提交后显示详细解析
- 选项级别分析（为什么对/为什么错）
- 扩展练习（巩固知识点）

### 3. 考试模式
- 模拟考试环境
- 计时功能
- 批量提交评分
- 考试结果分析

### 4. 解析系统
- **Explanation**: 每题独立解析
  - 题目分析
  - 知识点讲解
  - 学习重点备注
- **OptionAnalysis**: 选项级别解析
  - 为什么正确/错误
  - 详细解析
  - 易错点提示
- **ExtensionExercise**: 扩展练习
  - 相关题型巩固
  - 标签关联
- **GrammarPoint**: 语法详解
  - 接续方式
  - 用法说明
  - 例句 + 翻译
  - 相似语法对比

### 5. 学习追踪
- **Record**: 答题记录
  - 每次答题自动保存
  - 用时、正确率统计
- **WrongBook**: 错题本
  - 自动收集错题
  - 支持重新练习
- **Review**: 复习系统
  - 间隔重复
  - 记忆曲线
  - 复习状态追踪

### 6. 统计分析
- 做题总数、正确率
- 各级别掌握度
- 学习时间统计
- 趋势分析图表

### 7. 音频系统
- 题干朗读
- 例句发音
- 听力练习
- Web/Mobile 双端支持

## 数据模型

### Question (题目)
```prisma
model Question {
  id              String   @id
  level           JLPTLevel
  type            QuestionType
  content         String   // 题干
  contentReading  String?  // 读音
  contentImageUrl String?  // 图片
  audioUrl        String?  // 音频
  options         Json     // [{id, content, index, hint?, reading?}]
  answer          String   // 正确选项 ID
  explanationId   String   // 关联解析 ID
  order           Int      // 题目顺序
}
```

### Explanation (解析)
```prisma
model Explanation {
  id               String  @id
  questionId       String
  analysis         String  // 题目分析
  note             String? // 学习重点
  optionAnalysis   Json    // [{optionId, isCorrect, reason, detail?, pitfall?}]
  extensions       Json    // [{id, type, content, options[], answer, explanation?}]
  grammarPoints    Json    // [{name, connection, meaning, usage, exampleSentence?}]
}
```

## API 端点

### 认证
- `POST /api/auth/register` - 用户注册
- `POST /api/auth/login` - 用户登录

### 题目
- `GET /api/questions` - 获取题目列表
- `GET /api/questions/:id` - 获取单题详情
- `GET /api/questions/level/:level` - 按级别获取

### 解析
- `GET /api/explanations/:id` - 获取解析详情
- `GET /api/explanations/question/:questionId` - 按题目获取

### 学习记录
- `POST /api/records` - 保存答题记录
- `GET /api/records` - 获取答题记录
- `GET /api/wrong-book` - 获取错题本
- `POST /api/review` - 添加复习项

### 统计
- `GET /api/stats/overview` - 统计概览
- `GET /api/stats/trends` - 趋势分析

## 版本历史

当前版本: **v1.1.0** (2026-10-19)

详细变更请查看 [CHANGELOG.md](./CHANGELOG.md)

### v1.1.0 (最新)
- ✅ 前后端数据模型统一
- ✅ Question/Grammar/OptionAnalysis 字段重构
- ✅ JLPTLevel 枚举大小写统一
- ✅ 修复重复数据 ID

### v1.0.0
- ✅ 项目结构统一为 monorepo
- ✅ 后端: Node.js + Express + Prisma
- ✅ 前端: Flutter 3.27.4 Web
- ✅ 50 道 N5 题目 + 完整解析系统

## 开发规范

### 提交信息格式
```
<type>(<scope>): <subject>

例:
feat(backend): 添加听力题型支持
fix(frontend): 修复答题页面音频播放问题
docs: 更新 API 文档
```

### 版本发布流程
详见 [VERSIONING.md](./VERSIONING.md)

## 数据资产

项目包含以下数据资源:

- **5 套 JLPT 真题 PDF**: N1-N5 词汇 + 答案
- **2018 年 JLPT 词汇数据**: JSON 格式
- **官方解析编辑数据**: 结构化 JSON
- **音频样本**: N5 级别听力材料
- **日语字体**: Noto Sans JP (Regular/Medium/Bold) + Noto Serif JP

## 路线图

### Phase 1 (已完成)
- [x] 项目结构统一
- [x] 基础题库系统
- [x] 答题/解析流程
- [x] 错题本/复习系统
- [x] 统计分析面板

### Phase 2 (计划中)
- [ ] 模拟考试系统增强
- [ ] 好友功能 & 排行榜
- [ ] 学习小组/社区
- [ ] 更多级别题目 (N4-N1)

### Phase 3 (未来)
- [ ] 移动端正式发布 (iOS/Android)
- [ ] 离线学习模式
- [ ] AI 辅助解析
- [ ] 个性化学习路径

## 许可证

本项目为专有软件 (Proprietary Software)，未经授权不得复制、分发或修改。

## 联系方式

如有问题或建议，请通过 GitHub Issues 反馈。
