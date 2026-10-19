import { Router } from 'express';
import { ExplanationController } from '../controllers/explanation.controller';

const router = Router();
const ctrl = new ExplanationController();

router.get('/question/:questionId', (req, res) => ctrl.getByQuestionId(req, res));

export default router;
