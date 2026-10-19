# Japanese Learning Platform Backend

日语学习平台后端 API 服务，支持用户认证、题库管理、答题记录、复习系统等。

## 技术栈

- Node.js + Express + TypeScript
- PostgreSQL + Prisma ORM
- JWT 认证
- RESTful API

## 项目路径

```
/Volumes/Mac Data/Documents/StudioProjects/ja-learning-backend/
```

## 快速开始

### 1. 安装依赖

```bash
cd "/Volumes/Mac Data/Documents/StudioProjects/ja-learning-backend"
npm install
```

### 2. 配置数据库

编辑 `.env` 文件，配置 PostgreSQL 连接：

```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/ja_learning"
JWT_SECRET="your-secret-key-here"
PORT=3000
NODE_ENV="development"
```

### 3. 创建数据库

```bash
# 使用 psql 或 pgAdmin 创建数据库
createdb -U postgres ja_learning
```

### 4. 运行数据库迁移

```bash
npm run prisma:migrate
```

### 5. 生成 Prisma Client

```bash
npm run prisma:generate
```

### 6. 启动开发服务器

```bash
npm run dev
```

服务将在 `http://localhost:3000` 启动。

## API 端点

### 认证模块

#### POST /api/v1/auth/login

用户登录

**请求体:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**响应:**
```json
{
  "token": "jwt-token-here",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "User Name",
    "currentLevel": "N5",
    "targetLevel": "N4",
    "streakDays": 0,
    "totalQuestions": 0,
    "accuracy": 0,
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
}
```

#### POST /api/v1/auth/register

用户注册

