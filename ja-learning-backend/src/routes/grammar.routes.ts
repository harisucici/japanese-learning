/**
 * 语法路由
 */
import { Router } from 'express';
import { GrammarController } from '../controllers/grammar.controller';
import { adminMiddleware } from '../middleware/admin';

const router = Router();
const ctrl = new GrammarController();

router.get('/', (req, res) => ctrl.list(req, res));
router.get('/:id', (req, res) => ctrl.getById(req, res));
router.get('/:id/questions', (req, res) => ctrl.getQuestions(req, res));

router.post('/', adminMiddleware, (req, res) => ctrl.create(req, res));
router.put('/:id', adminMiddleware, (req, res) => ctrl.update(req, res));

export default router;
