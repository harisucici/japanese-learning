/**
 * Benchmark for novelLessonById API (GET /api/v1/learning/novel-lessons/:id)
 * Measures response time across warm-up + N requests. Reports avg/min/P95/max.
 */
import request from 'supertest';
import app from '../src/app';
import prisma from '../src/config/database';

async function run() {
  const testId = `bench-detail-${Date.now()}`;
  const data = {
    id: testId,
    title: 'Bench Detail',
    category: 'T',
    position: 9999,
    startPage: 1,
    endPage: 5,
    pages: JSON.stringify(
      Array.from({ length: 5 }, (_, i) => ({
        pageNumber: i + 1,
        text: `page${i}-${'x'.repeat(1500)}`,
      }))
    ),
    vocabulary: JSON.stringify(
      Array.from({ length: 20 }, (_, i) => ({
        word: `word${i}`,
        reading: `reading${i}`,
        meaning: `meaning${i}`,
        level: 'n5',
      }))
    ),
    note: 'bench note',
    materialId: 'm',
    paperId: 'p',
    questionCount: 0,
    published: true,
    sourceTitle: 'source',
    sourcePages: 5,
    attribution: 'attr',
  };
  await prisma.readingArticle.create({ data: data as any });

  // Warm-up (2 calls)
  await request(app).get(`/api/v1/learning/novel-lessons/${testId}`);
  await request(app).get(`/api/v1/learning/novel-lessons/${testId}`);

  const N = 50;
  const times: number[] = [];
  for (let i = 0; i < N; i++) {
    const start = process.hrtime.bigint();
    const res = await request(app).get(`/api/v1/learning/novel-lessons/${testId}`);
    const end = process.hrtime.bigint();
    times.push(Number(end - start) / 1_000_000);
    if (res.status !== 200) throw new Error(`status ${res.status}`);
    if (typeof res.body.pages === 'string') throw new Error('pages still a string');
    if (!Array.isArray(res.body.pages)) throw new Error('pages not array');
    if (!Array.isArray(res.body.vocabulary)) throw new Error('vocabulary not array');
    if (!res.headers['content-type']?.includes('application/json')) throw new Error('bad ct');
  }

  const sorted = [...times].sort((a, b) => a - b);
  const avg = times.reduce((a, b) => a + b, 0) / times.length;
  const p95 = sorted[Math.floor(N * 0.95)];
  const p50 = sorted[Math.floor(N * 0.50)];

  console.log(`=== novelLessonById detail benchmark (n=${N}) ===`);
  console.log(`avg:  ${avg.toFixed(2)} ms`);
  console.log(`min:  ${sorted[0].toFixed(2)} ms`);
  console.log(`p50:  ${p50.toFixed(2)} ms`);
  console.log(`p95:  ${p95.toFixed(2)} ms`);
  console.log(`max:  ${sorted[N - 1].toFixed(2)} ms`);
  console.log(`target: P95 < 100ms  ->  ${p95 < 100 ? 'PASS ✓' : 'FAIL ✗'}`);

  await prisma.readingArticle.delete({ where: { id: testId } });
  await prisma.$disconnect();
}

run().catch(err => {
  console.error('BENCH FAIL:', err.message);
  process.exit(1);
});
