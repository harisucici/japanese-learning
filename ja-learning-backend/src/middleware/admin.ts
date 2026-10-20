/**
 * 管理员鉴权中间件
 *
 * 策略：
 *   1. ADMIN_API_KEY can authenticate server-to-server requests;
 *   2. Browser requests require a signed account cookie and a current admin role
 *      in the separate user database. Development has no bypass.
 */
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config/env';
import { UserService } from '../services/user.service';

const users = new UserService();

export const adminMiddleware = (req: Request, res: Response, next: NextFunction): void => {
  const adminKey = process.env.ADMIN_API_KEY;

  // 1) 静态 API Key
  if (adminKey) {
    const provided = req.headers['x-admin-key'] as string | undefined;
    if (provided && provided === adminKey) return next();
  }

  // 2) Signed account session with admin role
  const authHeader = req.headers.authorization;
  const cookie = req.headers.cookie?.split(';').map(part => part.trim()).find(part => part.startsWith('ja_session='))?.slice('ja_session='.length);
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : cookie;
  if (token) {
    try {
      const payload = jwt.verify(decodeURIComponent(token), config.jwtSecret) as { userId?: string; kind?: string };
      if (payload.kind === 'account' && payload.userId) {
        users.findById(payload.userId)
          .then(user => user?.role === 'admin' ? next() : res.status(403).json({ error: 'Forbidden' }))
          .catch(() => res.status(503).json({ error: 'Admin verification unavailable' }));
        return;
      }
    } catch {
      /* fallthrough */
    }
  }

  res.status(403).json({ error: 'Forbidden' });
};
