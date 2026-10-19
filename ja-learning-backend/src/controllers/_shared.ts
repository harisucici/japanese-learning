import { Response } from 'express';
import { Prisma } from '@prisma/client';
import { z } from 'zod';
import { AuthRequest } from '../middleware/auth';

export class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

export const run = (fn: (req: AuthRequest, res: Response) => Promise<unknown>) =>
  async (req: AuthRequest, res: Response) => {
    try {
      await fn(req, res);
    } catch (e: any) {
      const conflict = ['P2002', 'P2034'].includes(e.code);
      const status = e instanceof HttpError
        ? e.status
        : e instanceof z.ZodError
        ? 400
        : e.code === 'P2025'
        ? 404
        : conflict
        ? 409
        : 500;
      if (status === 500) console.error(e);
      res.status(status).json({
        error: status === 500
          ? '服务暂时不可用，请重试'
          : conflict
          ? '该题已提交或状态已更新，请刷新'
          : e.code === 'P2025'
          ? '记录不存在，请重新连接'
          : e.message,
      });
    }
  };

export const ids = (value: Prisma.JsonValue): string[] => {
  if (!Array.isArray(value) || !value.every(item => typeof item === 'string')) {
    throw new HttpError(500, '题目编号格式无效');
  }
  return value as string[];
};

export const publicQuestion = (q: any) => {
  const { answer, explanationId, difficulty, ...visible } = q;
  if (visible.provenance) {
    const { correctOption, ...source } = visible.provenance;
    visible.provenance = source;
  }
  return visible;
};

export const points = (answers: { isCorrect: boolean }[], total: number) => ({
  correctCount: answers.filter(a => a.isCorrect).length,
  answeredCount: answers.length,
  totalQuestions: total,
  score: total ? Math.round(100 * answers.filter(a => a.isCorrect).length / total) : 0,
});

export async function endExamSection(db: Prisma.TransactionClient, session: any) {
  const c = session.examConfig as any;
  const i = c.sectionIndex;
  if (i + 1 >= c.sections.length) {
    await finish(db, session);
    return;
  }
  const next = c.sections[i + 1];
  await db.learningSession.update({
    where: { id: session.id },
    data: {
      currentIndex: session.questionIds.indexOf(next.questionIds[0]),
      awaitingNext: false,
      examConfig: { ...c, waitingSection: true, deadline: null },
    },
  });
}

export async function clockSync(db: Prisma.TransactionClient, id: string, userId: string) {
  const s = await db.learningSession.findFirst({ where: { id, userId } });
  const c = s?.examConfig as any;
  if (s && !s.completedAt && c && !c.waitingSection && c.deadline && Date.now() >= Date.parse(c.deadline)) {
    await endExamSection(db, s);
  }
}

export async function advance(db: Prisma.TransactionClient, session: any) {
  const c = session.examConfig as any;
  if (c) {
    const section = c.sections[c.sectionIndex];
    if (section.questionIds[section.questionIds.length - 1] === session.questionIds[session.currentIndex]) {
      await endExamSection(db, session);
      return;
    }
  }
  if (session.currentIndex + 1 === session.questionIds.length) await finish(db, session);
  else {
    await db.learningSession.update({
      where: { id: session.id },
      data: { currentIndex: { increment: 1 }, awaitingNext: false },
    });
  }
}

export async function state(db: Prisma.TransactionClient, id: string, userId: string) {
  await clockSync(db, id, userId);
  const session = await db.learningSession.findFirst({
    where: { id, userId },
    include: { answers: { orderBy: { answeredAt: 'asc' } } },
  });
  if (!session) throw new HttpError(404, '练习不存在');
  const questionIds = ids(session.questionIds);
  const qs = await db.question.findMany({ where: { id: { in: questionIds } } });
  const es = session.answers.length
    ? await db.explanation.findMany({ where: { questionId: { in: session.answers.map(a => a.questionId) } } })
    : [];
  const activity = session.collectionId
    ? await db.funPaper.findUnique({ where: { id: session.collectionId } })
    : null;
  const cfg = session.examConfig as any;
  const hide = cfg && !cfg.instantFeedback && !session.completedAt;
  return {
    ...session,
    activity,
    serverNow: new Date().toISOString(),
    ...points(session.answers, questionIds.length),
    questions: questionIds.map(qid => publicQuestion(qs.find(q => q.id === qid))),
    ...(hide ? { score: null, correctCount: null } : {}),
    answers: session.answers.map(a =>
      hide
        ? { questionId: a.questionId, selectedOptionId: a.selectedOptionId, answeredAt: a.answeredAt }
        : {
            ...a,
            correctOptionId: qs.find(q => q.id === a.questionId)!.answer,
            explanation: es.find(e => e.questionId === a.questionId) ?? null,
          }
    ),
  };
}

export async function finish(db: Prisma.TransactionClient, session: any) {
  const answers = await db.learningAnswer.findMany({ where: { sessionId: session.id } });
  if (!session.examConfig && answers.length !== session.questionIds.length) {
    throw new HttpError(409, '请完成全部题目后查看总分');
  }
  const now = new Date();
  await db.learningSession.update({
    where: { id: session.id },
    data: { completedAt: now, awaitingNext: false },
  });
  const p = points(answers, session.questionIds.length);
  await db.examRecord.upsert({
    where: { id: session.id },
    update: {},
    create: {
      id: session.id,
      userId: session.userId,
      level: session.level,
      recordType: session.mode === 'exam' ? 'exam' : 'practice',
      questionIds: session.questionIds,
      answers: answers.map(a => ({
        questionId: a.questionId,
        selectedOptionId: a.selectedOptionId,
        isCorrect: a.isCorrect,
      })),
      totalQuestions: p.totalQuestions,
      correctCount: p.correctCount,
      score: p.score,
      durationMs: now.getTime() - session.createdAt.getTime(),
    },
  });
}
