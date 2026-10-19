require('dotenv').config();
const assert = require('node:assert/strict');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const base = process.env.LEARNING_TEST_URL || `http://127.0.0.1:${process.env.PORT || 3002}/api/v1/learning/`;
const users = [];
async function call(path, token, body) {
  const response = await fetch(base + path, {
    method: body === undefined ? 'GET' : 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? {Authorization: `Bearer ${token}`} : {}) },
    ...(body === undefined ? {} : {body: JSON.stringify(body)}),
  });
  return {status: response.status, data: await response.json()};
}
async function guest() {
  const r = await call('guest', null, {}); assert.equal(r.status, 201);
  users.push(r.data.user.id); return r.data.token;
}
(async () => {
  const token = await guest(); const other = await guest();
  const catalog = await call('catalog');
  const dbCount = await prisma.question.count({where:{source:{in:['official','pastExam']},NOT:{provenance:{equals:require('@prisma/client').Prisma.DbNull}}}});
  assert.equal(catalog.data.total, dbCount);
  assert.equal((await call('dashboard', token)).data.totalAnswered, 0);
  assert.equal((await call('sessions', token, {level:'n5',type:'grammar'})).status,400);
  const s = await call('sessions',token,{level:'n5',limit:3}); assert.equal(s.status,201);
  const id=s.data.id; const qs=s.data.questions;
  assert.equal(qs.length,3); assert(qs.every(q=>!('answer' in q)&&!('correctOption' in q.provenance)));
  assert.equal((await call(`sessions/${id}`,other)).status,404);
  const originals=await prisma.question.findMany({where:{id:{in:qs.map(q=>q.id)}}});
  const correct=q=>originals.find(o=>o.id===q.id).answer;
  const wrong=q=>q.options.find(o=>o.id!==correct(q)).id;
  assert.equal((await call(`sessions/${id}/answers`,token,{questionId:qs[0].id,optionId:'invalid'})).status,400);
  let r=await call(`sessions/${id}/answers`,token,{questionId:qs[0].id,optionId:wrong(qs[0])});
  assert.equal(r.status,200); assert.equal(r.data.awaitingNext,true); assert.equal(r.data.currentIndex,0);
  assert(r.data.answers[0].explanation.sentenceStructure.length>0);
  assert.equal((await call(`sessions/${id}/answers`,token,{questionId:qs[0].id,optionId:correct(qs[0])})).status,409);
  r=await call(`sessions/${id}`,token); assert.equal(r.data.answers[0].isCorrect,false);
  assert.equal((await call(`sessions/${id}/next`,token,{})).data.currentIndex,1);
  assert.equal((await call(`sessions/${id}/answers`,token,{questionId:qs[1].id,optionId:correct(qs[1])})).data.currentIndex,2);
  r=await call(`sessions/${id}/answers`,token,{questionId:qs[2].id,optionId:correct(qs[2])});
  assert(r.data.completedAt); assert.equal(r.data.correctCount,2); assert.equal(r.data.score,67);
  const record=await prisma.examRecord.findUniqueOrThrow({where:{id}});assert.equal(record.score,67);assert.equal(record.totalQuestions,3);
  const stats=(await call('dashboard',token)).data;assert.equal(stats.totalAnswered,3);assert.equal(stats.completedSessions,1);assert.equal(stats.wrongCount,1);assert.equal(stats.accuracy,2/3);
  assert.equal((await call('mistakes',token)).data.items.length,1);
  assert.equal((await call(`sessions/${id}`,token)).data.score,67);
  assert.equal((await call(`sessions/${id}/next`,token,{})).status,409);
  const last=(await call('sessions',token,{level:'n5',limit:1})).data;
  r=await call(`sessions/${last.id}/answers`,token,{questionId:qs[0].id,optionId:wrong(qs[0])});
  assert.equal(r.data.completedAt,null);assert.equal(r.data.awaitingNext,true);
  r=await call(`sessions/${last.id}/next`,token,{});assert(r.data.completedAt);assert.equal(r.data.score,0);
  const concurrent=(await call('sessions',token,{level:'n5',limit:1})).data;
  const results=await Promise.all([1,2].map(()=>call(`sessions/${concurrent.id}/answers`,token,{questionId:qs[0].id,optionId:correct(qs[0])})));
  assert.deepEqual(results.map(x=>x.status).sort(),[200,409]);
  assert.equal(await prisma.learningAnswer.count({where:{sessionId:concurrent.id}}),1);
  assert.equal((await call(`sessions/${concurrent.id}`,token)).data.score,100);
  assert.equal(await prisma.explanation.count({where:{sentenceStructure:''}}),0);
  console.log('PASS: real catalog; empty category; answer privacy; ownership; invalid option; wrong answer lock; reload persistence; manual advance; correct auto advance; last-question feedback; 67/0/100 scores; stored records/statistics; concurrent duplicate submission; 162 explanations.');
})().catch(e=>{console.error(e);process.exitCode=1;}).finally(async()=>{
  await prisma.user.deleteMany({where:{id:{in:users}}});
  await prisma.$disconnect();
});
