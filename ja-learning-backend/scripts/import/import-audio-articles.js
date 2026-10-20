/** Idempotent import of uploaded Cloudinary audio and its article relationships. */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { PrismaClient } = require('@prisma/client');
const { PrismaLibSQL } = require('@prisma/adapter-libsql');

const root = path.join(__dirname, '..');
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'data/audio/audio-manifest.json'), 'utf8'));
const uploaded = JSON.parse(fs.readFileSync(path.join(root, 'data/audio/.upload-progress.json'), 'utf8'));
const dbUrl = process.env.TURSO_URL || 'file:' + path.join(root, 'prisma/dev.db');
const prisma = new PrismaClient({ adapter: new PrismaLibSQL({ url: dbUrl, authToken: process.env.TURSO_AUTH_TOKEN || undefined }) });

async function main() {
  let assets = 0, linked = 0, awaiting = 0;
  for (const entry of manifest.files) {
    const upload = uploaded[entry.id];
    const number = entry.number;
    const materialId = `material-${String(number).padStart(3, '0')}`;
    const existing = await prisma.studyMaterial.findUnique({ where: { id: materialId } });
    // The video-derived set has no article transcript yet. Store an honest text status.
    if (!existing) {
      await prisma.studyMaterial.create({ data: {
        id: materialId, title: entry.title, collection: entry.source_group, filename: '', pages: 0,
        sha256: '', fileUrl: '', audioUrl: null, videoUrl: null,
        japanese: null, translation: null, textStatus: 'text_pending',
        metadata: { number, sourceGroup: entry.source_group },
      } });
    } else if ((!existing.japanese && existing.textStatus === 'ready') || (existing.filename === '' && existing.collection !== entry.source_group)) {
      await prisma.studyMaterial.update({ where: { id: materialId }, data: { collection: entry.source_group, ...(!existing.japanese ? { textStatus: 'text_pending' } : {}) } });
    }
    if (!upload?.secure_url) { awaiting++; continue; }
    await prisma.audioAsset.upsert({
      where: { id: entry.id },
      create: { id: entry.id, title: entry.title, filename: entry.filename, url: upload.secure_url,
        storageProvider: 'cloudinary', storageKey: upload.public_id || `ja-learning/audio/${entry.id}`,
        sizeBytes: upload.bytes || entry.size_bytes, durationSeconds: upload.duration || null },
      update: { title: entry.title, url: upload.secure_url, sizeBytes: upload.bytes || entry.size_bytes,
        durationSeconds: upload.duration || null },
    });
    assets++;
    await prisma.materialAudio.upsert({
      where: { materialId_audioId: { materialId, audioId: entry.id } },
      create: { materialId, audioId: entry.id, position: 0 }, update: {},
    });
    linked++;
  }
  // The source article exists but number 42 has no source recording.
  await prisma.studyMaterial.upsert({ where: { id: 'material-042' }, create: {
    id: 'material-042', title: '天气预报', collection: '附赠100篇', filename: '', pages: 0,
    sha256: '', fileUrl: '', audioUrl: null, videoUrl: null, japanese: null,
    translation: null, textStatus: 'text_pending', metadata: { number: 42, sourceGroup: '附赠100篇' },
  }, update: {} });
  await prisma.studyMaterial.updateMany({ where: { japanese: null, textStatus: 'ready' }, data: { textStatus: 'text_pending' } });
  console.log(JSON.stringify({ assets, linked, awaiting, articles: await prisma.studyMaterial.count() }));
}
main().catch(e => { console.error(e); process.exitCode = 1; }).finally(() => prisma.$disconnect());
