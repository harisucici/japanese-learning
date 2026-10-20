// 用户业务逻辑：封装 User 表的所有 CRUD 操作
// 注意：User 表位于独立的 Turso 用户库（USER_TURSO_URL），不走 Prisma
import { randomUUID, randomBytes, createHash } from 'node:crypto';
import bcrypt from 'bcryptjs';
import { createClient, Client } from '@libsql/client';
import { config } from '../config/env';

// 用户表行结构（与 prisma/user-schema.sql 保持一致）
export interface UserRow {
  id: string;
  username: string | null;
  email: string | null;
  passwordHash: string;
  nickname: string;
  role: string;
  currentLevel: string;   // JLPTLevel: n5|n4|n3|n2|n1
  targetLevel: string;    // JLPTLevel: n5|n4|n3|n2|n1
  avatarUrl: string | null;
  resetToken: string | null;
  resetTokenExpiry: string | null;
  createdAt: string;
  updatedAt: string;
}

// 对外暴露的公开用户信息（剔除密码哈希与重置令牌）
export type PublicUser = Omit<UserRow, 'passwordHash' | 'resetToken' | 'resetTokenExpiry'>;

export const sanitize = (user: UserRow): PublicUser => {
  const { passwordHash, resetToken, resetTokenExpiry, ...publicUser } = user;
  return publicUser;
};

// 获取用户库连接（每次操作独立建连，用完关闭；libsql 连接廉价）
export function userDatabase(): Client {
  if (!config.userTursoUrl) {
    throw Object.assign(new Error('用户数据库尚未配置'), { status: 503 });
  }
  if (config.userTursoUrl === config.tursoUrl) {
    throw new Error('用户数据库必须独立于内容数据库');
  }
  return createClient({ url: config.userTursoUrl, authToken: config.userTursoAuthToken || undefined });
}

// bcrypt 盐轮数
const SALT_ROUNDS = 10;

// 密码重置令牌有效期
const RESET_TOKEN_TTL_MS = 60 * 60 * 1000; // 1 小时

export class UserService {
  async findByIdentifier(identifier: string): Promise<UserRow | null> {
    const value = identifier.trim().toLowerCase();
    const db = userDatabase();
    try {
      const result = await db.execute({
        sql: 'SELECT * FROM "User" WHERE username = ? OR email = ?',
        args: [value, value],
      });
      return (result.rows[0] as unknown as UserRow) || null;
    } finally { db.close(); }
  }

  // 根据邮箱查找用户（含密码哈希，仅内部使用）
  async findByEmail(email: string): Promise<UserRow | null> {
    const db = userDatabase();
    try {
      const result = await db.execute({
        sql: 'SELECT * FROM "User" WHERE email = ?',
        args: [email.trim().toLowerCase()],
      });
      return (result.rows[0] as unknown as UserRow) || null;
    } finally {
      db.close();
    }
  }

  // 根据 ID 查找用户（含密码哈希，仅内部使用）
  async findById(id: string): Promise<UserRow | null> {
    const db = userDatabase();
    try {
      const result = await db.execute({
        sql: 'SELECT * FROM "User" WHERE id = ?',
        args: [id],
      });
      return (result.rows[0] as unknown as UserRow) || null;
    } finally {
      db.close();
    }
  }

  // 根据 ID 获取公开用户信息（不存在则抛错）
  async getPublicUser(id: string): Promise<PublicUser> {
    const user = await this.findById(id);
    if (!user) throw Object.assign(new Error('用户不存在'), { status: 404 });
    return sanitize(user);
  }

