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

  /**
   * GET /stats/mistakes-detail?level=N5
   * 错题详情：题型分布、知识点分布、时间趋势
   * 区分"首次答错"和"多次稳定掌握"
   */
  async getMistakesDetail(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const level = (req.query.level as string | undefined);
      const stats = await svc.getMistakesDetail(userId, level);
      res.json(stats);
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  }
}
