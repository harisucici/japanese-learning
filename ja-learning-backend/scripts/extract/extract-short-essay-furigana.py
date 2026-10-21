#!/usr/bin/env python3
"""
从短文PDF提取完整的假名标注

PDF结构:
- 假名(小字)在汉字上方,通过x坐标对齐
- 一组连续的假名对应下方的一个或多个汉字(复合词)
- 格式: [漢字compound:reading] 例如 [夏休み:なつやすみ]
"""

import json
import os
import re
import sys
from pathlib import Path
from collections import defaultdict

try:
    import pdfplumber
except ImportError:
    print("需要安装 pdfplumber: pip install pdfplumber")
    sys.exit(1)

PDF_DIR = "/Volumes/Mac Data/Documents/阅读PDF/短文PDF"
OUTPUT_FILE = Path(__file__).parent / ".." / "data" / "short-essay-extracted.json"


def is_kanji(char):
    """判断是否为汉字"""
    if not char or len(char) != 1:
        return False
    cp = ord(char)
    return (0x4E00 <= cp <= 0x9FFF or
            0x3400 <= cp <= 0x4DBF or
            0x20000 <= cp <= 0x2A6DF or
            0xF900 <= cp <= 0xFAFF)


def char_right(c, default_width):
    """Get right edge of character"""
    w = c.get('width') or c.get('x1')
    if w and w > c['x0']:
        return w
    return c['x0'] + default_width


def extract_furigana_from_pdf(pdf_path):
    """从PDF提取带假名标注的文本"""
    with pdfplumber.open(pdf_path) as pdf:
        if not pdf.pages:
            return ""

        page = pdf.pages[0]
        chars = page.chars
        if not chars:
            return ""

        # 找出主文字号(众数)
        sizes = [c['size'] for c in chars]
        main_size = max(set(sizes), key=sizes.count)

        # 假名字号阈值
        furigana_threshold = main_size * 0.75

        small_chars = [c for c in chars if c['size'] < furigana_threshold]
        main_chars = [c for c in chars if c['size'] >= furigana_threshold]

        # 按y坐标分组主文字
        main_by_y = defaultdict(list)
        for c in main_chars:
            main_by_y[round(c['top'])].append(c)

        result_lines = []

        for y in sorted(main_by_y.keys()):
            line_chars = sorted(main_by_y[y], key=lambda c: c['x0'])

            # 找到这一行对应的假名(在上方,距离合理)
            above_smalls = [c for c in small_chars
                            if c['top'] < y - 3 and y - c['top'] < main_size * 1.5]
            above_smalls.sort(key=lambda c: c['x0'])

            if not above_smalls:
                line_text = ''.join(mc['text'] for mc in line_chars)
                result_lines.append(line_text)
                continue

            # 将假名按x连续性分组
            groups = [[above_smalls[0]]]
            for sc in above_smalls[1:]:
                last = groups[-1][-1]
                last_right = char_right(last, main_size * 0.5)
                # 如果x间距小于主字号*0.8,认为连续
                if sc['x0'] - last_right < main_size * 0.8:
                    groups[-1].append(sc)
                else:
                    groups.append([sc])

            # 对每个假名组,找到对应的汉字范围
            # 策略: 假名组的x范围覆盖的汉字就是该组的标注对象
            annotations = []  # (start_main_idx, end_main_idx_exclusive, furigana_text)

            for group in groups:
                g_text = ''.join(sc['text'] for sc in group)
                g_x_min = min(sc['x0'] for sc in group)
                g_x_max = max(char_right(sc, main_size * 0.5) for sc in group)

                # 找到x范围与假名组有重叠的主文字
                start_idx = None
                end_idx = None

                for i, mc in enumerate(line_chars):
                    mc_left = mc['x0']
                    mc_right = char_right(mc, main_size)
                    mc_center = (mc_left + mc_right) / 2

                    # 检查该主文字是否与假名组有重叠
                    # 条件: 主文字的x范围与假名组的x范围有交集
                    # 或主文字的中心在假名组的x范围内
                    overlaps = (mc_left <= g_x_max and mc_right >= g_x_min)
                    center_in_range = g_x_min - main_size * 0.3 <= mc_center <= g_x_max + main_size * 0.3

                    if overlaps or center_in_range:
                        if start_idx is None:
                            start_idx = i
                        end_idx = i

                if start_idx is not None and end_idx is not None:
                    # 提取汉字范围(只包含汉字,不含中间的非汉字)
                    # 但如果包含非汉字,说明范围太大,需要裁剪
                    kanji_start = None
                    kanji_end = None
                    for i in range(start_idx, end_idx + 1):
                        if is_kanji(line_chars[i]['text']):
                            if kanji_start is None:
                                kanji_start = i
                            kanji_end = i

                    if kanji_start is not None:
                        annotations.append((kanji_start, kanji_end + 1, g_text))

            # 构建文本
            line_text = ""
            annotated_ranges = set()
            for s, e, _ in annotations:
                for i in range(s, e):
                    annotated_ranges.add(i)

            i = 0
            while i < len(line_chars):
                # 检查是否是一个标注范围的开始
                matched_ann = None
                for s, e, ft in annotations:
                    if i == s:
                        matched_ann = (s, e, ft)
                        break

                if matched_ann:
                    s, e, ft = matched_ann
                    kanji_text = ''.join(line_chars[j]['text'] for j in range(s, e))
                    line_text += f"[{kanji_text}:{ft}]"
                    i = e
                else:
                    line_text += line_chars[i]['text']
                    i += 1

            result_lines.append(line_text)

        return "\n".join(result_lines)


