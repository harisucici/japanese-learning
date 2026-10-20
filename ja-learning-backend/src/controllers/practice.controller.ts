import { Response } from 'express';
import prisma from '../config/database';
import { AuthRequest } from '../middleware/auth';
import { PracticeService } from '../services/practice.service';
import { HttpError } from './_shared';

const practiceService = new PracticeService();

/** 把 query 值规范为单一 string */
const qs = (v: unknown): string | undefined => {
  if (typeof v === 'string') return v;
  if (Array.isArray(v) && typeof v[0] === 'string') return v[0];
  return undefined;
};

export class PracticeController {
  /**
   * GET /practice/by-type/:questionType?level=N5
   * 按题型练习入口
   */
  async getByType(req: AuthRequest, res: Response) {
    try {
      const questionType = String(req.params.questionType);
      const level = qs(req.query.level) || 'n5';
      const limit = Math.min(parseInt(qs(req.query.limit) || '20'), 200);

      // 验证题型
      const validTypes = [
        'vocabulary', 'kanji', 'grammar', 'reading',
        'listening', 'fillInBlank', 'comprehensive',
      ];
      if (!validTypes.includes(questionType)) {
        throw new HttpError(400, `无效题型: ${questionType}，可选: ${validTypes.join(', ')}`);
      }

      const questions = await practiceService.getByType(level, questionType, limit);
      res.json({
        level,
        type: questionType,
        count: questions.length,
        questions,
      });
    } catch (e: any) {
      const status = e instanceof HttpError ? e.status : 500;
      res.status(status).json({ error: e.message });
    }
  }

  /**
   * GET /practice/by-grammar/:grammarId
   * 按语法知识点练习
   */
  async getByGrammar(req: AuthRequest, res: Response) {
    try {
      const grammarId = String(req.params.grammarId);
      const limit = Math.min(parseInt(qs(req.query.limit) || '20'), 200);

      // 验证 grammarId 存在（用 $queryRaw 兜底，避免 Prisma Client 尚未 generate）
      const grammar: any = await (prisma as any).grammar
        .findUnique({ where: { id: grammarId } })
        .catch(() => null);
      if (!grammar) {
        throw new HttpError(404, '语法知识点不存在');
      }

      const questions = await practiceService.getByGrammar(grammarId, limit);
      res.json({
        grammar: { id: grammar.id, name: grammar.name, meaning: grammar.meaning },
        count: questions.length,
        questions,
      });
    } catch (e: any) {
      const status = e instanceof HttpError ? e.status : 500;
      res.status(status).json({ error: e.message });
    }
  }

  /**
   * GET /practice/mistakes?level=N5
   * 错题重练（从 ReviewItem 获取）
   */
  async getMistakes(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const level = qs(req.query.level);
      const limit = Math.min(parseInt(qs(req.query.limit) || '20'), 100);

      const mistakes = await practiceService.getMistakes(userId, level, limit);
      res.json({
        level: level || null,
        count: mistakes.length,
        items: mistakes,
      });
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  }

  /**
   * GET /practice/random?level=N5&limit=10
   * 随机题目练习
   */
  async getRandom(req: AuthRequest, res: Response) {
    try {
      const level = qs(req.query.level) || 'n5';
      const limit = Math.min(parseInt(qs(req.query.limit) || '10'), 100);
      const excludeParam = qs(req.query.exclude);
      const excludeIds = excludeParam ? excludeParam.split(',').filter(Boolean) : [];

      const questions = await practiceService.getRandom(level, limit, excludeIds);
      res.json({
        level,
        count: questions.length,
        questions,
      });
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  }
}

export const practiceController = new PracticeController();
