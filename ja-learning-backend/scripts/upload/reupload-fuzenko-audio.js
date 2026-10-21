#!/usr/bin/env node
/**
 * 清空 Cloudinary 上 ja-learning/audio 目录下的所有资源，
 * 然后从本地「附赠100篇（音频+PDF）」文件夹批量上传 MP3，
 * 并在 ArticleAudio 表建立关联。
 *
 * 编号映射:
 *   文件夹 1.暑假里想做的事 → material-001 / audio-001
 *   文件夹 2.我的奶奶 → material-002 / audio-002
 *   ...
 *   文件夹 100.布丁 → material-100 / audio-100
 */

require('dotenv').config();
const cloudinary = require('cloudinary').v2;
const path = require('path');
const fs = require('fs');
const { createClient } = require('@libsql/client');
const { PrismaClient } = require('@prisma/client');
const { PrismaLibSQL } = require('@prisma/adapter-libsql');

const SOURCE_DIR = '/Volumes/Mac Data/Documents/阅读PDF/附赠100篇（音频+PDF）';

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// ── helpers ──────────────────────────────────────────────────────────────────

/** Delete ALL resources under ja-learning/audio (paginated, max 100 per delete). */
async function clearCloudinaryAudio() {
  let totalDeleted = 0;
  let nextCursor = undefined;
  do {
    const res = await cloudinary.api.resources_by_asset_folder(
      'ja-learning/audio',
      { max_results: 100, type: 'upload', resource_type: 'video', next_cursor: nextCursor }
    );
    const publicIds = res.resources.map(r => r.public_id);
    if (publicIds.length === 0) break;
    
    // Cloudinary API limits to 100 public_ids per delete call
    for (let i = 0; i < publicIds.length; i += 100) {
      const batch = publicIds.slice(i, i + 100);
      await cloudinary.api.delete_resources(batch, { resource_type: 'video', type: 'upload' });
    }
    
    totalDeleted += publicIds.length;
    nextCursor = res.next_cursor;
  } while (nextCursor);
  return totalDeleted;
}

/**
 * Given a folder like "19.放暑假", find the audio file inside it.
 * Returns the full path or null.
 */
function findAudioInFolder(folderPath) {
  const files = fs.readdirSync(folderPath);
  const audio = files.find(f => /\.(mp3|mp4|m4a|wav)$/i.test(f));
  return audio ? path.join(folderPath, audio) : null;
}

/**
 * Extract the leading numeric index from a folder name like "1.暑假里想做的事".
 */
function folderIndex(folderName) {
  const m = folderName.match(/^(\d+)\./);
  return m ? parseInt(m[1], 10) : null;
}

// ── main ─────────────────────────────────────────────────────────────────────