  // 创建用户：邮箱必须唯一，密码 bcrypt 加盐哈希
  async createUser(input: {
    username?: string;
    email?: string;
    password: string;
    nickname?: string;
    currentLevel?: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
    targetLevel?: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
  }): Promise<PublicUser> {
    const username = input.username?.trim().toLowerCase() || null;
    const email = input.email?.trim().toLowerCase() || null;
    if (!username && !email) throw Object.assign(new Error('请输入账户名或邮箱'), { status: 400 });
    if (username && await this.findByIdentifier(username)) throw Object.assign(new Error('该账户名已被使用'), { status: 409 });
    if (email && await this.findByIdentifier(email)) throw Object.assign(new Error('该邮箱已被注册'), { status: 409 });

    const id = randomUUID();
    const passwordHash = await bcrypt.hash(input.password, SALT_ROUNDS);
    const nickname = input.nickname?.trim() || username || email!.split('@')[0];
    const currentLevel = input.currentLevel || 'n5';
    const targetLevel = input.targetLevel || currentLevel;
    const now = new Date().toISOString();

    const db = userDatabase();
    try {
      await db.execute({
        sql: `INSERT INTO "User"
              (id, username, email, passwordHash, nickname, currentLevel, targetLevel, createdAt, updatedAt)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        args: [id, username, email, passwordHash, nickname, currentLevel, targetLevel, now, now],
      });
    } finally {
      db.close();
    }

    return {
      id,
      username,
      email,
      nickname,
      role: 'learner',
      currentLevel,
      targetLevel,
      avatarUrl: null,
      createdAt: now,
      updatedAt: now,
    };
  }

  // 校验密码：返回用户（不含哈希）或 null
  async verifyPassword(identifier: string, password: string): Promise<PublicUser | null> {
    const user = await this.findByIdentifier(identifier);
    if (!user) return null;
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) return null;
    return sanitize(user);
  }

  // 更新用户资料（仅更新传入字段）
  async updateProfile(
    id: string,
    data: {
      nickname?: string;
      currentLevel?: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
      targetLevel?: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
      avatarUrl?: string | null;
    },
  ): Promise<PublicUser> {
    const fields: Array<{ key: keyof UserRow; value: unknown }> = [];
    if (data.nickname !== undefined) fields.push({ key: 'nickname', value: data.nickname });
    if (data.currentLevel !== undefined) fields.push({ key: 'currentLevel', value: data.currentLevel });
    if (data.targetLevel !== undefined) fields.push({ key: 'targetLevel', value: data.targetLevel });
    if (data.avatarUrl !== undefined) fields.push({ key: 'avatarUrl', value: data.avatarUrl });

    if (fields.length) {
      const db = userDatabase();
      try {
        const sets = fields.map((f) => `"${f.key}" = ?`).join(', ');
        const args = [...fields.map((f) => f.value as string | null), new Date().toISOString(), id];
        await db.execute({
          sql: `UPDATE "User" SET ${sets}, "updatedAt" = ? WHERE id = ?`,
          args,
        });
      } finally {
        db.close();
      }
    }
    return this.getPublicUser(id);
  }

  // 修改密码（需要校验旧密码）
  async changePassword(id: string, oldPassword: string, newPassword: string): Promise<void> {
    const user = await this.findById(id);
    if (!user) throw Object.assign(new Error('用户不存在'), { status: 404 });
    const ok = await bcrypt.compare(oldPassword, user.passwordHash);
    if (!ok) throw Object.assign(new Error('旧密码不正确'), { status: 400 });
    const passwordHash = await bcrypt.hash(newPassword, SALT_ROUNDS);
    const db = userDatabase();
    try {
      await db.execute({
        sql: `UPDATE "User" SET "passwordHash" = ?, "updatedAt" = ? WHERE id = ?`,
        args: [passwordHash, new Date().toISOString(), id],
      });
    } finally {
      db.close();
    }
  }

  // 直接用新密码覆盖（用于 reset-password 流程，已校验 token）
  async setPasswordByResetToken(token: string, newPassword: string): Promise<PublicUser> {
    const db = userDatabase();
    let user: UserRow | null = null;
    try {
      const result = await db.execute({
        sql: 'SELECT * FROM "User" WHERE "resetToken" = ?',
        args: [createHash('sha256').update(token).digest('hex')],
      });
      user = (result.rows[0] as unknown as UserRow) ?? null;
    } finally {
      db.close();
    }

    if (!user) throw Object.assign(new Error('重置令牌无效'), { status: 400 });
    if (!user.resetTokenExpiry || new Date(user.resetTokenExpiry).getTime() < Date.now()) {
      throw Object.assign(new Error('重置令牌已过期'), { status: 400 });
    }

    const passwordHash = await bcrypt.hash(newPassword, SALT_ROUNDS);
    const db2 = userDatabase();
    try {
      await db2.execute({
        sql: `UPDATE "User"
              SET "passwordHash" = ?, "resetToken" = NULL, "resetTokenExpiry" = NULL, "updatedAt" = ?
              WHERE id = ?`,
        args: [passwordHash, new Date().toISOString(), user.id],
      });
    } finally {
      db2.close();
    }
    return this.getPublicUser(user.id);
  }

  // 发起密码找回：生成重置令牌并记录（实际邮件发送在 controller 模拟）
  async createResetToken(email: string): Promise<{ token: string; user: PublicUser } | null> {
    const user = await this.findByEmail(email);
    if (!user) return null; // 出于安全考虑，邮箱不存在也返回成功，避免枚举
    const token = randomBytes(32).toString('hex');
    const expiry = new Date(Date.now() + RESET_TOKEN_TTL_MS).toISOString();
    const db = userDatabase();
    try {
      await db.execute({
        sql: `UPDATE "User"
              SET "resetToken" = ?, "resetTokenExpiry" = ?, "updatedAt" = ?
              WHERE id = ?`,
        args: [createHash('sha256').update(token).digest('hex'), expiry, new Date().toISOString(), user.id],
      });
    } finally {
      db.close();
    }
    return { token, user: sanitize(user) };
  }
}
