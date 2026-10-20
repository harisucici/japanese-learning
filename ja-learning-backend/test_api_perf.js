const start = Date.now();

// 模拟 getSession 的数据库查询
async function testPerformance() {
  const userPrisma = require('./src/config/user-database').default;
  const contentPrisma = require('./src/config/database').default;
  
  console.log('=== 测试后端 API 性能 ===\n');
  
  // 查找一个存在的 session
  const session = await userPrisma.learningSession.findFirst({
    include: { answers: { orderBy: { answeredAt: 'asc' } } }
  });
  
  if (!session) {
    console.log('没有找到 session');
    return;
  }
  
  console.log('Session ID:', session.id);
  console.log('题目数量:', session.questionIds.length);
  console.log('已答题数:', session.answers.length);
  console.log('查询 session 耗时:', Date.now() - start, 'ms\n');
  
  // 测试题目查询
  const questionIds = session.questionIds;
  const visibleIds = questionIds.slice(0, 10); // 只测试前10题
  
  const t1 = Date.now();
  const questions = await contentPrisma.question.findMany({
    where: { id: { in: visibleIds } }
  });
  console.log('查询', visibleIds.length, '个题目耗时:', Date.now() - t1, 'ms');
  console.log('实际返回:', questions.length, '个题目\n');
  
  // 测试讲解查询
  const t2 = Date.now();
  const explanations = await contentPrisma.explanation.findMany({
    where: { questionId: { in: visibleIds } }
  });
  console.log('查询讲解耗时:', Date.now() - t2, 'ms');
  console.log('实际返回:', explanations.length, '个讲解\n');
  
  // 测试完整 state 函数
  const t3 = Date.now();
  const { state } = require('./src/controllers/_shared');
  const result = await state(userPrisma, session.id, session.userId);
  console.log('完整 state() 函数耗时:', Date.now() - t3, 'ms');
  console.log('返回题目数:', result.questions.length);
  console.log('返回答案数:', result.answers.length);
  
  await userPrisma.$disconnect();
  await contentPrisma.$disconnect();
}

testPerformance().catch(console.error);
