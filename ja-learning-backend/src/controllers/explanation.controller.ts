import { Request, Response } from 'express';
import { ExplanationService } from '../services/explanation.service';

const svc = new ExplanationService();

export class ExplanationController {
  async getByQuestionId(req: Request, res: Response) {
    try {
      const questionId = req.params.questionId as string;
      const item = await svc.getByQuestionId(questionId);
      if (!item) return res.status(404).json({ error: 'Not found' });
      res.json(item);
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  }
}
