import { Response } from 'express';
import prisma from '../config/database';
import userPrisma from '../config/user-database';
import { AuthRequest } from '../middleware/auth';
import { HttpError, run, ids, stateAfterAnswer, clockSync, advance } from './_shared';
import { answerSchema } from '../validators/learning.validators';

export class AnswerController {
  submitAnswer = run(async (req: AuthRequest, res: Response) => {
    const body = answerSchema.parse(req.body);
    const result = await userPrisma.$transaction(
      async db => {
        await clockSync(db, req.params.id as string, req.userId!);
        const s = await db.learningSession.findFirst({
          where: { id: req.params.id as string, userId: req.userId },
          include: { answers: true },
        });
        if (!s) throw new HttpError(404, '练习不存在');
        if (s.answers.some(a => a.questionId === body.questionId)) {
          throw new HttpError(409, '本题已作答，首次答案已锁定，不能重答');
        }
        if ((s.examConfig as any)?.waitingSection) throw new HttpError(409, '请先开始下一科目');
        if (s.completedAt || s.awaitingNext || ids(s.questionIds)[s.currentIndex] !== body.questionId) {
          throw new HttpError(409, '请按顺序完成当前题目');
        }
        const q = await prisma.question.findUniqueOrThrow({ where: { id: body.questionId } });
        const typed = q.type === 'fillInBlank' && (q.options as any[]).length === 0;
        if (typed && (!body.optionId.trim() || body.optionId.length > 100)) throw new HttpError(400, '请填写不超过 100 字的答案');
        if (!typed && !(q.options as any[]).some(o => o.id === body.optionId)) throw new HttpError(400, '选项无效');
        const correct = typed
          ? q.answer.normalize('NFKC').replace(/\s+/g, '') === body.optionId.normalize('NFKC').replace(/\s+/g, '')
          : q.answer === body.optionId;
        await db.learningAnswer.create({
          data: {
            sessionId: s.id,
            questionId: q.id,
            selectedOptionId: body.optionId,
            isCorrect: correct,
          },
        });
        if (!correct) {
          await db.reviewItem.upsert({
            where: { userId_questionId: { userId: req.userId!, questionId: q.id } },
            update: {
              isWrongAnswer: true,
              wrongCount: { increment: 1 },
              status: 'learning',
              nextReviewAt: new Date(),
            },
            create: {
              userId: req.userId!,
              questionId: q.id,
              level: q.level,
              type: q.type,
              status: 'learning',
              isWrongAnswer: true,
              wrongCount: 1,
              nextReviewAt: new Date(),
            },
          });
        }
        const c = s.examConfig as any;
        if (!correct && (!c || c.instantFeedback)) {
          await db.learningSession.update({ where: { id: s.id }, data: { awaitingNext: true } });
        } else {
          await advance(db, s);
        }
        return stateAfterAnswer(db, s.id, req.userId!);
      },
      { isolationLevel: 'Serializable', timeout: 30000 }
    );
    res.json(result);
  });

  nextQuestion = run(async (req: AuthRequest, res: Response) => {
    const result = await userPrisma.$transaction(
      async db => {
        const s = await db.learningSession.findFirst({
          where: { id: req.params.id as string, userId: req.userId },
        });
        if (!s) throw new HttpError(404, '练习不存在');
        if (s.completedAt || !s.awaitingNext) throw new HttpError(409, '当前题目尚未完成');
        await clockSync(db, s.id, req.userId!);
        const fresh = await db.learningSession.findUniqueOrThrow({ where: { id: s.id } });
        if (!fresh.completedAt && !(fresh.examConfig as any)?.waitingSection) await advance(db, fresh);
        return stateAfterAnswer(db, s.id, req.userId!);
      },
      { isolationLevel: 'Serializable', timeout: 30000 }
    );
    res.json(result);
  });
}

export const answerController = new AnswerController();
