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

  // Read from local SQLite using libsql client
  const localClient = createClient({ url: `file:${SQLITE_PATH}` });
  
  const result = await localClient.execute('SELECT * FROM StudyMaterial');
  const materials = result.rows.map(row => ({
    id: row.id,
    title: row.title,
    collection: row.collection,
    japanese: row.japanese,
    translation: row.translation,
    textStatus: row.textStatus,
    metadata: row.metadata,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  }));

  console.log(`Read ${materials.length} materials from SQLite`);

  // Clear existing materials in Turso
  const existing = await prisma.studyMaterial.count();
  console.log(`Clearing ${existing} existing materials from Turso...`);
  await prisma.studyMaterial.deleteMany({});

  // Import to Turso
  console.log('Importing to Turso...');
  for (let i = 0; i < materials.length; i++) {
    const m = materials[i];
    await prisma.studyMaterial.create({
      data: {
        id: m.id,
        title: m.title,
        collection: m.collection,
        japanese: m.japanese,
        translation: m.translation,
        textStatus: m.textStatus,
        metadata: JSON.parse(m.metadata || '{}'),
        createdAt: new Date(m.createdAt),
        updatedAt: new Date(m.updatedAt),
      }
    });
    
    if ((i + 1) % 10 === 0) {
      console.log(`  Imported ${i + 1}/${materials.length}`);
    }
  }

  // Verify
  const count = await prisma.studyMaterial.count();
  console.log(`\nSUCCESS: Imported ${count} materials to Turso`);

  // Show sample
  const sample = await prisma.studyMaterial.findUnique({ where: { id: 'material-001' } });
  console.log('\nSample material-001:');
  console.log('  title:', sample.title);
  console.log('  collection:', sample.collection);
  console.log('  japanese length:', sample.japanese?.length || 0);
  console.log('  translation length:', sample.translation?.length || 0);
  console.log('  textStatus:', sample.textStatus);
  console.log('  japanese preview:', sample.japanese?.substring(0, 200));

  await localClient.close();
  await prisma.$disconnect();
}

main().catch(e => {
  console.error(e);
  process.exit(1);
});
