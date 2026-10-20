#!/usr/bin/env node
/**
 * 将 PDF 解析的 JSON 数据转换为 Turso ReadingArticle 格式
 *
 * 输入：data/novel-reading-articles.json
 * 输出：data/reading-articles-turso-format.json
 *
 * 核心思路：以 vocabulary 列表为「标注真相」，在每页文本中定位词+读音（允许跨一行 \n），
 * 由此生成 readingTokens；excerpt 从包含该词的原始行中抽取整句上下文。
 */

const fs = require('fs');
const path = require('path');

const inputPath = path.join(__dirname, '..', 'data', 'novel-reading-articles.json');
const outputPath = path.join(__dirname, '..', 'data', 'reading-articles-turso-format.json');

console.log('Reading input file:', inputPath);
const inputData = JSON.parse(fs.readFileSync(inputPath, 'utf-8'));
console.log(`Found ${inputData.articles.length} articles`);

// ---------- 字符分类 ----------
function isHiragana(ch) {
  const c = ch.charCodeAt(0);
  return c >= 0x3040 && c <= 0x309f;
}
function isKatakana(ch) {
  const c = ch.charCodeAt(0);
  return c >= 0x30a0 && c <= 0x30ff;
}
function isKana(ch) {
  return isHiragana(ch) || isKatakana(ch);
}
function isCJK(ch) {
  const c = ch.charCodeAt(0);
  // CJK Unified Ideographs + Extension A
  return (c >= 0x4e00 && c <= 0x9fff) || (c >= 0x3400 && c <= 0x4dbf);
}
function isJapanese(ch) {
  return isHiragana(ch) || isKatakana(ch) || isCJK(ch);
}

// ---------- 转义 ----------
function escapeRegExp(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * 在 text 中找出所有 vocabulary 标注的位置（基于 vocabulary 列表，而不是启发式）。
 *
 * 返回一个数组：[{start, end, word, reading, meaning, sourceText, lineIdx}]
 *  - start/end 是字符位置（基于 text，text 是 lines 用 '\n' join 而成）
 *  - meaning 是读音后紧随的 CJK 字符（可能为空）
 *
 * 同一位置被多个词命中时，按"最早开始 + 最长匹配"去重。
 */
function findAnnotations(text, lines, vocab) {
  // 预计算：每个 line 起始字符在 text 中的偏移
  const lineOffsets = [];
  let acc = 0;
  for (const line of lines) {
    lineOffsets.push(acc);
    acc += line.length + 1; // +1 为 '\n'
  }

  const hits = [];

  for (const v of vocab) {
    if (!v || !v.word || !v.reading) continue;
    const word = v.word;
    const reading = v.reading;

    // 在 text 中查找所有 word 出现
    const re = new RegExp(escapeRegExp(word), 'g');
    let m;
    while ((m = re.exec(text)) !== null) {
      const wordStart = m.index;
      const afterWord = wordStart + word.length;
      const afterText = text.slice(afterWord);

      // 读音匹配：允许读音中出现 1 个 \n（PDF 折行）
      // 策略：把 afterText 前 (reading.length + 2) 字符中所有的 \n 去掉，再比较前 reading.length 个字符
      const window = afterText.slice(0, reading.length + 2); // 宽松一点
      const collapsed = window.replace(/\n/g, '');
      if (!collapsed.startsWith(reading)) continue;

      // 计算匹配的"原文长度"（包含被跳过的 \n）
      let consumed = 0;
      let matchedReading = 0;
      while (matchedReading < reading.length && consumed < afterText.length) {
        const ch = afterText[consumed];
        if (ch === '\n') {
          consumed++;
          continue;
        }
        if (ch !== reading[matchedReading]) break;
        consumed++;
        matchedReading++;
      }
      if (matchedReading !== reading.length) continue;

      const readingEnd = afterWord + consumed; // 读音结束位置（在 text 中）

      // 读音后面紧接着的 CJK 字符即中文释义（最多取一段连续 CJK）
      let meaningStart = readingEnd;
      // 跳过单个 \n（如果释义在下一行开头）
      if (text[meaningStart] === '\n') meaningStart++;
      let meaningEnd = meaningStart;
      while (meaningEnd < text.length && isCJK(text[meaningEnd])) {
        meaningEnd++;
      }
      const meaning = text.slice(meaningStart, meaningEnd);

      const sourceText = text.slice(wordStart, meaningEnd);

      // 找到所在行号
      let lineIdx = 0;
      for (let i = 0; i < lineOffsets.length; i++) {
        if (lineOffsets[i] <= wordStart) lineIdx = i;
        else break;
      }

      hits.push({
        start: wordStart,
        end: meaningEnd,
        word,
        reading,
        meaning,
        sourceText,
        lineIdx,
      });
    }
  }

  // 去重：按词分组，对同一词的多个匹配按 start 升序后取最长/最早
  // （不同词的 annotation 即使位置重叠也应保留）
  const byWord = new Map();
  for (const h of hits) {
    if (!byWord.has(h.word)) byWord.set(h.word, []);
    byWord.get(h.word).push(h);
  }
  const deduped = [];
  for (const [word, wordHits] of byWord.entries()) {
    wordHits.sort((a, b) => a.start - b.start || (b.end - b.start) - (a.end - a.start));
    const perWord = [];
    for (const h of wordHits) {
      const last = perWord[perWord.length - 1];
      if (last && h.start < last.end) {
        // 同一词的重叠匹配，保留更长的
        if (h.end - h.start > last.end - last.start) {
          perWord[perWord.length - 1] = h;
        }
        continue;
      }
      perWord.push(h);
    }
    deduped.push(...perWord);
  }
  // 按位置排序最终结果
  deduped.sort((a, b) => a.start - b.start);

  return deduped;
}

/**
 * 根据标注位置，将一页 text 切分为 readingTokens：
 *  - 普通文本段 -> { text }
 *  - 标注段 -> { word, status: 'source_annotation', meaning, reading, sourceText }
 */
function buildReadingTokens(text, annotations) {
  const tokens = [];
  let cursor = 0;
  for (const a of annotations) {
    if (a.start > cursor) {
      tokens.push({ text: text.slice(cursor, a.start) });
    }
    tokens.push({
      word: a.word,
      status: 'source_annotation',
      meaning: a.meaning,
      reading: a.reading,
      sourceText: a.sourceText,
    });
    cursor = a.end;
  }
  if (cursor < text.length) {
    tokens.push({ text: text.slice(cursor) });
  }
  return tokens;
}

/**
 * 从原始 lines 中抽取包含 word 的句子作为 excerpt。
 * 句子边界：中文句号 / ！/ ？/ 换行；返回首个匹配行内完整句子。
 * 若单行句子太短（< 20 字符）且下一页首行以相同句子继续，则合并。
 */
function extractExcerpt(lines, word) {
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const idx = line.indexOf(word);
    if (idx < 0) continue;

    // 向左右扩展到句子边界
    const sentenceEnds = /[。！？]/;
    let start = idx;
    while (start > 0 && !sentenceEnds.test(line[start - 1])) start--;
    let end = idx + word.length;
    while (end < line.length && !sentenceEnds.test(line[end])) end++;
    if (end < line.length && sentenceEnds.test(line[end])) end++; // 包含终止符

    let excerpt = line.slice(start, end).trim();

    // 如果本行句子没有结束标点且下一行还在继续，合并下一行到下一个句子结束
    if (!sentenceEnds.test(line[line.length - 1]) && i + 1 < lines.length) {
      const nextLine = lines[i + 1];
      let ne = 0;
      while (ne < nextLine.length && !sentenceEnds.test(nextLine[ne])) ne++;
      if (ne < nextLine.length) ne++; // 包含终止符
      if (ne > 0) {
        excerpt = excerpt + nextLine.slice(0, ne);
      }
    }

    // 截断过长的 excerpt（上限 200 字符，避免把整段都吞进来）
    if (excerpt.length > 200) {
      excerpt = excerpt.slice(0, 200);
    }

    return excerpt;
  }
  return '';
}

