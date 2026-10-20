import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config/env';

export interface AuthRequest extends Request {
  userId?: string;
  authKind?: string;
}

export const authMiddleware = (req: AuthRequest, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;
  const cookie = req.headers.cookie?.split(';').map(part => part.trim()).find(part => part.startsWith('ja_session='))?.slice('ja_session='.length);
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : cookie;
  if (!token) {
    res.status(401).json({ error: 'Missing learning session cookie' });
    return;
  }
  try {
    const payload = jwt.verify(decodeURIComponent(token), config.jwtSecret) as { userId: string; kind?: string };
    req.userId = payload.userId;
    req.authKind = payload.kind;
    next();
  } catch (err) {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};
