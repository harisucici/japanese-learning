require('dotenv').config();const assert=require('node:assert/strict');const {PrismaClient}=require('@prisma/client');const {examSections,examConfig}=require('../dist/services/exam-rules');const p=new PrismaClient();let uid;
const base=`http://127.0.0.1:${process.env.PORT||3002}/api/v1/learning/`;let token;
async function call(path,body){const r=await fetch(base+path,{method:body===undefined?'GET':'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},...(body===undefined?{}:{body:JSON.stringify(body)})});return {status:r.status,data:await r.json()};}
async function fixture(feedback){const qs=await p.question.findMany({where:{level:'n5'},orderBy:{order:'asc'},take:3});const sections=examSections('n5').map((s,i)=>({...s,questionIds:[qs[i].id]}));const config=examConfig({id:'internal-clock-test-only',title:'Internal timer test (not a published paper)',kind:'official_workbook',sections},feedback);const s=await p.learningSession.create({data:{userId:uid,level:'n5',mode:'exam',questionIds:qs.map(q=>q.id),examConfig:config}});return {s,qs};}
async function expire(id){const s=await p.learningSession.findUniqueOrThrow({where:{id}});await p.learningSession.update({where:{id},data:{examConfig:{...s.examConfig,deadline:new Date(Date.now()-1000).toISOString()}}});}
(async()=>{
 assert.deepEqual(examSections('n5').map(s=>s.minutes),[20,40,30]);
 assert.deepEqual(examSections('n4',2018,7).map(s=>s.minutes),[30,60,35]);
 assert.deepEqual(examSections('n5',2018,12).map(s=>s.minutes),[25,50,30]);
 assert.equal(examSections('n1',2022,7)[1].minutes,60);assert.equal(examSections('n1',2022,12)[1].minutes,55);
 const g=await call('guest',{});uid=g.data.user.id;token=g.data.token;
 const cat=await call('exam-papers');assert.equal(cat.status,200);assert.equal(cat.data.papers.filter(p=>p.ready).length,0);
 assert.equal((await call('sessions',{level:'n5',mode:'exam',paperId:'official-workbook-2018-n5'})).status,400);
 let {s,qs}=await fixture(false);let wrong=qs[0].options.find(o=>o.id!==qs[0].answer).id;
 let r=await call(`sessions/${s.id}/answers`,{questionId:qs[0].id,optionId:wrong});assert.equal(r.status,200);
 assert.equal(r.data.examConfig.waitingSection,true);assert.equal(r.data.score,null);assert.equal(r.data.answers[0].isCorrect,undefined);assert.equal(r.data.answers[0].correctOptionId,undefined);assert.equal(r.data.answers[0].explanation,undefined);
 assert.equal((await call('mistakes')).data.items.length,0);assert.equal((await call('dashboard')).data.correctCount,0);
 r=await call(`sessions/${s.id}/section`,{action:'start'});assert.equal(r.data.examConfig.sectionIndex,1);assert(Date.parse(r.data.examConfig.deadline)>Date.now()+39*60000);
 const deadline=r.data.examConfig.deadline;assert.equal((await call(`sessions/${s.id}`)).data.examConfig.deadline,deadline);
 await expire(s.id);r=await call(`sessions/${s.id}`);assert.equal(r.data.examConfig.waitingSection,true);assert.equal(r.data.currentIndex,2);
 assert.equal((await call(`sessions/${s.id}/answers`,{questionId:qs[1].id,optionId:qs[1].answer})).status,409);
 await call(`sessions/${s.id}/section`,{action:'start'});r=await call(`sessions/${s.id}/answers`,{questionId:qs[2].id,optionId:qs[2].answer});assert(r.data.completedAt);assert.equal(r.data.score,33);assert.equal(r.data.answers.length,2);
 ({s,qs}=await fixture(true));wrong=qs[0].options.find(o=>o.id!==qs[0].answer).id;
 r=await call(`sessions/${s.id}/answers`,{questionId:qs[0].id,optionId:wrong});assert.equal(r.data.awaitingNext,true);assert(r.data.answers[0].explanation.sentenceStructure);assert.equal(r.data.examConfig.waitingSection,false);
 const firstDeadline=r.data.examConfig.deadline;assert.equal((await call(`sessions/${s.id}`)).data.examConfig.deadline,firstDeadline);
 assert.equal((await call(`sessions/${s.id}/answers`,{questionId:qs[0].id,optionId:qs[0].answer})).status,409);
 await expire(s.id);r=await call(`sessions/${s.id}`);assert.equal(r.data.examConfig.waitingSection,true);
 await call(`sessions/${s.id}/section`,{action:'start'});await call(`sessions/${s.id}/section`,{action:'submit'});await call(`sessions/${s.id}/section`,{action:'start'});await expire(s.id);r=await call(`sessions/${s.id}`);assert(r.data.completedAt);assert.equal(r.data.score,0);
 console.log('PASS: current/historical timing; incomplete papers rejected; section deadlines persist; feedback off hides answers; feedback on explains immediately without pausing; timeout locks section; next section starts separately; unanswered questions score zero; results saved.');
})().catch(e=>{console.error(e);process.exitCode=1}).finally(async()=>{if(uid)await p.user.delete({where:{id:uid}});await p.$disconnect()});
