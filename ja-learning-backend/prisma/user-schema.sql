-- User Schema (用户库)
-- 独立 Turso 数据库，存储注册用户账号信息
-- 配置: USER_TURSO_URL
--
-- 注意: 此表不纳入 Prisma 管理，因为:
-- 1. 用户库和内容库是分开的两个 Turso 数据库
-- 2. Prisma 只连接内容库 (DATABASE_URL)
-- 3. 用户库初始化: npm run db:init:users

CREATE TABLE IF NOT EXISTS "User" (
  "id" TEXT PRIMARY KEY NOT NULL,
  "email" TEXT NOT NULL UNIQUE,
  "passwordHash" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "currentLevel" TEXT NOT NULL DEFAULT 'n5',  -- JLPTLevel
  "targetLevel" TEXT NOT NULL DEFAULT 'n5',    -- JLPTLevel
  "avatarUrl" TEXT,
  "createdAt" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 索引（可选，按需启用）
-- CREATE INDEX IF NOT EXISTS "idx_user_email" ON "User"("email");
-- CREATE INDEX IF NOT EXISTS "idx_user_level" ON "User"("currentLevel", "targetLevel");
