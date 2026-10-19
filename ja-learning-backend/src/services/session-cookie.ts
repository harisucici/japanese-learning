import { Response } from 'express';
import { config } from '../config/env';

export function setSessionCookie(res: Response, token: string) {
  res.cookie('ja_session', token, {
    httpOnly: true, secure: config.nodeEnv === 'production', sameSite: 'lax',
    path: '/api', maxAge: 365 * 24 * 60 * 60 * 1000,
  });
}

export function clearSessionCookie(res: Response) {
  res.clearCookie('ja_session', { httpOnly: true, secure: config.nodeEnv === 'production', sameSite: 'lax', path: '/api' });
}
