import { Response } from 'express';
import { Prisma } from '@prisma/client';
import contentPrisma from '../config/database';
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
  const provenance = q.provenance
    ? {
        kind: q.provenance.kind,
        collection: q.provenance.collection,
        passage: q.provenance.passage,
        title: q.provenance.title,
        sourcePage: q.provenance.sourcePage,
      }
    : null;
  return {
    id: q.id, level: q.level, type: q.type, content: q.content,
    contentReading: q.contentReading, options: q.options, provenance,
    ...(q.audioUrl ? { audioUrl: q.audioUrl } : {}),
  };
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
  let session = await db.learningSession.findFirst({
    where: { id, userId },
    include: { answers: { orderBy: { answeredAt: 'asc' } } },
  });
  if (!session) throw new HttpError(404, '练习不存在');
  const initialConfig = session.examConfig as any;
  if (!session.completedAt && initialConfig && !initialConfig.waitingSection &&
      initialConfig.deadline && Date.now() >= Date.parse(initialConfig.deadline)) {
    await endExamSection(db, session);
    session = await db.learningSession.findFirst({
      where: { id, userId },
      include: { answers: { orderBy: { answeredAt: 'asc' } } },
    });
    if (!session) throw new HttpError(404, '练习不存在');
  }
  const questionIds = ids(session.questionIds);
  const currentQuestionId = questionIds[session.currentIndex];
  const answeredQuestionIds = session.answers.map(answer => answer.questionId);
  const visibleQuestionIds = session.completedAt
    ? questionIds
    : [...new Set([currentQuestionId, ...answeredQuestionIds].filter(Boolean))];
  const [qs, es] = await Promise.all([
    contentPrisma.question.findMany({ where: { id: { in: visibleQuestionIds } } }),
    session.answers.length
      ? contentPrisma.explanation.findMany({ where: { questionId: { in: session.answers.map(a => a.questionId) } } })
      : Promise.resolve([]),
  ]);
  const questionsById = new Map(qs.map(q => [q.id, q]));
  const explanationsByQuestionId = new Map(es.map(e => [e.questionId, e]));
  if (questionsById.size !== visibleQuestionIds.length) throw new HttpError(409, '练习题目尚未完整入库');
  const cfg = session.examConfig as any;
  const hide = cfg && !cfg.instantFeedback && !session.completedAt;
  return {
    id: session.id,
    mode: session.mode,
    examConfig: session.examConfig,
    currentIndex: session.currentIndex,
    awaitingNext: session.awaitingNext,
    completedAt: session.completedAt,
    serverNow: new Date().toISOString(),
    ...points(session.answers, questionIds.length),
    questions: questionIds.map(qid => {
      const question = questionsById.get(qid);
      if (!question) return {};
      if (session.completedAt || qid !== currentQuestionId) {
        return { id: qid, content: question.content, options: question.options };
      }
      return publicQuestion(question);
    }),
    ...(hide ? { score: null, correctCount: null } : {}),
    answers: session.answers.map(a =>
      hide
        ? { questionId: a.questionId, selectedOptionId: a.selectedOptionId, answeredAt: a.answeredAt }
        : {
            ...a,
            correctOptionId: questionsById.get(a.questionId)!.answer,
            explanation: explanationsByQuestionId.get(a.questionId) ?? null,
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
