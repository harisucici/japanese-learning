import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { StatsService } from '../services/stats.service';

const svc = new StatsService();

export class StatsController {
  async getMyStats(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const stats = await svc.getUserStats(userId);
      res.json(stats);
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  }
}
