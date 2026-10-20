/** Restore the original fun papers and article text to Turso from a read-only export. */
require('dotenv').config();
const { execFileSync } = require('node:child_process');
const path = require('node:path');
const { PrismaClient } = require('@prisma/client');
const { PrismaLibSQL } = require('@prisma/adapter-libsql');

const source = process.argv[2];
if (!source || !process.env.TURSO_URL || !process.env.TURSO_AUTH_TOKEN) {
  console.error('Usage: node scripts/import/import-fun-from-sqlite-to-turso.js <historical-sqlite-export>');
  process.exit(1);
}
const data = JSON.parse(execFileSync('python3', [path.join(__dirname, 'export-fun-source.py'), source], {
  encoding: 'utf8', maxBuffer: 16 * 1024 * 1024,
}));
const prisma = new PrismaClient({ adapter: new PrismaLibSQL({
  url: process.env.TURSO_URL, authToken: process.env.TURSO_AUTH_TOKEN,
}) });

const parse = value => JSON.parse(value);
const materialId = sourceId => {
  const match = /^short-(\d{3})-[a-f0-9]+$/.exec(sourceId);
  if (!match) throw new Error(`Unexpected source material: ${sourceId}`);
  return `material-${String(Number(match[1]) + 100).padStart(3, '0')}`;
};
const fields = (row, names) => Object.fromEntries(names.map(name => [name, row[name]]));

async function importMissing(model, entries, key) {
  const existing = new Set((await model.findMany({ select: { [key]: true } })).map(row => row[key]));
  const missing = entries.filter(row => !existing.has(row[key]));
  for (let index = 0; index < missing.length; index += 40) {
    await model.createMany({ data: missing.slice(index, index + 40) });
  }
  return missing.length;
}

async function main() {
  if (data.materials.length !== 100 || data.papers.length !== 10 ||
      data.questions.length !== 50 || data.explanations.length !== 50) {
    throw new Error('Unexpected fun source dataset size');
  }
  const targetIds = data.materials.map(row => materialId(row.id));
  const targets = await prisma.studyMaterial.findMany({
    where: { id: { in: targetIds } }, select: { id: true },
  });
  if (targets.length !== 100 || new Set(targetIds).size !== 100) {
    throw new Error('The 100 audio materials must already exist in Turso');
  }

  const questions = data.questions.map(row => {
    const provenance = parse(row.provenance);
    const { filename, pdfPage, pdfSha256, sourceUrl, ...safeProvenance } = provenance;
    const options = parse(row.options);
    if (!options.some(option => option.id === row.answer) ||
        !provenance.passage?.includes(provenance.supportingQuote)) {
      throw new Error(`Invalid source question: ${row.id}`);
    }
    return {
      ...fields(row, ['id', 'level', 'type', 'content', 'contentReading',
        'answer', 'source', 'explanationId', 'difficulty', 'order']),
      options, tags: parse(row.tags),
      provenance: { ...safeProvenance, materialId: materialId(provenance.materialId), sourcePage: pdfPage },
    };
  });
  const explanations = data.explanations.map(row => ({
    ...fields(row, ['id', 'questionId', 'translation', 'sentenceStructure']),
    wordAnalysis: parse(row.wordAnalysis), grammar: parse(row.grammar),
    optionAnalysis: parse(row.optionAnalysis), extensions: parse(row.extensions),
    note: row.note?.replace(/出处：.*?\.pdf 第(\d+)页。/, '出处：原文第$1页。') ?? null,
  }));
  const papers = data.papers.map(row => ({
    ...fields(row, ['id', 'title', 'description', 'theme']),
    questionIds: parse(row.questionIds), materialIds: parse(row.materialIds).map(materialId),
    published: Boolean(row.published),
  }));
  const questionIds = new Set(questions.map(row => row.id));
  for (const paper of papers) {
    if (paper.questionIds.length !== 5 || paper.materialIds.length !== 1 ||
        paper.questionIds.some(id => !questionIds.has(id))) {
      throw new Error(`Invalid source paper: ${paper.id}`);
    }
  }

  for (const row of data.materials) {
    await prisma.studyMaterial.update({
      where: { id: materialId(row.id) },
      data: { title: row.title, japanese: row.japanese, translation: row.translation,
        textStatus: 'text_extracted' },
    });
  }
  const imported = {
    articleTexts: data.materials.length,
    questions: await importMissing(prisma.question, questions, 'id'),
    explanations: await importMissing(prisma.explanation, explanations, 'questionId'),
    papers: await importMissing(prisma.funPaper, papers, 'id'),
  };
  console.log(JSON.stringify(imported));
}
main().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => prisma.$disconnect());
