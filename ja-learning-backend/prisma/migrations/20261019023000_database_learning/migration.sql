CREATE TABLE "LearningSession" (
 "id" TEXT PRIMARY KEY, "userId" TEXT NOT NULL REFERENCES "User"("id") ON DELETE CASCADE,
 "level" "JLPTLevel" NOT NULL, "mode" TEXT NOT NULL DEFAULT 'practice', "questionIds" TEXT[] NOT NULL,
 "currentIndex" INTEGER NOT NULL DEFAULT 0, "awaitingNext" BOOLEAN NOT NULL DEFAULT false,
 "completedAt" TIMESTAMP(3), "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 "updatedAt" TIMESTAMP(3) NOT NULL
);
CREATE TABLE "LearningAnswer" (
 "id" TEXT PRIMARY KEY, "sessionId" TEXT NOT NULL REFERENCES "LearningSession"("id") ON DELETE CASCADE,
 "questionId" TEXT NOT NULL REFERENCES "Question"("id") ON DELETE RESTRICT,
 "selectedOptionId" TEXT NOT NULL, "isCorrect" BOOLEAN NOT NULL,
 "answeredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX "LearningAnswer_sessionId_questionId_key" ON "LearningAnswer"("sessionId","questionId");
CREATE INDEX "LearningAnswer_sessionId_idx" ON "LearningAnswer"("sessionId");
CREATE INDEX "LearningSession_userId_createdAt_idx" ON "LearningSession"("userId","createdAt");
