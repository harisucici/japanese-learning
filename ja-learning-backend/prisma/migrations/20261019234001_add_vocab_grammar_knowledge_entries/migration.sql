/*
  Warnings:

  - You are about to drop the `AudioAsset` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `MaterialAudio` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `NovelLesson` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `User` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the column `audioUrl` on the `Question` table. All the data in the column will be lost.
  - You are about to drop the column `contentImageUrl` on the `Question` table. All the data in the column will be lost.
  - You are about to drop the column `audioUrl` on the `StudyMaterial` table. All the data in the column will be lost.
  - You are about to drop the column `fileUrl` on the `StudyMaterial` table. All the data in the column will be lost.
  - You are about to drop the column `filename` on the `StudyMaterial` table. All the data in the column will be lost.
  - You are about to drop the column `pages` on the `StudyMaterial` table. All the data in the column will be lost.
  - You are about to drop the column `sha256` on the `StudyMaterial` table. All the data in the column will be lost.
  - You are about to drop the column `videoUrl` on the `StudyMaterial` table. All the data in the column will be lost.

*/
-- DropIndex
DROP INDEX "AudioAsset_filename_key";

-- DropIndex
DROP INDEX "MaterialAudio_audioId_idx";

-- DropIndex
DROP INDEX "NovelLesson_paperId_key";

-- DropIndex
DROP INDEX "User_email_key";

-- DropTable
PRAGMA foreign_keys=off;
DROP TABLE "AudioAsset";
PRAGMA foreign_keys=on;

-- DropTable
PRAGMA foreign_keys=off;
DROP TABLE "MaterialAudio";
PRAGMA foreign_keys=on;

-- DropTable
PRAGMA foreign_keys=off;
DROP TABLE "NovelLesson";
PRAGMA foreign_keys=on;

-- DropTable
PRAGMA foreign_keys=off;
DROP TABLE "User";
PRAGMA foreign_keys=on;

