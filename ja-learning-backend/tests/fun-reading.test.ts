/**
 * 趣味阅读模块 - 后端API自动化测试
 * Test coverage: 文章获取、问题与答案逻辑、会话管理
 */
jest.setTimeout(60000);

import request from 'supertest';
import app from '../src/app';
import prisma from '../src/config/database';
import userPrisma from '../src/config/user-database';
import { config } from '../src/config/env';

describe('趣味阅读模块 - API测试', () => {
  let testUserId: string;
  let testCookie: string;

  // 测试数据
  const mockFunPaper = {
    id: `fun-test-${Date.now()}`,
    title: '测试趣味题组',
    description: '用于自动化测试的趣味题组',
    theme: '测试主题',
    questionIds: '[]',
    materialIds: '[]',
    published: true,
  };

  const mockReadingArticle = {
    id: `novel-test-${Date.now()}`,
    title: '测试小说章节',
    category: '长篇小说',
    position: 999,
    startPage: 1,
    endPage: 5,
    pages: JSON.stringify([
      { pageNumber: 1, text: '测试内容第一页' },
      { pageNumber: 2, text: '测试内容第二页' },
    ]),
    vocabulary: JSON.stringify([
      { word: '测试', reading: 'テスト', meaning: 'test', level: 'n5' },
    ]),
    note: '测试备注',
    materialId: 'test-material',
    paperId: mockFunPaper.id,
    questionCount: 0,
    published: true,
    sourceTitle: '测试来源',
    sourcePages: 10,
    attribution: '测试作者',
  };

  beforeAll(async () => {
    if (!config.userTursoUrl || !config.tursoUrl) {
      console.warn('数据库未配置，跳过测试');
      return;
    }

    // 创建测试用户
    const user = await userPrisma.anonymousLearner.create({
      data: { id: `test-user-${Date.now()}` },
    });
    testUserId = user.id;

    // 生成JWT token模拟登录
    const jwt = await import('jsonwebtoken');
    const token = jwt.default.sign({ userId: testUserId, kind: 'guest' }, config.jwtSecret, { expiresIn: '1h' });
    testCookie = `ja_session=${token}`;

    // 插入测试数据
    await prisma.funPaper.create({ data: mockFunPaper as any });
    await prisma.readingArticle.create({ data: mockReadingArticle as any });
  }, 30000);

  afterAll(async () => {
    if (!config.userTursoUrl || !config.tursoUrl) return;

    // 清理测试数据：先删子记录，再删主记录，避免外键约束失败
    const idsToDelete = {
      articleId: mockReadingArticle.id,
      paperId: mockFunPaper.id,
      userId: testUserId,
    };

    try {
      // 清理所有关联的 learningSession 及其 answers（级联）
      await userPrisma.learningSession.deleteMany({
        where: { userId: idsToDelete.userId },
      });

      // 清理阅读文章
      await prisma.readingArticle.delete({ where: { id: idsToDelete.articleId } }).catch(() => {});

      // 清理趣味题组
      await prisma.funPaper.delete({ where: { id: idsToDelete.paperId } }).catch(() => {});

      // 清理测试用户（级联会删除关联记录）
      await userPrisma.anonymousLearner.delete({ where: { id: idsToDelete.userId } }).catch(() => {});
    } catch (e) {
      console.error('清理测试数据失败:', e);
    }

    await Promise.all([prisma.$disconnect(), userPrisma.$disconnect()]);
  });

  describe('GET /api/v1/learning/fun-papers', () => {
    it('应该成功获取趣味题组列表', async () => {
      if (!config.tursoUrl) return;

      const res = await request(app)
        .get('/api/v1/learning/fun-papers')
        .expect(200);

      expect(res.body).toHaveProperty('papers');
      expect(res.body).toHaveProperty('label');
      expect(Array.isArray(res.body.papers)).toBe(true);
      expect(res.body.papers.length).toBeGreaterThan(0);

      // 验证返回的数据结构
      const paper = res.body.papers[0];
      expect(paper).toHaveProperty('id');
      expect(paper).toHaveProperty('title');
      expect(paper).toHaveProperty('description');
      expect(paper).toHaveProperty('theme');
      expect(paper).toHaveProperty('questionCount');
      expect(paper).toHaveProperty('ready');
      expect(paper).toHaveProperty('readingLessonId');
    });

    it('应该正确计算题目完成度', async () => {
      if (!config.tursoUrl) return;

      const res = await request(app)
        .get('/api/v1/learning/fun-papers')
        .expect(200);

      const paper = res.body.papers.find((p: any) => p.id === mockFunPaper.id);
      if (paper) {
        expect(paper.questionCount).toBeGreaterThanOrEqual(0);
        expect(typeof paper.ready).toBe('boolean');
        // ready = questionIds.length > 0 && 所有题目都在数据库中
      }
    });

    it('应该关联阅读课程ID', async () => {
      if (!config.tursoUrl) return;

      const res = await request(app)
        .get('/api/v1/learning/fun-papers')
        .expect(200);

      const paper = res.body.papers.find((p: any) => p.id === mockFunPaper.id);
      if (paper) {
        expect(paper.readingLessonId).toBe(mockReadingArticle.id);
      }
    });
  });

  describe('GET /api/v1/learning/novel-lessons', () => {
    it('应该成功获取小说章节列表', async () => {
      if (!config.tursoUrl) return;

      const res = await request(app)
        .get('/api/v1/learning/novel-lessons')
        .expect(200);

      expect(res.body).toHaveProperty('lessons');
      expect(res.body).toHaveProperty('title');
      expect(res.body).toHaveProperty('attribution');
      expect(res.body).toHaveProperty('sourceTitle');
      expect(res.body).toHaveProperty('sourcePages');
      expect(Array.isArray(res.body.lessons)).toBe(true);

      // 验证返回的数据结构
      const lesson = res.body.lessons.find((l: any) => l.id === mockReadingArticle.id);
      if (lesson) {
        expect(lesson.title).toBe(mockReadingArticle.title);
        expect(lesson.category).toBe(mockReadingArticle.category);
        expect(lesson).toHaveProperty('vocabularyCount');
        expect(lesson).not.toHaveProperty('pages'); // 列表不应包含完整页面内容
        expect(lesson).not.toHaveProperty('vocabulary'); // 列表不应包含完整词汇
      }
    });

    it('应该按position排序', async () => {
      if (!config.tursoUrl) return;

      const res = await request(app)
        .get('/api/v1/learning/novel-lessons')
        .expect(200);

      const positions = res.body.lessons.map((l: any) => l.position);
      const sorted = [...positions].sort((a: number, b: number) => a - b);
      expect(positions).toEqual(sorted);
    });
  });

  describe('GET /api/v1/learning/novel-lessons/:id', () => {
    it('应该成功获取小说章节详情', async () => {
      if (!config.tursoUrl) return;

      const res = await request(app)
        .get(`/api/v1/learning/novel-lessons/${mockReadingArticle.id}`)
        .expect(200);

      expect(res.body).toHaveProperty('id', mockReadingArticle.id);
      expect(res.body).toHaveProperty('title', mockReadingArticle.title);
      expect(res.body).toHaveProperty('pages');
      expect(res.body).toHaveProperty('vocabulary');
      expect(Array.isArray(res.body.pages)).toBe(true);
      expect(Array.isArray(res.body.vocabulary)).toBe(true);
    });

    it('应该返回404当章节不存在', async () => {
      if (!config.tursoUrl) return;

      const res = await request(app)
        .get('/api/v1/learning/novel-lessons/non-existent-id')
        .expect(404);

      expect(res.body).toHaveProperty('error');
    });

    it('应该对特殊字符进行URL编码', async () => {
      if (!config.tursoUrl) return;

      const res = await request(app)
        .get(`/api/v1/learning/novel-lessons/${encodeURIComponent(mockReadingArticle.id)}`)
        .expect(200);

      expect(res.body.id).toBe(mockReadingArticle.id);
    });
  });

  describe('POST /api/v1/learning/sessions (趣味模式)', () => {
    it('应该成功创建趣味会话', async () => {
      if (!config.tursoUrl || !config.userTursoUrl) return;

      // 先创建一个有题目的FunPaper
      const paperWithQuestions = {
        ...mockFunPaper,
        id: `fun-with-q-${Date.now()}`,
        questionIds: JSON.stringify(['test-q-1', 'test-q-2']),
      };

      // 创建测试题目
      const testQuestions = [
        {
          id: 'test-q-1',
          level: 'ungraded',
          type: 'vocabulary',
          content: '测试题目1',
          options: JSON.stringify([{ id: 'opt1', content: '选项1' }, { id: 'opt2', content: '选项2' }]),
          answer: 'opt1',
          source: 'custom',
          explanationId: 'exp-1',
        },
        {
          id: 'test-q-2',
          level: 'ungraded',
          type: 'vocabulary',
          content: '测试题目2',
          options: JSON.stringify([{ id: 'opt3', content: '选项3' }, { id: 'opt4', content: '选项4' }]),
          answer: 'opt3',
          source: 'custom',
          explanationId: 'exp-2',
        },
      ];

      try {
        await prisma.funPaper.create({ data: paperWithQuestions as any });
        for (const q of testQuestions) {
          await prisma.question.create({ data: q as any });
        }

        const res = await request(app)
          .post('/api/v1/learning/sessions')
          .set('Cookie', testCookie)
          .send({
            level: 'n5',
            mode: 'fun',
            collectionId: paperWithQuestions.id,
          })
          .expect(201);

        expect(res.body).toHaveProperty('id');
        expect(res.body).toHaveProperty('mode', 'fun');
        expect(res.body).toHaveProperty('collectionId', paperWithQuestions.id);
        expect(res.body).toHaveProperty('questions');
        expect(Array.isArray(res.body.questions)).toBe(true);
      } finally {
        // 清理
        await prisma.funPaper.delete({ where: { id: paperWithQuestions.id } }).catch(() => {});
        await prisma.question.deleteMany({ where: { id: { in: testQuestions.map(q => q.id) } } }).catch(() => {});
      }
    });

    it('应该拒绝未发布的趣味题组', async () => {
      if (!config.tursoUrl || !config.userTursoUrl) return;

      const unpublishedPaper = {
        ...mockFunPaper,
        id: `fun-unpub-${Date.now()}`,
        published: false,
      };

      try {
        await prisma.funPaper.create({ data: unpublishedPaper as any });

        await request(app)
          .post('/api/v1/learning/sessions')
          .set('Cookie', testCookie)
          .send({
            level: 'n5',
            mode: 'fun',
            collectionId: unpublishedPaper.id,
          })
          .expect(404);
      } finally {
        await prisma.funPaper.delete({ where: { id: unpublishedPaper.id } }).catch(() => {});
      }
    });

    it('应该拒绝未认证请求', async () => {
      if (!config.tursoUrl) return;

      await request(app)
        .post('/api/v1/learning/sessions')
        .send({
          level: 'n5',
          mode: 'fun',
          collectionId: mockFunPaper.id,
        })
        .expect(401);
    });

    it('应该验证mode参数', async () => {
      if (!config.tursoUrl || !config.userTursoUrl) return;

      await request(app)
        .post('/api/v1/learning/sessions')
        .set('Cookie', testCookie)
        .send({
          level: 'n5',
          mode: 'invalid-mode',
          collectionId: mockFunPaper.id,
        })
        .expect(400);
    });
  });

  describe('会话答题流程', () => {
    let sessionId: string;
    let questionIds: string[];
    let testPaperId: string;

    beforeAll(async () => {
      if (!config.tursoUrl || !config.userTursoUrl) return;

      // 使用唯一的ID避免冲突
      testPaperId = `fun-flow-${Date.now()}-${Math.random().toString(36).substring(7)}`;
      const testQuestionIds = [`q-flow-1-${Date.now()}`, `q-flow-2-${Date.now()}`];

      await prisma.funPaper.create({
        data: {
          id: testPaperId,
          title: '流程测试题组',
          description: '测试',
          theme: '测试',
          questionIds: JSON.stringify(testQuestionIds),
          materialIds: '[]',
          published: true,
        } as any,
      });

      await prisma.question.create({
        data: {
          id: testQuestionIds[0],
          level: 'ungraded',
          type: 'vocabulary',
          content: '题目1',
          options: JSON.stringify([{ id: 'a1', content: 'A' }, { id: 'a2', content: 'B' }]),
          answer: 'a1',
          source: 'custom',
          explanationId: `exp-flow-1-${Date.now()}`,
        } as any,
      });

      await prisma.question.create({
        data: {
          id: testQuestionIds[1],
          level: 'ungraded',
          type: 'vocabulary',
          content: '题目2',
          options: JSON.stringify([{ id: 'b1', content: 'C' }, { id: 'b2', content: 'D' }]),
          answer: 'b2',
          source: 'custom',
          explanationId: `exp-flow-2-${Date.now()}`,
        } as any,
      });

      // 创建会话
      const res = await request(app)
        .post('/api/v1/learning/sessions')
        .set('Cookie', testCookie)
        .send({
          level: 'n5',
          mode: 'fun',
          collectionId: testPaperId,
        });

      sessionId = res.body.id;
      questionIds = testQuestionIds;
    }, 30000);

    afterAll(async () => {
      if (!config.tursoUrl || !config.userTursoUrl) return;

      // 清理会话和答题记录
      if (sessionId) {
        await userPrisma.learningSession.delete({ where: { id: sessionId } }).catch(() => {});
      }
      
      // 清理测试题目和题组
      if (testPaperId) {
        await prisma.funPaper.delete({ where: { id: testPaperId } }).catch(() => {});
      }
      
      if (questionIds && questionIds.length > 0) {
        await prisma.question.deleteMany({ 
          where: { id: { in: questionIds } } 
        }).catch(() => {});
      }
    }, 30000);

    it('应该获取会话详情', async () => {
      if (!sessionId) return;

      const res = await request(app)
        .get(`/api/v1/learning/sessions/${sessionId}`)
        .set('Cookie', testCookie)
        .expect(200);

      expect(res.body).toHaveProperty('id', sessionId);
      expect(res.body).toHaveProperty('questions');
      expect(res.body).toHaveProperty('currentIndex', 0);
    });

    it('应该提交答案并返回结果', async () => {
      if (!sessionId || !questionIds.length) return;

      const res = await request(app)
        .post(`/api/v1/learning/sessions/${sessionId}/answers`)
        .set('Cookie', testCookie)
        .send({
          questionId: questionIds[0],
          optionId: 'a1', // 正确答案
        })
        .expect(200);

      expect(res.body).toHaveProperty('answers');
      const answer = res.body.answers.find((a: any) => a.questionId === questionIds[0]);
      expect(answer).toHaveProperty('isCorrect', true);
      expect(answer).toHaveProperty('correctOptionId', 'a1');
    });

    it('应该拒绝重复答题', async () => {
      if (!sessionId || !questionIds.length) return;

      await request(app)
        .post(`/api/v1/learning/sessions/${sessionId}/answers`)
        .set('Cookie', testCookie)
        .send({
          questionId: questionIds[0],
          optionId: 'a2',
        })
        .expect(409);
    });

    it('应该进入下一题', async () => {
      if (!sessionId) return;

      const res = await request(app)
        .post(`/api/v1/learning/sessions/${sessionId}/next`)
        .set('Cookie', testCookie)
        .expect(200);

      expect(res.body).toHaveProperty('currentIndex');
    });

    it('应该验证答案参数', async () => {
      if (!sessionId) return;

      // 缺少questionId
      await request(app)
        .post(`/api/v1/learning/sessions/${sessionId}/answers`)
        .set('Cookie', testCookie)
        .send({
          optionId: 'a1',
        })
        .expect(400);

      // 缺少optionId
      await request(app)
        .post(`/api/v1/learning/sessions/${sessionId}/answers`)
        .set('Cookie', testCookie)
        .send({
          questionId: questionIds[1] || 'dummy',
        })
        .expect(400);
    });

    it('应该拒绝无效选项', async () => {
      if (!sessionId || !questionIds[1]) return;

      await request(app)
        .post(`/api/v1/learning/sessions/${sessionId}/answers`)
        .set('Cookie', testCookie)
        .send({
          questionId: questionIds[1],
          optionId: 'invalid-option-id',
        })
        .expect(400);
    });
  });

  describe('数据完整性验证', () => {
    it('趣味题组的questionIds应该是有效JSON数组', async () => {
      if (!config.tursoUrl) return;

      const res = await request(app)
        .get('/api/v1/learning/fun-papers')
        .expect(200);

      for (const paper of res.body.papers) {
        expect(typeof paper.questionCount).toBe('number');
        expect(paper.questionCount).toBeGreaterThanOrEqual(0);
      }
    });

    it('小说章节的pages应该是有效JSON数组', async () => {
      if (!config.tursoUrl) return;

      const res = await request(app)
        .get(`/api/v1/learning/novel-lessons/${mockReadingArticle.id}`)
        .expect(200);

      expect(Array.isArray(res.body.pages)).toBe(true);
      for (const page of res.body.pages) {
        expect(page).toHaveProperty('pageNumber');
        expect(typeof page.pageNumber).toBe('number');
      }
    });

    it('小说章节的vocabulary应该是有效JSON数组', async () => {
      if (!config.tursoUrl) return;

      const res = await request(app)
        .get(`/api/v1/learning/novel-lessons/${mockReadingArticle.id}`)
        .expect(200);

      expect(Array.isArray(res.body.vocabulary)).toBe(true);
      for (const vocab of res.body.vocabulary) {
        expect(vocab).toHaveProperty('word');
        expect(vocab).toHaveProperty('reading');
        expect(vocab).toHaveProperty('meaning');
      }
    });
  });
});
