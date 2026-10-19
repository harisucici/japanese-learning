-- Run against a separate Turso database configured as USER_TURSO_URL.
-- The table starts empty; the content database stores only opaque learner IDs.
CREATE TABLE IF NOT EXISTS "User" (
  "id" TEXT PRIMARY KEY NOT NULL,
  "email" TEXT NOT NULL UNIQUE,
  "passwordHash" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "currentLevel" TEXT NOT NULL DEFAULT 'n5',
  "targetLevel" TEXT NOT NULL DEFAULT 'n5',
  "avatarUrl" TEXT,
  "createdAt" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
