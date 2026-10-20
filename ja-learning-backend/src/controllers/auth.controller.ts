// 认证控制器：处理 HTTP 请求，委托给 AuthService
import { Response } from 'express';
import jwt from 'jsonwebtoken';
import { AuthRequest } from '../middleware/auth';
import { AuthService } from '../services/auth.service';
import {
  loginSchema,
  registerSchema,
  updateProfileSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  changePasswordSchema,
  migrateFromAnonymousSchema,
} from '../config/validators';
import { setSessionCookie, clearSessionCookie } from '../services/session-cookie';
import { config } from '../config/env';

const svc = new AuthService();

export class AuthController {
  // POST /auth/register — 注册
  async register(req: AuthRequest, res: Response) {
    try {
      const parsed = registerSchema.safeParse(req.body);
      if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
      const { username, email, password, nickname, currentLevel, targetLevel, inviteCode } = parsed.data;
      const cookie = req.headers.cookie?.split(';').map(part => part.trim()).find(part => part.startsWith('ja_session='))?.slice('ja_session='.length);
      let guestId: string | undefined;
      if (cookie) {
        try {
          const payload = jwt.verify(decodeURIComponent(cookie), config.jwtSecret) as { userId?: string; kind?: string };
          if (payload.kind === 'guest') guestId = payload.userId;
        } catch { /* Invalid cookie does not prevent a new registration. */ }
      }
      const result = guestId
        ? await svc.migrateFromAnonymous({ userId: guestId, anonymousId: guestId, username, email, password, nickname, currentLevel, targetLevel })
        : await svc.register({ username, email, password, nickname, currentLevel, targetLevel, inviteCode });
      setSessionCookie(res, result.token);
      res.status(201).json({ user: result.user });
    } catch (e: any) {
      res.status(e.status || 400).json({ error: e.message });
    }
  }

  // POST /auth/login — 登录
  async login(req: AuthRequest, res: Response) {
    try {
      const parsed = loginSchema.safeParse(req.body);
      if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
      const result = await svc.login(parsed.data.identifier || parsed.data.email!, parsed.data.password);
      setSessionCookie(res, result.token);
      res.json({ user: result.user });
    } catch (e: any) {
      res.status(e.status || 401).json({ error: e.message });
    }
  }

  // POST /auth/logout — 登出（清除 cookie）
  async logout(req: AuthRequest, res: Response) {
    clearSessionCookie(res);
    res.json({ success: true });
  }

  // GET /auth/me — 获取当前用户信息
  async me(req: AuthRequest, res: Response) {
    try {
      const user = await svc.me(req.userId!);
      res.json({ user });
    } catch (e: any) {
      res.status(e.status || 404).json({ error: e.message });
    }
  }

  // GET /auth/profile — 别名（兼容前端）
  async profile(req: AuthRequest, res: Response) {
    try {
      const user = await svc.me(req.userId!);
      res.json({ user });
    } catch (e: any) {
      res.status(e.status || 404).json({ error: e.message });
    }
  }

  // PUT /auth/profile — 更新用户资料
  async updateProfile(req: AuthRequest, res: Response) {
    try {
      const parsed = updateProfileSchema.safeParse(req.body);
      if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
      const userId = req.userId!;
      const { nickname, currentLevel, targetLevel, avatarUrl } = parsed.data;
      const user = await svc.updateProfile(userId, { nickname, currentLevel, targetLevel, avatarUrl });
      res.json({ user });
    } catch (e: any) {
      res.status(e.status || 400).json({ error: e.message });
    }
  }

  async changePassword(req: AuthRequest, res: Response) {
    try {
      const parsed = changePasswordSchema.safeParse(req.body);
      if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
      await svc.changePassword(req.userId!, parsed.data.oldPassword, parsed.data.newPassword);
      res.json({ success: true });
    } catch (e: any) {
      res.status(e.status || 400).json({ error: e.message });
    }
  }

  // POST /auth/forgot-password — 发送重置邮件（模拟）
  async forgotPassword(req: AuthRequest, res: Response) {
    try {
      const parsed = forgotPasswordSchema.safeParse(req.body);
      if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
      const result = await svc.forgotPassword(parsed.data.email);
      res.json(result);
    } catch (e: any) {
      res.status(e.status || 500).json({ error: e.message });
    }
  }

  // POST /auth/reset-password — 重置密码
  async resetPassword(req: AuthRequest, res: Response) {
    try {
      const parsed = resetPasswordSchema.safeParse(req.body);
      if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
      const user = await svc.resetPassword(parsed.data.token, parsed.data.password);
      res.json({ user });
    } catch (e: any) {
      res.status(e.status || 400).json({ error: e.message });
    }
  }

  // POST /auth/migrate-from-anonymous — 匿名学习者迁移
  // 当前已登录的匿名用户提供邮箱/密码后升级为注册用户，并合并匿名数据
  async migrateFromAnonymous(req: AuthRequest, res: Response) {
    try {
      const parsed = migrateFromAnonymousSchema.safeParse(req.body);
      if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

      // 需要额外字段：email / password / nickname 等
      const extra = registerSchema.safeParse(req.body);
      if (!extra.success) return res.status(400).json({ error: extra.error.flatten() });

      const userId = req.userId;
      if (!userId) return res.status(401).json({ error: '未登录' });
      const { anonymousId } = parsed.data;
      if (req.authKind !== 'guest' || anonymousId !== userId) return res.status(403).json({ error: '仅可迁移当前访客的学习记录' });
      const { username, email, password, nickname, currentLevel, targetLevel } = extra.data;

      const result = await svc.migrateFromAnonymous({
        userId,
        anonymousId,
        username,
        email,
        password,
        nickname,
        currentLevel,
        targetLevel,
      });
      setSessionCookie(res, result.token);
      res.json({ user: result.user });
    } catch (e: any) {
      res.status(e.status || 400).json({ error: e.message });
    }
  }
}
