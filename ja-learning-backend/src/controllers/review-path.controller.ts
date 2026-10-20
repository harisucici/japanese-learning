import { Response } from 'express';
import prisma from '../config/database';
import userPrisma from '../config/user-database';
import { AuthRequest } from '../middleware/auth';
import { HttpError } from './_shared';

export class ReviewPathController {
  /**
   * POST /review/:itemId/next
   * 获取下一题（支持 mode 参数）
   * - mode='original': 返回原题
   * - mode='similar': 返回同 vocabularyId/grammarId 的其他题目
   */
  async getNext(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const itemId = req.params.itemId as string;
      const mode = (req.body.mode as string) || 'original';

      // 验证 mode
      if (!['original', 'similar'].includes(mode)) {
        throw new HttpError(400, 'mode 参数无效，可选: original | similar');
      }

      // 获取 review item（不依赖 question relation，单独查询题目）
      const item: any = await userPrisma.reviewItem.findFirst({
        where: { id: itemId, userId },
      });
      if (!item) {
        throw new HttpError(404, '复习项不存在');
      }

      // 获取关联的题目
      const sourceQuestion: any = await prisma.question.findUnique({
        where: { id: item.questionId },
      });
      if (!sourceQuestion) {
        throw new HttpError(404, '关联题目不存在');
      }

      // 更新 reviewMode
      await (userPrisma.reviewItem as any).update({
        where: { id: itemId },
        data: { reviewMode: mode },
      });

      if (mode === 'original') {
        // 返回原题
        res.json({
          reviewItemId: item.id,
          mode: 'original',
          question: sanitizeQuestion(sourceQuestion),
          explanation: null, // 可后续扩展加载解析
        });
      } else {
        // mode === 'similar': 返回同 vocabularyId/grammarId 的其他题目
        const where: any = {
          id: { not: sourceQuestion.id }, // 排除原题
        };
        if (sourceQuestion.vocabularyId) {
          where.vocabularyId = sourceQuestion.vocabularyId;
        } else if (sourceQuestion.grammarId) {
          where.grammarId = sourceQuestion.grammarId;
        } else {
          // 如果没有关联知识点，退回同等级同题型
          where.level = sourceQuestion.level;
          where.type = sourceQuestion.type;
        }

        const similarQuestions = await prisma.question.findMany({
          where,
          take: 5,
          orderBy: { order: 'asc' },
        });

        if (similarQuestions.length === 0) {
          throw new HttpError(404, '暂无同知识点的其他题目');
        }

        // 随机选一题
        const picked = similarQuestions[Math.floor(Math.random() * similarQuestions.length)];
        res.json({
          reviewItemId: item.id,
          mode: 'similar',
          question: sanitizeQuestion(picked),
          alternatives: similarQuestions.map(sanitizeQuestion),
        });
      }
    } catch (e: any) {
      const status = e instanceof HttpError ? e.status : 500;
      res.status(status).json({ error: e.message });
    }
  }

  /**
   * POST /review/:itemId/retry-original
   * 重新答原题：创建新的 LearningSession，但关联同一道题
   * 确保生成新的作答记录，不覆盖历史
   */
  async retryOriginal(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const itemId = req.params.itemId as string;

      // 获取 review item
      const item: any = await userPrisma.reviewItem.findFirst({
        where: { id: itemId, userId },
      });
      if (!item) {
        throw new HttpError(404, '复习项不存在');
      }

      // 获取关联的题目
      const question: any = await prisma.question.findUnique({
        where: { id: item.questionId },
      });
      if (!question) {
        throw new HttpError(404, '关联题目不存在');
      }

      // 创建新的学习会话（mode='retry'）
      const session = await userPrisma.learningSession.create({
        data: {
          userId,
          level: item.level,
          mode: 'retry', // 标识为重做模式
          questionIds: [item.questionId], // 只包含这一道题
        },
      });

      // 返回会话信息（不含答案）
      res.status(201).json({
        sessionId: session.id,
        reviewItemId: item.id,
        question: sanitizeQuestion(question),
        message: '新的练习会话已创建，请作答',
      });
    } catch (e: any) {
      const status = e instanceof HttpError ? e.status : 500;
      res.status(status).json({ error: e.message });
    }
  }
}

/**
 * 移除题目的正确答案等敏感字段，防止泄漏
 */
function sanitizeQuestion(q: any) {
  const { answer, explanationId, difficulty, ...visible } = q;
  if (visible.provenance) {
    const { correctOption, answer: sourceAnswer, ...source } = visible.provenance;
    visible.provenance = source;
  }
  return visible;
}

export const reviewPathController = new ReviewPathController();
