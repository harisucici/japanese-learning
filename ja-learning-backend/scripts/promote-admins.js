/**
 * promote-admins.js
 * Promote users 'admin' and 'harisucici' to the admin role.
 * Target: User table on the USER_TURSO_URL Turso database.
 * Usage: node scripts/promote-admins.js
 */
require('dotenv').config();
const { createClient } = require('@libsql/client');

const TARGETS = ['admin', 'harisucici'];

async function main() {
  if (!process.env.USER_TURSO_URL || !process.env.USER_TURSO_AUTH_TOKEN) {
    throw new Error('Missing USER_TURSO_URL or USER_TURSO_AUTH_TOKEN in .env');
  }
  const client = createClient({
    url: process.env.USER_TURSO_URL,
    authToken: process.env.USER_TURSO_AUTH_TOKEN,
  });

  try {
    // 1. Show BEFORE state
    const beforeRes = await client.execute({
      sql: 'SELECT id, username, email, nickname, role FROM "User" WHERE username IN (?, ?) OR email IN (?, ?)',
      args: [...TARGETS, ...TARGETS],
    });
    console.log('\n=== BEFORE ===');
    console.table(
      beforeRes.rows.map((r) => ({
        id: r.id,
        username: r.username,
        email: r.email,
        nickname: r.nickname,
        role: r.role,
      })),
    );

    // 2. Update role to 'admin' for matched users that are not already admin
    const updateRes = await client.execute({
      sql: 'UPDATE "User" SET role = \'admin\', "updatedAt" = CURRENT_TIMESTAMP WHERE (username IN (?, ?) OR email IN (?, ?)) AND role != \'admin\'',
      args: [...TARGETS, ...TARGETS],
    });
    console.log(`\nUpdated rows: ${updateRes.rowsAffected}`);

    // 3. Show AFTER state + verify
    const afterRes = await client.execute({
      sql: 'SELECT id, username, email, nickname, role FROM "User" WHERE username IN (?, ?) OR email IN (?, ?)',
      args: [...TARGETS, ...TARGETS],
    });
    console.log('\n=== AFTER ===');
    console.table(
      afterRes.rows.map((r) => ({
        id: r.id,
        username: r.username,
        email: r.email,
        nickname: r.nickname,
        role: r.role,
      })),
    );

    // 4. Verification
    const nonAdmin = afterRes.rows.filter((r) => r.role !== 'admin');
    if (nonAdmin.length > 0) {
      console.warn(`\n⚠️  WARNING: ${nonAdmin.length} target(s) still not admin:`, nonAdmin.map((r) => r.username || r.email));
      process.exitCode = 1;
    } else {
      console.log(`\n✅ All ${afterRes.rows.length} target user(s) are now admin.`);
    }
  } finally {
    await client.close();
  }
}

main().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
