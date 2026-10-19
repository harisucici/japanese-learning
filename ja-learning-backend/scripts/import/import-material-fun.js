require('dotenv').config();const fs=require('fs'),path=require('path'),crypto=require('crypto');const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();
(async()=>{
 const d=JSON.parse(fs.readFileSync(path.join(__dirname,'../data/material-fun-library.json')));
 for(const m of d.materials){const file=path.join(__dirname,'../data/study-assets',m.id+'.pdf');if(crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')!==m.sha256)throw Error(`Source checksum mismatch ${m.id}`);}
 for(const q of d.questions){const s=q.provenance;if(!s.passage.includes(s.supportingQuote)||q.level!=='ungraded'||q.source!=='custom'||q.options.length!==4||new Set(q.options.map(o=>o.id)).size!==4||!q.options.some(o=>o.id===q.answer))throw Error(`Invalid source-grounded question ${q.id}`);}
 await p.$transaction(async tx=>{
  for(const m of d.materials)await tx.studyMaterial.upsert({where:{id:m.id},create:m,update:m});
  for(const q of d.questions)await tx.question.upsert({where:{id:q.id},create:q,update:q});
  for(const e of d.explanations)await tx.explanation.upsert({where:{questionId:e.questionId},create:e,update:e});
  for(const paper of d.papers)await tx.funPaper.upsert({where:{id:paper.id},create:paper,update:paper});
 },{timeout:60000});
 console.log(JSON.stringify({materials:d.materials.length,papers:d.papers.length,questions:d.questions.length,existingOfficialQuestions:await p.question.count({where:{source:'pastExam'}})}));
})().catch(e=>{console.error(e);process.exitCode=1}).finally(()=>p.$disconnect());
