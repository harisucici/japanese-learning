import { Router } from 'express';
import { QuestionController } from '../controllers/question.controller';

const router = Router();
const ctrl = new QuestionController();

router.get('/', (req, res) => ctrl.list(req, res));
router.get('/level/:level', (req, res) => ctrl.getByLevel(req, res));
router.get('/:id', (req, res) => ctrl.getById(req, res));

export default router;