-- CreateTable
CREATE TABLE "AnonymousLearner" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "ArticleAudio" (
    "materialId" TEXT NOT NULL,
    "audioId" TEXT NOT NULL,
    "position" INTEGER NOT NULL DEFAULT 0,

    PRIMARY KEY ("materialId", "audioId"),
    CONSTRAINT "ArticleAudio_materialId_fkey" FOREIGN KEY ("materialId") REFERENCES "StudyMaterial" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Vocabulary" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "word" TEXT NOT NULL,
    "reading" TEXT NOT NULL,
    "meaning" TEXT NOT NULL,
    "level" TEXT NOT NULL,
    "exampleSentences" JSONB NOT NULL DEFAULT [],
    "note" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "VocabularyRelation" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "fromVocabularyId" TEXT NOT NULL,
    "toVocabularyId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "VocabularyRelation_fromVocabularyId_fkey" FOREIGN KEY ("fromVocabularyId") REFERENCES "Vocabulary" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "VocabularyRelation_toVocabularyId_fkey" FOREIGN KEY ("toVocabularyId") REFERENCES "Vocabulary" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Grammar" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "structure" TEXT NOT NULL,
    "meaning" TEXT NOT NULL,
    "level" TEXT NOT NULL,
    "usage" JSONB NOT NULL,
    "exampleSentences" JSONB NOT NULL DEFAULT [],
    "note" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "GrammarRelation" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "fromGrammarId" TEXT NOT NULL,
    "toGrammarId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "GrammarRelation_fromGrammarId_fkey" FOREIGN KEY ("fromGrammarId") REFERENCES "Grammar" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "GrammarRelation_toGrammarId_fkey" FOREIGN KEY ("toGrammarId") REFERENCES "Grammar" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_ExamRecord" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "level" TEXT NOT NULL,
    "recordType" TEXT NOT NULL,
    "questionIds" JSONB NOT NULL,
    "answers" JSONB NOT NULL,
    "score" INTEGER NOT NULL DEFAULT 0,
    "totalQuestions" INTEGER NOT NULL,
    "correctCount" INTEGER NOT NULL DEFAULT 0,
    "durationMs" INTEGER NOT NULL,
    "completedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ExamRecord_userId_fkey" FOREIGN KEY ("userId") REFERENCES "AnonymousLearner" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO "new_ExamRecord" ("answers", "completedAt", "correctCount", "createdAt", "durationMs", "id", "level", "questionIds", "recordType", "score", "totalQuestions", "userId") SELECT "answers", "completedAt", "correctCount", "createdAt", "durationMs", "id", "level", "questionIds", "recordType", "score", "totalQuestions", "userId" FROM "ExamRecord";
DROP TABLE "ExamRecord";
ALTER TABLE "new_ExamRecord" RENAME TO "ExamRecord";
CREATE INDEX "ExamRecord_userId_idx" ON "ExamRecord"("userId");
CREATE INDEX "ExamRecord_userId_createdAt_idx" ON "ExamRecord"("userId", "createdAt");
CREATE TABLE "new_LearningSession" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "level" TEXT NOT NULL,
    "mode" TEXT NOT NULL DEFAULT 'practice',
    "examConfig" JSONB,
    "collectionId" TEXT,
    "questionIds" JSONB NOT NULL,
    "currentIndex" INTEGER NOT NULL DEFAULT 0,
    "awaitingNext" BOOLEAN NOT NULL DEFAULT false,
    "completedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "LearningSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "AnonymousLearner" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO "new_LearningSession" ("awaitingNext", "collectionId", "completedAt", "createdAt", "currentIndex", "examConfig", "id", "level", "mode", "questionIds", "updatedAt", "userId") SELECT "awaitingNext", "collectionId", "completedAt", "createdAt", "currentIndex", "examConfig", "id", "level", "mode", "questionIds", "updatedAt", "userId" FROM "LearningSession";
DROP TABLE "LearningSession";
ALTER TABLE "new_LearningSession" RENAME TO "LearningSession";
CREATE INDEX "LearningSession_userId_createdAt_idx" ON "LearningSession"("userId", "createdAt");
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
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Question_vocabularyId_fkey" FOREIGN KEY ("vocabularyId") REFERENCES "Vocabulary" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Question_grammarId_fkey" FOREIGN KEY ("grammarId") REFERENCES "Grammar" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "new_Question" ("answer", "content", "contentReading", "createdAt", "difficulty", "explanationId", "id", "level", "options", "order", "provenance", "source", "tags", "type", "updatedAt") SELECT "answer", "content", "contentReading", "createdAt", "difficulty", "explanationId", "id", "level", "options", "order", "provenance", "source", "tags", "type", "updatedAt" FROM "Question";
DROP TABLE "Question";
ALTER TABLE "new_Question" RENAME TO "Question";
CREATE TABLE "new_ReviewItem" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "questionId" TEXT NOT NULL,
    "level" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'new_',
    "reviewCount" INTEGER NOT NULL DEFAULT 0,
    "nextReviewAt" DATETIME,
    "easeFactor" REAL NOT NULL DEFAULT 2.5,
    "intervalDays" INTEGER NOT NULL DEFAULT 0,
    "isFavorite" BOOLEAN NOT NULL DEFAULT false,
    "isWrongAnswer" BOOLEAN NOT NULL DEFAULT false,
    "wrongCount" INTEGER NOT NULL DEFAULT 0,
    "correctStreak" INTEGER NOT NULL DEFAULT 0,
    "lastCorrectAt" DATETIME,
    "reviewMode" TEXT NOT NULL DEFAULT 'original',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "ReviewItem_userId_fkey" FOREIGN KEY ("userId") REFERENCES "AnonymousLearner" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "ReviewItem_questionId_fkey" FOREIGN KEY ("questionId") REFERENCES "Question" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO "new_ReviewItem" ("correctStreak", "createdAt", "easeFactor", "id", "intervalDays", "isFavorite", "isWrongAnswer", "level", "nextReviewAt", "questionId", "reviewCount", "status", "type", "updatedAt", "userId", "wrongCount") SELECT "correctStreak", "createdAt", "easeFactor", "id", "intervalDays", "isFavorite", "isWrongAnswer", "level", "nextReviewAt", "questionId", "reviewCount", "status", "type", "updatedAt", "userId", "wrongCount" FROM "ReviewItem";
DROP TABLE "ReviewItem";
ALTER TABLE "new_ReviewItem" RENAME TO "ReviewItem";
CREATE INDEX "ReviewItem_userId_nextReviewAt_idx" ON "ReviewItem"("userId", "nextReviewAt");
CREATE INDEX "ReviewItem_userId_status_idx" ON "ReviewItem"("userId", "status");
CREATE UNIQUE INDEX "ReviewItem_userId_questionId_key" ON "ReviewItem"("userId", "questionId");
CREATE TABLE "new_StudyMaterial" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "collection" TEXT NOT NULL,
    "japanese" TEXT,
    "translation" TEXT,
    "textStatus" TEXT NOT NULL,
    "metadata" JSONB NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
INSERT INTO "new_StudyMaterial" ("collection", "createdAt", "id", "japanese", "metadata", "textStatus", "title", "translation", "updatedAt") SELECT "collection", "createdAt", "id", "japanese", "metadata", "textStatus", "title", "translation", "updatedAt" FROM "StudyMaterial";
DROP TABLE "StudyMaterial";
ALTER TABLE "new_StudyMaterial" RENAME TO "StudyMaterial";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;

-- CreateIndex
CREATE UNIQUE INDEX "ArticleAudio_audioId_key" ON "ArticleAudio"("audioId");

-- CreateIndex
CREATE INDEX "Vocabulary_level_idx" ON "Vocabulary"("level");

-- CreateIndex
CREATE INDEX "VocabularyRelation_fromVocabularyId_idx" ON "VocabularyRelation"("fromVocabularyId");

-- CreateIndex
CREATE INDEX "VocabularyRelation_toVocabularyId_idx" ON "VocabularyRelation"("toVocabularyId");

-- CreateIndex
CREATE UNIQUE INDEX "VocabularyRelation_fromVocabularyId_toVocabularyId_type_key" ON "VocabularyRelation"("fromVocabularyId", "toVocabularyId", "type");

-- CreateIndex
CREATE INDEX "Grammar_level_idx" ON "Grammar"("level");

-- CreateIndex
CREATE INDEX "GrammarRelation_fromGrammarId_idx" ON "GrammarRelation"("fromGrammarId");

-- CreateIndex
CREATE INDEX "GrammarRelation_toGrammarId_idx" ON "GrammarRelation"("toGrammarId");

-- CreateIndex
CREATE UNIQUE INDEX "GrammarRelation_fromGrammarId_toGrammarId_type_key" ON "GrammarRelation"("fromGrammarId", "toGrammarId", "type");
