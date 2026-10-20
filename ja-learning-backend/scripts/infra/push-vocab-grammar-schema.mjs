import { createClient } from '@libsql/client';
import fs from 'node:fs';

const TURSO_URL = process.env.TURSO_URL;
const TURSO_AUTH_TOKEN = process.env.TURSO_AUTH_TOKEN;

if (!TURSO_URL || !TURSO_AUTH_TOKEN) {
  console.error('TURSO_URL and TURSO_AUTH_TOKEN must be set');
  process.exit(1);
}

const sql = `
CREATE TABLE "Vocabulary" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "word" TEXT NOT NULL,
    "reading" TEXT NOT NULL,
    "meaning" TEXT NOT NULL,
    "level" TEXT NOT NULL,
    "exampleSentences" JSONB NOT NULL DEFAULT '[]',
    "note" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
CREATE INDEX "Vocabulary_level_idx" ON "Vocabulary"("level");

CREATE TABLE "VocabularyRelation" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "fromVocabularyId" TEXT NOT NULL,
    "toVocabularyId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "VocabularyRelation_fromVocabularyId_fkey" FOREIGN KEY ("fromVocabularyId") REFERENCES "Vocabulary" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "VocabularyRelation_toVocabularyId_fkey" FOREIGN KEY ("toVocabularyId") REFERENCES "Vocabulary" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "VocabularyRelation_fromVocabularyId_idx" ON "VocabularyRelation"("fromVocabularyId");
CREATE INDEX "VocabularyRelation_toVocabularyId_idx" ON "VocabularyRelation"("toVocabularyId");
CREATE UNIQUE INDEX "VocabularyRelation_fromVocabularyId_toVocabularyId_type_key" ON "VocabularyRelation"("fromVocabularyId","toVocabularyId","type");

CREATE TABLE "Grammar" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "structure" TEXT NOT NULL,
    "meaning" TEXT NOT NULL,
    "level" TEXT NOT NULL,
    "usage" JSONB NOT NULL,
    "exampleSentences" JSONB NOT NULL DEFAULT '[]',
    "note" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
CREATE INDEX "Grammar_level_idx" ON "Grammar"("level");

CREATE TABLE "GrammarRelation" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "fromGrammarId" TEXT NOT NULL,
    "toGrammarId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "GrammarRelation_fromGrammarId_fkey" FOREIGN KEY ("fromGrammarId") REFERENCES "Grammar" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "GrammarRelation_toGrammarId_fkey" FOREIGN KEY ("toGrammarId") REFERENCES "Grammar" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "GrammarRelation_fromGrammarId_idx" ON "GrammarRelation"("fromGrammarId");
CREATE INDEX "GrammarRelation_toGrammarId_idx" ON "GrammarRelation"("toGrammarId");
CREATE UNIQUE INDEX "GrammarRelation_fromGrammarId_toGrammarId_type_key" ON "GrammarRelation"("fromGrammarId","toGrammarId","type");

ALTER TABLE "Question" ADD COLUMN "vocabularyId" TEXT;
ALTER TABLE "Question" ADD COLUMN "grammarId" TEXT;
`;

async function main() {
  const client = createClient({ url: TURSO_URL, authToken: TURSO_AUTH_TOKEN });
  const statements = sql.split(';').map(s => s.trim()).filter(s => s.length > 0);
  console.log(`Running ${statements.length} statements...`);

  for (let i = 0; i < statements.length; i++) {
    try {
      await client.execute({ sql: statements[i], args: [] });
      const preview = statements[i].split('\n')[0].slice(0, 80);
      console.log(`[${i+1}/${statements.length}] OK: ${preview}`);
    } catch (err) {
      // ALTER TABLE may fail if column already exists — that's fine
      console.log(`[${i+1}] SKIP/FAIL: ${err.message.slice(0, 120)}`);
    }
  }

  const tables = await client.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_prisma%' ORDER BY name");
  console.log('Tables:', tables.rows.map(r => r[0]));
  client.close();
}
main().catch(e => { console.error(e); process.exit(1); });
