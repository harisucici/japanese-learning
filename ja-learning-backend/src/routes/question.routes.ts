import { Router } from 'express';
import { QuestionController } from '../controllers/question.controller';
import { authMiddleware } from '../middleware/auth';

const router = Router();
const ctrl = new QuestionController();

// 所有题目接口都需要身份认证
router.use(authMiddleware);

router.get('/', (req, res) => ctrl.list(req, res));
router.get('/level/:level', (req, res) => ctrl.getByLevel(req, res));
router.get('/:id', (req, res) => ctrl.getById(req, res));

export default router;
