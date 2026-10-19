import { Request, Response } from 'express';
import { QuestionService } from '../services/question.service';

const svc = new QuestionService();

export class QuestionController {
  async list(req: Request, res: Response) {
    try {
      const { level, type, limit, offset } = req.query;
      const result = await svc.list({
        level: level as string | undefined,
        type: type as string | undefined,
        limit: limit ? parseInt(limit as string, 10) : undefined,
        offset: offset ? parseInt(offset as string, 10) : undefined,
      });
      res.json(result);
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  }

  async getById(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      const item = await svc.getById(id);
      if (!item) return res.status(404).json({ error: 'Not found' });
      res.json(item);
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  }

  async getByLevel(req: Request, res: Response) {
    try {
      const level = req.params.level as string;
      const items = await svc.getByLevel(level);
      res.json(items);
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  }
}
