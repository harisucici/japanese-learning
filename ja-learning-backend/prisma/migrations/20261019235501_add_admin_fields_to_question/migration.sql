-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Question" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "level" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "contentReading" TEXT,
    "options" JSONB NOT NULL,
    "answer" TEXT NOT NULL,
    "source" TEXT NOT NULL DEFAULT 'official',
    "provenance" JSONB,
    "explanationId" TEXT NOT NULL,
    "tags" JSONB NOT NULL DEFAULT [],
    "difficulty" REAL NOT NULL DEFAULT 0.5,
    "order" INTEGER NOT NULL DEFAULT 0,
    "vocabularyId" TEXT,
    "grammarId" TEXT,
    "status" TEXT NOT NULL DEFAULT 'draft',
    "importedAt" DATETIME,
    "publishedAt" DATETIME,
    "deletedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Question_vocabularyId_fkey" FOREIGN KEY ("vocabularyId") REFERENCES "Vocabulary" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Question_grammarId_fkey" FOREIGN KEY ("grammarId") REFERENCES "Grammar" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "new_Question" ("answer", "content", "contentReading", "createdAt", "difficulty", "explanationId", "grammarId", "id", "level", "options", "order", "provenance", "source", "tags", "type", "updatedAt", "vocabularyId") SELECT "answer", "content", "contentReading", "createdAt", "difficulty", "explanationId", "grammarId", "id", "level", "options", "order", "provenance", "source", "tags", "type", "updatedAt", "vocabularyId" FROM "Question";
DROP TABLE "Question";
ALTER TABLE "new_Question" RENAME TO "Question";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
