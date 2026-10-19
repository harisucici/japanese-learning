# Local material library and fun practice

Imported user-provided documents for local personal study: 201 PDFs, 99 audio files, one video. Originals are copied unchanged with SHA256 checksums; no missing media is generated. Assets are served only by the loopback-bound backend at port 3002. Personal material files and import payload are excluded from Git.

`StudyMaterial` holds provenance, original filename, text status, Japanese text/translation when extracted, and original media links. Scanned PDFs remain available as originals without unverified OCR. The novel vocabulary PDF retains attribution and a note that annotations require review; it is not a verified JLPT vocabulary list.

Ten `FunPaper` collections reference 50 material-derived questions. Each question is `custom` / `ungraded`, stores an exact supporting quote and source PDF checksum/page, and has a Chinese explanation. These are authored practice questions, not official exam items. Official catalog selection remains restricted to verified official/pastExam sources (162 questions).

Routes: `/fun`, `/materials`, `/materials/:id`; APIs under `/api/v1/learning/`. Fun sessions use persisted first-answer locking, automatic advance for correct answers, explanation and manual advance for wrong answers, and percent final scores. They have no claimed JLPT exam timing or scaled score.

Import: `node scripts/import-material-fun.js` (local payload required; validates checksums and source quotes; idempotent upserts). Check: `node scripts/check-material-fun-flow.js`; dedicated test account is removed afterward.
