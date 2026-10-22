import { PrismaClient } from '@prisma/client';
import { PrismaLibSQL } from '@prisma/adapter-libsql';
import { config } from './env';

const adapter = new PrismaLibSQL({
  url: config.tursoUrl,
  authToken: config.tursoAuthToken,
});
const prisma = new PrismaClient({ adapter } as any);

// 启动时验证数据库连接，连接参数为空或连接失败时立即暴露错误。
export async function verifyDatabaseConnection(): Promise<void> {
  if (!config.tursoUrl) {
    throw new Error('TURSO_URL is not configured');
  }
  try {
    await prisma.$connect();
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    throw new Error(`Failed to connect to content database: ${message}`);
  }
}

export default prisma;
