#!/usr/bin/env python3
"""Build the twelve reading lessons from the supplied 2–280 PDF pages.

The existing Turso backup supplies verified ruby tokens on the original pages.
The full PDF extraction supplies the few final story pages absent from that backup.
Recall pages are retained in the payload as provenance for the linked exercises,
but are never placed in ReadingArticle.pages.
"""
import json
import re
from pathlib import Path
import pdfplumber

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'data'
BACKUP = DATA / 'reading-articles-turso-backup-2026-10-20T06-28-51-080Z.json'
FULL = DATA / 'reading-articles-turso-format.json'
OUT = DATA / 'reading-replacement-2026-10-20.json'
PDF = Path('/Volumes/Mac Data/Documents/看知乎小说背日语N1词汇.pdf')
MAIN_ENDS = [6, 15, 24, 35, 47, 63, 81, 104, 132, 170, 216, 261]
RECALL_ENDS = [11, 19, 29, 40, 54, 71, 90, 116, 148, 191, 241, 280]
MARKER = re.compile(r'\s*背诵回忆版(?:请看|看|见)下页')

def plain(token):
    return token.get('sourceText', token.get('text', ''))

def clip(page, end):
    page = dict(page)
    page['text'] = page['text'][:end].rstrip()
    remaining = len(page['text'])
    tokens = []
    for token in page.get('readingTokens', []):
        if remaining <= 0:
            break
        source = plain(token)
        if len(source) <= remaining:
            tokens.append(token)
            remaining -= len(source)
        elif 'text' in token:
            tokens.append({'text': source[:remaining]})
            remaining = 0
        else:
            raise ValueError(f"Annotation intersects a page boundary: {page['number']}")
    if tokens and ''.join(map(plain, tokens)) != page['text']:
        raise ValueError(f"Ruby reconstruction failed: {page['number']}")
    page['readingTokens'] = tokens or [{'text': page['text']}]
    page['recall'] = False
    return page

def restore_highlights(page, pdf_page, recall_text, issues):
    """Recover word/ruby/gloss spans on story 8 from highlighted PDF rectangles."""
    boxes = []
    for rect in pdf_page.rects:
        color = rect.get('non_stroking_color')
        if not isinstance(color, (tuple, list)) or len(color) != 3 or min(color) > .96 or max(color) < .2:
            continue
        chars = [char for char in pdf_page.chars if char['size'] < 25 and
                 char['x0'] >= rect['x0'] - 1 and char['x1'] <= rect['x1'] + 1 and
                 char['top'] >= rect['top'] - 2 and char['bottom'] <= rect['bottom'] + 2]
        value = ''.join(char['text'] for char in chars).strip()
        if value:
            boxes.append((value, rect['x0'], rect['x1'], rect['top']))
    groups = []
    for box in boxes:
        if groups:
            previous = groups[-1][-1]
            same_line = abs(previous[3] - box[3]) < 2 and abs(previous[2] - box[1]) < 2
            wrapped = previous[2] > 490 and box[1] < 110 and 20 < box[3] - previous[3] < 40
            if same_line or wrapped:
                groups[-1].append(box)
                continue
        groups.append([box])
    recall = re.sub(r'\s+', '', recall_text)
    hits = []
    for group in groups:
        raw = ''.join(box[0] for box in group)
        candidates = [raw[:cut] for cut in range(1, len(raw)) if raw[:cut] + '（）' in recall]
        if not candidates:
            issues.append({'page': page['number'], 'kind': 'unmatched-highlight', 'detail': raw})
            continue
        word = max(candidates, key=len)
        rest = raw[len(word):]
        reading = re.match(r'[ぁ-ゖー]*', rest).group()
        meaning = rest[len(reading):]
        if not meaning:
            issues.append({'page': page['number'], 'kind': 'missing-gloss', 'detail': raw})
            continue
        pattern = re.compile(r'\s*'.join(map(re.escape, raw)))
        matches = list(pattern.finditer(page['text']))
        if len(matches) != 1:
            issues.append({'page': page['number'], 'kind': 'highlight-location',
                           'detail': f'{raw}: {len(matches)} matches'})
            continue
        match = matches[0]
        hits.append((match.start(), match.end(), word, reading, meaning))
    hits.sort()
    tokens, cursor = [], 0
    for start, end, word, reading, meaning in hits:
        if start < cursor:
            issues.append({'page': page['number'], 'kind': 'overlapping-highlight', 'detail': word})
            continue
        if start > cursor:
            tokens.append({'text': page['text'][cursor:start]})
        tokens.append({'word': word, 'reading': reading, 'meaning': meaning,
                       'sourceText': page['text'][start:end], 'status': 'source_annotation'})
        cursor = end
    if cursor < len(page['text']):
        tokens.append({'text': page['text'][cursor:]})
    page['readingTokens'] = tokens or [{'text': page['text']}]
    if ''.join(map(plain, page['readingTokens'])) != page['text']:
        raise ValueError(f"Highlight reconstruction failed: {page['number']}")
    return page

