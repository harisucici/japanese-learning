#!/usr/bin/env node
/**
 * 重建音频关联 (Rebuild audio associations)
 *
 * 数据库重置后 ArticleAudio / StudyMaterial / ReadingArticle 均为空。
 * 本脚本重建：
 *   - 附赠100篇: material-001 ~ material-100 → audio-001 ~ audio-100
 *   - 短文PDF:   material-101 ~ material-201 → short-audio-101 ~ short-audio-201
 *
 * 数据来源：
 *   - 附赠100篇目录: /Volumes/Mac Data/Documents/阅读PDF/附赠100篇（音频+PDF）
 *   - 短文PDF提取数据: scripts/data/short-essay-extracted.json
 *   - 短文PDF目录: /Volumes/Mac Data/Documents/阅读PDF/短文PDF (用于填充101#等缺失条目)
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { PrismaClient } = require('@prisma/client');

const FUZOKU_BASE = '/Volumes/Mac Data/Documents/阅读PDF/附赠100篇（音频+PDF）';
const SHORT_BASE = '/Volumes/Mac Data/Documents/阅读PDF/短文PDF';
const SHORT_EXTRACTED = path.join(__dirname, '..', 'data', 'short-essay-extracted.json');

function padNum(n) {
  return String(n).padStart(3, '0');
}

function extractNumber(dirname) {
  const m = dirname.match(/^(\d+)[.．]/);
  return m ? parseInt(m[1], 10) : null;
}

async function main() {
  // Use local dev.db
  const dbUrl = process.env.DATABASE_URL || 'file:./prisma/dev.db';
  console.log(`Using database: ${dbUrl}`);

  const prisma = new PrismaClient();

  // ═══════════════════════════════════════════════════════════════════════
  // 1. 附赠100篇: material-001 ~ material-100, audio-001 ~ audio-100
  // ═══════════════════════════════════════════════════════════════════════
  console.log('\n═══ 附赠100篇 ═══');
  const fuzokuDirs = fs.readdirSync(FUZOKU_BASE).filter(d => {
    return fs.statSync(path.join(FUZOKU_BASE, d)).isDirectory();
  }).sort((a, b) => {
    const na = extractNumber(a) || 0;
    const nb = extractNumber(b) || 0;
    return na - nb;
  });
  console.log(`Found ${fuzokuDirs.length} subdirectories`);

  let fuzokuMaterials = 0;
  let fuzokuAudioLinks = 0;

  for (const dir of fuzokuDirs) {
    const num = extractNumber(dir);
    if (!num || num < 1 || num > 100) {
      console.log(`  SKIP: ${dir} (number=${num})`);
      continue;
    }

    const materialId = `material-${padNum(num)}`;
    const audioId = `audio-${padNum(num)}`;
    // Title from directory: "1.暑假里想做的事" → "暑假里想做的事"
    const title = dir.replace(/^\d+[.．]/, '');

    // Create/update StudyMaterial
    await prisma.studyMaterial.upsert({
      where: { id: materialId },
      create: {
        id: materialId,
        title: title,
        collection: '附赠100篇',
        japanese: null,
        translation: null,
        textStatus: 'ready',
        metadata: { number: num, source: '附赠100篇' },
      },
      update: {
        title: title,
        collection: '附赠100篇',
        metadata: { number: num, source: '附赠100篇' },
      },
    });
    fuzokuMaterials++;

    // Create ArticleAudio link
    await prisma.articleAudio.upsert({
      where: {
        materialId_audioId: { materialId, audioId },
      },
      create: { materialId, audioId, position: 0 },
      update: {},
    });
    fuzokuAudioLinks++;
  }
  console.log(`  Materials created: ${fuzokuMaterials}`);
  console.log(`  Audio links created: ${fuzokuAudioLinks}`);

  // ═══════════════════════════════════════════════════════════════════════
  // 2. 短文PDF: material-101 ~ material-201, short-audio-101 ~ short-audio-201
  // ═══════════════════════════════════════════════════════════════════════
  console.log('\n═══ 短文PDF ═══');

  // Load extracted data
  const extracted = JSON.parse(fs.readFileSync(SHORT_EXTRACTED, 'utf-8'));
  const byNumber = new Map();
  for (const e of extracted) {
    byNumber.set(e.number, e);
  }
  console.log(`Loaded ${extracted.length} extracted entries (numbers ${Math.min(...byNumber.keys())}-${Math.max(...byNumber.keys())})`);

  // Scan mp4 files to find which numbers exist as videos
  const shortFiles = fs.readdirSync(SHORT_BASE);
  const mp4Numbers = new Set();
  for (const f of shortFiles) {
    if (f.endsWith('.mp4')) {
      const m = f.match(/^(\d+)/);
      if (m) mp4Numbers.add(parseInt(m[1], 10));
    }
  }
  console.log(`Found ${mp4Numbers.size} mp4 files (numbers ${Math.min(...mp4Numbers)}-${Math.max(...mp4Numbers)})`);

  // Union of all numbers we should process: extracted data numbers + mp4 numbers
  const allNumbers = new Set([...byNumber.keys(), ...mp4Numbers]);
  console.log(`Total numbers to process: ${allNumbers.size}`);

  let shortMaterials = 0;
  let shortAudioLinks = 0;
  let missingText = 0;

  for (const num of [...allNumbers].sort((a, b) => a - b)) {
    const materialNum = num + 100;  // offset: 1→101, 2→102, ...
    const materialId = `material-${padNum(materialNum)}`;
    const audioId = `short-audio-${padNum(materialNum)}`;

    const entry = byNumber.get(num);
    let title = '';
    let japanese = null;
    let translation = null;

    if (entry) {
      title = entry.title;
      japanese = entry.japanese || null;
      translation = entry.translation || null;
    } else {
      // No extracted text — derive title from mp4 filename
      const mp4File = shortFiles.find(f => f.endsWith('.mp4') && f.match(/^(\d+)/)?.[1] == num);
      if (mp4File) {
        title = mp4File.replace(/^\d+/, '').replace('.mp4', '');
      } else {
        title = `短文${num}`;
      }
      missingText++;
    }

    // Create StudyMaterial
    await prisma.studyMaterial.upsert({
      where: { id: materialId },
      create: {
        id: materialId,
        title: title,
        collection: '短文PDF',
        japanese: japanese,
        translation: translation,
        textStatus: entry ? 'ready' : 'text_pending',
        metadata: {
          number: num,
          source: '短文PDF',
          ...(entry?.filename ? { filename: entry.filename } : {}),
          audioExtracted: true,
        },
      },
      update: {
        title: title,
        collection: '短文PDF',
        ...(entry ? { japanese, translation, textStatus: 'ready' } : {}),
        metadata: {
          number: num,
          source: '短文PDF',
          ...(entry?.filename ? { filename: entry.filename } : {}),
          audioExtracted: true,
        },
      },
    });
    shortMaterials++;

    // Create ArticleAudio link
    await prisma.articleAudio.upsert({
      where: {
        materialId_audioId: { materialId, audioId },
      },
      create: { materialId, audioId, position: 0 },
      update: {},
    });
    shortAudioLinks++;
  }

  console.log(`  Materials created: ${shortMaterials}`);
  console.log(`  Audio links created: ${shortAudioLinks}`);
  console.log(`  Missing text data: ${missingText}`);

  // ═══════════════════════════════════════════════════════════════════════
  // Verification
  // ═══════════════════════════════════════════════════════════════════════
  console.log('\n═══ Verification ═══');
  const totalMaterials = await prisma.studyMaterial.count();
  const fuzokuCount = await prisma.studyMaterial.count({ where: { collection: '附赠100篇' } });
  const shortCount = await prisma.studyMaterial.count({ where: { collection: '短文PDF' } });
  const totalAudioLinks = await prisma.articleAudio.count();
  const fuzokuLinks = await prisma.articleAudio.count({
    where: { audioId: { startsWith: 'audio-' } }
  });
  const shortLinks = await prisma.articleAudio.count({
    where: { audioId: { startsWith: 'short-audio-' } }
  });

  console.log(`  StudyMaterial total: ${totalMaterials} (附赠100篇: ${fuzokuCount}, 短文PDF: ${shortCount})`);
  console.log(`  ArticleAudio total: ${totalAudioLinks} (audio-*: ${fuzokuLinks}, short-audio-*: ${shortLinks})`);

  // Spot-check specific IDs
  const checks = [
    { materialId: 'material-001', audioId: 'audio-001' },
    { materialId: 'material-050', audioId: 'audio-050' },
    { materialId: 'material-100', audioId: 'audio-100' },
    { materialId: 'material-101', audioId: 'short-audio-101' },
    { materialId: 'material-150', audioId: 'short-audio-150' },
    { materialId: 'material-201', audioId: 'short-audio-201' },
  ];
  console.log('\n  Spot checks:');
  for (const { materialId, audioId } of checks) {
    const mat = await prisma.studyMaterial.findUnique({ where: { id: materialId } });
    const link = await prisma.articleAudio.findUnique({
      where: { materialId_audioId: { materialId, audioId } }
    });
    console.log(`  ${materialId} → ${audioId}: material=${mat ? '✓' : '✗'}, link=${link ? '✓' : '✗'}${mat ? ` title="${mat.title}"` : ''}`);
  }

  await prisma.$disconnect();
  console.log('\n✨ Done.');
}

main().catch(err => {
  console.error('💥 Fatal:', err);
  process.exit(1);
});
