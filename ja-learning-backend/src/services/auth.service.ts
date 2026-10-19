import { randomUUID } from 'node:crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { createClient, Client } from '@libsql/client';
import prisma from '../config/database';
import { config } from '../config/env';

interface UserRow {
  id: string;
  email: string;
  passwordHash: string;
  name: string;
  currentLevel: string;
  targetLevel: string;
  avatarUrl: string | null;
  createdAt: string;
  updatedAt: string;
}

function userDatabase(): Client {
  if (!config.userTursoUrl || !config.userTursoAuthToken) {
    throw Object.assign(new Error('用户数据库尚未配置'), { status: 503 });
  }
  if (config.userTursoUrl === config.tursoUrl) throw new Error('用户数据库必须独立于内容数据库');
  return createClient({ url: config.userTursoUrl, authToken: config.userTursoAuthToken });
}

const sanitize = (user: UserRow) => {
  const { passwordHash, ...publicUser } = user;
  return publicUser;
};
const tokenFor = (userId: string) => jwt.sign({ userId, kind: 'account' }, config.jwtSecret, { expiresIn: config.jwtExpiresIn } as jwt.SignOptions);

export class AuthService {
  async login(email: string, password: string) {
    const db = userDatabase();
    try {
      const result = await db.execute({ sql: 'SELECT * FROM "User" WHERE email = ?', args: [email] });
      const user = result.rows[0] as unknown as UserRow | undefined;
      if (!user || !await bcrypt.compare(password, user.passwordHash)) throw new Error('Invalid email or password');
      await prisma.anonymousLearner.upsert({ where: { id: user.id }, update: {}, create: { id: user.id } });
      return { token: tokenFor(user.id), user: sanitize(user) };
    } finally { db.close(); }
  }

  async register(email: string, password: string, name: string, targetLevel: 'n5' | 'n4' | 'n3' | 'n2' | 'n1' = 'n5') {
    if (!config.userRegistrationEnabled) throw Object.assign(new Error('用户注册尚未开放'), { status: 503 });
    const db = userDatabase();
    try {
      const id = randomUUID();
      const passwordHash = await bcrypt.hash(password, 10);
      const now = new Date().toISOString();
      await db.execute({ sql: 'INSERT INTO "User" (id,email,passwordHash,name,currentLevel,targetLevel,createdAt,updatedAt) VALUES (?,?,?,?,?,?,?,?)', args: [id,email,passwordHash,name,targetLevel,targetLevel,now,now] });
      await prisma.anonymousLearner.create({ data: { id } });
      return { token: tokenFor(id), user: { id,email,name,currentLevel:targetLevel,targetLevel,avatarUrl:null,createdAt:now,updatedAt:now } };
    } finally { db.close(); }
  }

  async me(userId: string) {
    const db = userDatabase();
    try {
      const result = await db.execute({ sql: 'SELECT * FROM "User" WHERE id = ?', args: [userId] });
      const user = result.rows[0] as unknown as UserRow | undefined;
      if (!user) throw new Error('User not found');
      return sanitize(user);
    } finally { db.close(); }
  }

  async updateProfile(userId: string, data: {
    name?: string;
    avatarUrl?: string;
    currentLevel?: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
    targetLevel?: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
  }) {
    const db = userDatabase();
    try {
      const fields = Object.entries(data).filter(([, value]) => value !== undefined);
      if (fields.length) {
        await db.execute({ sql: `UPDATE "User" SET ${fields.map(([key]) => `"${key}" = ?`).join(', ')}, "updatedAt" = ? WHERE id = ?`, args: [...fields.map(([, value]) => value as string), new Date().toISOString(), userId] });
      }
    } finally { db.close(); }
    return this.me(userId);
  }
}
