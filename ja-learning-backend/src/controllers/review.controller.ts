import { Request, Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ReviewService } from '../services/review.service';
import { markReviewSchema } from '../config/validators';

const svc = new ReviewService();

export class ReviewController {
  async listItems(req: AuthRequest, res: Response) {
    try {
      const userId = (req.query.userId as string) || req.userId!;
      const due = req.query.due === 'true';
      const items = await svc.listItems(userId, due);
      res.json(items);
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  }

  async mark(req: AuthRequest, res: Response) {
    try {
      const parsed = markReviewSchema.safeParse(req.body);
      if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
      const result = await svc.mark(parsed.data.itemId, parsed.data.correct);
      res.json(result);
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  }

  async getDueItems(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const items = await svc.getDueItems(userId);
      res.json(items);
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  }
}
