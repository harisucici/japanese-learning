ALTER TYPE "JLPTLevel" ADD VALUE 'ungraded';
ALTER TABLE "LearningSession" ADD COLUMN "collectionId" TEXT;
CREATE TABLE "StudyMaterial" (
 "id" TEXT PRIMARY KEY,"title" TEXT NOT NULL,"collection" TEXT NOT NULL,"filename" TEXT NOT NULL,"pages" INTEGER NOT NULL,
 "sha256" TEXT NOT NULL,"fileUrl" TEXT NOT NULL,"audioUrl" TEXT,"videoUrl" TEXT,"japanese" TEXT,"translation" TEXT,"textStatus" TEXT NOT NULL,
 "metadata" JSONB NOT NULL,"createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,"updatedAt" TIMESTAMP(3) NOT NULL
);
CREATE TABLE "FunPaper" (
 "id" TEXT PRIMARY KEY,"title" TEXT NOT NULL,"description" TEXT NOT NULL,"theme" TEXT NOT NULL,"questionIds" TEXT[] NOT NULL,"materialIds" TEXT[] NOT NULL,
 "published" BOOLEAN NOT NULL DEFAULT false,"createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,"updatedAt" TIMESTAMP(3) NOT NULL
);
