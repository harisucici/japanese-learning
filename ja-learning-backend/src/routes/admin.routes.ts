/**
 * 管理端路由
 * 挂载所有 /admin/* 路由
 */
import { Router } from 'express';
import { AdminController } from '../controllers/admin.controller';
import { ImportController } from '../controllers/import.controller';
import { adminMiddleware } from '../middleware/admin';

const router = Router();
const adminCtrl = new AdminController();
const importCtrl = new ImportController();

// 所有 /admin/* 路由都需要管理员权限
router.use(adminMiddleware);

// ============ 内容管理路由 ============
// 查询所有题目（支持分页、过滤）
router.get('/questions', (req, res) => adminCtrl.listQuestions(req, res));

// 查询题目详情
router.get('/questions/:id', (req, res) => adminCtrl.getQuestion(req, res));

// 更新题目
router.put('/questions/:id', (req, res) => adminCtrl.updateQuestion(req, res));

// 软删除题目
router.delete('/questions/:id', (req, res) => adminCtrl.deleteQuestion(req, res));

// 发布题目
router.post('/questions/:id/publish', (req, res) => adminCtrl.publishQuestion(req, res));

// 撤回题目
router.post('/questions/:id/unpublish', (req, res) => adminCtrl.unpublishQuestion(req, res));

// ============ 导入路由 ============
// 批量导入题目
router.post('/import/questions', (req, res) => importCtrl.importQuestions(req, res));

export default router;
