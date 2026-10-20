#!/usr/bin/env python3
"""Parse '看知乎小说背日语N1词汇.pdf' into ReadingArticle JSON records.

ReadingArticle schema (prisma/schema.prisma):
  id            String  @id
  title         String  # lesson title (Chinese)
  category      String  # 长篇小说 / 复合动词 / 副词
  position      Int     # 1-based order
  startPage     Int     # first PDF page of this lesson (inclusive)
  endPage       Int     # last PDF page (inclusive)
  pages         Json    # [{pageNumber, lines: [str], images?: [str]}]
  vocabulary    Json    # [{word, reading, meaning, level?}]
  note          String  # free-form note
  materialId    String
  paperId       String
  questionCount Int
  published     Boolean
  sourceTitle   String?
  sourcePages   Int
  attribution   String?

Output:
  <backend>/data/novel-reading-articles.json
    { articles: [...], meta: {...} }

Vocabulary extraction
---------------------
The PDF annotates target words inline like:
    発足ほっそく成立      # 汉字 + 平假名reading + 中文meaning
    馴染むなじむ熟悉      # 汉字+okurigana + reading + meaning
    素っ気ないそっけない冷淡
    發足(ほっそく) 成立    # parenthesized reading variant (not present here)

We match each target word at its surrounding position and pull the hiragana
reading + Chinese meaning that immediately follows it.
"""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

try:
    import pdfplumber
except ImportError:
    sys.exit("pdfplumber is required (pip install pdfplumber)")

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

PDF_PATH = Path("/Volumes/Mac Data/Documents/看知乎小说背日语N1词汇.pdf")
BACKEND_DIR = Path(
    "/Volumes/Mac Data/Documents/StudioProjects/japanese-learning/ja-learning-backend"
)
OUTPUT_PATH = BACKEND_DIR / "data" / "novel-reading-articles.json"

# Canonical lesson boundaries (PDF page numbers, 1-indexed). The 12 long-form
# novels span pages 2-280; pages 281-297 each contain one short lesson;
# page 298 is the closing.
LESSON_STARTS = [
    2, 12, 20, 30, 41, 55, 72, 91, 117, 149, 192, 242,
    281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291, 292, 294, 295, 296, 297,
]

LESSON_TITLES = [
    # 12 long-form novels
    "校草的粉红小鸡",
    "当我穿进虐文里当沙雕女主",
    "家族破产后，送外卖遇上前男友",
    "惊！世子爷竟是女儿身",
    "死后的第101天",
    "醒来时校霸的裤衩子挂在我的裤腰带上",
    "当了三年金丝雀后，金主的未婚妻回国了",
    "当痔疮手术遇上清冷男神",
    "极寒末世，我在3000㎡的仓储超市里吃烧烤",
    "和死对头上恋综亲嘴被全网直播了",
    "我爸是省委书记，而我却在街道办当小科员",
    "装了三年清纯小白花后，被豪门老公读心了",
    # 10 compound-verb short lessons
    "恋爱脑的觉醒",
    "让人着迷的男大",
    "我与青梅竹马死对头的爱恨情仇",
    "校园三人修罗场",
    "抛弃金主，清醒影后要出逃",
    "安小鸟的阴谋",
    "无法挽回的恋人",
    "大小姐落难记",
    "霸总白月光在线要钱",
    "霸总夫人的夜店丑闻",
    # 6 adverb lessons
    "诡计多端的男同",
    "闺蜜的阴谋",
    "陆少的小娇妻",
    "痴情女二清醒后要离婚",
    "玩弄权势的太后",
    "震惊全校之校草爱上我",
]

