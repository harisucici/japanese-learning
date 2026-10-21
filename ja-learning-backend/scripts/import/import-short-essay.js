#!/usr/bin/env node
/**
 * 短文PDF处理脚本
 * 
 * 1. 从PDF提取日语文字（带假名注音）和中文翻译
 * 2. 从MP4视频提取音频（ffmpeg）
 * 3. 上传音频到Cloudinary
 * 4. 创建/更新StudyMaterial记录并关联ArticleAudio
 * 
 * 数据来源：
 *   - 提取的PDF内容：data/short-essay-extracted.json（由Python脚本预生成）
 *   - 视频文件：/Volumes/Mac Data/Documents/阅读PDF/短文PDF/*.mp4
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const cloudinary = require('cloudinary').v2;
const { PrismaClient } = require('@prisma/client');
const { PrismaLibSQL } = require('@prisma/adapter-libsql');

const PDF_VIDEO_DIR = '/Volumes/Mac Data/Documents/阅读PDF/短文PDF';
const EXTRACTED_DATA = path.join(__dirname, '..', 'data', 'short-essay-extracted.json');
const AUDIO_TMP_DIR = path.join(__dirname, '..', 'data', 'audio-tmp');

// Retry helper for transient network errors
async function withRetry(fn, maxAttempts = 3, label = '') {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (e) {
      const isTimeout = e.code === 'UND_ERR_CONNECT_TIMEOUT' || e.message?.includes('timeout') || e.code === 'ETIMEDOUT';
      const isTransient = isTimeout || e.message?.includes('fetch failed') || e.code === 'ECONNRESET';
      if (!isTransient || attempt === maxAttempts) throw e;
      const wait = attempt * 2000;
      console.log(`  ⏳ Retry ${attempt}/${maxAttempts} for ${label}: ${e.code || e.message.slice(0,60)} (wait ${wait}ms)`);
      await new Promise(r => setTimeout(r, wait));
    }
  }
}

// Cloudinary config
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

async function main() {
  // Validate env
  if (!process.env.TURSO_URL || !process.env.TURSO_AUTH_TOKEN) {
    throw new Error('TURSO_URL and TURSO_AUTH_TOKEN must be set');
  }
  if (!process.env.CLOUDINARY_CLOUD_NAME) {
    throw new Error('CLOUDINARY_CLOUD_NAME must be set');
  }

  // Check ffmpeg
  try {
    execFileSync('ffmpeg', ['-version'], { stdio: 'ignore' });
  } catch (e) {
    throw new Error('ffmpeg not found. Install it first.');
  }

  // Load extracted PDF data
  const extracted = JSON.parse(fs.readFileSync(EXTRACTED_DATA, 'utf-8'));
  console.log(`📄 Loaded ${extracted.length} extracted PDF entries`);

  // Create audio tmp dir
  fs.mkdirSync(AUDIO_TMP_DIR, { recursive: true });

  // Build number->extracted map
  const byNumber = new Map();
  for (const e of extracted) {
    byNumber.set(e.number, e);
  }

  // Scan video files
  const videoFiles = fs.readdirSync(PDF_VIDEO_DIR)
    .filter(f => f.toLowerCase().endsWith('.mp4'))
    .sort();
  console.log(`🎬 Found ${videoFiles.length} video files`);

  // Connect to Turso
  const adapter = new PrismaLibSQL({
    url: process.env.TURSO_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
  });
  const prisma = new PrismaClient({ adapter });

  // Stats
  let audioUploaded = 0;
  let audioFailed = 0;
  let matchedAudios = 0;
  let pdfProcessed = 0;
  const audioUploadFailures = [];
  const unmatchedAudios = [];

  // Process each video
  for (const videoFile of videoFiles) {
    const match = videoFile.match(/^(\d+)/);
    const num = match ? parseInt(match[1], 10) : null;
    // Offset by 100 to avoid conflict with existing material-001 to material-100
    const materialNum = num ? num + 100 : null;
    const videoPath = path.join(PDF_VIDEO_DIR, videoFile);
    const audioId = materialNum ? `short-audio-${String(materialNum).padStart(3, '0')}` : null;

    console.log(`\n[${num ? String(num).padStart(3, '0') : '???'} → material-${materialNum}] ${videoFile}`);

    // 1. Extract audio from video using ffmpeg
    const audioTmpPath = path.join(AUDIO_TMP_DIR, `${audioId || 'unknown'}.mp3`);
    try {
      execFileSync('ffmpeg', [
        '-y', '-i', videoPath,
        '-vn',                   // no video
        '-acodec', 'libmp3lame', // MP3 encoding
        '-ab', '128k',           // bitrate
        '-ar', '44100',          // sample rate
        audioTmpPath
      ], { stdio: 'pipe', timeout: 120000 });
      
      const stat = fs.statSync(audioTmpPath);
      console.log(`  ✅ Audio extracted: ${(stat.size / 1024).toFixed(0)}KB`);
    } catch (e) {
      console.log(`  ❌ Audio extraction failed: ${e.message.slice(0, 100)}`);
      audioFailed++;
      audioUploadFailures.push(`${videoFile}: extraction failed`);
      continue;
    }

    // 2. Upload to Cloudinary
    if (!audioId) {
      console.log(`  ⚠️  Cannot determine number from filename`);
      unmatchedAudios.push(videoFile);
      continue;
    }

    let secureUrl;
    try {
      const result = await cloudinary.uploader.upload(audioTmpPath, {
        resource_type: 'video',
        folder: 'ja-learning/audio',
        public_id: audioId,
        format: 'mp3',
        overwrite: false,
      });
      secureUrl = result.secure_url;
      console.log(`  📤 Uploaded: ${audioId} → Cloudinary`);
      audioUploaded++;
    } catch (e) {
      console.log(`  ❌ Upload failed: ${e.message.slice(0, 100)}`);
      audioFailed++;
      audioUploadFailures.push(`${videoFile}: ${e.message.slice(0, 80)}`);
      continue;
    }

    // 3. Create/Update StudyMaterial with extracted text
    const entry = byNumber.get(num);
    if (!entry) {
      console.log(`  ⚠️  No extracted PDF data for number ${num}`);
      unmatchedAudios.push(`${videoFile} (no PDF data)`);
      // Still create a basic record
      try {
        await withRetry(() => prisma.studyMaterial.upsert({
          where: { id: `material-${String(materialNum).padStart(3, '0')}` },
          create: {
            id: `material-${String(materialNum).padStart(3, '0')}`,
            title: videoFile.replace('.mp4', '').replace(/^\d+/, ''),
            collection: '短文PDF',
            japanese: null,
            translation: null,
            textStatus: 'text_pending',
            metadata: { number: num, source: '短文PDF', audioExtracted: true },
          },
          update: {
            collection: '短文PDF',
            metadata: { number: num, source: '短文PDF', audioExtracted: true },
          },
        }), 3, `material-${num}`);
      } catch (e) {
        console.log(`  ⚠️  StudyMaterial upsert failed: ${e.message.slice(0, 100)}`);
      }
    } else {
      console.log(`  📝 Title: ${entry.title}`);
      pdfProcessed++;
      
      await withRetry(() => prisma.studyMaterial.upsert({
        where: { id: `material-${String(materialNum).padStart(3, '0')}` },
        create: {
          id: `material-${String(materialNum).padStart(3, '0')}`,
          title: entry.title,
          collection: '短文PDF',
          japanese: entry.japanese,
          translation: entry.translation,
          textStatus: 'ready',
          metadata: {
            number: num,
            source: '短文PDF',
            filename: entry.filename,
            audioExtracted: true,
          },
        },
        update: {
          title: entry.title,
          collection: '短文PDF',
          japanese: entry.japanese,
          translation: entry.translation,
          textStatus: 'ready',
          metadata: {
            number: num,
            source: '短文PDF',
            filename: entry.filename,
            audioExtracted: true,
          },
        },
      }), 3, `material-${materialNum}`);
    }

    // 4. Create ArticleAudio link
    const materialId = `material-${String(materialNum).padStart(3, '0')}`;
    try {
      await withRetry(() => prisma.articleAudio.upsert({
        where: { audioId },
        create: { materialId, audioId, position: 0 },
        update: { materialId },
      }), 3, `articleAudio-${audioId}`);
      console.log(`  🔗 ${audioId} → ${materialId}`);
      matchedAudios++;
    } catch (e) {
      console.log(`  ⚠️  ArticleAudio link failed: ${e.message.slice(0, 100)}`);
    }
  }

  // Cleanup tmp audio files
  try {
    const tmpFiles = fs.readdirSync(AUDIO_TMP_DIR);
    for (const f of tmpFiles) {
      fs.unlinkSync(path.join(AUDIO_TMP_DIR, f));
    }
    fs.rmdirSync(AUDIO_TMP_DIR);
    console.log(`\n🧹 Cleaned up ${tmpFiles.length} tmp audio files`);
  } catch (e) { /* ignore */ }

  // Verification
  console.log('\n' + '═'.repeat(60));
  console.log('SUMMARY');
  console.log(`  Videos processed      : ${videoFiles.length}`);
  console.log(`  Audio extracted+uploaded: ${audioUploaded}`);
  console.log(`  Audio extraction failed : ${audioFailed}`);
  console.log(`  PDF text processed    : ${pdfProcessed}`);
  console.log(`  ArticleAudio linked   : ${matchedAudios}`);
  console.log(`  Unmatched             : ${unmatchedAudios.length}`);

  if (audioUploadFailures.length > 0) {
    console.log(`\n❌ Upload failures (${audioUploadFailures.length}):`);
    for (const f of audioUploadFailures) console.log(`  - ${f}`);
  }

  if (unmatchedAudios.length > 0) {
    console.log(`\n⚠️  Unmatched (${unmatchedAudios.length}):`);
    for (const u of unmatchedAudios) console.log(`  - ${u}`);
  }

  // Verify DB
  const count = await prisma.studyMaterial.count({ where: { collection: '短文PDF' } });
  const audioLinks = await prisma.articleAudio.count({
    where: { audioId: { startsWith: 'short-audio-' } }
  });
  console.log(`\n🔍 DB verification:`);
  console.log(`  短文PDF materials: ${count}`);
  console.log(`  short-audio-* links: ${audioLinks}`);

  await prisma.$disconnect();

  console.log('\n✨ Done.');
  return {
    audioUploaded,
    audioFailed,
    matchedAudios,
    pdfProcessed,
    audioUploadFailures,
    unmatchedAudios,
  };
}

main()
  .then(r => {
    if (!r) process.exit(1);
    process.exit(r.audioFailed > 0 ? 2 : 0);
  })
  .catch(err => {
    console.error('\n💥 Fatal:', err);
    process.exit(1);
  });