async function main() {
  if (!process.env.TURSO_URL || !process.env.TURSO_AUTH_TOKEN) {
    throw new Error('TURSO_URL / TURSO_AUTH_TOKEN must be set');
  }

  // 1) Clear existing Cloudinary audio
  console.log('🗑️  Clearing existing audio from Cloudinary (ja-learning/audio)…');
  const deleted = await clearCloudinaryAudio();
  console.log(`   Deleted ${deleted} existing resources.\n`);

  // 2) Enumerate folders
  const folders = fs.readdirSync(SOURCE_DIR)
    .filter(name => fs.statSync(path.join(SOURCE_DIR, name)).isDirectory() && /^\d+\./.test(name))
    .sort((a, b) => folderIndex(a) - folderIndex(b));

  console.log(`📁 Found ${folders.length} numbered folders.\n`);

  // 3) Upload
  const uploads = [];        // { idx, audioId, filePath }
  const mismatches = [];     // folders that had no audio or couldn't be matched

  for (const folderName of folders) {
    const idx = folderIndex(folderName);
    if (idx == null) { mismatches.push(`${folderName}: cannot parse index`); continue; }
    const folderPath = path.join(SOURCE_DIR, folderName);
    const audioPath = findAudioInFolder(folderPath);
    if (!audioPath) {
      mismatches.push(`${folderName}: no audio file found`);
      continue;
    }
    const audioId = `audio-${String(idx).padStart(3, '0')}`;
    uploads.push({ idx, audioId, filePath: audioPath, folderName });
  }

  console.log(`📤 Uploading ${uploads.length} audio files (concurrency=3)…\n`);

  const CONCURRENCY = 3;
  const uploaded = [];

  for (let i = 0; i < uploads.length; i += CONCURRENCY) {
    const batch = uploads.slice(i, i + CONCURRENCY);
    const results = await Promise.all(batch.map(async (u) => {
      try {
        const result = await cloudinary.uploader.upload(u.filePath, {
          resource_type: 'video',
          folder: 'ja-learning/audio',
          public_id: u.audioId,
          format: 'mp3',
          overwrite: true,
        });
        console.log(`   [${String(u.idx).padStart(3,'0')}] ✅ ${u.audioId}  ← ${path.basename(u.filePath)}`);
        return { ...u, secure_url: result.secure_url, public_id: result.public_id };
      } catch (err) {
        console.error(`   [${String(u.idx).padStart(3,'0')}] ❌ ${u.audioId}: ${err.message}`);
        return { ...u, error: err.message };
      }
    }));
    uploaded.push(...results);
  }

  const successes = uploaded.filter(r => !r.error);
  const failures = uploaded.filter(r => r.error);

  console.log(`\n📊 Upload: ${successes.length} ok, ${failures.length} failed.\n`);

  // 4) Connect to Turso and write ArticleAudio rows
  const adapter = new PrismaLibSQL({
    url: process.env.TURSO_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
  });
  const prisma = new PrismaClient({ adapter });

  // Clear existing ArticleAudio rows (and any orphaned ones)
  console.log('🗑️  Clearing existing ArticleAudio rows in Turso…');
  const existingLinks = await prisma.articleAudio.count();
  await prisma.articleAudio.deleteMany({});
  console.log(`   Removed ${existingLinks} existing rows.`);

  // Also clear any old audioUrl on StudyMaterial (the legacy field isn't in schema
  // anymore, but the old script wrote to it — skip if not present).

  let linked = 0;
  const linkMismatches = [];

  for (const s of successes) {
    const materialId = `material-${String(s.idx).padStart(3, '0')}`;
    // Verify material exists
    const mat = await prisma.studyMaterial.findUnique({ where: { id: materialId } });
    if (!mat) {
      linkMismatches.push(`${s.folderName}: material ${materialId} not found in Turso`);
      continue;
    }
    try {
      await prisma.articleAudio.create({
        data: { materialId, audioId: s.audioId, position: 0 }
      });
      linked++;
    } catch (err) {
      linkMismatches.push(`${s.folderName}: ${err.message}`);
    }
  }

  console.log(`\n🔗 Linked ${linked}/${successes.length} audio → articles.\n`);

  await prisma.$disconnect();

  // 5) Summary
  const allMismatches = [...mismatches, ...linkMismatches, ...failures.map(f => `${f.folderName}: upload failed – ${f.error}`)];
  console.log('═'.repeat(60));
  console.log('SUMMARY');
  console.log(`  Cloudinary cleared     : ${deleted} resources removed`);
  console.log(`  Audio uploaded         : ${successes.length} / ${folders.length} folders`);
  console.log(`  ArticleAudio linked    : ${linked}`);
  console.log(`  Mismatches / failures  : ${allMismatches.length}`);
  if (allMismatches.length > 0) {
    console.log('\n⚠️  Mismatches:');
    allMismatches.forEach(m => console.log(`   • ${m}`));
  }

  // 6) Verify by reading back a few URLs from Turso
  console.log('\n🔍 Verification — first 3 ArticleAudio rows:');
  const verify = await prisma.articleAudio.findMany({ take: 3, include: { material: { select: { id: true, title: true } } } });
  const audioBase = process.env.AUDIO_PUBLIC_BASE_URL
    || `https://res.cloudinary.com/${process.env.CLOUDINARY_CLOUD_NAME}/video/upload/ja-learning/audio`;
  for (const row of verify) {
    console.log(`   ${row.material.id} "${row.material.title}" → ${audioBase}/${row.audioId}.mp3`);
  }

  return {
    cleared: deleted,
    uploaded: successes.length,
    linked,
    mismatches: allMismatches,
  };
}

main()
  .then(r => {
    console.log('\n✨ Done.');
    process.exit(r.mismatches.length > 0 ? 2 : 0);
  })
  .catch(err => {
    console.error('\n💥 Fatal:', err);
    process.exit(1);
  });
