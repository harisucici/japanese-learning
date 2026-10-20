import request from 'supertest';
import app from '../src/app';
import prisma from '../src/config/database';
import userPrisma from '../src/config/user-database';

describe('Review System Enhancement APIs', () => {
  let cookie: string;
  let userId: string;

  beforeAll(async () => {
    // Create guest session and capture cookie
    const res = await request(app)
      .post('/api/v1/learning/guest')
      .expect(200);

    const setCookie = res.headers['set-cookie'];
    if (Array.isArray(setCookie)) {
      const sessionCookie = setCookie.find(c => c.startsWith('ja_session='));
      cookie = sessionCookie!.split(';')[0];
    } else if (typeof setCookie === 'string' && setCookie.startsWith('ja_session=')) {
      cookie = setCookie.split(';')[0];
    }

    // Parse token to get userId
    const jwt = await import('jsonwebtoken');
    const { config } = await import('../src/config/env');
    const token = cookie.split('=')[1];
    const decoded = jwt.default.verify(decodeURIComponent(token), config.jwtSecret) as any;
    userId = decoded.userId;
  });

  describe('Practice API - by-type', () => {
    it('should return 401 without auth', async () => {
      await request(app)
        .get('/api/v1/practice/by-type/grammar?level=n5')
        .expect(401);
    });

    it('should return 400 for invalid question type', async () => {
      const res = await request(app)
        .get('/api/v1/practice/by-type/invalid-type?level=n5')
        .set('Cookie', cookie)
        .expect(400);

      expect(res.body.error).toMatch(/无效题型/);
    });

    it('should accept valid question type and return expected shape', async () => {
      const res = await request(app)
        .get('/api/v1/practice/by-type/grammar?level=n5&limit=5')
        .set('Cookie', cookie)
        .expect(200);

      expect(res.body).toHaveProperty('level', 'n5');
      expect(res.body).toHaveProperty('type', 'grammar');
      expect(res.body).toHaveProperty('count');
      expect(res.body).toHaveProperty('questions');
      expect(Array.isArray(res.body.questions)).toBe(true);

      // Questions must NOT contain answer field (security)
      for (const q of res.body.questions) {
        expect(q).not.toHaveProperty('answer');
      }
    });

    it('should accept limit parameter', async () => {
      const res = await request(app)
        .get('/api/v1/practice/by-type/vocabulary?level=n5&limit=2')
        .set('Cookie', cookie)
        .expect(200);

      expect(res.body.count).toBeLessThanOrEqual(2);
    });
  });

  describe('Practice API - by-grammar', () => {
    it('should return 404 for non-existent grammar', async () => {
      await request(app)
        .get('/api/v1/practice/by-grammar/non-existent-id')
        .set('Cookie', cookie)
        .expect(404);
    });

    it('should return grammar info with questions for existing grammar', async () => {
      // Create a grammar entry
      const grammar = await (prisma as any).grammar.create({
        data: {
          name: 'テスト文法',
          structure: 'V-て + も',
          meaning: 'even if',
          level: 'n5',
          usage: {},
        },
      });

      const res = await request(app)
        .get(`/api/v1/practice/by-grammar/${grammar.id}?limit=5`)
        .set('Cookie', cookie)
        .expect(200);

      expect(res.body).toHaveProperty('grammar');
      expect(res.body.grammar).toHaveProperty('id', grammar.id);
      expect(res.body).toHaveProperty('count');
      expect(res.body).toHaveProperty('questions');
      expect(Array.isArray(res.body.questions)).toBe(true);

      // Cleanup
      await (prisma as any).grammar.delete({ where: { id: grammar.id } });
    });
  });

  describe('Practice API - mistakes', () => {
    it('should return 401 without auth', async () => {
      await request(app)
        .get('/api/v1/practice/mistakes')
        .expect(401);
    });

    it('should return mistakes list with expected shape', async () => {
      const res = await request(app)
        .get('/api/v1/practice/mistakes?level=n5&limit=10')
        .set('Cookie', cookie)
        .expect(200);

      expect(res.body).toHaveProperty('level', 'n5');
      expect(res.body).toHaveProperty('count');
      expect(res.body).toHaveProperty('items');
      expect(Array.isArray(res.body.items)).toBe(true);
    });

    it('should work without level filter', async () => {
      const res = await request(app)
        .get('/api/v1/practice/mistakes')
        .set('Cookie', cookie)
        .expect(200);

      expect(res.body).toHaveProperty('items');
    });
  });

  describe('Practice API - random', () => {
    it('should return 401 without auth', async () => {
      await request(app)
        .get('/api/v1/practice/random')
        .expect(401);
    });

    it('should return random questions with expected shape', async () => {
      const res = await request(app)
        .get('/api/v1/practice/random?level=n5&limit=5')
        .set('Cookie', cookie)
        .expect(200);

      expect(res.body).toHaveProperty('level', 'n5');
      expect(res.body).toHaveProperty('count');
      expect(res.body).toHaveProperty('questions');
      expect(Array.isArray(res.body.questions)).toBe(true);
      expect(res.body.count).toBeLessThanOrEqual(5);

      // Security: answers must not leak
      for (const q of res.body.questions) {
        expect(q).not.toHaveProperty('answer');
      }
    });

    it('should support exclude parameter', async () => {
      const res = await request(app)
        .get('/api/v1/practice/random?level=n5&limit=5&exclude=fake-id-1,fake-id-2')
        .set('Cookie', cookie)
        .expect(200);

      expect(res.body).toHaveProperty('questions');
    });
  });

  describe('Review Path API - next', () => {
    let testItemId: string;

    beforeAll(async () => {
      // Create a review item directly for this user
      // First need a question
      const question = await prisma.question.findFirst({});
      if (!question) return;

      const item = await (userPrisma.reviewItem as any).create({
        data: {
          userId,
          questionId: question.id,
          level: question.level,
          type: question.type,
          isWrongAnswer: true,
          wrongCount: 1,
          status: 'learning',
        },
      });
      testItemId = item.id;
    });

    afterAll(async () => {
      if (testItemId) {
        await (userPrisma.reviewItem as any).delete({ where: { id: testItemId } }).catch(() => {});
      }
    });

    it('should return 401 without auth', async () => {
      await request(app)
        .post('/api/v1/review/some-id/next')
        .send({ mode: 'original' })
        .expect(401);
    });

    it('should return 400 for invalid mode', async () => {
      if (!testItemId) return;

      await request(app)
        .post(`/api/v1/review/${testItemId}/next`)
        .set('Cookie', cookie)
        .send({ mode: 'invalid' })
        .expect(400);
    });

    it('should return original question with mode=original', async () => {
      if (!testItemId) return;

      const res = await request(app)
        .post(`/api/v1/review/${testItemId}/next`)
        .set('Cookie', cookie)
        .send({ mode: 'original' })
        .expect(200);

      expect(res.body).toHaveProperty('reviewItemId', testItemId);
      expect(res.body).toHaveProperty('mode', 'original');
      expect(res.body).toHaveProperty('question');
      expect(res.body.question).not.toHaveProperty('answer');
    });

    it('should update reviewMode after call', async () => {
      if (!testItemId) return;

      const response = await request(app)
        .post(`/api/v1/review/${testItemId}/next`)
        .set('Cookie', cookie)
        .send({ mode: 'similar' });
      expect([200, 404]).toContain(response.status); // A single-question fixture has no similar question.

      const item: any = await userPrisma.reviewItem.findUnique({ where: { id: testItemId } });
      expect(item.reviewMode).toBe('similar');
    });

    it('should return 404 for non-existent review item', async () => {
      await request(app)
        .post('/api/v1/review/non-existent-id/next')
        .set('Cookie', cookie)
        .send({ mode: 'original' })
        .expect(404);
    });
  });

  describe('Review Path API - retry-original', () => {
    let testItemId: string;

    beforeAll(async () => {
      const question = await prisma.question.findFirst({});
      if (!question) return;

      const item = await (userPrisma.reviewItem as any).create({
        data: {
          userId,
          questionId: question.id,
          level: question.level,
          type: question.type,
          isWrongAnswer: true,
          wrongCount: 1,
          status: 'learning',
        },
      });
      testItemId = item.id;
    });

    afterAll(async () => {
      if (testItemId) {
        await (userPrisma.reviewItem as any).delete({ where: { id: testItemId } }).catch(() => {});
      }
    });

    it('should return 401 without auth', async () => {
      await request(app)
        .post('/api/v1/review/some-id/retry-original')
        .expect(401);
    });

    it('should create new session for retry', async () => {
      if (!testItemId) return;

      const res = await request(app)
        .post(`/api/v1/review/${testItemId}/retry-original`)
        .set('Cookie', cookie)
        .expect(201);

      expect(res.body).toHaveProperty('sessionId');
      expect(res.body).toHaveProperty('reviewItemId', testItemId);
      expect(res.body).toHaveProperty('question');
      expect(res.body).toHaveProperty('message');
      expect(res.body.question).not.toHaveProperty('answer');

      // Verify the session was actually created with mode='retry'
      const session = await userPrisma.learningSession.findUnique({
        where: { id: res.body.sessionId },
      });
      expect(session).not.toBeNull();
      expect(session!.mode).toBe('retry');
      expect(session!.userId).toBe(userId);
    });

    it('should return 404 for non-existent review item', async () => {
      await request(app)
        .post('/api/v1/review/non-existent-id/retry-original')
        .set('Cookie', cookie)
        .expect(404);
    });
  });

  describe('Stats API - mistakes-detail', () => {
    it('should return 401 without auth', async () => {
      await request(app)
        .get('/api/v1/stats/mistakes-detail')
        .expect(401);
    });

    it('should return mistakes detail with expected shape', async () => {
      const res = await request(app)
        .get('/api/v1/stats/mistakes-detail?level=n5')
        .set('Cookie', cookie)
        .expect(200);

      expect(res.body).toHaveProperty('totalMistakes');
      expect(res.body).toHaveProperty('typeDistribution');
      expect(res.body).toHaveProperty('knowledgeDistribution');
      expect(res.body).toHaveProperty('timeTrend');
      expect(res.body).toHaveProperty('firstTimeWrong');
      expect(res.body).toHaveProperty('masteredAfterMistakes');
      expect(res.body).toHaveProperty('items');
      expect(Array.isArray(res.body.items)).toBe(true);

      // Verify numeric counters
      expect(typeof res.body.totalMistakes).toBe('number');
      expect(typeof res.body.firstTimeWrong).toBe('number');
      expect(typeof res.body.masteredAfterMistakes).toBe('number');
    });

    it('should work without level filter', async () => {
      const res = await request(app)
        .get('/api/v1/stats/mistakes-detail')
        .set('Cookie', cookie)
        .expect(200);

      expect(res.body).toHaveProperty('totalMistakes');
    });
  });
});