**请求体:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "User Name",
  "targetLevel": "N5"
}
```

**响应:** 同 login

#### GET /api/v1/auth/me

获取当前用户信息

**请求头:**
```
Authorization: Bearer <token>
```

**响应:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "User Name",
    "currentLevel": "N5",
    "targetLevel": "N4",
    "streakDays": 0,
    "totalQuestions": 0,
    "accuracy": 0,
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### 题库模块

#### GET /api/v1/questions

获取题目列表

**查询参数:**
- `level` (可选): N5, N4, N3, N2, N1
- `type` (可选): vocabulary, kanji, grammar, reading, listening, fillInBlank, comprehensive
- `limit` (可选): 返回数量，默认 20
- `offset` (可选): 偏移量，默认 0

**响应:**
```json
{
  "items": [
    {
      "id": "uuid",
      "level": "N5",
      "type": "vocabulary",
      "content": "题目内容",
      "options": [{"optionId": "opt1", "text": "选项1"}],
      "answer": "opt1",
      "source": "official",
      "tags": ["tag1", "tag2"],
      "difficulty": 0.5,
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "total": 100
}
```

#### GET /api/v1/questions/:id

获取单个题目

**响应:** 题目对象

#### GET /api/v1/questions/level/:level

按等级获取题目

**响应:** 题目数组

### 答题记录

#### POST /api/v1/records

创建答题记录

**请求头:**
```
Authorization: Bearer <token>
```

**请求体:**
```json
{
  "level": "N5",
  "recordType": "practice",
  "questionIds": ["q1", "q2", "q3"],
  "answers": [
    {"questionId": "q1", "selectedOptionId": "opt1", "isCorrect": true},
    {"questionId": "q2", "selectedOptionId": "opt2", "isCorrect": false},
    {"questionId": "q3", "selectedOptionId": "opt3", "isCorrect": true}
  ],
  "durationMs": 120000
}
```

**响应:**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "level": "N5",
  "recordType": "practice",
  "questionIds": ["q1", "q2", "q3"],
  "answers": [...],
  "score": 67,
  "totalQuestions": 3,
  "correctCount": 2,
  "durationMs": 120000,
  "completedAt": "2024-01-01T00:00:00.000Z"
}
```

#### GET /api/v1/records/user/:userId

获取用户答题记录

**响应:** 记录数组

### 复习系统

#### GET /api/v1/review/items

获取复习项列表

**请求头:**
```
Authorization: Bearer <token>
```

**查询参数:**
- `userId` (可选): 用户 ID，默认使用 token 中的用户
- `due` (可选): true 表示只返回到期项目

**响应:**
```json
[
  {
    "id": "uuid",
    "userId": "uuid",
    "questionId": "uuid",
    "level": "N5",
    "type": "vocabulary",
    "status": "learning",
    "reviewCount": 3,
    "nextReviewAt": "2024-01-02T00:00:00.000Z",
    "easeFactor": 2.5,
    "intervalDays": 6,
    "isFavorite": false,
    "isWrongAnswer": true,
    "wrongCount": 2,
    "correctStreak": 1,
    "question": {...}
  }
]
```

#### POST /api/v1/review/mark

标记复习结果

**请求头:**
```
Authorization: Bearer <token>
```

**请求体:**
```json
{
  "itemId": "uuid",
  "correct": true
}
```

**响应:** 更新后的复习项

### 解析模块

#### GET /api/v1/explanations/question/:questionId

获取题目解析

**响应:**
```json
{
  "id": "uuid",
  "questionId": "uuid",
  "translation": "整体翻译",
  "wordAnalysis": [
    {"word": "単語", "reading": "たんご", "meaning": "意思"}
  ],
  "sentenceStructure": "句子结构说明",
  "grammar": [
    {"point": "文型", "explanation": "说明"}
  ],
  "optionAnalysis": [
    {"optionId": "opt1", "analysis": "分析"}
  ],
  "extensions": [
    {"type": "exercise", "content": "内容"}
  ]
}
```

## 数据模型

### User

```prisma
model User {
  id            String    @id @default(uuid())
  email         String    @unique
  passwordHash  String
  name          String
  currentLevel  JLPTLevel
  targetLevel   JLPTLevel
  avatarUrl     String?
  streakDays    Int
  totalQuestions Int
  accuracy      Float
  createdAt     DateTime
  updatedAt     DateTime
}
```

### Question

```prisma
model Question {
  id            String
  level         JLPTLevel
  type          QuestionType
  content       String
  options       Json
  answer        String
  source        QuestionSource
  tags          String[]
  difficulty    Float
  createdAt     DateTime
  updatedAt     DateTime
}
```

### Explanation

```prisma
model Explanation {
  id                String
  questionId        String
  translation       String
  wordAnalysis      Json
  sentenceStructure String
  grammar           Json
  optionAnalysis    Json
  extensions        Json
  createdAt         DateTime
  updatedAt         DateTime
}
```

### ExamRecord

```prisma
model ExamRecord {
  id              String
  userId          String
  level           JLPTLevel
  recordType      ExamRecordType
  questionIds     String[]
  answers         Json
  score           Int
  totalQuestions  Int
  correctCount    Int
  durationMs      Int
  completedAt     DateTime
  createdAt       DateTime
}
```

### ReviewItem

```prisma
model ReviewItem {
  id              String
  userId          String
  questionId      String
  level           JLPTLevel
  type            QuestionType
  status          ReviewStatus
  reviewCount     Int
  nextReviewAt    DateTime?
  easeFactor      Float
  intervalDays    Int
  isFavorite      Boolean
  isWrongAnswer   Boolean
  wrongCount      Int
  correctStreak   Int
  createdAt       DateTime
  updatedAt       DateTime
}
```

## 枚举定义

```typescript
// JLPTLevel
enum JLPTLevel {
  N5, N4, N3, N2, N1
}

// QuestionType
enum QuestionType {
  vocabulary,    // 文字・語彙
  kanji,         // 漢字
  grammar,       // 文法
  reading,       // 読解
  listening,     // 聴解
  fillInBlank,   // 文脈規定
  comprehensive  // 総合
}

// QuestionSource
enum QuestionSource {
  official,       // 真题
  mock,           // 模拟题
  textbook,       // 教材题
  userGenerated,  // 用户生成
  aiGenerated,    // AI 生成
  pastExam,       // 历年真题
  custom          // 自定义
}

// ExamRecordType
enum ExamRecordType {
  practice,  // 练习
  exam,      // 考试
  review     // 复习
}

// ReviewStatus
enum ReviewStatus {
  new,       // 新题
  learning,  // 学习中
  reviewing, // 复习中
  mastered   // 已掌握
}
```

## 项目结构

```
ja-learning-backend/
├── src/
│   ├── index.ts                 # 入口文件
│   ├── app.ts                   # Express 配置
│   ├── config/
│   │   ├── database.ts          # Prisma 客户端
│   │   ├── env.ts               # 环境变量
│   │   └── validators.ts        # Zod 验证器
│   ├── controllers/
│   │   ├── auth.controller.ts
│   │   ├── question.controller.ts
│   │   ├── record.controller.ts
│   │   ├── review.controller.ts
│   │   └── explanation.controller.ts
│   ├── services/
│   │   ├── auth.service.ts
│   │   ├── question.service.ts
│   │   ├── record.service.ts
│   │   ├── review.service.ts
│   │   └── explanation.service.ts
│   ├── routes/
│   │   ├── auth.routes.ts
│   │   ├── question.routes.ts
│   │   ├── record.routes.ts
│   │   ├── review.routes.ts
│   │   └── explanation.routes.ts
│   └── middleware/
│       └── auth.ts              # JWT 认证中间件
├── prisma/
│   └── schema.prisma            # 数据库模型
├── .env                         # 环境变量
├── .gitignore
├── package.json
├── tsconfig.json
└── README.md
```

## 启动命令

```bash
# 开发环境
npm run dev

# 构建生产版本
npm run build

# 启动生产版本
npm start

# 数据库迁移
npm run prisma:migrate

# 生成 Prisma Client
npm run prisma:generate

# Prisma Studio (数据库可视化)
npm run prisma:studio
```

## API 文档

- Base URL: `http://localhost:3000`
- 所有 API 前缀: `/api/v1`
- 认证方式: JWT Bearer Token

## 注意事项

1. 确保 PostgreSQL 服务已启动
2. 创建 `ja_learning` 数据库
3. 修改 `.env` 中的数据库连接配置
4. 运行 `npm run prisma:migrate` 创建表结构
5. 开发模式下使用 `npm run dev`，支持热重载

## 下一步

- [ ] 添加题目种子数据
- [ ] 实现解析数据的种子数据
- [ ] 添加更多验证逻辑
- [ ] 实现用户统计信息更新
- [ ] 添加单元测试
- [ ] 添加 API 文档生成器 (Swagger/OpenAPI)