/**
 * 找出 vocabulary 中每个词首次出现的页面（按 pageNumber）
 */
function findSourcePage(pages, word) {
  for (const p of pages) {
    for (const line of p.lines) {
      if (line.includes(word)) return p.pageNumber;
    }
  }
  return null;
}

/**
 * 转换 vocabulary 列表
 */
function convertVocabulary(originalVocab, pages) {
  if (!originalVocab || !originalVocab.length) return [];
  return originalVocab
    .filter(v => v && v.word)
    .map(v => {
      const sourcePage = findSourcePage(pages, v.word);
      // 提取 excerpt：在 sourcePage 那一页的原始 lines 中查找
      let excerpt = '';
      if (sourcePage != null) {
        const page = pages.find(p => p.pageNumber === sourcePage);
        if (page) excerpt = extractExcerpt(page.lines, v.word);
      }
      return {
        kind: 'source_recall',
        word: v.word,
        excerpt,
        sourcePage: sourcePage || pages[0].pageNumber,
      };
    });
}

/**
 * 生成 note 字段
 */
function generateNote(article) {
  const start = article.startPage;
  const end = article.endPage;
  return `原文第 ${start}–${end} 页。原材料中的读音与释义未经独立核验。`;
}

// ---------- 主转换 ----------
const outputArticles = inputData.articles.map((article, index) => {
  console.log(`Processing article ${index + 1}/${inputData.articles.length}: ${article.title}`);

  const vocab = article.vocabulary || [];

  // 构建完整文本（所有页面），用双换行分隔，并记录每页在全文中的字符范围
  const pageRanges = []; // [{start, end, pageNumber, lines}]
  let fullText = '';
  let charOffset = 0;

  article.pages.forEach((page, pageIndex) => {
    const pageText = page.lines.join('\n');
    pageRanges.push({
      start: charOffset,
      end: charOffset + pageText.length,
      pageNumber: page.pageNumber,
      lines: page.lines,
    });
    fullText += pageText;
    charOffset += pageText.length;
    // 页面间加双换行作为分隔符（除了最后一页）
    if (pageIndex < article.pages.length - 1) {
      fullText += '\n\n';
      charOffset += 2;
    }
  });

  // 在全文中查找所有标注（跨页匹配支持）
  const allAnnotations = findAnnotations(fullText, fullText.split('\n'), vocab);

  // 将标注分配到各页面
  const pageAnnotations = new Map(); // pageNumber -> annotations[]
  for (const page of article.pages) {
    pageAnnotations.set(page.pageNumber, []);
  }

  for (const anno of allAnnotations) {
    // 找到这个标注所在的页面
    for (const range of pageRanges) {
      if (anno.start >= range.start && anno.start < range.end) {
        // 将全文位置转换为页面内位置
        const localStart = anno.start - range.start;
        const localEnd = Math.min(anno.end, range.end) - range.start;
        const pageAnno = {
          ...anno,
          start: localStart,
          end: localEnd,
        };
        pageAnnotations.get(range.pageNumber).push(pageAnno);
        break;
      }
    }
  }

  // 转换 pages：对每一页独立生成 readingTokens
  const convertedPages = article.pages.map(page => {
    const text = page.lines.join('\n');
    const annotations = pageAnnotations.get(page.pageNumber);
    const readingTokens = buildReadingTokens(text, annotations);
    return {
      text,
      number: page.pageNumber,
      recall: false,
      readingTokens,
    };
  });

  const convertedVocabulary = convertVocabulary(vocab, article.pages);

  const outputArticle = {
    id: article.id,
    title: article.title,
    category: article.category,
    position: article.position,
    startPage: article.startPage,
    endPage: article.endPage,
    pages: convertedPages,
    vocabulary: convertedVocabulary,
    note: generateNote(article),
    materialId: article.materialId,
    paperId: article.paperId,
    questionCount: article.questionCount,
    published: article.published,
    sourceTitle: article.sourceTitle,
    sourcePages: article.sourcePages,
    attribution: article.attribution,
  };
  if (article.createdAt) outputArticle.createdAt = article.createdAt;
  if (article.updatedAt) outputArticle.updatedAt = article.updatedAt;

  return outputArticle;
});

