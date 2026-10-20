/**
 * 词汇路由
 * RESTful 风格，与 question.routes.ts 保持一致
 */
import { Router } from 'express';
import { VocabularyController } from '../controllers/vocabulary.controller';
import { adminMiddleware } from '../middleware/admin';

const router = Router();
const ctrl = new VocabularyController();

// 只读接口：按等级查询 / 详情 / 反向索引
router.get('/', (req, res) => ctrl.list(req, res));
router.get('/:id', (req, res) => ctrl.getById(req, res));
router.get('/:id/questions', (req, res) => ctrl.getQuestions(req, res));

// 写接口：需要管理员权限
router.post('/', adminMiddleware, (req, res) => ctrl.create(req, res));
router.put('/:id', adminMiddleware, (req, res) => ctrl.update(req, res));

export default router;
