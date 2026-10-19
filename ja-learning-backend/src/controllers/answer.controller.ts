import { Response } from 'express';
import prisma from '../config/database';
import { AuthRequest } from '../middleware/auth';
import { HttpError, run, ids, state, clockSync, advance } from './_shared';
import { answerSchema } from '../validators/learning.validators';

export class AnswerController {
  submitAnswer = run(async (req: AuthRequest, res: Response) => {
    const body = answerSchema.parse(req.body);
    const result = await prisma.$transaction(
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
        const q = await db.question.findUniqueOrThrow({ where: { id: body.questionId } });
        if (!(q.options as any[]).some(o => o.id === body.optionId)) throw new HttpError(400, '选项无效');
        const correct = q.answer === body.optionId;
        await db.learningAnswer.create({
          data: {
            sessionId: s.id,
            questionId: q.id,
            selectedOptionId: body.optionId,
            isCorrect: correct,
          },
        });
        const c = s.examConfig as any;
        if (!correct && (!c || c.instantFeedback)) {
          await db.learningSession.update({ where: { id: s.id }, data: { awaitingNext: true } });
        } else {
          await advance(db, s);
        }
        return state(db, s.id, req.userId!);
      },
      { isolationLevel: 'Serializable' }
    );
    res.json(result);
  });

  nextQuestion = run(async (req: AuthRequest, res: Response) => {
    const result = await prisma.$transaction(
      async db => {
        const s = await db.learningSession.findFirst({
          where: { id: req.params.id as string, userId: req.userId },
        });
        if (!s) throw new HttpError(404, '练习不存在');
        if (s.completedAt || !s.awaitingNext) throw new HttpError(409, '当前题目尚未完成');
        await clockSync(db, s.id, req.userId!);
        const fresh = await db.learningSession.findUniqueOrThrow({ where: { id: s.id } });
        if (!fresh.completedAt && !(fresh.examConfig as any)?.waitingSection) await advance(db, fresh);
        return state(db, s.id, req.userId!);
      },
      { isolationLevel: 'Serializable' }
    );
    res.json(result);
  });
}

export const answerController = new AnswerController();
