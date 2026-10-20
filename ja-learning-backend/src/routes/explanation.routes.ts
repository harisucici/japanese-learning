import { Router } from 'express';
import { ExplanationController } from '../controllers/explanation.controller';
import { authMiddleware } from '../middleware/auth';

const router = Router();
const ctrl = new ExplanationController();

router.get('/question/:questionId', authMiddleware, (req, res) => ctrl.getByQuestionId(req, res));

export default router;