# Source-word list: the words the PDF annotates inline. Order matches the
# PDF's own progression, so the first 10 matches we find per long-form novel
# will be the lesson's vocabulary set.
INLINE_WORDS = (
    "受験 紹介 責任者 正常 意識 不便 執筆 接触 収集 証拠 出張 処理 雰囲気 複雑 受付 "
    "解決 世話 危険 通知 連絡 計画 現場 企業 輸出 教育 支持 変化 交換 包帯 迅速 観察 "
    "血液 感覚 独立 関係 成績 記録 感動 動作 悩み 空気 責任 手続き 迷惑 予約 疑問 保証 "
    "項目 損失 秘書 圧力 交渉 調査 事業 現実 期限 回答 発足 密集 瞬間 執念 品種 腹筋 "
    "躊躇う 呆れる 発送 費やす 落胆 断念 発見 進展 徹夜 伝説 尊い 飼料 回転 火花 呼吸 "
    "全身 台詞 安価 主役 溢れる 洋服 熟知 原著 倒産 脚本 手渡す 出前 我慢 誘い 刻む "
    "嘆息 頷く 公寓 生まれる 必然 激動 穏やか 即刻 布団 忠誠 保護 作物 周辺 孤児 稼ぐ "
    "玄関 下駄箱 散歩 場所 墓碑 専門 程度 隙間 無数 可能性 帰国 告白 非難 資源 出資 "
    "提供 投資 名刺 脱出 完全 食料品 幸福 天気 舗装道路 気温 触感 距離 交替 確認 人事 "
    "裏側 居住者 懲罰 微笑み 蓋 カーテン ストレス キャンパス ドラマ コメント コンビニ "
    "エアコン キーボード ハンドル ラーメン アルバイト ヘルメット キャッシュカード "
    "マンション プロジェクト コーヒー メッセージ"
).split()

