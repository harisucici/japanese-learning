import { createClient } from '@libsql/client';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = '/Volumes/Mac Data/Documents/StudioProjects/japanese-learning/ja-learning-backend';

const TURSO_URL = process.env.TURSO_URL || 'libsql://japanese-learning-harisucici.aws-ap-northeast-1.turso.io';
const TURSO_AUTH_TOKEN = process.env.TURSO_AUTH_TOKEN || '';

const schemaSql = fs.readFileSync(path.join(ROOT, 'prisma/dev.db.schema.sql'), 'utf8');

async function main() {
  const client = createClient({
    url: TURSO_URL,
    authToken: TURSO_AUTH_TOKEN,
  });

  // Execute each statement
  const statements = schemaSql
    .split(';')
    .map(s => s.trim())
    .filter(s => s.length > 0);

  console.log(`Found ${statements.length} statements`);

  for (let i = 0; i < statements.length; i++) {
    const stmt = statements[i];
    try {
      await client.execute({ sql: stmt, args: [] });
      const preview = stmt.split('\n')[0].slice(0, 80);
      console.log(`[${i + 1}/${statements.length}] OK: ${preview}`);
    } catch (err) {
      console.error(`[${i + 1}] FAIL: ${err.message}`);
      console.error(`  SQL: ${stmt.slice(0, 200)}`);
      // Continue — some statements may already exist (e.g. UNIQUE indexes)
    }
  }

  // Verify
  const tables = await client.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name");
  console.log('\nTables in Turso:', tables.rows.map(r => r[0]));

  const idxCount = await client.execute("SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'");
  console.log('Indexes:', idxCount.rows.length);

  client.close();
}

main().catch(err => { console.error(err); process.exit(1); });
