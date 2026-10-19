import { Router } from 'express';
import { ReviewController } from '../controllers/review.controller';
import { authMiddleware } from '../middleware/auth';

const router = Router();
const ctrl = new ReviewController();

router.get('/items', authMiddleware, (req, res) => ctrl.listItems(req, res));
router.get('/due', authMiddleware, (req, res) => ctrl.getDueItems(req, res));
router.post('/mark', authMiddleware, (req, res) => ctrl.mark(req, res));

export default router;
