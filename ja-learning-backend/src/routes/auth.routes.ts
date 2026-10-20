import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth';

const router = Router();
const ctrl = new AuthController();

// 公开端点（无需登录）
router.post('/register', (req, res) => ctrl.register(req, res));
router.post('/login', (req, res) => ctrl.login(req, res));
router.post('/forgot-password', (req, res) => ctrl.forgotPassword(req, res));
router.post('/reset-password', (req, res) => ctrl.resetPassword(req, res));

// 需要登录的端点
router.post('/logout', authMiddleware, (req, res) => ctrl.logout(req, res));
router.get('/me', authMiddleware, (req, res) => ctrl.me(req, res));
router.get('/profile', authMiddleware, (req, res) => ctrl.profile(req, res));
router.put('/profile', authMiddleware, (req, res) => ctrl.updateProfile(req, res));
router.post('/change-password', authMiddleware, (req, res) => ctrl.changePassword(req, res));
router.post('/migrate-from-anonymous', authMiddleware, (req, res) => ctrl.migrateFromAnonymous(req, res));

export default router;
