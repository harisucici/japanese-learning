// 认证服务：账号与个人学习记录共用独立用户库；题库始终留在内容库。
import jwt from 'jsonwebtoken';
import userPrisma from '../config/user-database';
import { config } from '../config/env';
import { UserService, PublicUser } from './user.service';

// 签发 JWT：payload 仅含 userId 与 token 类别
const tokenFor = (userId: string, role: string) =>
  jwt.sign({ userId, kind: 'account', role }, config.jwtSecret, {
    expiresIn: config.jwtExpiresIn,
  } as jwt.SignOptions);

export class AuthService {
  private users = new UserService();

  // 登录：账户名或邮箱 + 密码
  async login(identifier: string, password: string) {
    const user = await this.users.verifyPassword(identifier, password);
    if (!user) throw Object.assign(new Error('邮箱或密码错误'), { status: 401 });

    // 确保内容库存在对应 AnonymousLearner（学习会话通过它关联）
    await userPrisma.anonymousLearner.upsert({
      where: { id: user.id },
      update: {},
      create: { id: user.id },
    });

    return { token: tokenFor(user.id, user.role), user };
  }

  // 注册：创建用户 + 同步 AnonymousLearner
  async register(input: {
    username?: string;
    email?: string;
    password: string;
    nickname?: string;
    currentLevel?: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
    targetLevel?: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
  }) {
    if (!config.userRegistrationEnabled) {
      throw Object.assign(new Error('用户注册尚未开放'), { status: 503 });
    }
    const user = await this.users.createUser(input);
    await userPrisma.anonymousLearner.upsert({
      where: { id: user.id },
      update: {},
      create: { id: user.id },
    });
    return { token: tokenFor(user.id, user.role), user };
  }

  // 获取当前用户
  async me(userId: string): Promise<PublicUser> {
    return this.users.getPublicUser(userId);
  }

  // 更新资料
  async updateProfile(
    userId: string,
    data: {
      nickname?: string;
      currentLevel?: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
      targetLevel?: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
      avatarUrl?: string | null;
    },
  ): Promise<PublicUser> {
    return this.users.updateProfile(userId, data);
  }

  // 修改密码（需校验旧密码）
  async changePassword(userId: string, oldPassword: string, newPassword: string): Promise<void> {
    return this.users.changePassword(userId, oldPassword, newPassword);
  }

  // 发起密码找回
  async forgotPassword(email: string): Promise<{ sent: boolean }> {
    if (!config.passwordResetApiKey || !config.passwordResetFrom || !config.publicAppUrl) {
      throw Object.assign(new Error('邮箱找回尚未配置，请联系管理员'), { status: 503 });
    }
    const result = await this.users.createResetToken(email);
    // 不论邮箱是否存在都返回 sent: true，避免枚举
    if (!result) return { sent: true };
    const link = `${config.publicAppUrl.replace(/\/$/, '')}/reset-password?token=${encodeURIComponent(result.token)}`;
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${config.passwordResetApiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: config.passwordResetFrom,
        to: [result.user.email],
        subject: '山间书院 · 重置密码',
        text: `请在一小时内打开以下链接重置密码：\n${link}\n如果不是你本人操作，可以忽略此邮件。`,
      }),
    });
    if (!response.ok) throw Object.assign(new Error('邮件发送失败，请稍后重试'), { status: 503 });
    return { sent: true };
  }

  // 用令牌重置密码
  async resetPassword(token: string, newPassword: string): Promise<PublicUser> {
    return this.users.setPasswordByResetToken(token, newPassword);
  }

  // 匿名学习者迁移为注册用户
  // 流程：在事务中先把匿名数据转移到新用户 ID 下，再删除旧匿名占位记录。
  // 注意：必须在删除前转移数据，否则 Prisma 级联会一并清除学习记录。
  async migrateFromAnonymous(params: {
    userId: string;
    anonymousId: string;
    username?: string;
    email?: string;
    password: string;
    nickname?: string;
    currentLevel?: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
    targetLevel?: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
  }) {
    if (!config.userRegistrationEnabled) {
      throw Object.assign(new Error('用户注册尚未开放'), { status: 503 });
    }
    // 1) 校验匿名用户是否存在
    const anon = await userPrisma.anonymousLearner.findUnique({
      where: { id: params.anonymousId },
    });
    if (!anon) throw Object.assign(new Error('匿名学习者不存在'), { status: 404 });

    // 2) 校验该邮箱是否已被注册
    const existing = params.username
      ? await this.users.findByIdentifier(params.username)
      : params.email ? await this.users.findByIdentifier(params.email) : null;
    if (existing) {
      throw Object.assign(new Error('该账户名或邮箱已被注册'), { status: 409 });
    }

    // 3) 注册用户
    const user = await this.users.createUser({
      username: params.username,
      email: params.email,
      password: params.password,
      nickname: params.nickname,
      currentLevel: params.currentLevel,
      targetLevel: params.targetLevel,
    });

    // 4) 原子迁移：在同一事务内把匿名数据转移到新用户 ID 下
    //    关键顺序：先转移（updateMany），再删除旧占位，最后创建新占位
    await userPrisma.$transaction(async (tx) => {
      await tx.anonymousLearner.create({ data: { id: user.id } });
      // 转移 LearningSession（级联的 LearningAnswer 通过 session 跟随迁移）
      await tx.learningSession.updateMany({
        where: { userId: params.anonymousId },
        data: { userId: user.id },
      });
      await tx.reviewItem.updateMany({
        where: { userId: params.anonymousId },
        data: { userId: user.id },
      });
      await tx.examRecord.updateMany({
        where: { userId: params.anonymousId },
        data: { userId: user.id },
      });

      // 删除旧匿名占位记录（数据已转移，级联不会触发）
      await tx.anonymousLearner.delete({ where: { id: params.anonymousId } });
    });

    return { token: tokenFor(user.id, user.role), user };
  }
}
