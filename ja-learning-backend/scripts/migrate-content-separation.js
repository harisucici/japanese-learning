/** One-time remote Turso migration: retain articles and audio IDs, remove media metadata and personal data. */
require('dotenv').config();
const { createClient } = require('@libsql/client');

if (!process.env.TURSO_URL || !process.env.TURSO_AUTH_TOKEN) throw new Error('Turso content database is required');
const db = createClient({ url: process.env.TURSO_URL, authToken: process.env.TURSO_AUTH_TOKEN });
const count = async (sql, client = db) => Number((await client.execute(sql)).rows[0].n);
const hasTable = async name => !!(await db.execute({ sql: "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?", args: [name] })).rows.length;
const columns = async name => (await db.execute(`PRAGMA table_info("${name}")`)).rows.map(row => row.name);

async function main() {
  if (await hasTable('AnonymousLearner') && await hasTable('ArticleAudio') && !await hasTable('AudioAsset')) {
    await db.execute('DROP INDEX IF EXISTS "ArticleAudio_audioId_idx"');
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS "ArticleAudio_audioId_key" ON "ArticleAudio"("audioId")');
    if (await hasTable('NovelLesson')) {
      if (await count('SELECT count(*) AS n FROM "NovelLesson"')) throw new Error('Legacy NovelLesson contains data');
      await db.execute('DROP TABLE "NovelLesson"');
    }
    console.log(JSON.stringify({ alreadyMigrated: true })); return;
  }
  if (!await hasTable('User') || !await hasTable('AudioAsset') || !await hasTable('MaterialAudio')) {
    throw new Error('Unexpected content database schema');
  }
  const sourceLinks = await count('SELECT count(*) AS n FROM "MaterialAudio"');
  const validLinks = await count("SELECT count(*) AS n FROM \"MaterialAudio\" m JOIN \"AudioAsset\" a ON a.id=m.audioId WHERE a.storageProvider='cloudinary' AND a.id GLOB 'audio-[0-9][0-9][0-9]'");
  if (sourceLinks !== validLinks) throw new Error('Some audio links cannot be resolved by ID');
  const media = await count("SELECT count(*) AS n FROM \"StudyMaterial\" WHERE filename<>'' OR pages<>0 OR sha256<>'' OR fileUrl<>'' OR audioUrl IS NOT NULL OR videoUrl IS NOT NULL");
  if (media || await count('SELECT count(*) AS n FROM "Question" WHERE contentImageUrl IS NOT NULL OR audioUrl IS NOT NULL')) {
    throw new Error('Unexpected media fields contain data; migration stopped');
  }
  const hasLegacyNovel = await hasTable('NovelLesson');
  if (hasLegacyNovel && await count('SELECT count(*) AS n FROM "NovelLesson"')) {
    throw new Error('Legacy NovelLesson contains data; migration stopped');
  }
  const transaction = await db.transaction('write');
  try {
    await transaction.execute('CREATE TABLE "ArticleAudio" ("materialId" TEXT NOT NULL, "audioId" TEXT NOT NULL, "position" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("materialId","audioId"), FOREIGN KEY ("materialId") REFERENCES "StudyMaterial"("id") ON DELETE CASCADE ON UPDATE CASCADE)');
    await transaction.execute('INSERT INTO "ArticleAudio" ("materialId","audioId","position") SELECT "materialId","audioId","position" FROM "MaterialAudio"');
    if (await count('SELECT count(*) AS n FROM "ArticleAudio"', transaction) !== sourceLinks) throw new Error('Audio link copy count mismatch');
    await transaction.execute('CREATE UNIQUE INDEX "ArticleAudio_audioId_key" ON "ArticleAudio"("audioId")');
    await transaction.execute('DROP TABLE "MaterialAudio"');
    await transaction.execute('DROP TABLE "AudioAsset"');
    await transaction.execute('ALTER TABLE "User" RENAME TO "AnonymousLearner"');
    await transaction.execute('DROP INDEX "User_email_key"');
    for (const column of ['email','passwordHash','name','currentLevel','targetLevel','avatarUrl','streakDays','totalQuestions','accuracy']) {
      await transaction.execute(`ALTER TABLE "AnonymousLearner" DROP COLUMN "${column}"`);
    }
    for (const column of ['filename','pages','sha256','fileUrl','audioUrl','videoUrl']) {
      await transaction.execute(`ALTER TABLE "StudyMaterial" DROP COLUMN "${column}"`);
    }
    for (const column of ['contentImageUrl','audioUrl']) {
      await transaction.execute(`ALTER TABLE "Question" DROP COLUMN "${column}"`);
    }
    if (hasLegacyNovel) await transaction.execute('DROP TABLE "NovelLesson"');
    await transaction.commit();
  } catch (error) { await transaction.rollback(); throw error; }
  const learnerColumns = await columns('AnonymousLearner');
  if (learnerColumns.includes('email') || await hasTable('AudioAsset')) throw new Error('Post-migration schema validation failed');
  console.log(JSON.stringify({ migrated: true, articleAudioLinks: await count('SELECT count(*) AS n FROM "ArticleAudio"'), anonymousLearners: await count('SELECT count(*) AS n FROM "AnonymousLearner"') }));
}
main().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => db.close());
