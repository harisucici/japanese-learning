import { PrismaClient } from '@prisma/client';
import { PrismaLibSQL } from '@prisma/adapter-libsql';
import { config } from './env';

const adapter = new PrismaLibSQL({
  url: config.tursoUrl,
  authToken: config.tursoAuthToken,
});
const prisma = new PrismaClient({ adapter } as any);

export default prisma;
