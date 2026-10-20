import { PrismaClient } from '@prisma/client';
import { PrismaLibSQL } from '@prisma/adapter-libsql';
import { config } from './env';

// Personal learning tables live in USER_TURSO_URL. The content client never writes them.
if (!config.userTursoUrl || config.userTursoUrl === config.tursoUrl) {
  throw new Error('USER_TURSO_URL must point to a database separate from TURSO_URL');
}
const adapter = new PrismaLibSQL({
  url: config.userTursoUrl,
  authToken: config.userTursoAuthToken || undefined,
});
const userPrisma = new PrismaClient({ adapter } as any);
export default userPrisma;
