/** One-time migration: copy published reading content from the legacy API to Turso. */
require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const { PrismaLibSQL } = require('@prisma/adapter-libsql');

const source = process.env.LEGACY_LEARNING_API || 'http://localhost:3002/api/v1/learning';
const prisma = new PrismaClient({ adapter: new PrismaLibSQL({
  url: process.env.TURSO_URL, authToken: process.env.TURSO_AUTH_TOKEN,
}) });

async function get(path) {
  const response = await fetch(`${source}/${path}`);
  if (!response.ok) throw new Error(`${path}: HTTP ${response.status}`);
  return response.json();
}

async function main() {
  if (!process.env.TURSO_URL || !process.env.TURSO_AUTH_TOKEN) throw new Error('Turso connection is required');
  const catalog = await get('novel-lessons');
  if (catalog.lessons?.length !== 28) throw new Error(`Expected 28 legacy articles, found ${catalog.lessons?.length}`);
  let imported = 0;
  for (const summary of catalog.lessons) {
    const detail = await get(`novel-lessons/${encodeURIComponent(summary.id)}`);
    if (!Array.isArray(detail.pages) || !detail.pages.length) throw new Error(`${detail.id}: missing pages`);
    const data = {
      title: detail.title, category: detail.category, position: detail.position,
      startPage: detail.startPage, endPage: detail.endPage,
      pages: detail.pages.map(({ imageUrl, ...page }) => page), vocabulary: detail.vocabulary, note: detail.note,
      materialId: detail.materialId, paperId: detail.paperId,
      questionCount: detail.questionCount, published: detail.published,
      sourceTitle: catalog.sourceTitle, sourcePages: catalog.sourcePages,
      attribution: catalog.attribution,
    };
    await prisma.readingArticle.upsert({ where: { id: detail.id }, create: { id: detail.id, ...data }, update: data });
    imported++;
  }
  console.log(JSON.stringify({ imported, remoteTotal: await prisma.readingArticle.count() }));
}
main().catch(e => { console.error(e.message); process.exitCode = 1; }).finally(() => prisma.$disconnect());
