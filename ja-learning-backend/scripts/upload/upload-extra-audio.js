#!/usr/bin/env node
/**
 * 上传 5 个额外音频到 Cloudinary 并关联到对应文章
 * 
 * 文件映射:
 *   42.天气预报 → /Volumes/Mac Data/Documents/天气预报音频.wav → material-042 / audio-042
 *   27.穿衣服 → material-027 / audio-027
 *   69.调休上班 → material-069 / audio-069
 *   75.想成为一名老师 → material-075 / audio-075
 *   77.不擅长打电话 → material-077 / audio-077
 */

require('dotenv').config();
const cloudinary = require('cloudinary').v2;
const path = require('path');
const fs = require('fs');
const { createClient } = require('@libsql/client');
const { PrismaClient } = require('@prisma/client');
const { PrismaLibSQL } = require('@prisma/adapter-libsql');

// 需要上传的音频文件（4 个之前失败的 + 5 个新增）
const AUDIO_FILES = [
  {
    idx: 27,
    filePath: '/Volumes/Mac Data/Documents/阅读PDF/附赠100篇（音频+PDF）/27.穿衣服/穿衣服.MP3',
    description: '穿衣服'
  },
  {
    idx: 69,
    filePath: '/Volumes/Mac Data/Documents/阅读PDF/附赠100篇（音频+PDF）/69.调休上班/调休上班.mp3',
    description: '调休上班'
  },
  {
    idx: 75,
    filePath: '/Volumes/Mac Data/Documents/阅读PDF/附赠100篇（音频+PDF）/75.想成为一名老师/想成为一名老师.mp3',
    description: '想成为一名老师'
  },
  {
    idx: 77,
    filePath: '/Volumes/Mac Data/Documents/阅读PDF/附赠100篇（音频+PDF）/77.不擅长打电话/不擅长打电话.mp3',
    description: '不擅长打电话'
  },
  {
    idx: 79,
    filePath: '/Volumes/Mac Data/Documents/阅读PDF/附赠100篇（音频+PDF）/79.网上学日语/网上学日语.mp3',
    description: '网上学日语'
  },
  {
    idx: 85,
    filePath: '/Volumes/Mac Data/Documents/阅读PDF/附赠100篇（音频+PDF）/85.不喜欢喝酒/不喜欢喝酒.mp3',
    description: '不喜欢喝酒'
  },
  {
    idx: 87,
    filePath: '/Volumes/Mac Data/Documents/阅读PDF/附赠100篇（音频+PDF）/87.我很不安/我很不安.mp3',
    description: '我很不安'
  },
  {
    idx: 95,
    filePath: '/Volumes/Mac Data/Documents/阅读PDF/附赠100篇（音频+PDF）/95.不想起床/不想起床.mp3',
    description: '不想起床'
  },
  {
    idx: 96,
    filePath: '/Volumes/Mac Data/Documents/阅读PDF/附赠100篇（音频+PDF）/96.最近很忙/忙得不可开交.mp3',
    description: '最近很忙（音频文件名: 忙得不可开交.mp3）'
  }
];

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

