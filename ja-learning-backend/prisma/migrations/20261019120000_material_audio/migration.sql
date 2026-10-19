CREATE TABLE "AudioAsset" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "title" TEXT NOT NULL,
  "filename" TEXT NOT NULL,
  "url" TEXT NOT NULL,
  "storageProvider" TEXT NOT NULL,
  "storageKey" TEXT,
  "mimeType" TEXT NOT NULL DEFAULT 'audio/mpeg',
  "sizeBytes" INTEGER,
  "durationSeconds" REAL,
  "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" DATETIME NOT NULL
);
CREATE UNIQUE INDEX "AudioAsset_filename_key" ON "AudioAsset"("filename");
CREATE TABLE "MaterialAudio" (
  "materialId" TEXT NOT NULL,
  "audioId" TEXT NOT NULL,
  "position" INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY ("materialId", "audioId"),
  FOREIGN KEY ("materialId") REFERENCES "StudyMaterial"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("audioId") REFERENCES "AudioAsset"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "MaterialAudio_audioId_idx" ON "MaterialAudio"("audioId");
