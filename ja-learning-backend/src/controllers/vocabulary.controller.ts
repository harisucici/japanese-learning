/**
 * 词汇控制器
 * 负责参数提取、校验分发与错误响应
 */
import { Request, Response } from 'express';
import { VocabularyService } from '../services/vocabulary.service';
import {
  createVocabularySchema,
  updateVocabularySchema,
  listQuerySchema,
} from '../validators/knowledge.validators';

const svc = new VocabularyService();

export class VocabularyController {
  /** GET /vocabulary?level=N5&limit=20&offset=0 */
  async list(req: Request, res: Response) {
    try {
      const parsed = listQuerySchema.safeParse(req.query);
      if (!parsed.success) {
        return res.status(400).json({ error: 'Invalid query', details: parsed.error.flatten() });
      }
      const result = await svc.list({
        level: parsed.data.level,
        limit: parsed.data.limit,
        offset: parsed.data.offset,
      });
      res.json({ ...result, limit: parsed.data.limit, offset: parsed.data.offset });
    } catch (e: any) {
      res.status(500).json({ error: e.message || 'Internal error' });
    }
  }

  /** GET /vocabulary/:id */
  async getById(req: Request, res: Response) {
    try {
      const item = await svc.getById(req.params.id as string);
      if (!item) return res.status(404).json({ error: '未找到该文件' });
      res.json(item);
    } catch (e: any) {
      res.status(500).json({ error: e.message || 'Internal error' });
    }
  }

  /** POST /vocabulary */
  async create(req: Request, res: Response) {
    try {
      const parsed = createVocabularySchema.safeParse(req.body);
      if (!parsed.success) {
        return res.status(400).json({ error: 'Invalid payload', details: parsed.error.flatten() });
      }
      const item = await svc.create(parsed.data);
      res.status(201).json(item);
    } catch (e: any) {
      res.status(500).json({ error: e.message || 'Internal error' });
    }
  }

  /** PUT /vocabulary/:id */
  async update(req: Request, res: Response) {
    try {
      const parsed = updateVocabularySchema.safeParse(req.body);
      if (!parsed.success) {
        return res.status(400).json({ error: 'Invalid payload', details: parsed.error.flatten() });
      }
      const item = await svc.update(req.params.id as string, parsed.data);
      if (!item) return res.status(404).json({ error: '未找到该文件' });
      res.json(item);
    } catch (e: any) {
      res.status(500).json({ error: e.message || 'Internal error' });
    }
  }

  /** GET /vocabulary/:id/questions */
  async getQuestions(req: Request, res: Response) {
    try {
      const limit = parseInt((req.query.limit as string) || '20', 10);
      const offset = parseInt((req.query.offset as string) || '0', 10);
      const result = await svc.getQuestions(req.params.id as string, limit, offset);
      if (!result) return res.status(404).json({ error: 'Vocabulary not found' });
      res.json({ ...result, limit, offset });
    } catch (e: any) {
      res.status(500).json({ error: e.message || 'Internal error' });
    }
  }
}