# Short-lesson vocabulary (compound verbs / adverbs). Index 0 corresponds to
# LESSON_TITLES[12] ("恋爱脑的觉醒").
SHORT_ENTRIES = [
    # 复合动词
    [("振り返る", "ふりかえる", "回顾，反省"),
     ("振り切る", "ふりきる", "拒绝，摆脱，甩开"),
     ("振り回す", "ふりまわす", "挥舞，滥用，摆弄"),
     ("振り替える", "ふりかえる", "转账，调换"),
     ("振り込む", "ふりこむ", "汇款，存入")],
    [("気を付ける", "きをつける", "小心，注意"),
     ("気に入る", "きにいる", "喜欢"),
     ("気になる", "きになる", "在意，关心"),
     ("きにかける", "きにかける", "关心，在意"),
     ("気にする", "きにする", "在意，担心"),
     ("気がつく", "きがつく", "意识到，注意到")],
    [("打ち込む", "うちこむ", "热衷，拼命工作"),
     ("打ち出す", "うちだす", "提出，打出，制定"),
     ("打ち消す", "うちけす", "否定，取消"),
     ("打ち明ける", "うちあける", "坦白，倾诉"),
     ("打ち合わせる", "うちあわせる", "商量"),
     ("打ち解ける", "うちとける", "敞开心扉，融洽")],
    [("詰め込む", "つめこむ", "填鸭式学习，塞满"),
     ("入れ込む", "いれこむ", "着迷，振奋，装入"),
     ("落ち込む", "おちこむ", "心情低落，陷入困境"),
     ("思い込む", "おもいこむ", "深信不疑，误以为"),
     ("割り込む", "わりこむ", "打断，插话，插入")],
    [("引き取る", "ひきとる", "退出，领取，收养"),
     ("引っ掛ける", "ひっかける", "撞上，挂上，欺骗"),
     ("引き起こす", "ひきおこす", "引起，扶起"),
     ("引き受ける", "ひきうける", "继承，接受，承担"),
     ("引き止める", "ひきとめる", "阻止，挽留"),
     ("引き出す", "ひきだす", "提出，提取，引出")],
    [("差し控える", "さしひかえる", "避免，克制，暂缓"),
     ("差し掛かる", "さしかかる", "来到，接近，遮盖"),
     ("差し支える", "さしつかえる", "有碍，妨碍，影响"),
     ("差し出す", "さしだす", "递出，伸出"),
     ("差し上げる", "さしあげる", "赠送"),
     ("差し替える", "さしかえる", "调换")],
    [("思い合う", "おもいあう", "相互思念"),
     ("思い返す", "おもいかえす", "反省，回顾"),
     ("思い当たる", "おもいあたる", "意识到，想到"),
     ("思い立つ", "おもいたつ", "想要做，下决心"),
     ("思い詰める", "おもいつめる", "过度思虑，钻牛角尖"),
     ("思い浮かべる", "おもいうかべる", "浮现于脑海")],
    [("受け持つ", "うけもつ", "担任，负责"),
     ("受け取る", "うけとる", "接受，理解，承担"),
     ("受け合う", "うけあう", "承诺"),
     ("受け入れる", "うけいれる", "接纳"),
     ("受け止める", "うけとめる", "阻止，接住，理解"),
     ("受け継ぐ", "うけつぐ", "继承")],
    [("取り組む", "とりくむ", "致力于，处理，投入"),
     ("取り次ぐ", "とりつぐ", "转达，传递，代办"),
     ("取り出す", "とりだす", "拿出，挑出"),
     ("取り消す", "とりけす", "取消"),
     ("取り上げる", "とりあげる", "举起，采纳，没收，报道")],
    [("打ち込む", "うちこむ", "热衷，拼命工作，输入"),
     ("打ち切る", "うちきる", "中断"),
     ("打ち合わせる", "うちあわせる", "商量"),
     ("打ち消す", "うちけす", "否认，取消"),
     ("打ち明ける", "うちあける", "坦白，倾诉")],
    # 副词
    [("こつこつ", "こつこつ", "孜孜不倦"),
     ("つるつる", "つるつる", "光滑"),
     ("じろじろ", "じろじろ", "目不转睛"),
     ("わくわく", "わくわく", "兴奋"),
     ("もじもじ", "もじもじ", "扭捏")],
    [("いやに", "いやに", "异常，非常"),
     ("きっぱり", "きっぱり", "果断"),
     ("いまだ", "いまだ", "尚未"),
     ("きっかり", "きっかり", "清晰，正好"),
     ("べったり", "べったり", "过分依赖，黏糊糊"),
     ("じっくり", "じっくり", "慢慢地，仔细"),
     ("ぐっすり", "ぐっすり", "熟睡"),
     ("ゆっくり", "ゆっくり", "慢慢地")],
    [("しっとり", "しっとり", "潮湿，沉静"),
     ("じっくり", "じっくり", "仔细"),
     ("ざあざあ", "ざあざあ", "哗啦哗啦"),
     ("ぴったり", "ぴったり", "严丝合缝"),
     ("ぐったり", "ぐったり", "筋疲力尽"),
     ("しとしと", "しとしと", "淅淅沥沥"),
     ("こっそり", "こっそり", "悄悄，偷偷")],
    [("どきっと", "どきっと", "震惊"),
     ("すっと", "すっと", "一下子，一直"),
     ("ほっと", "ほっと", "安心，松口气"),
     ("ざっと", "ざっと", "粗略地，大致"),
     ("ひょっと", "ひょっと", "忽然，或许"),
     ("そっと", "そっと", "悄悄，偷偷")],
    [("もっぱら", "もっぱら", "独揽，专门"),
     ("しきりに", "しきりに", "频繁地"),
     ("すっきり", "すっきり", "痛快，清爽"),
     ("なんら", "なんら", "毫无"),
     ("ぐらぐら", "ぐらぐら", "不稳定"),
     ("ありあり", "ありあり", "明显，显而易见"),
     ("のろのろ", "のろのろ", "缓慢"),
     ("どんより", "どんより", "阴沉")],
    [("ふと", "ふと", "突然"),
     ("ひしひし", "ひしひし", "感觉强烈，切实"),
     ("ふんわり", "ふんわり", "蓬松"),
     ("うっとり", "うっとり", "陶醉"),
     ("がらりと", "がらりと", "突然，彻底"),
     ("あっさり", "あっさり", "口味清淡，简单，朴素"),
     ("ぎくしゃく", "ぎくしゃく", "不自然，生硬"),
     ("かねがね", "かねがね", "很久以前")],
]

# Category assignment per lesson index (0-based)
def category_for(idx: int) -> str:
    if idx < 12:
        return "长篇小说"
    if idx < 22:
        return "复合动词"
    return "副词"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

