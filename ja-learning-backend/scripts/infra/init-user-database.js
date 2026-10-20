/** Initialize the separate, initially empty Turso account database. */
require('dotenv').config();
const fs = require('node:fs');
const path = require('node:path');
const { createClient } = require('@libsql/client');

if (!process.env.USER_TURSO_URL) {
  console.error('USER_TURSO_URL is required');
  process.exit(1);
}
if (process.env.USER_TURSO_URL === process.env.TURSO_URL) {
  console.error('The user database must be separate from the content database');
  process.exit(1);
}
const client = createClient({ url: process.env.USER_TURSO_URL, authToken: process.env.USER_TURSO_AUTH_TOKEN || undefined });
async function main() {
  const existing = (await client.execute('PRAGMA table_info("User")')).rows;
  const oldColumns = new Map(existing.map(row => [String(row.name), row]));
  if (oldColumns.size && (!oldColumns.has('username') || !oldColumns.has('nickname') || Number(oldColumns.get('email')?.notnull) === 1)) {
    const originalCount = Number((await client.execute('SELECT count(*) AS n FROM "User"')).rows[0].n);
    const value = (name, fallback) => oldColumns.has(name) ? `"${name}"` : fallback;
    const nickname = oldColumns.has('nickname') ? '"nickname"' : value('name', "'学习者'");
    await client.batch([
      `CREATE TABLE "User_v2" ("id" TEXT PRIMARY KEY NOT NULL, "username" TEXT UNIQUE, "email" TEXT UNIQUE, "passwordHash" TEXT NOT NULL, "nickname" TEXT NOT NULL, "role" TEXT NOT NULL DEFAULT 'learner', "currentLevel" TEXT NOT NULL DEFAULT 'n5', "targetLevel" TEXT NOT NULL DEFAULT 'n5', "avatarUrl" TEXT, "resetToken" TEXT, "resetTokenExpiry" TEXT, "createdAt" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, CHECK ("username" IS NOT NULL OR "email" IS NOT NULL))`,
      `INSERT INTO "User_v2" ("id", "username", "email", "passwordHash", "nickname", "role", "currentLevel", "targetLevel", "avatarUrl", "resetToken", "resetTokenExpiry", "createdAt", "updatedAt") SELECT "id", ${value('username', 'NULL')}, ${value('email', 'NULL')}, "passwordHash", ${nickname}, ${value('role', "'learner'")}, ${value('currentLevel', "'n5'")}, ${value('targetLevel', "'n5'")}, ${value('avatarUrl', 'NULL')}, ${value('resetToken', 'NULL')}, ${value('resetTokenExpiry', 'NULL')}, ${value('createdAt', 'CURRENT_TIMESTAMP')}, ${value('updatedAt', 'CURRENT_TIMESTAMP')} FROM "User"`,
      'DROP TABLE "User"',
      'ALTER TABLE "User_v2" RENAME TO "User"',
    ], 'write');
    const migratedCount = Number((await client.execute('SELECT count(*) AS n FROM "User"')).rows[0].n);
    if (migratedCount !== originalCount) throw new Error('User table migration count mismatch');
  }
  const sql = fs.readFileSync(path.join(__dirname, '../../prisma/user-schema.sql'), 'utf8').replace(/^--.*$/gm, '').trim();
  await client.executeMultiple(sql);
  const result = await client.execute('SELECT count(*) AS count FROM "User"');
  console.log(JSON.stringify({ initialized: true, users: Number(result.rows[0].count) }));
}
main().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => client.close());
