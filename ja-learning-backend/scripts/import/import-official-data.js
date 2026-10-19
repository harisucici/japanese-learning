require('dotenv').config();
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { PrismaClient } = require('@prisma/client');
const root = path.join(__dirname, '..');
const dataset = JSON.parse(fs.readFileSync(path.join(root, 'data/official/jlpt-2018-vocabulary.json'), 'utf8'));
function validate(data) {
  const ids = new Set(), explanationIds = new Set();
  if (!data.questions.length || data.questions.length !== data.explanations.length) throw Error('Invalid dataset size');
  for (const q of data.questions) {
    if (ids.has(q.id)) throw Error(`Duplicate ID ${q.id}`); ids.add(q.id);
    if (q.source !== 'pastExam' || !/^n[1-5]$/.test(q.level) || !q.content.trim() || /\(cid:/.test(q.content)) throw Error(`Invalid question ${q.id}`);
    if (q.options.length !== 4 || new Set(q.options.map(o=>o.id)).size !== 4 || q.options.some((o,i)=>!o.content.trim() || o.index!==i || /\(cid:/.test(o.content))) throw Error(`Invalid options ${q.id}`);
    const p = q.provenance;
    if (!p || p.examYear !== null || p.publicationYear !== 2018 || !Number.isInteger(p.pdfPage) || p.pdfPage < 1 || !Number.isInteger(p.number) || ![1,2,3,4].includes(p.correctOption) || q.answer !== q.options[p.correctOption-1].id) throw Error(`Invalid provenance/answer ${q.id}`);
    for (const url of [p.sourceUrl,p.answerUrl]) if (new URL(url).origin !== 'https://www.jlpt.jp') throw Error(`Invalid source ${q.id}`);
    const pdf = fs.readFileSync(path.join(root, 'data/official/pdf', new URL(p.sourceUrl).pathname.split('/').pop()));
    if (crypto.createHash('sha256').update(pdf).digest('hex') !== p.pdfSha256) throw Error(`Source checksum mismatch ${q.id}`);
    const e = data.explanations.find(e=>e.id===q.explanationId && e.questionId===q.id);
    if (!e || explanationIds.has(e.id)) throw Error(`Invalid explanation ${q.id}`); explanationIds.add(e.id);
  }
}
async function main() {
  validate(dataset);
  const byLevel = Object.fromEntries(['n1','n2','n3','n4','n5'].map(l=>[l,dataset.questions.filter(q=>q.level===l).length]));
  if (!process.argv.includes('--replace')) {console.log(JSON.stringify({mode:'validation_only',questions:dataset.questions.length,byLevel})); return;}
  const prisma = new PrismaClient();
  try {
    const result = await prisma.$transaction(async tx => {
      const old = {
        questions: await tx.question.findMany(), explanations: await tx.explanation.findMany(),
        examRecords: await tx.examRecord.findMany(), reviewItems: await tx.reviewItem.findMany(),
        userStats: await tx.user.findMany({select:{id:true,totalQuestions:true,accuracy:true,streakDays:true}}),
      };
      const backupDir = path.join(root,'data/backups'); fs.mkdirSync(backupDir,{recursive:true});
      const backup = path.join(backupDir,`before-official-${Date.now()}.json`);
      fs.writeFileSync(backup, JSON.stringify(old,null,2), {mode:0o600,flag:'wx'});
      await tx.reviewItem.deleteMany(); await tx.examRecord.deleteMany();
      await tx.explanation.deleteMany(); await tx.question.deleteMany();
      await tx.user.updateMany({data:{totalQuestions:0,accuracy:0,streakDays:0}});
      await tx.question.createMany({data:dataset.questions});
      await tx.explanation.createMany({data:dataset.explanations});
      const count = await tx.question.count();
      if (count !== dataset.questions.length) throw Error('Post-import count mismatch');
      return {questions:count,byLevel,deleted:{questions:old.questions.length,explanations:old.explanations.length,examRecords:old.examRecords.length,reviewItems:old.reviewItems.length},accountsPreserved:old.userStats.length,backup};
    }, {timeout:60000,isolationLevel:'Serializable'});
    console.log(JSON.stringify({mode:'replaced',...result},null,2));
  } finally {await prisma.$disconnect();}
}
main().catch(e=>{console.error(e);process.exitCode=1;});
