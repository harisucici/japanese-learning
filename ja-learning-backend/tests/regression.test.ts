
import request from 'supertest';
import app from '../src/app';
import prisma from '../src/config/database';
import userPrisma from '../src/config/user-database';

const TEST_INVITE = 'QATEST' + Date.now().toString().slice(-2);
const TEST_EMAIL = 'qatest_af3fc8@example.com';
const TEST_PASSWORD = 'Test123456';

describe('Full Regression Test', () => {
  let agent: any;

  beforeAll(async () => {
    agent = request.agent(app);
    // Clean up stale test user from previous runs so register (test 4) gets 201
    // User table is managed via raw SQL, not Prisma models
    await (userPrisma as any).$executeRaw`DELETE FROM "User" WHERE email = ${TEST_EMAIL}`;
    await userPrisma.inviteCode.deleteMany({ where: { code: TEST_INVITE } });
    await userPrisma.inviteCode.create({ data: { code: TEST_INVITE, used: false } });
  }, 10000);

  afterAll(async () => {
    await userPrisma.$disconnect();
  }, 5000);

  // 1-3. Public endpoints
  it('1. Health check', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
  });

  it('2. Public: fun-papers', async () => {
    const res = await request(app).get('/api/v1/learning/fun-papers');
    expect(res.status).toBe(200);
  });

  it('3. Public: novel-lessons', async () => {
    const res = await request(app).get('/api/v1/learning/novel-lessons');
    expect(res.status).toBe(200);
  });

  // 4. Register
  it('4. Register with valid invite code', async () => {
    const res = await agent
      .post('/api/v1/auth/register')
      .send({ email: TEST_EMAIL, password: TEST_PASSWORD, currentLevel: 'n5', inviteCode: TEST_INVITE });
    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('user');
  });

  // 5. Duplicate email
  it('5. Reject duplicate email', async () => {
    const res = await agent
      .post('/api/v1/auth/register')
      .send({ email: TEST_EMAIL, password: TEST_PASSWORD, currentLevel: 'n5', inviteCode: TEST_INVITE });
    expect(res.status).toBe(409);
  });

  // 6. Weak password
  it('6. Reject weak password', async () => {
    const res = await agent
      .post('/api/v1/auth/register')
      .send({ email: 'weak@test.com', password: 'weak', currentLevel: 'n5', inviteCode: TEST_INVITE });
    expect(res.status).toBe(400);
  });

  // 7. Invalid email
  it('7. Reject invalid email', async () => {
    const res = await agent
      .post('/api/v1/auth/register')
      .send({ email: 'invalid', password: TEST_PASSWORD, currentLevel: 'n5', inviteCode: TEST_INVITE });
    expect(res.status).toBe(400);
  });

  // 8. Logout
  it('8. Logout after register', async () => {
    // Establish an explicit session before testing logout.
    await agent
      .post('/api/v1/auth/login')
      .send({ email: TEST_EMAIL, password: TEST_PASSWORD });
    const res = await agent.post('/api/v1/auth/logout');
    expect(res.status).toBe(200);
  });

  // 9. Login
  it('9. Login with valid credentials', async () => {
    const res = await agent
      .post('/api/v1/auth/login')
      .send({ email: TEST_EMAIL, password: TEST_PASSWORD });
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('user');
  });

  // 10. Wrong password
  it('10. Reject wrong password', async () => {
    const res = await agent
      .post('/api/v1/auth/login')
      .send({ email: TEST_EMAIL, password: 'wrongpassword' });
    expect(res.status).toBe(401);
  });

  // 11. Get profile when authenticated
  it('11. Get authenticated profile', async () => {
    const res = await agent.get('/api/v1/auth/me');
    expect(res.status).toBe(200);
    expect(res.body.user.email).toBe(TEST_EMAIL);
  });

  // 12. Logout for unauth tests
  it('12. Logout for unauth tests', async () => {
    const res = await agent.post('/api/v1/auth/logout');
    expect(res.status).toBe(200);
  });

  // 13-19. Unauthenticated protected endpoints
  it('13. Unauth: /auth/me → 401', async () => {
    const res = await agent.get('/api/v1/auth/me');
    expect(res.status).toBe(401);
  });

  it('14. Unauth: /review/items → 401', async () => {
    const res = await agent.get('/api/v1/review/items');
    expect(res.status).toBe(401);
  });

  it('15. Unauth: /review/due → 401', async () => {
    const res = await agent.get('/api/v1/review/due');
    expect(res.status).toBe(401);
  });

  it('16. Unauth: /stats/mistakes-detail → 401', async () => {
    const res = await agent.get('/api/v1/stats/mistakes-detail');
    expect(res.status).toBe(401);
  });

  it('17. Unauth: /practice/mistakes → 401', async () => {
    const res = await agent.get('/api/v1/practice/mistakes');
    expect(res.status).toBe(401);
  });

  it('18. Unauth: /practice/random → 401', async () => {
    const res = await agent.get('/api/v1/practice/random');
    expect(res.status).toBe(401);
  });

  it('19. Unauth: create session → 401', async () => {
    const res = await agent
      .post('/api/v1/learning/sessions')
      .send({ mode: 'practice', level: 'n5', limit: 3 });
    expect(res.status).toBe(401);
  });

  // 20. Re-login
  it('20. Re-login for authenticated tests', async () => {
    const res = await agent
      .post('/api/v1/auth/login')
      .send({ email: TEST_EMAIL, password: TEST_PASSWORD });
    expect(res.status).toBe(200);
  });

  // 21. Create practice session
  it('21. Create practice session', async () => {
    // The regression must not depend on a pre-existing N5 question bank.
    const question = await prisma.question.create({ data: {
      level: 'n5', type: 'vocabulary', content: 'テスト',
      options: [{ id: 'a', content: 'テスト', index: 0 }],
      answer: 'a', source: 'custom', explanationId: 'regression-explanation',
    } });
    try {
      const res = await agent
        .post('/api/v1/learning/sessions')
        .send({ mode: 'practice', level: 'n5', limit: 3 });
      expect(res.status).toBe(201);
    } finally {
      await prisma.question.delete({ where: { id: question.id } });
    }
  });

  // 22-23. Review items
  it('22. Get review items', async () => {
    const res = await agent.get('/api/v1/review/items');
    expect(res.status).toBe(200);
  });

  it('23. Get review due items', async () => {
    const res = await agent.get('/api/v1/review/due');
    expect(res.status).toBe(200);
  });

  // 24-26. Practice endpoints
  it('24. Practice by type', async () => {
    const res = await agent.get('/api/v1/practice/by-type/grammar?level=n5&limit=3');
    expect(res.status).toBe(200);
  });

  it('25. Practice random', async () => {
    const res = await agent.get('/api/v1/practice/random?level=n5&limit=3');
    expect(res.status).toBe(200);
  });

  it('26. Practice mistakes', async () => {
    const res = await agent.get('/api/v1/practice/mistakes?level=n5');
    expect(res.status).toBe(200);
  });

  // 27. Stats
  it('27. Get mistakes detail', async () => {
    const res = await agent.get('/api/v1/stats/mistakes-detail');
    expect(res.status).toBe(200);
  });

  // 28. Change password
  it('28. Change password', async () => {
    const res = await agent
      .post('/api/v1/auth/change-password')
      .send({ currentPassword: TEST_PASSWORD, newPassword: 'NewTest789012' });
    expect(res.status).toBe(200);
  });

  // 29. Login with new password
  it('29. Login with new password', async () => {
    await agent.post('/api/v1/auth/logout');
    const res = await agent
      .post('/api/v1/auth/login')
      .send({ email: TEST_EMAIL, password: 'NewTest789012' });
    expect(res.status).toBe(200);
  });

  // 30. Change back
  it('30. Change password back', async () => {
    const res = await agent
      .post('/api/v1/auth/change-password')
      .send({ currentPassword: 'NewTest789012', newPassword: TEST_PASSWORD });
    expect(res.status).toBe(200);
  });

  // 31. Update profile
  it('31. Update profile', async () => {
    const res = await agent
      .put('/api/v1/auth/profile')
      .send({ currentLevel: 'n4', targetLevel: 'n3' });
    expect(res.status).toBe(200);
  });

  // 32. Create exam session
  it('32. Create exam session', async () => {
    // exam mode requires a ready ExamPaper with minutes-bearing sections
    const paperId = `regression-exam-${Date.now()}`;
    await prisma.examPaper.create({
      data: {
        id: paperId,
        title: 'regression-exam',
        level: 'n5',
        kind: 'practice_exam',
        ready: true,
        sections: [{ id: 's1', title: 's1', questionIds: [], minutes: 30 }],
        materials: [],
        verificationNote: 'test',
      },
    });
    try {
      const res = await agent
        .post('/api/v1/learning/sessions')
        .send({ mode: 'exam', level: 'n5', paperId, instantFeedback: false });
      expect(res.status).toBe(201);
    } finally {
      await prisma.examPaper.delete({ where: { id: paperId } }).catch(() => {});
    }
  });

  // 33. Guest session
  it('33. Get guest session', async () => {
    await agent.post('/api/v1/auth/logout');
    const res = await request(app).post('/api/v1/learning/guest');
    expect(res.status).toBe(200);
  });

  // 34. Practice by grammar
  it('34. Practice by grammar', async () => {
    await agent
      .post('/api/v1/auth/login')
      .send({ email: TEST_EMAIL, password: TEST_PASSWORD });
    // Dynamically create a grammar entry instead of using a hardcoded ID
    // (the previously hardcoded `5d2ff05d-…` did not exist in the test DB and caused 404)
    const grammar = await (prisma as any).grammar.create({
      data: {
        name: 'regression-grammar',
        structure: 'X + Y',
        meaning: 'regression test grammar',
        level: 'n5',
        usage: {},
      },
    });
    try {
      const res = await agent.get(`/api/v1/practice/by-grammar/${grammar.id}?limit=5`);
      expect(res.status).toBe(200);
    } finally {
      await (prisma as any).grammar.delete({ where: { id: grammar.id } }).catch(() => {});
    }
  });

  // 35. Stats me
  it('35. Get my stats', async () => {
    const res = await agent.get('/api/v1/stats/me');
    expect(res.status).toBe(200);
  });

  // 36. Forgot password (expect 503 - no email service)
  it('36. Forgot password (expect 503)', async () => {
    const res = await agent
      .post('/api/v1/auth/forgot-password')
      .send({ email: TEST_EMAIL });
    expect([200, 503]).toContain(res.status);
  });

  // 37. Admin endpoints without admin role
  it('37. Admin questions (no auth)', async () => {
    await agent.post('/api/v1/auth/logout');
    const res = await request(app).get('/api/v1/admin/questions');
    expect([401, 403]).toContain(res.status);
  });

  // 38-40. Vocabulary / Grammar / Questions endpoints (require auth per v3.0)
  it('38. Authenticated: vocabulary list', async () => {
    await agent.post('/api/v1/auth/login').send({ email: TEST_EMAIL, password: TEST_PASSWORD });
    const res = await agent.get('/api/v1/vocabulary');
    expect(res.status).toBe(200);
  });

  it('39. Authenticated: grammar list', async () => {
    const res = await agent.get('/api/v1/grammar');
    expect(res.status).toBe(200);
  });

  it('40. Authenticated: questions list', async () => {
    const res = await agent.get('/api/v1/questions');
    expect(res.status).toBe(200);
  });
});