PAGE_FOOTER_RE = re.compile(r"第\s*\d+\s*页\s*共\s*298\s*页")
SIGNATURE_RE = re.compile(r"小红书号\d+创作|@叫我とうさん")


def split_lines(text: str) -> list[str]:
    """Split page text into logical lines, stripping footers/signatures."""
    text = PAGE_FOOTER_RE.sub("", text)
    text = SIGNATURE_RE.sub("", text)
    lines = [ln.strip() for ln in text.splitlines()]
    return [ln for ln in lines if ln]


def extract_inline_annotations(text: str, word: str) -> list[dict]:
    """Find occurrences of `word` + reading + meaning in `text`.

    Pattern: kanji-word + hiragana reading + Chinese meaning.
    We also accept katakana reading (e.g. メッセージ → メッセージ) though the
    PDF mostly uses hiragana.
    """
    results = []
    if not word:
        return results
    # Escape for regex; the word may contain long-vowel marks etc.
    escaped = re.escape(word)
    has_kanji = bool(re.search(r"[一-龥々]", word))
    # Reading is hiragana (or katakana) following the word; meaning starts
    # with a CJK char / punctuation.
    if has_kanji:
        # Reading is hiragana (or katakana); meaning is a short Chinese gloss
        # (2-8 CJK chars). Story text resumes immediately after.
        pattern = re.compile(escaped + r"([ぁ-ゖー]+|[ァ-ヺー]+)([一-龥々]{2,8})")
    else:
        # Kana-only word: reading == word itself, followed directly by meaning.
        pattern = re.compile(escaped + r"([一-龥々]{2,8})")
    for m in pattern.finditer(text):
        if has_kanji:
            reading = m.group(1)
            meaning = m.group(2).strip()
        else:
            reading = word
            meaning = m.group(1).strip()
        # Trim trailing junk (line-break residue, brackets).
        meaning = re.sub(r"[\s\n\r]+", "", meaning)
        meaning = meaning.rstrip("（(「『")
        if meaning:
            results.append({"reading": reading, "meaning": meaning})
    return results


def vocabulary_for_long_form(pages_text: list[tuple[int, str]], words: list[str]) -> list[dict]:
    """Scan the joined text of all pages and pick the first 10 words that
    have inline annotations. Returns a list of vocab records.
    """
    joined = "".join("".join(lines) for _, lines in pages_text)  # lines already joined at call site
    # Note: pages_text here is list of (pageNumber, raw_text); re-join below.
    pass  # placeholder (caller uses its own joined string)
    return []


def find_short_vocab(pages_text: list[str], entries: list[tuple]) -> list[dict]:
    """For a short lesson, confirm each entry actually appears on the pages
    and return it with its reading/meaning from the canonical table.
    """
    joined = "\n".join(pages_text)
    out = []
    for word, reading, meaning in entries:
        # Normalize spaces so multi-kanji phrases still match.
        norm = re.sub(r"\s+", "", joined)
        if re.search(re.escape(word), norm):
            out.append({"word": word, "reading": reading, "meaning": meaning, "level": "n1"})
    return out


# ---------------------------------------------------------------------------
# Main extraction
# ---------------------------------------------------------------------------


