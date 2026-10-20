import { Router } from 'express';
import { ReviewController } from '../controllers/review.controller';
import { reviewPathController } from '../controllers/review-path.controller';
import { authMiddleware } from '../middleware/auth';

const router = Router();
const ctrl = new ReviewController();

router.get('/items', authMiddleware, (req, res) => ctrl.listItems(req, res));
router.get('/due', authMiddleware, (req, res) => ctrl.getDueItems(req, res));
router.post('/mark', authMiddleware, (req, res) => ctrl.mark(req, res));

// 复习路径选择：获取下一题（支持 original / similar）
router.post('/:itemId/next', authMiddleware, (req, res) => reviewPathController.getNext(req, res));

// 重新答原题：创建新会话重做同一道题
router.post('/:itemId/retry-original', authMiddleware, (req, res) => reviewPathController.retryOriginal(req, res));

export default router;