const outputData = {
  convertedAt: new Date().toISOString(),
  source: 'data/novel-reading-articles.json',
  articleCount: outputArticles.length,
  articles: outputArticles,
};

fs.writeFileSync(outputPath, JSON.stringify(outputData, null, 2), 'utf-8');
console.log(`\nConversion complete!`);
console.log(`Output written to: ${outputPath}`);
console.log(`Total articles: ${outputArticles.length}`);

// ---------- 验证 ----------
const verifyData = JSON.parse(fs.readFileSync(outputPath, 'utf-8'));
console.log(`\nVerification:`);
console.log(`- Articles: ${verifyData.articleCount}`);

// 校验第一篇
const first = verifyData.articles[0];
console.log(`- First article id=${first.id} title="${first.title}"`);
console.log(`  pages: ${first.pages.length}, vocabulary: ${first.vocabulary.length}`);
console.log(`  note: ${first.note}`);

if (first.pages[0].readingTokens.length) {
  const firstToken = first.pages[0].readingTokens.find(t => t.status === 'source_annotation');
  console.log(`  first annotation token:`, JSON.stringify(firstToken, null, 2));
}
if (first.vocabulary.length) {
  console.log(`  first vocabulary:`, JSON.stringify(first.vocabulary[0], null, 2));
}

// 统计：所有文章共多少 vocab / annotation
let totalVocab = 0;
let totalAnnotations = 0;
let totalArticles = verifyData.articles.length;
for (const a of verifyData.articles) {
  totalVocab += (a.vocabulary || []).length;
  for (const p of a.pages || []) {
    for (const t of p.readingTokens || []) {
      if (t.status === 'source_annotation') totalAnnotations++;
    }
  }
}
console.log(`\nAggregate:`);
console.log(`- total articles: ${totalArticles}`);
console.log(`- total vocabulary entries: ${totalVocab}`);
console.log(`- total annotation tokens (across all pages): ${totalAnnotations}`);

// 找出没有匹配 annotation 的 vocabulary（用于排查）
const unmatchedVocab = [];
for (const a of verifyData.articles) {
  for (const v of a.vocabulary || []) {
    let found = false;
    for (const p of a.pages || []) {
      for (const t of p.readingTokens || []) {
        if (t.status === 'source_annotation' && t.word === v.word) {
          found = true;
          break;
        }
      }
      if (found) break;
    }
    if (!found) unmatchedVocab.push(`${a.id} :: ${v.word}`);
  }
}
if (unmatchedVocab.length) {
  console.log(`\nUnmatched vocabulary (word not found as annotation token in any page): ${unmatchedVocab.length}`);
  for (const u of unmatchedVocab.slice(0, 20)) console.log(`  - ${u}`);
  if (unmatchedVocab.length > 20) console.log(`  ... and ${unmatchedVocab.length - 20} more`);
} else {
  console.log(`\nAll vocabulary words were matched as annotation tokens.`);
}
