/**
 * Benchmark for novelLessons (list) API
 */
import request from 'supertest';
import app from '../src/app';

async function run() {
  // Warm-up
  await request(app).get('/api/v1/learning/novel-lessons');

  const N = 30;
  const times: number[] = [];
  for (let i = 0; i < N; i++) {
    const start = process.hrtime.bigint();
    const res = await request(app).get('/api/v1/learning/novel-lessons');
    const end = process.hrtime.bigint();
    times.push(Number(end - start) / 1_000_000);
    if (res.status !== 200) throw new Error(`status ${res.status}`);
  }

  const sorted = [...times].sort((a, b) => a - b);
  const avg = times.reduce((a, b) => a + b, 0) / times.length;
  console.log(`=== novelLessons list benchmark (n=${N}) ===`);
  console.log(`avg:  ${avg.toFixed(1)} ms`);
  console.log(`min:  ${sorted[0].toFixed(1)} ms`);
  console.log(`p95:  ${sorted[Math.floor(N * 0.95)].toFixed(1)} ms`);
  console.log(`max:  ${sorted[N - 1].toFixed(1)} ms`);

  process.exit(0);
}

run().catch(err => {
  console.error('BENCH FAIL:', err.message);
  process.exit(1);
});
