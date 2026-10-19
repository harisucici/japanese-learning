require('dotenv').config();
const assert=require('node:assert/strict');
const {PrismaClient}=require('@prisma/client');
const db=new PrismaClient();let userId;
const base='http://127.0.0.1:3002/api/v1/learning/';
async function call(path,token,body){const r=await fetch(base+path,{method:body===undefined?'GET':'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},...(body===undefined?{}:{body:JSON.stringify(body)})});return {status:r.status,data:await r.json()};}
(async()=>{
assert.equal((await call('catalog')).data.total,162);
const ms=(await call('materials')).data;assert.equal(ms.total,201);assert.equal(ms.audioCount,100);assert.equal(ms.videoCount,0);
for(const item of [ms.items[0],ms.items.find(x=>x.audioUrl),ms.items.find(x=>x.audioUrl && x.id.startsWith('short-'))]){const m=(await call('materials/'+item.id)).data;assert(!('sourcePath' in m.metadata));for(const url of [m.fileUrl,m.audioUrl,m.videoUrl].filter(Boolean)){const r=await fetch(url,{headers:{Range:'bytes=0-99'}});assert.equal(r.status,206);assert.equal((await r.arrayBuffer()).byteLength,100);}}
const papers=(await call('fun-papers')).data.papers;assert.equal(papers.length,10);assert(papers.every(p=>p.ready&&p.questionCount===5));
const guest=(await call('guest',null,{})).data;userId=guest.user.id;const token=guest.token;
let s=(await call('sessions',token,{level:'n5',mode:'fun',collectionId:papers[0].id})).data;assert.equal(s.level,'ungraded');assert.equal(s.questions.length,5);assert.equal(s.activity.title,papers[0].title);
const qs=await db.question.findMany({where:{id:{in:s.questionIds}}});
for(let i=0;i<5;i++){const q=s.questions[i];const original=qs.find(x=>x.id===q.id);assert.equal(original.source,'custom');assert(original.provenance.passage.includes(original.provenance.supportingQuote));assert(!('answer' in q));const option=i===1?q.options.find(x=>x.id!==original.answer).id:original.answer;let r=await call(`sessions/${s.id}/answers`,token,{questionId:q.id,optionId:option});assert.equal(r.status,200);s=r.data;if(i===1){assert(s.awaitingNext);assert(s.answers.find(a=>a.questionId===q.id).explanation.sentenceStructure);assert.equal((await call(`sessions/${s.id}/answers`,token,{questionId:q.id,optionId:original.answer})).status,409);s=(await call(`sessions/${s.id}/next`,token,{})).data;}else if(i<4)assert.equal(s.currentIndex,i+1);}
assert(s.completedAt);assert.equal(s.score,80);assert.equal((await db.examRecord.findUniqueOrThrow({where:{id:s.id}})).score,80);assert.equal((await call('dashboard',token)).data.sessions[0].activityTitle,papers[0].title);
console.log('PASS: 201 original PDFs, 100 audio, 0 video, byte-range playback; 10 material papers / 50 questions; source quotes; correct auto advance; wrong feedback and immutable answer; final 80 score; official catalog still 162.');
})().catch(e=>{console.error(e);process.exitCode=1}).finally(async()=>{if(userId)await db.user.delete({where:{id:userId}});await db.$disconnect()});
