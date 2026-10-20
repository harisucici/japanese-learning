-- User Schema (用户库)
-- 独立 Turso 数据库，存储注册用户账号信息
-- 配置: USER_TURSO_URL
--
-- User 账号表由 libSQL 服务访问；学习记录通过同一个 Prisma Client
-- 连接 USER_TURSO_URL。用户库初始化: npm run db:init:users。
--
-- 关联: 注册用户在本库的 AnonymousLearner 表中拥有同 ID 记录；
--       LearningSession / LearningAnswer / ReviewItem 通过 userId 关联。

CREATE TABLE IF NOT EXISTS "User" (
  "id" TEXT PRIMARY KEY NOT NULL,
  "username" TEXT UNIQUE,
  "email" TEXT UNIQUE,
  "passwordHash" TEXT NOT NULL,
  "nickname" TEXT NOT NULL,                    -- 用户昵称
  "role" TEXT NOT NULL DEFAULT 'learner',       -- learner | admin
  "currentLevel" TEXT NOT NULL DEFAULT 'n5',   -- JLPTLevel: n5 | n4 | n3 | n2 | n1
  "targetLevel" TEXT NOT NULL DEFAULT 'n5',    -- JLPTLevel: n5 | n4 | n3 | n2 | n1
  "avatarUrl" TEXT,
  "resetToken" TEXT,                           -- 密码找回 token
  "resetTokenExpiry" TEXT,                     -- token 过期时间 (ISO 8601)
  "createdAt" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK ("username" IS NOT NULL OR "email" IS NOT NULL)
);

-- 索引
CREATE INDEX IF NOT EXISTS "idx_user_email" ON "User"("email");
CREATE UNIQUE INDEX IF NOT EXISTS "idx_user_username" ON "User"("username");
CREATE INDEX IF NOT EXISTS "idx_user_reset_token" ON "User"("resetToken");

-- Personal learning data. Question IDs refer to the separate shared content database,
-- so they are deliberately not declared as cross-database foreign keys.
CREATE TABLE IF NOT EXISTS "AnonymousLearner" (
  "id" TEXT PRIMARY KEY NOT NULL,
  "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS "LearningSession" (
  "id" TEXT PRIMARY KEY NOT NULL,
  "userId" TEXT NOT NULL,
  "level" TEXT NOT NULL,
  "mode" TEXT NOT NULL DEFAULT 'practice',
  "examConfig" JSONB,
  "collectionId" TEXT,
  "questionIds" JSONB NOT NULL,
  "currentIndex" INTEGER NOT NULL DEFAULT 0,
  "awaitingNext" BOOLEAN NOT NULL DEFAULT false,
  "completedAt" DATETIME,
  "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("userId") REFERENCES "AnonymousLearner"("id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "LearningAnswer" (
  "id" TEXT PRIMARY KEY NOT NULL,
  "sessionId" TEXT NOT NULL,
  "questionId" TEXT NOT NULL,
  "selectedOptionId" TEXT NOT NULL,
  "isCorrect" BOOLEAN NOT NULL,
  "answeredAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("sessionId") REFERENCES "LearningSession"("id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "ExamRecord" (
  "id" TEXT PRIMARY KEY NOT NULL,
  "userId" TEXT NOT NULL,
  "level" TEXT NOT NULL,
  "recordType" TEXT NOT NULL,
  "questionIds" JSONB NOT NULL,
  "answers" JSONB NOT NULL,
  "score" INTEGER NOT NULL DEFAULT 0,
  "totalQuestions" INTEGER NOT NULL,
  "correctCount" INTEGER NOT NULL DEFAULT 0,
  "durationMs" INTEGER NOT NULL,
  "completedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("userId") REFERENCES "AnonymousLearner"("id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "ReviewItem" (
  "id" TEXT PRIMARY KEY NOT NULL,
  "userId" TEXT NOT NULL,
  "questionId" TEXT NOT NULL,
  "level" TEXT NOT NULL,
  "type" TEXT NOT NULL,
  "status" TEXT NOT NULL DEFAULT 'new_',
  "reviewCount" INTEGER NOT NULL DEFAULT 0,
  "nextReviewAt" DATETIME,
  "easeFactor" REAL NOT NULL DEFAULT 2.5,
  "intervalDays" INTEGER NOT NULL DEFAULT 0,
  "isFavorite" BOOLEAN NOT NULL DEFAULT false,
  "isWrongAnswer" BOOLEAN NOT NULL DEFAULT false,
  "wrongCount" INTEGER NOT NULL DEFAULT 0,
  "correctStreak" INTEGER NOT NULL DEFAULT 0,
  "lastCorrectAt" DATETIME,
  "reviewMode" TEXT NOT NULL DEFAULT 'original',
  "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("userId") REFERENCES "AnonymousLearner"("id") ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS "LearningSession_userId_createdAt_idx" ON "LearningSession"("userId", "createdAt");
CREATE INDEX IF NOT EXISTS "LearningAnswer_sessionId_idx" ON "LearningAnswer"("sessionId");
CREATE UNIQUE INDEX IF NOT EXISTS "LearningAnswer_sessionId_questionId_key" ON "LearningAnswer"("sessionId", "questionId");
CREATE INDEX IF NOT EXISTS "ExamRecord_userId_idx" ON "ExamRecord"("userId");
CREATE INDEX IF NOT EXISTS "ExamRecord_userId_createdAt_idx" ON "ExamRecord"("userId", "createdAt");
CREATE INDEX IF NOT EXISTS "ReviewItem_userId_nextReviewAt_idx" ON "ReviewItem"("userId", "nextReviewAt");
CREATE INDEX IF NOT EXISTS "ReviewItem_userId_status_idx" ON "ReviewItem"("userId", "status");
CREATE UNIQUE INDEX IF NOT EXISTS "ReviewItem_userId_questionId_key" ON "ReviewItem"("userId", "questionId");
