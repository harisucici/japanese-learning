require('dotenv').config();
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { PrismaClient } = require('@prisma/client');

const PDF_BASE = '/Volumes/Mac Data/Documents/附赠100篇（音频+PDF）';
const MANIFEST_PATH = path.join(__dirname, '../data/audio/audio-manifest.json');

function sha256File(filepath) {
  const data = fs.readFileSync(filepath);
  return crypto.createHash('sha256').update(data).digest('hex');
}

function getPdfPages(filepath) {
  try {
    const data = fs.readFileSync(filepath);
    // Count page markers in PDF
    const content = data.toString('latin1');
    const matches = content.match(/\/Type\s*\/Page[^s]/g);
    return matches ? matches.length : 1;
  } catch {
    return 1;
  }
}

function extractNumber(dirname) {
  const match = dirname.match(/^(\d+)\./);
  return match ? parseInt(match[1], 10) : null;
}

(async () => {
  const prisma = new PrismaClient();

  // Load manifest
  const manifest = JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf-8'));
  const audioByNumber = {};
  for (const audio of manifest.files) {
    if (audio.source_group === '附赠100篇') {
      audioByNumber[audio.number] = audio;
    }
  }
  console.log(`Audio files for 附赠100篇: ${Object.keys(audioByNumber).length}`);

  // Check current state
  const existingCount = await prisma.studyMaterial.count({
    where: { collection: '附赠100篇' }
  });
  console.log(`Existing 附赠100篇 materials: ${existingCount}`);

  // Scan PDF directories
  const dirs = fs.readdirSync(PDF_BASE).sort((a, b) => {
    const na = extractNumber(a) || 0;
    const nb = extractNumber(b) || 0;
    return na - nb;
  });

  const materials = [];
  for (const dirname of dirs) {
    const number = extractNumber(dirname);
    if (number === null) continue;

    const dirPath = path.join(PDF_BASE, dirname);
    if (!fs.statSync(dirPath).isDirectory()) continue;

    // Find PDF
    const pdfFiles = fs.readdirSync(dirPath).filter(f => f.toLowerCase().endsWith('.pdf'));
    if (pdfFiles.length === 0) {
      console.log(`WARNING: No PDF in ${dirname}`);
      continue;
    }

    const pdfFilename = pdfFiles[0];
    const pdfPath = path.join(dirPath, pdfFilename);

    // Metadata
    const title = dirname.split('.').slice(1).join('.');
    const pages = getPdfPages(pdfPath);
    const sha256 = sha256File(pdfPath);

    // URLs
    const fileUrl = `/study-assets/${pdfFilename}`;
    const audioInfo = audioByNumber[number];
    let audioUrl = null;
    if (audioInfo) {
      audioUrl = `https://res.cloudinary.com/dfh2jvj6e/video/upload/v1792404837/ja-learning/audio/${audioInfo.filename}`;
    }

    materials.push({
      id: `material-${String(number).padStart(3, '0')}`,
      title,
      collection: '附赠100篇',
      filename: pdfFilename,
      pages,
      sha256,
      fileUrl,
      audioUrl,
      videoUrl: null,
      japanese: null,
      translation: null,
      textStatus: 'ready',
      metadata: {
        number,
        sourceDir: dirname,
        audioId: audioInfo ? audioInfo.id : null,
        audioFilename: audioInfo ? audioInfo.filename : null
      }
    });

    console.log(`[${String(number).padStart(3)}] ${title} (${pages}p) audio: ${audioUrl ? 'yes' : 'no'}`);
  }

  console.log(`\nTotal materials to create: ${materials.length}`);

  // Upsert
  let created = 0;
  for (const m of materials) {
    try {
      await prisma.studyMaterial.upsert({
        where: { id: m.id },
        create: m,
        update: m
      });
      created++;
    } catch (e) {
      console.error(`ERROR ${m.id}: ${e.message}`);
    }
  }

  console.log(`\nCreated/updated ${created} StudyMaterial records`);

  // Final count
  const finalCount = await prisma.studyMaterial.count();
  console.log(`Total StudyMaterial records in DB: ${finalCount}`);

  await prisma.$disconnect();

  // Output result
  console.log('\n=== RESULT ===');
  console.log(JSON.stringify({
    success: true,
    materials_created: created,
    audio_count: Object.keys(audioByNumber).length
  }));
})().catch(e => {
  console.error(e);
  process.exitCode = 1;
});
