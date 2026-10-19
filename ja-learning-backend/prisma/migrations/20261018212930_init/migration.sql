-- CreateEnum
CREATE TYPE "JLPTLevel" AS ENUM ('n5', 'n4', 'n3', 'n2', 'n1');

-- CreateEnum
CREATE TYPE "QuestionType" AS ENUM ('vocabulary', 'kanji', 'grammar', 'reading', 'listening', 'fillInBlank', 'comprehensive');

-- CreateEnum
CREATE TYPE "QuestionSource" AS ENUM ('official', 'mock', 'textbook', 'userGenerated', 'aiGenerated', 'pastExam', 'custom');

-- CreateEnum
CREATE TYPE "ExamRecordType" AS ENUM ('practice', 'exam', 'review');

-- CreateEnum
CREATE TYPE "ReviewStatus" AS ENUM ('new_', 'learning', 'reviewing', 'mastered');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "currentLevel" "JLPTLevel" NOT NULL DEFAULT 'n5',
    "targetLevel" "JLPTLevel" NOT NULL DEFAULT 'n5',
    "avatarUrl" TEXT,
    "streakDays" INTEGER NOT NULL DEFAULT 0,
    "totalQuestions" INTEGER NOT NULL DEFAULT 0,
    "accuracy" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Question" (
    "id" TEXT NOT NULL,
    "level" "JLPTLevel" NOT NULL,
    "type" "QuestionType" NOT NULL,
    "content" TEXT NOT NULL,
    "contentReading" TEXT,
    "contentImageUrl" TEXT,
    "audioUrl" TEXT,
    "options" JSONB NOT NULL,
    "answer" TEXT NOT NULL,
    "source" "QuestionSource" NOT NULL DEFAULT 'official',
    "explanationId" TEXT NOT NULL,
    "tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "difficulty" DOUBLE PRECISION NOT NULL DEFAULT 0.5,
    "order" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Question_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Explanation" (
    "id" TEXT NOT NULL,
    "questionId" TEXT NOT NULL,
    "translation" TEXT NOT NULL,
    "wordAnalysis" JSONB NOT NULL DEFAULT '[]',
    "sentenceStructure" TEXT NOT NULL DEFAULT '',
    "grammar" JSONB NOT NULL DEFAULT '[]',
    "optionAnalysis" JSONB NOT NULL DEFAULT '[]',
    "extensions" JSONB NOT NULL DEFAULT '[]',
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Explanation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ExamRecord" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "level" "JLPTLevel" NOT NULL,
    "recordType" "ExamRecordType" NOT NULL,
    "questionIds" TEXT[],
    "answers" JSONB NOT NULL,
    "score" INTEGER NOT NULL DEFAULT 0,
    "totalQuestions" INTEGER NOT NULL,
    "correctCount" INTEGER NOT NULL DEFAULT 0,
    "durationMs" INTEGER NOT NULL,
    "completedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ExamRecord_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ReviewItem" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "questionId" TEXT NOT NULL,
    "level" "JLPTLevel" NOT NULL,
    "type" "QuestionType" NOT NULL,
    "status" "ReviewStatus" NOT NULL DEFAULT 'new_',
    "reviewCount" INTEGER NOT NULL DEFAULT 0,
    "nextReviewAt" TIMESTAMP(3),
    "easeFactor" DOUBLE PRECISION NOT NULL DEFAULT 2.5,
    "intervalDays" INTEGER NOT NULL DEFAULT 0,
    "isFavorite" BOOLEAN NOT NULL DEFAULT false,
    "isWrongAnswer" BOOLEAN NOT NULL DEFAULT false,
    "wrongCount" INTEGER NOT NULL DEFAULT 0,
    "correctStreak" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ReviewItem_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Explanation_questionId_key" ON "Explanation"("questionId");

-- CreateIndex
CREATE INDEX "ExamRecord_userId_idx" ON "ExamRecord"("userId");

-- CreateIndex
CREATE INDEX "ReviewItem_userId_nextReviewAt_idx" ON "ReviewItem"("userId", "nextReviewAt");

-- CreateIndex
CREATE UNIQUE INDEX "ReviewItem_userId_questionId_key" ON "ReviewItem"("userId", "questionId");

-- AddForeignKey
ALTER TABLE "ExamRecord" ADD CONSTRAINT "ExamRecord_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ReviewItem" ADD CONSTRAINT "ReviewItem_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ReviewItem" ADD CONSTRAINT "ReviewItem_questionId_fkey" FOREIGN KEY ("questionId") REFERENCES "Question"("id") ON DELETE CASCADE ON UPDATE CASCADE;