async function main() {
  if (!process.env.TURSO_URL || !process.env.TURSO_AUTH_TOKEN) {
    throw new Error('TURSO_URL / TURSO_AUTH_TOKEN must be set');
  }

  console.log('📤 Uploading 5 extra audio files to Cloudinary...\n');

  const uploads = [];
  for (const file of AUDIO_FILES) {
    const audioId = `audio-${String(file.idx).padStart(3, '0')}`;
    uploads.push({ ...file, audioId });
  }

  // Upload all 5 files (use buffer upload to handle paths with special chars)
  const results = await Promise.all(uploads.map(async (u) => {
    try {
      const buffer = fs.readFileSync(u.filePath);
      const result = await cloudinary.uploader.upload(
        `data:audio/mp3;base64,${buffer.toString('base64')}`,
        {
          resource_type: 'video',
          folder: 'ja-learning/audio',
          public_id: u.audioId,
          format: 'mp3',
          overwrite: true,
        }
      );
      console.log(`   [${String(u.idx).padStart(3, '0')}] ✅ ${u.audioId}  ← ${u.description}`);
      return { ...u, secure_url: result.secure_url, public_id: result.public_id };
    } catch (err) {
      console.error(`   [${String(u.idx).padStart(3, '0')}] ❌ ${u.audioId}: ${err.message}`);
      return { ...u, error: err.message };
    }
  }));

  const successes = results.filter(r => !r.error);
  const failures = results.filter(r => r.error);

  console.log(`\n📊 Upload: ${successes.length} ok, ${failures.length} failed.\n`);

  if (successes.length === 0) {
    console.log('❌ No files uploaded successfully. Exiting.');
    return;
  }

  // Connect to Turso and write ArticleAudio rows
  const adapter = new PrismaLibSQL({
    url: process.env.TURSO_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
  });
  const prisma = new PrismaClient({ adapter });

  let linked = 0;
  const linkMismatches = [];

  for (const s of successes) {
    const materialId = `material-${String(s.idx).padStart(3, '0')}`;
    
    // Verify material exists
    const mat = await prisma.studyMaterial.findUnique({ where: { id: materialId } });
    if (!mat) {
      linkMismatches.push(`${s.description}: material ${materialId} not found in Turso`);
      continue;
    }
    
    // Check if ArticleAudio already exists for this material
    const existing = await prisma.articleAudio.findUnique({ 
      where: { audioId: s.audioId } 
    });
    
    if (existing) {
      console.log(`   ⚠️  ${s.audioId} already linked to ${existing.materialId}, skipping...`);
      linked++;
      continue;
    }
    
    try {
      await prisma.articleAudio.create({
        data: { materialId, audioId: s.audioId, position: 0 }
      });
      console.log(`   🔗 ${s.audioId} → ${materialId} (${mat.title})`);
      linked++;
    } catch (err) {
      linkMismatches.push(`${s.description}: ${err.message}`);
    }
  }

  console.log(`\n🔗 Linked ${linked}/${successes.length} audio → articles.\n`);

  await prisma.$disconnect();

  // Summary
  console.log('═'.repeat(60));
  console.log('SUMMARY');
  console.log(`  Audio uploaded         : ${successes.length} / ${uploads.length} files`);
  console.log(`  ArticleAudio linked    : ${linked}`);
  console.log(`  Mismatches / failures  : ${failures.length + linkMismatches.length}`);
  
  if (failures.length > 0) {
    console.log('\n❌ Upload failures:');
    failures.forEach(f => console.log(`   • ${f.description}: ${f.error}`));
  }
  
  if (linkMismatches.length > 0) {
    console.log('\n⚠️  Link mismatches:');
    linkMismatches.forEach(m => console.log(`   • ${m}`));
  }

  // Verify by reading back the newly linked URLs
  console.log('\n🔍 Verification — newly linked articles:');
  const verify = await prisma.articleAudio.findMany({
    where: {
      audioId: { in: successes.map(s => s.audioId) }
    },
    include: { material: { select: { id: true, title: true } } }
  });
  
  const audioBase = process.env.AUDIO_PUBLIC_BASE_URL
    || `https://res.cloudinary.com/${process.env.CLOUDINARY_CLOUD_NAME}/video/upload/ja-learning/audio`;
  
  for (const row of verify) {
    console.log(`   ${row.material.id} "${row.material.title}" → ${audioBase}/${row.audioId}.mp3`);
  }

  return {
    uploaded: successes.length,
    linked,
    failures: failures.length,
    mismatches: linkMismatches,
  };
}

main()
  .then(r => {
    if (!r) {
      process.exit(1);
    }
    console.log('\n✨ Done.');
    process.exit(r.mismatches.length > 0 || r.failures > 0 ? 2 : 0);
  })
  .catch(err => {
    console.error('\n💥 Fatal:', err);
    process.exit(1);
  });
