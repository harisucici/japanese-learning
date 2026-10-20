/** Copy legacy personal learning rows from the content database into USER_TURSO_URL.
 * Run db:init:users first. Defaults to a read-only count preview; --apply copies
 * rows idempotently and never deletes source data. Back up both databases first.
 */
require('dotenv').config();
const { createClient } = require('@libsql/client');

const sourceUrl = process.env.TURSO_URL;
const targetUrl = process.env.USER_TURSO_URL;
if (!sourceUrl || !targetUrl || sourceUrl === targetUrl) {
  console.error('TURSO_URL and a separate USER_TURSO_URL are required');
  process.exit(1);
}
const source = createClient({ url: sourceUrl, authToken: process.env.TURSO_AUTH_TOKEN || undefined });
const target = createClient({ url: targetUrl, authToken: process.env.USER_TURSO_AUTH_TOKEN || undefined });
const tables = ['AnonymousLearner', 'LearningSession', 'LearningAnswer', 'ExamRecord', 'ReviewItem'];
const apply = process.argv.includes('--apply');

async function count(db, table) {
  try {
    const result = await db.execute(`SELECT count(*) AS total FROM "${table}"`);
    return Number(result.rows[0].total);
  } catch (error) {
    if (String(error.message).includes('no such table')) {
      throw new Error(`Missing ${table} in one database. Run npm run db:init:users for the separate user database before previewing or applying this migration.`);
    }
    throw error;
  }
}

async function main() {
  for (const table of tables) {
    const before = await count(target, table);
    const from = await count(source, table);
    if (apply && from) {
      const rows = (await source.execute(`SELECT * FROM "${table}"`)).rows;
      const targetFields = new Set((await target.execute(`PRAGMA table_info("${table}")`)).rows.map(r => String(r.name)));
      for (let offset = 0; offset < rows.length; offset += 100) {
        const batch = rows.slice(offset, offset + 100).map(row => {
          const columns = Object.keys(row).filter(key => targetFields.has(key));
          return {
            sql: `INSERT OR IGNORE INTO "${table}" (${columns.map(c => `"${c}"`).join(',')}) VALUES (${columns.map(() => '?').join(',')})`,
            args: columns.map(c => row[c]),
          };
        });
        await target.batch(batch, 'write');
      }
    }
    const after = await count(target, table);
    console.log(`${table}: source=${from}, targetBefore=${before}, targetAfter=${after}`);
    if (apply && after < from) throw new Error(`${table}: target row count is lower than source; inspect duplicates before cutover`);
  }
  console.log(apply ? 'Copy complete. Source rows remain untouched.' : 'Read-only preview. Pass --apply to copy.');
}

main().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => {
  source.close();
  target.close();
});