def extract_translation_from_pdf(pdf_path):
    """从PDF提取中文翻译"""
    with pdfplumber.open(pdf_path) as pdf:
        if not pdf.pages:
            return ""

        page = pdf.pages[0]
        text = page.extract_text()

        lines = text.split('\n')
        chinese_lines = []

        for line in lines:
            if re.search(r'[\u4e00-\u9fff]', line):
                if len(line) > 10 or '，' in line or '。' in line:
                    chinese_lines.append(line)

        return '\n'.join(chinese_lines).strip()


def extract_title_from_pdf(pdf_path):
    """从文件名提取标题"""
    filename = os.path.basename(pdf_path)
    match = re.match(r'^\d+(.+?)\.pdf$', filename)
    if match:
        return match.group(1)
    return filename.replace('.pdf', '')


def main():
    pdf_files = sorted([
        f for f in os.listdir(PDF_DIR)
        if f.endswith('.pdf') and re.match(r'^\d+', f)
    ], key=lambda f: int(re.match(r'^(\d+)', f).group(1)))

    print(f"找到 {len(pdf_files)} 个PDF文件")

    results = []
    total_furigana = 0

    for pdf_file in pdf_files:
        pdf_path = os.path.join(PDF_DIR, pdf_file)
        num_match = re.match(r'^(\d+)', pdf_file)
        number = int(num_match.group(1))

        title = extract_title_from_pdf(pdf_path)
        japanese = extract_furigana_from_pdf(pdf_path)
        furigana_count = japanese.count('[')
        total_furigana += furigana_count
        translation = extract_translation_from_pdf(pdf_path)

        print(f"#{number:3d} {title:<20s} furigana: {furigana_count:2d}")

        results.append({
            "number": number,
            "filename": pdf_file,
            "title": title,
            "japanese": japanese,
            "translation": translation
        })

    print(f"\n总计: {len(results)} 篇文章, {total_furigana} 个假名标注")
    print(f"平均每篇: {total_furigana / len(results):.2f} 个")

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    print(f"保存到: {OUTPUT_FILE.resolve()}")

    # Show sample
    print("\n示例 (#1):")
    print(results[0]['japanese'][:400])
    print("\n示例 (#101):")
    print([e for e in results if e['number'] == 101][0]['japanese'][:400])


if __name__ == '__main__':
    main()
