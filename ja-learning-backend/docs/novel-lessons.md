# Novel vocabulary board

`/novel` is independent from official JLPT and the ten short-text fun papers. It provides the supplied PDF's 28 source sections (12 long stories, ten compound-verb sections and six adverb sections), spanning source pages 2–297. The contents page and final publisher notice remain in the original PDF. Long stories include the original recall versions where present. Image-based short stories have original page renders so image text is not silently lost.

203 custom, ungraded questions train literal source recall or matching the supplied annotation table. They do not certify N1 vocabulary, dictionary definitions or the mixed-language sentences as correct Japanese. Source authorship, PDF hash, exact page, passage and supporting quote are retained. Unverified source readings are not turned into reading questions.

`NovelLesson` links the source `StudyMaterial` to one `FunPaper` per chapter and stores pages/word cards as JSON. The existing immutable-answer and scoring flow handles exercises. GET `/api/v1/learning/novel-lessons` returns database-backed counts and GET `/novel-lessons/:id` returns the actual chapter. Novel papers are excluded from the separate short-text fun catalog; history keeps their title.

Prepare local payload with `scripts/prepare-novel-lessons.py` using the PDF runtime (pdfplumber/Pillow). Import with `node scripts/import-novel-lessons.js`; repeated imports use stable IDs and do not add duplicates. Run `node scripts/check-novel-flow.js` to check all chapter boundaries/source quotes and persisted answer/score behavior. The portable database exporter automatically includes the new table, relations and page images.

## Inline reading format

The supplied reading/gloss annotations are stored in `NovelLesson.pages[].readingTokens` as separate word, reading and meaning fields, with `sourceText` retaining the exact original span. Plain tokens retain the original text. Concatenating sourceText/plain text reconstructs the original page exactly. The first extraction contains 725 occurrences across 124 original reading pages; recall pages retain their blanks and image pages retain original images. Source readings and annotations remain attributed to the source rather than independently certified dictionary entries.

`node scripts/format-novel-reading.js` applies the local `data/novel-annotations.json` payload to the database and the import payload. Run after preparing/reimporting lessons if the payload was regenerated. The frontend renders ruby inline and opens the translation beside its word, with screen-edge clamping and dismissal on outside tap, repeat tap, scroll and reader disposal.
