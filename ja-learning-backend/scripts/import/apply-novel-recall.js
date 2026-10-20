/** Apply the PDF's twelve long stories and their paired recall exercises. */
require('dotenv').config();
const fs = require('node:fs');
const crypto = require('node:crypto');
const { PrismaClient } = require('@prisma/client');
const { PrismaLibSQL } = require('@prisma/adapter-libsql');

const [payloadPath, backupPath] = process.argv.slice(2);
if (!payloadPath || !backupPath || !process.env.TURSO_URL || !process.env.TURSO_AUTH_TOKEN) {
  throw Error('Usage: node scripts/import/apply-novel-recall.js <prepared-json> <verified-backup-json>');
}
const backupBytes = fs.readFileSync(backupPath);
const backup = JSON.parse(backupBytes);
const payload = JSON.parse(fs.readFileSync(payloadPath));
if (backup.tables?.ReadingArticle?.length !== 28 || payload.articles?.length !== 12 ||
    payload.papers?.length !== 12 || payload.questions?.length !== payload.explanations?.length ||
    payload.questions?.length < 700 || payload.sourcePages !== 280) {
  throw Error('Backup or prepared data failed validation');
}
for (let i = 0; i < 12; i++) {
  const article = payload.articles[i], paper = payload.papers[i];
  if (article.position !== i+1 || article.paperId !== paper.id || article.questionCount !== paper.questionIds.length ||
      article.pages.some(page => page.recall) || article.endPage > 280) throw Error(`Article ${i+1} failed validation`);
}
const prisma = new PrismaClient({adapter:new PrismaLibSQL({
  url:process.env.TURSO_URL, authToken:process.env.TURSO_AUTH_TOKEN,
})});
async function main() {
  const current = await prisma.readingArticle.findMany({select:{id:true,startPage:true,endPage:true}});
  if (current.length < 12 || current.length > 28 || current.some(row => {
      const saved=backup.tables.ReadingArticle.find(item=>item.id===row.id);
      const prepared=payload.articles.find(item=>item.id===row.id);
      return !saved || !((saved.startPage===row.startPage && saved.endPage===row.endPage) ||
        (prepared && prepared.startPage===row.startPage && prepared.endPage===row.endPage));
    })) {
    throw Error('Database changed since backup; aborting update');
  }
  const oldQuestions = new Set(backup.tables.Question.map(row => row.id));
  const oldExplanations = new Set(backup.tables.Explanation.map(row => row.questionId));
  if (payload.questions.some(row => oldQuestions.has(row.id)) || payload.explanations.some(row => oldExplanations.has(row.questionId))) {
    throw Error('Prepared question IDs already exist');
  }
  async function createMissing(model, rows, key) {
    for (let i=0;i<rows.length;i+=20) {
      const chunk=rows.slice(i,i+20);
      for (let attempt=0;attempt<5;attempt++) {
        try {
          const present=new Set((await model.findMany({where:{[key]:{in:chunk.map(row=>row[key])}},select:{[key]:true}})).map(row=>row[key]));
          const missing=chunk.filter(row=>!present.has(row[key]));
          if (missing.length) await model.createMany({data:missing});
          break;
        } catch (error) {
          if (attempt===4) throw error;
          await new Promise(resolve=>setTimeout(resolve,500*(attempt+1)));
        }
      }
    }
  }
  if (await prisma.question.count({where:{id:{startsWith:'novel-recall-'}}}) < payload.questions.length)
    await createMissing(prisma.question,payload.questions,'id');
  if (await prisma.explanation.count({where:{id:{startsWith:'novel-recall-'}}}) < payload.explanations.length)
    await createMissing(prisma.explanation,payload.explanations,'questionId');
  async function retry(operation) {
    for (let attempt=0;attempt<5;attempt++) {
      try { return await operation(); }
      catch (error) { if (attempt===4) throw error; await new Promise(resolve=>setTimeout(resolve,1000*(attempt+1))); }
    }
  }
  // Publish the new paper lists after every referenced question and explanation exists.
  for (let i=0;i<12;i++) {
    const {id:articleId,...article}=payload.articles[i];
    const {id:paperId,...paper}=payload.papers[i];
    await retry(()=>prisma.readingArticle.update({where:{id:articleId},data:article}));
    await retry(()=>prisma.funPaper.update({where:{id:paperId},data:paper}));
  }
  const obsolete=backup.tables.ReadingArticle.filter(row=>row.position>12);
  for (const row of obsolete) {
    await retry(()=>prisma.funPaper.update({where:{id:row.paperId},data:{published:false}}));
    if (current.some(item=>item.id===row.id)) await retry(()=>prisma.readingArticle.delete({where:{id:row.id}}));
  }
  const articles=await prisma.readingArticle.findMany({select:{id:true,endPage:true,questionCount:true}});
  if (articles.length!==12 || articles.some(row=>row.endPage>280)) throw Error('Post-update article validation failed');
  console.log(JSON.stringify({backupSha256:crypto.createHash('sha256').update(backupBytes).digest('hex'),
    articles:articles.length, questions:payload.questions.length,
    publishedQuestions:articles.reduce((sum,row)=>sum+row.questionCount,0),
    archivedAppendix:obsolete.length}));
}
main().catch(e=>{console.error(e);process.exitCode=1}).finally(()=>prisma.$disconnect());
