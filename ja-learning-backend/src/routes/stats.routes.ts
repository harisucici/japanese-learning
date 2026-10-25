import { Router } from 'express';
import { StatsController } from '../controllers/stats.controller';
import { authMiddleware } from '../middleware/auth';

const router = Router();
const ctrl = new StatsController();

router.get('/me', authMiddleware, (req, res) => ctrl.getMyStats(req, res));
router.get('/overview', authMiddleware, (req, res) => ctrl.getMyStats(req, res));
router.get('/mistakes-detail', authMiddleware, (req, res) => ctrl.getMistakesDetail(req, res));

export default router;
