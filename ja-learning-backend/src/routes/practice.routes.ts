import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { practiceController } from '../controllers/practice.controller';

const router = Router();

// 所有练习入口都需要身份认证
router.use(authMiddleware);

// 按题型练习
router.get('/by-type/:questionType', (req, res) => practiceController.getByType(req, res));

// 按语法知识点练习
router.get('/by-grammar/:grammarId', (req, res) => practiceController.getByGrammar(req, res));

// 错题重练
router.get('/mistakes', (req, res) => practiceController.getMistakes(req, res));

// 随机题目练习
router.get('/random', (req, res) => practiceController.getRandom(req, res));

export default router;
