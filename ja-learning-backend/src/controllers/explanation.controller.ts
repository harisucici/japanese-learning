import { Response } from 'express';
import { ExplanationService } from '../services/explanation.service';
import userPrisma from '../config/user-database';
import { AuthRequest } from '../middleware/auth';

const svc = new ExplanationService();

export class ExplanationController {
  async getByQuestionId(req: AuthRequest, res: Response) {
    try {
      const questionId = req.params.questionId as string;
      const answered = await userPrisma.learningAnswer.findFirst({
        where: {
          questionId,
          session: {
            userId: req.userId,
            OR: [{ mode: { not: 'exam' } }, { completedAt: { not: null } }],
          },
        },
        select: { id: true },
      });
      if (!answered) return res.status(403).json({ error: '提交答案或完成考试后可查看解析' });
      const item = await svc.getByQuestionId(questionId);
      if (!item) return res.status(404).json({ error: '未找到该文件' });
      res.json(item);
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  }
}
