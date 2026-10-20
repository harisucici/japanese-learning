import { Response } from 'express';
import { Prisma } from '@prisma/client';
import prisma from '../config/database';
import userPrisma from '../config/user-database';
import { examSections, examConfig, timingSource } from '../services/exam-rules';
import { articleAudio } from '../services/article-audio';
import { AuthRequest } from '../middleware/auth';
import { HttpError, run, ids, points } from './_shared';

const verified: Prisma.QuestionWhereInput = {
  source: { in: ['pastExam', 'official'] as string[] },
  provenance: { not: Prisma.DbNull },
};

export class ContentController {
  catalog = run(async (_req: AuthRequest, res: Response) => {
    const groups = await prisma.question.groupBy({
      by: ['level', 'type'],
      where: verified,
      _count: { _all: true },
    });
    res.json({
      total: groups.reduce((s, g) => s + g._count._all, 0),
      groups: groups.map(g => ({ level: g.level, type: g.type, count: g._count._all })),
    });
  });

  examPapers = run(async (_req: AuthRequest, res: Response) => {
    const papers = await prisma.examPaper.findMany({ orderBy: [{ examYear: 'desc' }, { level: 'desc' }] });
    res.json({
      papers,
      timingSource,
      rules: Object.fromEntries(
        ['n5', 'n4', 'n3', 'n2', 'n1'].map(l => [l, examSections(l)])
      ),
    });
  });

  funPapers = run(async (_req: AuthRequest, res: Response) => {
    const reading = await prisma.readingArticle.findMany({ select: { id: true, paperId: true } });
    const papers = await prisma.funPaper.findMany({ where: { published: true }, orderBy: { id: 'asc' } });
    const qs = await prisma.question.findMany({
      where: { id: { in: papers.flatMap(p => ids(p.questionIds)) }, source: 'custom' },
      select: { id: true },
    });
    const known = new Set(qs.map(q => q.id));
    res.json({
      papers: papers.map(p => {
        const pids = ids(p.questionIds);
        return {
          ...p,
          readingLessonId: reading.find(l => l.paperId === p.id)?.id ?? null,
          questionCount: pids.filter(id => known.has(id)).length,
          ready: pids.length > 0 && pids.every(id => known.has(id)),
        };
      }),
      label: '用户素材改编练习，非JLPT真题，不作等级认证',
    });
  });

  novelLessons = run(async (_req: AuthRequest, res: Response) => {
    const rows = await prisma.readingArticle.findMany({ orderBy: { position: 'asc' } });
    res.json({
      title: '小说词汇阅读与练习',
      attribution: rows[0]?.attribution ?? null,
      sourceTitle: rows[0]?.sourceTitle ?? null,
      sourcePages: rows[0]?.sourcePages ?? 0,
      lessons: rows.map(({ pages, vocabulary, ...article }) => ({
        ...article,
        vocabularyCount: (vocabulary as any[]).length,
      })),
    });
  });

  novelLessonById = run(async (req: AuthRequest, res: Response) => {
    const l = await prisma.readingArticle.findUnique({ where: { id: req.params.id as string } });
    if (!l) throw new HttpError(404, '小说章节不存在');
    res.json(l);
  });

  materials = run(async (_req: AuthRequest, res: Response) => {
    const rows = await prisma.studyMaterial.findMany({
      select: { id: true, title: true, collection: true, textStatus: true, japanese: true, audioLinks: { orderBy: { position: 'asc' } } },
      orderBy: [{ collection: 'asc' }, { id: 'asc' }],
    });
    const items = rows.map(({ audioLinks, japanese, ...item }) => ({
      ...item,
      hasText: !!japanese,
      audios: audioLinks.map(l => articleAudio(l.audioId)),
    }));
    res.json({ items, total: items.length, audioCount: items.filter(i => i.audios.length).length });
  });

  materialById = run(async (req: AuthRequest, res: Response) => {
    const m = await prisma.studyMaterial.findUnique({
      where: { id: req.params.id as string },
      include: { audioLinks: { orderBy: { position: 'asc' } } },
    });
    if (!m) throw new HttpError(404, '素材不存在');
    const { sourcePath, ...metadata } = m.metadata as any;
    const { audioLinks, ...article } = m;
    res.json({ ...article, metadata, audios: audioLinks.map(l => articleAudio(l.audioId)) });
  });

  dashboard = run(async (req: AuthRequest, res: Response) => {
    const [user, sessions, attempts] = await Promise.all([
      userPrisma.anonymousLearner.findUniqueOrThrow({
        where: { id: req.userId },
        select: { id: true, createdAt: true },
      }),
      userPrisma.learningSession.findMany({
        where: { userId: req.userId },
        orderBy: { createdAt: 'desc' },
        include: { answers: true },
      }),
      userPrisma.learningAnswer.findMany({
        where: {
          session: {
            userId: req.userId,
            OR: [{ mode: { not: 'exam' } }, { completedAt: { not: null } }],
          },
        },
        select: { isCorrect: true },
      }),
    ]);
    const activities = await prisma.funPaper.findMany({
      where: { id: { in: sessions.flatMap(s => (s.collectionId ? [s.collectionId] : [])) } },
    });
    const done = sessions.filter(s => s.completedAt);
    res.json({
      user,
      totalAnswered: attempts.length,
      correctCount: attempts.filter(a => a.isCorrect).length,
      wrongCount: attempts.filter(a => !a.isCorrect).length,
      completedSessions: done.length,
      accuracy: attempts.length ? attempts.filter(a => a.isCorrect).length / attempts.length : null,
      sessions: sessions.map(({ answers, ...s }) => ({
        ...s,
        activityTitle: activities.find(p => p.id === s.collectionId)?.title ?? null,
        ...points(answers, ids(s.questionIds).length),
      })),
    });
  });
}

export const contentController = new ContentController();
