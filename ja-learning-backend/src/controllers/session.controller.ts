import { Response } from 'express';
import { Prisma } from '@prisma/client';
import prisma from '../config/database';
import userPrisma from '../config/user-database';
import { examConfig } from '../services/exam-rules';
import { AuthRequest } from '../middleware/auth';
import { HttpError, run, ids, state } from './_shared';
import { startSchema } from '../validators/learning.validators';

const verified: Prisma.QuestionWhereInput = {
  source: { in: ['pastExam', 'official'] as string[] },
  provenance: { not: Prisma.DbNull },
};

export class SessionController {
  startSession = run(async (req: AuthRequest, res: Response) => {
    const data = startSchema.parse(req.body);
    if (data.mode === 'fun') {
      const paper = data.collectionId
        ? await prisma.funPaper.findUnique({ where: { id: data.collectionId } })
        : null;
      if (!paper?.published) throw new HttpError(404, '趣味题组不存在');
      const paperQuestionIds = ids(paper.questionIds);
      const qs = await prisma.question.findMany({
        where: { id: { in: paperQuestionIds }, source: 'custom', level: 'ungraded' },
      });
      if (qs.length !== paperQuestionIds.length || !qs.length) throw new HttpError(409, '题组尚未完整入库');
      const session = await userPrisma.learningSession.create({
        data: {
          userId: req.userId!,
          level: 'ungraded',
          mode: 'fun',
          collectionId: paper.id,
          questionIds: paperQuestionIds,
        },
      });
      res.status(201).json(await state(userPrisma, session.id, req.userId!));
      return;
    }
    if (data.mode === 'exam') {
      const paper = data.paperId ? await prisma.examPaper.findUnique({ where: { id: data.paperId } }) : null;
      if (!paper?.ready) {
        throw new HttpError(400, '完整试卷尚未通过校验：必须具备所有科目、标准答案和听力材料');
      }
      const cfg = examConfig(paper, data.instantFeedback);
      const questionIds = cfg.sections.flatMap((s: any) => s.questionIds);
      if (data.instantFeedback) {
        const count = await prisma.explanation.count({
          where: { questionId: { in: questionIds }, sentenceStructure: { not: '' } },
        });
        if (count !== questionIds.length) {
          throw new HttpError(400, '本卷尚有题目缺少已核验讲解，请关闭即时讲解或补齐讲解后开始');
        }
      }
      const s = await userPrisma.learningSession.create({
        data: {
          userId: req.userId!,
          level: paper.level,
          mode: 'exam',
          questionIds,
          examConfig: cfg,
        },
      });
      res.status(201).json(await state(userPrisma, s.id, req.userId!));
      return;
    }
    const qs = await prisma.question.findMany({
      where: {
        ...verified,
        level: data.level,
        ...(data.type ? { type: data.type } : {}),
      },
      orderBy: [{ order: 'asc' }, { id: 'asc' }],
      ...(data.limit ? { take: data.limit } : {}),
    });
    if (!qs.length) throw new HttpError(400, '该等级和题型暂无已核验题目');
    const session = await userPrisma.learningSession.create({
      data: {
        userId: req.userId!,
        level: data.level,
        mode: data.mode,
        questionIds: qs.map(q => q.id),
      },
    });
    res.status(201).json(await state(userPrisma, session.id, req.userId!));
  });

  getSession = run(async (req: AuthRequest, res: Response) =>
    res.json(await state(userPrisma, req.params.id as string, req.userId!))
  );
}

export const sessionController = new SessionController();
