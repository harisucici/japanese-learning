CREATE TABLE "_prisma_migrations" (
    "id"                    TEXT PRIMARY KEY NOT NULL,
    "checksum"              TEXT NOT NULL,
    "finished_at"           DATETIME,
    "migration_name"        TEXT NOT NULL,
    "logs"                  TEXT,
    "rolled_back_at"        DATETIME,
    "started_at"            DATETIME NOT NULL DEFAULT current_timestamp,
    "applied_steps_count"   INTEGER UNSIGNED NOT NULL DEFAULT 0
);
CREATE TABLE "Explanation" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "questionId" TEXT NOT NULL,
    "translation" TEXT NOT NULL,
    "wordAnalysis" JSONB NOT NULL DEFAULT [],
    "sentenceStructure" TEXT NOT NULL DEFAULT '',
    "grammar" JSONB NOT NULL DEFAULT [],
    "optionAnalysis" JSONB NOT NULL DEFAULT [],
    "extensions" JSONB NOT NULL DEFAULT [],
    "note" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
CREATE TABLE "LearningAnswer" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "sessionId" TEXT NOT NULL,
    "questionId" TEXT NOT NULL,
    "selectedOptionId" TEXT NOT NULL,
    "isCorrect" BOOLEAN NOT NULL,
    "answeredAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "LearningAnswer_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "LearningSession" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "LearningAnswer_questionId_fkey" FOREIGN KEY ("questionId") REFERENCES "Question" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE TABLE "ExamPaper" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "level" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "examYear" INTEGER,
    "examMonth" INTEGER,
    "ready" BOOLEAN NOT NULL DEFAULT false,
    "sections" JSONB NOT NULL,
    "materials" JSONB NOT NULL,
    "verificationNote" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
CREATE TABLE "FunPaper" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "theme" TEXT NOT NULL,
    "questionIds" JSONB NOT NULL,
    "materialIds" JSONB NOT NULL,
    "published" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
CREATE UNIQUE INDEX "Explanation_questionId_key" ON "Explanation"("questionId");
CREATE INDEX "LearningAnswer_sessionId_idx" ON "LearningAnswer"("sessionId");
CREATE UNIQUE INDEX "LearningAnswer_sessionId_questionId_key" ON "LearningAnswer"("sessionId", "questionId");
CREATE TABLE "ReadingArticle" (
 "id" TEXT NOT NULL PRIMARY KEY,
 "title" TEXT NOT NULL,
 "category" TEXT NOT NULL,
 "position" INTEGER NOT NULL,
 "startPage" INTEGER NOT NULL,
 "endPage" INTEGER NOT NULL,
 "pages" JSONB NOT NULL,
 "vocabulary" JSONB NOT NULL,
 "note" TEXT NOT NULL,
 "materialId" TEXT NOT NULL,
 "paperId" TEXT NOT NULL,
 "questionCount" INTEGER NOT NULL DEFAULT 0,
 "published" BOOLEAN NOT NULL DEFAULT false,
 "sourceTitle" TEXT,
 "sourcePages" INTEGER NOT NULL DEFAULT 0,
 "attribution" TEXT,
 "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 "updatedAt" DATETIME NOT NULL
);
CREATE INDEX "ReadingArticle_position_idx" ON "ReadingArticle"("position");
CREATE TABLE "AnonymousLearner" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
CREATE TABLE "ArticleAudio" (
    "materialId" TEXT NOT NULL,
    "audioId" TEXT NOT NULL,
    "position" INTEGER NOT NULL DEFAULT 0,

    PRIMARY KEY ("materialId", "audioId"),
    CONSTRAINT "ArticleAudio_materialId_fkey" FOREIGN KEY ("materialId") REFERENCES "StudyMaterial" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
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
CREATE TABLE "VocabularyRelation" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "fromVocabularyId" TEXT NOT NULL,
    "toVocabularyId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "VocabularyRelation_fromVocabularyId_fkey" FOREIGN KEY ("fromVocabularyId") REFERENCES "Vocabulary" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "VocabularyRelation_toVocabularyId_fkey" FOREIGN KEY ("toVocabularyId") REFERENCES "Vocabulary" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
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
CREATE TABLE "GrammarRelation" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "fromGrammarId" TEXT NOT NULL,
    "toGrammarId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "GrammarRelation_fromGrammarId_fkey" FOREIGN KEY ("fromGrammarId") REFERENCES "Grammar" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "GrammarRelation_toGrammarId_fkey" FOREIGN KEY ("toGrammarId") REFERENCES "Grammar" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE "ExamRecord" (
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
CREATE INDEX "ExamRecord_userId_idx" ON "ExamRecord"("userId");
CREATE INDEX "ExamRecord_userId_createdAt_idx" ON "ExamRecord"("userId", "createdAt");
CREATE TABLE "LearningSession" (
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
CREATE INDEX "LearningSession_userId_createdAt_idx" ON "LearningSession"("userId", "createdAt");
CREATE TABLE "Question" (
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
CREATE TABLE "ReviewItem" (
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
CREATE INDEX "ReviewItem_userId_nextReviewAt_idx" ON "ReviewItem"("userId", "nextReviewAt");
CREATE INDEX "ReviewItem_userId_status_idx" ON "ReviewItem"("userId", "status");
CREATE UNIQUE INDEX "ReviewItem_userId_questionId_key" ON "ReviewItem"("userId", "questionId");
CREATE TABLE "StudyMaterial" (
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
CREATE UNIQUE INDEX "ArticleAudio_audioId_key" ON "ArticleAudio"("audioId");
CREATE INDEX "Vocabulary_level_idx" ON "Vocabulary"("level");
CREATE INDEX "VocabularyRelation_fromVocabularyId_idx" ON "VocabularyRelation"("fromVocabularyId");
CREATE INDEX "VocabularyRelation_toVocabularyId_idx" ON "VocabularyRelation"("toVocabularyId");
CREATE UNIQUE INDEX "VocabularyRelation_fromVocabularyId_toVocabularyId_type_key" ON "VocabularyRelation"("fromVocabularyId", "toVocabularyId", "type");
CREATE INDEX "Grammar_level_idx" ON "Grammar"("level");
CREATE INDEX "GrammarRelation_fromGrammarId_idx" ON "GrammarRelation"("fromGrammarId");
CREATE INDEX "GrammarRelation_toGrammarId_idx" ON "GrammarRelation"("toGrammarId");
CREATE UNIQUE INDEX "GrammarRelation_fromGrammarId_toGrammarId_type_key" ON "GrammarRelation"("fromGrammarId", "toGrammarId", "type");
