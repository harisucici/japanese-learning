/** Initialize the separate, initially empty Turso account database. */
require('dotenv').config();
const fs = require('node:fs');
const path = require('node:path');
const { createClient } = require('@libsql/client');

if (!process.env.USER_TURSO_URL || !process.env.USER_TURSO_AUTH_TOKEN) {
  console.error('USER_TURSO_URL and USER_TURSO_AUTH_TOKEN are required');
  process.exit(1);
}
if (process.env.USER_TURSO_URL === process.env.TURSO_URL) {
  console.error('The user database must be separate from the content database');
  process.exit(1);
}
const client = createClient({ url: process.env.USER_TURSO_URL, authToken: process.env.USER_TURSO_AUTH_TOKEN });
async function main() {
  const sql = fs.readFileSync(path.join(__dirname, '../prisma/user-schema.sql'), 'utf8').replace(/^--.*$/gm, '').trim();
  await client.execute(sql);
  const result = await client.execute('SELECT count(*) AS count FROM "User"');
  console.log(JSON.stringify({ initialized: true, users: Number(result.rows[0].count) }));
}
main().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => client.close());
