// 认证系统完整测试：验证所有 API 端点
jest.setTimeout(60000);

// 降低 bcrypt 的 salt rounds，避免事务内计算时间过长导致 SQLite 流空闲超时
jest.mock('bcryptjs', () => {
  const actual = jest.requireActual('bcryptjs');
  const mocked = {
    ...actual,
    hash: jest.fn().mockImplementation((password: string, _rounds?: number) => actual.hash(password, 4)),
    compare: jest.fn().mockImplementation((password: string, hash: string) => actual.compare(password, hash)),
  };
  // bcryptjs 使用 default export
  return {
    __esModule: true,
    default: mocked,
  };
});

import request from 'supertest';
import app from '../src/app';
import prisma from '../src/config/database';
import userPrisma from '../src/config/user-database';
import { config } from '../src/config/env';

describe('Authentication System', () => {
  const testUser = {
    email: `test-${Date.now()}@example.com`,
    password: 'Test1234',
    nickname: '测试用户',
    currentLevel: 'n5' as const,
    targetLevel: 'n4' as const,
  };

  let authToken: string;
  let userId: string;
  let testInviteCode: string;
  let duplicateInviteCode: string;
  let migrateInviteCode: string;

  beforeAll(async () => {
    // 确保用户数据库已初始化
    if (!config.userTursoUrl) {
      console.warn('用户数据库未配置，跳过认证测试');
      return;
    }

    // 创建测试用邀请码（必须为 8 位大写字母/数字）
    testInviteCode = 'TEST' + Date.now().toString(36).toUpperCase().slice(-4).padStart(4, '0');
    duplicateInviteCode = 'DUP' + (Date.now() + 1).toString(36).toUpperCase().slice(-5).padStart(5, '0');
    migrateInviteCode = 'MIG' + (Date.now() + 2).toString(36).toUpperCase().slice(-5).padStart(5, '0');
    await userPrisma.inviteCode.createMany({
      data: [
        { code: testInviteCode, used: false, createdAt: new Date() },
        { code: duplicateInviteCode, used: false, createdAt: new Date() },
        { code: migrateInviteCode, used: false, createdAt: new Date() },
      ],
    });
  });

  describe('POST /auth/register', () => {
    it('应该成功注册新用户', async () => {
      if (!config.userTursoUrl) return;

      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({ ...testUser, inviteCode: testInviteCode });

      if (res.status !== 201) {
        console.error('Register failed:', res.status, res.body.data);
      }

      expect(res.status).toBe(201);

      expect(res.body.data).toHaveProperty('user');
      expect(res.body.data.user.email).toBe(testUser.email);
      expect(res.body.data.user.nickname).toBe(testUser.nickname);
      expect(res.body.data.user.currentLevel).toBe(testUser.currentLevel);
      expect(res.body.data.user.targetLevel).toBe(testUser.targetLevel);
      expect(res.body.data.user).not.toHaveProperty('passwordHash');

      authToken = res.headers['set-cookie']?.[0]?.split(';')[0].split('=')[1];
      userId = res.body.data.user.id;
    });

    it('应该拒绝重复邮箱注册', async () => {
      if (!config.userTursoUrl) return;

      await request(app)
        .post('/api/v1/auth/register')
        .send({ ...testUser, inviteCode: duplicateInviteCode })
        .expect(409);
    });

    it('应该拒绝弱密码', async () => {
      if (!config.userTursoUrl) return;

      await request(app)
        .post('/api/v1/auth/register')
        .send({
          email: 'weak@example.com',
          password: 'weak',
          nickname: '弱密码用户',
        })
        .expect(400);
    });

    it('应该拒绝无效邮箱', async () => {
      if (!config.userTursoUrl) return;

      await request(app)
        .post('/api/v1/auth/register')
        .send({
          email: 'invalid-email',
          password: 'Test1234',
          nickname: '无效邮箱用户',
        })
        .expect(400);
    });
  });

  describe('POST /auth/login', () => {
    it('应该成功登录', async () => {
      if (!config.userTursoUrl) return;

      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: testUser.email,
          password: testUser.password,
        })
        .expect(200);

      expect(res.body.data).toHaveProperty('user');
      expect(res.body.data.user.email).toBe(testUser.email);
    });

    it('应该拒绝错误密码', async () => {
      if (!config.userTursoUrl) return;

      await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: testUser.email,
          password: 'WrongPassword123',
        })
        .expect(401);
    });

    it('应该拒绝不存在的邮箱', async () => {
      if (!config.userTursoUrl) return;

      await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'Test1234',
        })
        .expect(401);
    });
  });

  describe('GET /auth/me', () => {
    it('应该返回当前用户信息', async () => {
      if (!config.userTursoUrl || !authToken) return;

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body.data).toHaveProperty('user');
      expect(res.body.data.user.email).toBe(testUser.email);
      expect(res.body.data.user.id).toBe(userId);
    });

    it('应该拒绝未认证请求', async () => {
      if (!config.userTursoUrl) return;

      await request(app)
        .get('/api/v1/auth/me')
        .expect(401);
    });
  });

  describe('PUT /auth/profile', () => {
    it('应该更新用户资料', async () => {
      if (!config.userTursoUrl || !authToken) return;

      const res = await request(app)
        .put('/api/v1/auth/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          nickname: '新昵称',
          currentLevel: 'n4',
          targetLevel: 'n3',
        })
        .expect(200);

      expect(res.body.data.user.nickname).toBe('新昵称');
      expect(res.body.data.user.currentLevel).toBe('n4');
      expect(res.body.data.user.targetLevel).toBe('n3');
    });

    it('应该拒绝无效的等级', async () => {
      if (!config.userTursoUrl || !authToken) return;

      await request(app)
        .put('/api/v1/auth/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          currentLevel: 'invalid',
        })
        .expect(400);
    });
  });

  describe('POST /auth/forgot-password', () => {
    it('明确提示未配置邮件服务', async () => {
      if (!config.userTursoUrl || config.passwordResetApiKey) return;
      await request(app).post('/api/v1/auth/forgot-password').send({ email: testUser.email }).expect(503);
    });
    it('未配置时不假装向不存在邮箱发信', async () => {
      if (!config.userTursoUrl || config.passwordResetApiKey) return;
      await request(app).post('/api/v1/auth/forgot-password').send({ email: 'nonexistent@example.com' }).expect(503);
    });
  });

  describe('POST /auth/reset-password', () => {
    it('应该拒绝无效的重置令牌', async () => {
      if (!config.userTursoUrl) return;

      await request(app)
        .post('/api/v1/auth/reset-password')
        .send({
          token: 'invalid-token',
          password: 'NewPassword123',
        })
        .expect(400);
    });
  });

  describe('POST /auth/logout', () => {
    it('应该成功登出', async () => {
      if (!config.userTursoUrl || !authToken) return;

      const res = await request(app)
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('success');
      expect(res.body.success).toBe(true);
    });
  });

  describe('POST /auth/migrate-from-anonymous', () => {
    it('仅允许迁移当前访客身份', async () => {
      if (!config.userTursoUrl) return;
      const guest = await request(app).post('/api/v1/learning/guest').expect(200);
      const guestCookie = guest.headers['set-cookie'][0].split(';')[0];
      const jwt = await import('jsonwebtoken');
      const payload = jwt.default.verify(decodeURIComponent(guestCookie.split('=')[1]), config.jwtSecret) as { userId: string };
      const input = { email: `migrate-${Date.now()}@example.com`, password: 'Migrate123', nickname: '迁移用户', anonymousId: payload.userId, inviteCode: migrateInviteCode };
      const upgraded = await request(app).post('/api/v1/auth/migrate-from-anonymous').set('Cookie', guestCookie).send(input).expect(200);
      expect(upgraded.body.data.user.email).toBe(input.email);
      await request(app).post('/api/v1/auth/migrate-from-anonymous').set('Authorization', `Bearer ${authToken}`).send({ ...input, email: `other-${Date.now()}@example.com` }).expect(403);
    });
  });

  afterAll(async () => {
    // 清理测试数据
    if (config.userTursoUrl && userId) {
      try {
        await userPrisma.anonymousLearner.delete({ where: { id: userId } });
      } catch (e) {
        // 忽略删除错误
      }
    }
    await Promise.all([prisma.$disconnect(), userPrisma.$disconnect()]);
  });
});
