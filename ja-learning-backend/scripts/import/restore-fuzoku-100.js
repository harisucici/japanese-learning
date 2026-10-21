require('dotenv').config();
const { createClient } = require('@libsql/client');
const { PrismaClient } = require('@prisma/client');
const { PrismaLibSQL } = require('@prisma/adapter-libsql');

const SQLITE_PATH = '/Volumes/Mac Data/Documents/StudioProjects/japanese-learning/ja-learning-backend/prisma/dev.db';

async function main() {
  if (!process.env.TURSO_URL || !process.env.TURSO_AUTH_TOKEN) {
    console.error('Error: TURSO_URL and TURSO_AUTH_TOKEN must be set');
    process.exit(1);
  }

  // Connect to Turso via Prisma
  const adapter = new PrismaLibSQL({
    url: process.env.TURSO_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
  });
  const prisma = new PrismaClient({ adapter: adapter });

  // Read from local SQLite
  const localClient = createClient({ url: `file:${SQLITE_PATH}` });
  
  const result = await localClient.execute("SELECT * FROM StudyMaterial WHERE collection = '附赠100篇'");
  const materials = result.rows.map(row => ({
    id: row.id,
    title: row.title,
    collection: row.collection,
    japanese: row.japanese,
    translation: row.translation,
    textStatus: row.textStatus,
    metadata: JSON.parse(row.metadata || '{}'),
    createdAt: new Date(row.createdAt),
    updatedAt: new Date(row.updatedAt),
  }));

  console.log(`Read ${materials.length} "附赠100篇" materials from local SQLite`);

  // Upsert to Turso (restore overwritten records)
  console.log('Restoring to Turso (upsert)...');
  let restored = 0;
  let skipped = 0;
  
  for (let i = 0; i < materials.length; i++) {
    const m = materials[i];
    try {
      await prisma.studyMaterial.upsert({
        where: { id: m.id },
        create: m,
        update: m,
      });
      restored++;
    } catch (e) {
      console.error(`Error upserting ${m.id}:`, e.message);
      skipped++;
    }
    
    if ((i + 1) % 10 === 0) {
      console.log(`  Processed ${i + 1}/${materials.length}`);
    }
  }

  // Verify final state
  const count = await prisma.studyMaterial.count();
  const fuzokuCount = await prisma.studyMaterial.count({ where: { collection: '附赠100篇' } });
  const shortPdfCount = await prisma.studyMaterial.count({ where: { collection: '短文PDF' } });
  
  console.log(`\n=== Final Turso State ===`);
  console.log(`Total materials: ${count}`);
  console.log(`"附赠100篇" materials: ${fuzokuCount}`);
  console.log(`"短文PDF" materials: ${shortPdfCount}`);
  console.log(`\nRestored: ${restored}, Skipped: ${skipped}`);

  // Show sample
  const sample = await prisma.studyMaterial.findUnique({ where: { id: 'material-001' } });
  console.log('\nSample material-001:');
  console.log('  title:', sample.title);
  console.log('  collection:', sample.collection);
  console.log('  japanese preview:', sample.japanese?.substring(0, 100));

  await localClient.close();
  await prisma.$disconnect();
}

main().catch(e => {
  console.error(e);
  process.exit(1);
});
