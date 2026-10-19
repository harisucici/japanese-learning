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
