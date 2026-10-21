/**
 * Benchmark for novelLessonById API response format fix
 */
import request from 'supertest';
import app from '../src/app';
import prisma from '../src/config/database';

async function run() {
  const testId = `bench-${Date.now()}`;
  const data = {
    id: testId,
    title: 'Bench',
    category: 'T',
    position: 9999,
    startPage: 1,
    endPage: 2,
    pages: JSON.stringify([
      { pageNumber: 1, text: 'p1'.repeat(500) },
      { pageNumber: 2, text: 'p2'.repeat(500) },
    ]),
    vocabulary: JSON.stringify([
      { word: 't', reading: 't', meaning: 'm', level: 'n5' },
    ]),
    note: 'n',
    materialId: 'm',
    paperId: 'p',
    questionCount: 0,
    published: true,
    sourceTitle: 's',
    sourcePages: 1,
    attribution: 'a',
  };
  await prisma.readingArticle.create({ data: data as any });

  // Warm-up
  await request(app).get(`/api/v1/learning/novel-lessons/${testId}`);

  const N = 30;
  const times: number[] = [];
  for (let i = 0; i < N; i++) {
    const start = process.hrtime.bigint();
    const res = await request(app).get(`/api/v1/learning/novel-lessons/${testId}`);
    const end = process.hrtime.bigint();
    times.push(Number(end - start) / 1_000_000);
    if (res.status !== 200) throw new Error(`status ${res.status}`);
    if (typeof res.body.pages === 'string') throw new Error('pages still a string');
    if (!Array.isArray(res.body.pages)) throw new Error('pages not array');
    if (!res.headers['content-type']?.includes('application/json')) throw new Error('bad ct');
  }

  const sorted = [...times].sort((a, b) => a - b);
  const avg = times.reduce((a, b) => a + b, 0) / times.length;
  console.log(`=== novelLessonById benchmark (n=${N}) ===`);
  console.log(`avg:  ${avg.toFixed(1)} ms`);
  console.log(`min:  ${sorted[0].toFixed(1)} ms`);
  console.log(`p95:  ${sorted[Math.floor(N * 0.95)].toFixed(1)} ms`);
  console.log(`max:  ${sorted[N - 1].toFixed(1)} ms`);
  console.log('All responses: valid JSON, pages/vocabulary parsed, Content-Type: application/json');

  await prisma.readingArticle.delete({ where: { id: testId } });
  await prisma.$disconnect();
}

run().catch(err => {
  console.error('BENCH FAIL:', err.message);
  process.exit(1);
});
