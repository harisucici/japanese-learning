ALTER TABLE "LearningSession" ADD COLUMN "examConfig" JSONB;
CREATE TABLE "ExamPaper" (
 "id" TEXT PRIMARY KEY, "title" TEXT NOT NULL, "level" "JLPTLevel" NOT NULL,
 "kind" TEXT NOT NULL, "examYear" INTEGER, "examMonth" INTEGER,
 "ready" BOOLEAN NOT NULL DEFAULT false, "sections" JSONB NOT NULL,
 "materials" JSONB NOT NULL, "verificationNote" TEXT NOT NULL,
 "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,"updatedAt" TIMESTAMP(3) NOT NULL
);
