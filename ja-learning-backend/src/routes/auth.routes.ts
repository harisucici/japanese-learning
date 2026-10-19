import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth';

const router = Router();
const ctrl = new AuthController();

router.post('/login', (req, res) => ctrl.login(req, res));
router.post('/register', (req, res) => ctrl.register(req, res));
router.post('/logout', authMiddleware, (req, res) => ctrl.logout(req, res));
router.get('/me', authMiddleware, (req, res) => ctrl.me(req, res));
router.get('/profile', authMiddleware, (req, res) => ctrl.profile(req, res));
router.put('/profile', authMiddleware, (req, res) => ctrl.updateProfile(req, res));

export default router;
