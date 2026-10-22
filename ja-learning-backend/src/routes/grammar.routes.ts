/**
 * 语法路由
 */
import { Router } from 'express';
import { GrammarController } from '../controllers/grammar.controller';
import { authMiddleware } from '../middleware/auth';
import { adminMiddleware } from '../middleware/admin';

const router = Router();
const ctrl = new GrammarController();

// 所有语法接口都需要身份认证
router.use(authMiddleware);

router.get('/', (req, res) => ctrl.list(req, res));
router.get('/:id', (req, res) => ctrl.getById(req, res));
router.get('/:id/questions', (req, res) => ctrl.getQuestions(req, res));

router.post('/', adminMiddleware, (req, res) => ctrl.create(req, res));
router.put('/:id', adminMiddleware, (req, res) => ctrl.update(req, res));

export default router;