def add_known_span(page, raw, word, reading, meaning):
    for index, token in enumerate(page['readingTokens']):
        if 'text' not in token or raw not in token['text']:
            continue
        before, after = token['text'].split(raw, 1)
        replacement = []
        if before:
            replacement.append({'text': before})
        replacement.append({'word': word, 'reading': reading, 'meaning': meaning,
                            'sourceText': raw, 'status': 'source_annotation'})
        if after:
            replacement.append({'text': after})
        page['readingTokens'][index:index + 1] = replacement
        return
    raise ValueError(f"Expected highlight missing on page {page['number']}: {raw}")

def main():
    old = json.loads(BACKUP.read_text())['articles']
    full = json.loads(FULL.read_text())['articles']
    articles, recalls, issues = [], [], []
    pdf = pdfplumber.open(PDF)
    for index, (saved, source) in enumerate(zip(old, full)):
        assert saved['id'] == source['id'] and saved['position'] == index + 1
        main_end, recall_end = MAIN_ENDS[index], RECALL_ENDS[index]
        assert source['startPage'] == saved['startPage']
        assert source['endPage'] == recall_end
        saved_pages = {p['number']: p for p in saved['pages']}
        source_pages = {p['number']: p for p in source['pages']}
        pages = []
        for number in range(saved['startPage'], main_end + 1):
            page = saved_pages.get(number, source_pages[number])
            text = page['text']
            marker = MARKER.search(text)
            if marker:
                page = clip(page, marker.start())
            elif number == 104:
                # This PDF page contains the end of story 8 and the first recall page.
                boundary = text.find('背诵回忆版')
                if boundary >= 0:
                    page = clip(page, boundary)
                else:
                    page = clip(page, len(text))
            else:
                page = clip(page, len(text))
            if number == 132:
                # The watermark overlaps the last end marker in the PDF text layer.
                page['text'] = page['text'].replace('小红—书—完——号508109733创作', '——完——')
                page['readingTokens'] = [{'text': page['text']}]
                add_known_span(page, '完結かんけつ完结', '完結', 'かんけつ', '完结')
                issues.append({'page': 132, 'kind': 'text-layer-overlap',
                               'detail': '页尾水印与“——完——”重叠；正文按可读语义修复，需人工核对版面。'})
            if not page['text'].strip():
                raise ValueError(f'Empty original page {number}')
            pages.append(page)
        if index == 0:
            # Manually verified from the PDF and confirmed by the user.
            final_page = pages[-1]
            add_known_span(final_page, '忽然こつぜん忽然', '忽然', 'こつぜん', '忽然')
            add_known_span(final_page, '抱くだく\n拥', '抱く', 'だく', '拥')
        recall_pages = []
        if index == 7:
            mixed = source_pages[104]['text']
            start = mixed.find('背诵回忆版')
            if start < 0:
                raise ValueError('Page 104 lacks its inline recall boundary')
            recall_pages.append({'number': 104, 'text': mixed[start:]})
        for number in range(main_end + 1, recall_end + 1):
            page = source_pages[number]
            text = page['text']
            if not text.strip():
                raise ValueError(f'Empty recall page {number}')
            recall_pages.append({'number': number, 'text': text})
        if index == 7:
            recall_text = ''.join(page['text'] for page in recall_pages)
            pages = [restore_highlights(page, pdf.pages[page['number'] - 1], recall_text, issues)
                     if page['number'] < 104 else page for page in pages]
            by_number = {page['number']: page for page in pages}
            add_known_span(by_number[98], '回数', '回数', 'かいすう', '次数')
            if not by_number[99]['text'].startswith('かいすう次数'):
                raise ValueError('Cross-page reading/gloss changed on page 99')
            by_number[99]['text'] = by_number[99]['text'][len('かいすう次数'):]
            first = by_number[99]['readingTokens'][0]
            if first.get('text', '').startswith('かいすう次数'):
                first['text'] = first['text'][len('かいすう次数'):]
            else:
                raise ValueError('Cross-page token changed on page 99')
            add_known_span(by_number[101], '手続き手续', '手続き', '', '手续')
            issues[:] = [issue for issue in issues if issue.get('detail') not in
                         ('回数', 'かいすう次数', '手続き手续')]
            issues.append({'page': 98, 'kind': 'cross-page-annotation',
                           'detail': '回数的假名与释义落在第99页；阅读版将完整词元放在第98页并移除第99页重复标注。'})
        article = {key: saved[key] for key in (
            'id', 'title', 'category', 'position', 'startPage', 'vocabulary',
            'note', 'materialId', 'paperId', 'sourceTitle', 'sourcePages', 'attribution')}
        article.update(endPage=main_end, pages=pages, published=True,
                       questionCount=0)
        articles.append(article)
        recalls.append({'articleId': article['id'], 'pages': recall_pages})
    assert len(articles) == len(recalls) == 12
    assert sum(len(a['pages']) + len(r['pages']) for a, r in zip(articles, recalls)) == 280
    OUT.write_text(json.dumps({'sourcePages': 280, 'articles': articles,
                               'recallSources': recalls, 'issues': issues},
                              ensure_ascii=False, indent=2) + '\n')
    print(f'Prepared {len(articles)} originals, {sum(map(lambda x: len(x["pages"]), recalls))} recall pages: {OUT}')
    pdf.close()

if __name__ == '__main__':
    main()
