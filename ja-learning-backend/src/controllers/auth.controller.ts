import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { AuthService } from '../services/auth.service';
import { loginSchema, registerSchema } from '../config/validators';

const svc = new AuthService();

export class AuthController {
  async login(req: AuthRequest, res: Response) {
    try {
      const parsed = loginSchema.safeParse(req.body);
      if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
      const result = await svc.login(parsed.data.email, parsed.data.password);
      res.json(result);
    } catch (e: any) {
      res.status(401).json({ error: e.message });
    }
  }

  async register(req: AuthRequest, res: Response) {
    try {
      const parsed = registerSchema.safeParse(req.body);
      if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
      const { email, password, name, targetLevel } = parsed.data;
      const result = await svc.register(email, password, name, targetLevel);
      res.status(201).json(result);
    } catch (e: any) {
      res.status(400).json({ error: e.message });
    }
  }

  async me(req: AuthRequest, res: Response) {
    try {
      const user = await svc.me(req.userId!);
      res.json({ user });
    } catch (e: any) {
      res.status(404).json({ error: e.message });
    }
  }

  // GET /profile — alias of /me (前端 /api/v1/auth/profile)
  async profile(req: AuthRequest, res: Response) {
    try {
      const user = await svc.me(req.userId!);
      res.json({ user });
    } catch (e: any) {
      res.status(404).json({ error: e.message });
    }
  }

  // PUT /profile — 更新用户资料
  async updateProfile(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const { name, avatarUrl, currentLevel, targetLevel } = req.body || {};
      const user = await svc.updateProfile(userId, { name, avatarUrl, currentLevel, targetLevel });
      res.json({ user });
    } catch (e: any) {
      res.status(400).json({ error: e.message });
    }
  }

  // POST /logout — JWT 无状态，简单返回成功
  async logout(req: AuthRequest, res: Response) {
    res.json({ success: true });
  }
}
