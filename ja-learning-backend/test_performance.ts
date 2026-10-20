import userPrisma from './src/config/user-database';
import contentPrisma from './src/config/database';
import { state } from './src/controllers/_shared';

async function testPerformance() {
  const startTime = Date.now();
  
  // 获取第一个 session
  const session = await userPrisma.learningSession.findFirst();
  if (!session) {
    console.log('No sessions found');
    process.exit(1);
  }
  
  console.log(`Session ID: ${session.id}`);
  console.log(`Question count: ${session.questionIds.length}`);
  
  const queryStart = Date.now();
  const result = await state(userPrisma, session.id, session.userId);
  const queryTime = Date.now() - queryStart;
  
  console.log(`\nQuery time: ${queryTime}ms`);
  console.log(`Total questions: ${result.questions.length}`);
  console.log(`Answered: ${result.answers.length}`);
  console.log(`Current index: ${result.currentIndex}`);
  
  // 测试单独查询
  const singleStart = Date.now();
  const singleQuestion = await contentPrisma.question.findFirst({
    where: { id: session.questionIds[0] }
  });
  const singleTime = Date.now() - singleStart;
  console.log(`\nSingle question query: ${singleTime}ms`);
  
  // 测试批量查询
  const batchStart = Date.now();
  const batchQuestions = await contentPrisma.question.findMany({
    where: { id: { in: session.questionIds.slice(0, 10) } }
  });
  const batchTime = Date.now() - batchStart;
  console.log(`Batch query (10 questions): ${batchTime}ms`);
  
  process.exit(0);
}

testPerformance().catch(console.error);
