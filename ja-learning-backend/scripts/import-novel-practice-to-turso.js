/** Import verified novel practice questions into Turso without storing a local database. */
require('dotenv').config();
const fs = require('fs');
const { PrismaClient } = require('@prisma/client');
const { PrismaLibSQL } = require('@prisma/adapter-libsql');

const source = process.argv[2];
if (!source || !process.env.TURSO_URL || !process.env.TURSO_AUTH_TOKEN) {
  console.error('Usage: node scripts/import-novel-practice-to-turso.js <prepared-json> (TURSO_URL and TURSO_AUTH_TOKEN required)');
  process.exit(1);
}
const data = JSON.parse(fs.readFileSync(source, 'utf8'));
const prisma = new PrismaClient({ adapter: new PrismaLibSQL({
  url: process.env.TURSO_URL, authToken: process.env.TURSO_AUTH_TOKEN,
}) });

async function importMissing(model, entries, key) {
  const existing = new Set((await model.findMany({ select: { [key]: true } })).map(row => row[key]));
  const missing = entries.filter(row => !existing.has(row[key]));
  for (let index = 0; index < missing.length; index += 40) {
    await model.createMany({ data: missing.slice(index, index + 40) });
  }
  return missing.length;
}

async function main() {
  if (data.lessons.length !== 28 || data.questions.length !== 203 || data.papers.length !== 28) {
    throw new Error('Unexpected novel practice dataset size');
  }
  const articles = await prisma.readingArticle.findMany({ select: { id: true, paperId: true, questionCount: true } });
  if (articles.length !== 28) throw new Error('Reading articles must be imported first');
  for (const article of articles) {
    const paper = data.papers.find(item => item.id === article.paperId);
    if (!paper || paper.questionIds.length !== article.questionCount) throw new Error(`Question count mismatch: ${article.id}`);
  }
  const questions = data.questions.map(question => {
    const { filename, pdfPage, pdfSha256, sourceUrl, ...provenance } = question.provenance;
    return { ...question, provenance: { ...provenance, sourcePage: pdfPage } };
  });
  const explanations = data.explanations.map(explanation => ({
    ...explanation,
    note: explanation.note.replace(/^出处：.*? 第(\d+)页。/, '出处：原文第$1页。'),
  }));
  const papers = data.papers.map(paper => ({ ...paper, materialIds: [] }));
  const imported = {
    questions: await importMissing(prisma.question, questions, 'id'),
    explanations: await importMissing(prisma.explanation, explanations, 'questionId'),
    papers: await importMissing(prisma.funPaper, papers, 'id'),
  };
  console.log(JSON.stringify(imported));
}
main().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => prisma.$disconnect());
