const { PrismaClient } = require('@prisma/client');
const userPrisma = new PrismaClient({ datasources: { db: { url: process.env.USER_DATABASE_URL || 'file:./dev-user.db' } } });

async function main() {
  console.log('Testing DB query performance...');
  const start = Date.now();
  
  // 获取一个 session
  const session = await userPrisma.learningSession.findFirst();
  if (!session) {
    console.log('No sessions in DB');
    return;
  }
  
  console.log(`Found session: ${session.id}`);
  console.log(`Questions count: ${Array.isArray(session.questionIds) ? session.questionIds.length : 'N/A'}`);
  console.log(`Query time: ${Date.now() - start}ms`);
}

main().catch(console.error).finally(() => userPrisma.$disconnect());
