import { Router } from 'express';
import { RecordController } from '../controllers/record.controller';
import { authMiddleware } from '../middleware/auth';

const router = Router();
const ctrl = new RecordController();

router.post('/', authMiddleware, (req, res) => ctrl.create(req, res));
router.get('/user/:userId', authMiddleware, (req, res) => ctrl.listByUser(req, res));
router.get('/:id', authMiddleware, (req, res) => ctrl.getById(req, res));

export default router;
