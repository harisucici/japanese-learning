// 邀请码服务：验证和标记邀请码使用
import userPrisma from '../config/user-database';

export class InviteCodeService {
  // 验证邀请码：存在且未使用
  async validateCode(code: string) {
    return userPrisma.inviteCode.findFirst({
      where: {
        code: code.toUpperCase(),
        used: false,
      },
    });
  }

  // 标记邀请码已使用（在事务中调用）
  async markAsUsed(
    codeId: string,
    userId: string,
    tx: any = userPrisma
  ) {
    return tx.inviteCode.update({
      where: { id: codeId },
      data: {
        used: true,
        usedBy: userId,
        usedAt: new Date(),
      },
    });
  }
}
