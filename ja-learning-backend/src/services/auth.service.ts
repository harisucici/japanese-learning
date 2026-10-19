import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from '../config/database';
import { config } from '../config/env';

export class AuthService {
  async login(email: string, password: string) {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) throw new Error('Invalid email or password');
    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) throw new Error('Invalid email or password');
    const token = jwt.sign({ userId: user.id }, config.jwtSecret, { expiresIn: config.jwtExpiresIn } as jwt.SignOptions);
    return { token, user: this.sanitize(user) };
  }

  async register(email: string, password: string, name: string, targetLevel: 'n5' | 'n4' | 'n3' | 'n2' | 'n1' = 'n5') {
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) throw new Error('Email already in use');
    const passwordHash = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { email, passwordHash, name, targetLevel, currentLevel: targetLevel },
    });
    const token = jwt.sign({ userId: user.id }, config.jwtSecret, { expiresIn: config.jwtExpiresIn } as jwt.SignOptions);
    return { token, user: this.sanitize(user) };
  }

  async me(userId: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new Error('User not found');
    return this.sanitize(user);
  }

  async updateProfile(userId: string, data: {
    name?: string;
    avatarUrl?: string;
    currentLevel?: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
    targetLevel?: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
  }) {
    const updateData: any = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.avatarUrl !== undefined) updateData.avatarUrl = data.avatarUrl;
    if (data.currentLevel !== undefined) updateData.currentLevel = data.currentLevel;
    if (data.targetLevel !== undefined) updateData.targetLevel = data.targetLevel;

    const user = await prisma.user.update({
      where: { id: userId },
      data: updateData,
    });
    return this.sanitize(user);
  }

  private sanitize(user: any) {
    const { passwordHash, ...rest } = user;
    return rest;
  }
}
