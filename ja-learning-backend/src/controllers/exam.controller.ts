import { Response } from 'express';
import prisma from '../config/database';
import { AuthRequest } from '../middleware/auth';
import { HttpError, run, state, clockSync, endExamSection } from './_shared';
import { sectionActionSchema } from '../validators/learning.validators';

export class ExamController {
  sectionAction = run(async (req: AuthRequest, res: Response) => {
    const { action } = sectionActionSchema.parse(req.body);
    res.json(
      await prisma.$transaction(
        async db => {
          await clockSync(db, req.params.id as string, req.userId!);
          const s = await db.learningSession.findFirst({
            where: { id: req.params.id as string, userId: req.userId },
          });
          if (!s || s.completedAt || !s.examConfig) throw new HttpError(409, '考试状态不可用');
          const c = s.examConfig as any;
          if (action === 'submit') {
            if (c.waitingSection) throw new HttpError(409, '本科目已结束');
            await endExamSection(db, s);
          } else {
            if (!c.waitingSection) throw new HttpError(409, '科目已经开始');
            const i = c.sectionIndex + 1;
            const now = Date.now();
            await db.learningSession.update({
              where: { id: s.id },
              data: {
                examConfig: {
                  ...c,
                  sectionIndex: i,
                  waitingSection: false,
                  sectionStartedAt: new Date(now).toISOString(),
                  deadline: new Date(now + c.sections[i].minutes * 60000).toISOString(),
                },
              },
            });
          }
          return state(db, s.id, req.userId!);
        },
        { isolationLevel: 'Serializable' }
      )
    );
  });
}

export const examController = new ExamController();