def extract_all(pdf_path: Path) -> dict:
    pdf_bytes = pdf_path.read_bytes()
    sha256 = hashlib.sha256(pdf_bytes).hexdigest()
    material_id = "novel-" + sha256[:12]

    with pdfplumber.open(pdf_path) as doc:
        total_pages = len(doc.pages)
        if total_pages != 298:
            print(f"WARNING: expected 298 pages, got {total_pages}", file=sys.stderr)

        articles = []
        for idx, start in enumerate(LESSON_STARTS):
            title = LESSON_TITLES[idx]
            end = LESSON_STARTS[idx + 1] - 1 if idx + 1 < len(LESSON_STARTS) else total_pages
            paper_id = f"novel-lesson-{idx + 1:02d}-practice"
            article_id = f"novel-lesson-{idx + 1:02d}"

            pages_json = []
            page_texts: list[tuple[int, str]] = []  # (pageNumber, joined_text)
            for number in range(start, end + 1):
                page_obj = doc.pages[number - 1]
                raw = page_obj.extract_text() or ""
                lines = split_lines(raw)
                page_entry = {"pageNumber": number, "lines": lines}
                pages_json.append(page_entry)
                page_texts.append((number, "".join(lines)))

            # Vocabulary ---------------------------------------------------
            vocabulary: list[dict] = []
            if idx < 12:
                # Long-form: scan inline annotations.
                joined = "".join(t for _, t in page_texts)
                seen: set[str] = set()
                for word in INLINE_WORDS:
                    if word in seen:
                        continue
                    anns = extract_inline_annotations(joined, word)
                    if not anns:
                        continue
                    # Take the first (most natural) annotation.
                    ann = anns[0]
                    vocabulary.append(
                        {
                            "word": word,
                            "reading": ann["reading"],
                            "meaning": ann["meaning"],
                            "level": "n1",
                        }
                    )
                    seen.add(word)
            else:
                # Short lesson: use the canonical vocabulary table.
                short_idx = idx - 12
                if short_idx < len(SHORT_ENTRIES):
                    joined = [t for _, t in page_texts]
                    vocabulary = find_short_vocab(joined, SHORT_ENTRIES[short_idx])

            note = (
                "素材标题中的N1为原作者标注，不代表本平台已验证JLPT等级。"
                "练习按原文记忆或材料注释作答，混合语言故事不是规范日语例句。"
            )

            articles.append(
                {
                    "id": article_id,
                    "title": title,
                    "category": category_for(idx),
                    "position": idx + 1,
                    "startPage": start,
                    "endPage": end,
                    "pages": pages_json,
                    "vocabulary": vocabulary,
                    "note": note,
                    "materialId": material_id,
                    "paperId": paper_id,
                    "questionCount": 0,
                    "published": False,
                    "sourceTitle": "看知乎小说背日语N1词汇",
                    "sourcePages": total_pages,
                    "attribution": "@叫我とうさん（小红书号：508109733）",
                }
            )

        meta = {
            "pdfPath": str(pdf_path),
            "pdfSha256": sha256,
            "materialId": material_id,
            "totalArticles": len(articles),
            "totalPages": total_pages,
        }
        return {"articles": articles, "meta": meta}


def validate(articles: list[dict]) -> list[str]:
    """Return a list of issues; empty if everything looks good."""
    issues = []
    seen_ids: set[str] = set()
    for a in articles:
        if not a.get("id"):
            issues.append("article missing id")
        if a["id"] in seen_ids:
            issues.append(f"duplicate id {a['id']}")
        seen_ids.add(a["id"])
        if not a.get("title"):
            issues.append(f"{a['id']}: missing title")
        if not a.get("pages"):
            issues.append(f"{a['id']}: empty pages")
        for p in a.get("pages", []):
            if "pageNumber" not in p or "lines" not in p:
                issues.append(f"{a['id']}: page missing pageNumber/lines")
                break
        if not isinstance(a.get("vocabulary"), list):
            issues.append(f"{a['id']}: vocabulary is not a list")
        for v in a.get("vocabulary", []):
            for key in ("word", "reading", "meaning"):
                if not v.get(key):
                    issues.append(f"{a['id']}: vocab missing {key}: {v}")
                    break
    return issues


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    if not PDF_PATH.exists():
        print(f"PDF not found: {PDF_PATH}", file=sys.stderr)
        return 2

    result = extract_all(PDF_PATH)
    articles = result["articles"]

    issues = validate(articles)
    if issues:
        for i in issues:
            print("ISSUE:", i, file=sys.stderr)

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(json.dumps(result, ensure_ascii=False, indent=2))

    summary = {
        "totalArticles": len(articles),
        "totalPages": sum(len(a["pages"]) for a in articles),
        "vocabPerLesson": [len(a["vocabulary"]) for a in articles],
        "totalVocab": sum(len(a["vocabulary"]) for a in articles),
        "output": str(OUTPUT_PATH),
        "issues": len(issues),
    }
    print(json.dumps(summary, ensure_ascii=False))
    return 1 if issues else 0


if __name__ == "__main__":
    sys.exit(main())
