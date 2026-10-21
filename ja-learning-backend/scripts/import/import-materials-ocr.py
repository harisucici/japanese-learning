#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
素材阅读馆数据导入脚本
1. 清空 StudyMaterial 表
2. 从 PDF 中提取文本（使用 macOS Vision OCR）
3. 添加假名注音 [漢字:仮名]
4. 导入数据库
"""
import os
import sys
import json
import subprocess
import tempfile
import sqlite3
from pathlib import Path
from typing import List, Tuple, Dict, Optional

# PDF 源目录
PDF_BASE = Path("/Volumes/Mac Data/Documents/阅读PDF/附赠100篇（音频+PDF）")
# OCR 工具
OCR_TOOL = Path("/tmp/jp_ocr")
# 数据库路径
DB_PATH = Path("/Volumes/Mac Data/Documents/StudioProjects/japanese-learning/ja-learning-backend/prisma/dev.db")

# 尝试导入 fugashi 进行假名标注
try:
    import fugashi
    TAGGER = fugashi.Tagger()
    HAS_FUGASHI = True
except ImportError:
    HAS_FUGASHI = False
    print("Warning: fugashi not available, furigana annotation disabled")


def extract_number(dirname: str) -> Optional[int]:
    """从目录名提取编号"""
    import re
    match = re.match(r'^(\d+)\.', dirname)
    return int(match.group(1)) if match else None


def ocr_pdf(pdf_path: Path) -> str:
    """使用 macOS Vision OCR 提取 PDF 文本"""
    with tempfile.TemporaryDirectory() as tmpdir:
        png_path = Path(tmpdir) / "page.png"
        # 转换为 PNG
        result = subprocess.run(
            ["sips", "-s", "format", "png", str(pdf_path), "--out", str(png_path)],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            print(f"  sips failed: {result.stderr}")
            return ""
        
        # OCR
        result = subprocess.run(
            [str(OCR_TOOL), str(png_path)],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            print(f"  OCR failed: {result.stderr}")
            return ""
        
        return result.stdout.strip()


def add_furigana(text: str) -> str:
    """
    为日文文本添加假名注音
    格式: [漢字:仮名]
    """
    if not HAS_FUGASHI:
        return text
    
    result = []
    lines = text.split('\n')
    
    for line in lines:
        # 跳过纯中文行（翻译）
        if all('\u4e00' <= c <= '\u9fff' or c in '。，！？、' for c in line if not c.isspace()):
            result.append(line)
            continue
        
        # 跳过英文
        if all(c.isascii() or c.isspace() for c in line):
            result.append(line)
            continue
        
        # 处理日文行
        processed = process_line(line)
        result.append(processed)
    
    return '\n'.join(result)


def process_line(line: str) -> str:
    """处理单行，添加假名注音"""
    if not line.strip():
        return line
    
    # 使用 fugashi 分词
    words = TAGGER(line)
    result = []
    
    for word in words:
        surface = word.surface
        # 获取读音（kana 字段是片假名）
        reading = word.feature.kana if hasattr(word.feature, 'kana') else None
        
        if reading and reading != '*':
            # 片假名转平假名
            reading_hira = katakana_to_hiragana(reading)
            # 只有当表面形式包含汉字且读音不同时才标注
            if contains_kanji(surface) and surface != reading_hira:
                result.append(f"[{surface}:{reading_hira}]")
            else:
                result.append(surface)
        else:
            result.append(surface)
    
    return ''.join(result)


def katakana_to_hiragana(text: str) -> str:
    """片假名转平假名"""
    result = []
    for c in text:
        code = ord(c)
        if 0x30A1 <= code <= 0x30F6:
            result.append(chr(code - 0x60))
        else:
            result.append(c)
    return ''.join(result)


def contains_kanji(text: str) -> bool:
    """检查是否包含汉字"""
    return any('\u4e00' <= c <= '\u9fff' for c in text)


def split_japanese_and_translation(text: str) -> Tuple[str, str]:
    """分离日文原文和中文翻译"""
    lines = text.split('\n')
    japanese_lines = []
    translation_lines = []
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        # 检测是否是中文翻译行
        # 中文特征：包含中文字符但不包含日文假名
        has_kana = any('\u3040' <= c <= '\u309f' or '\u30a0' <= c <= '\u30ff' for c in line)
        has_kanji = any('\u4e00' <= c <= '\u9fff' for c in line)
        has_chinese_only = has_kanji and not has_kana
        
        # 检查是否包含典型中文标点或词汇
        chinese_patterns = ['我这个', '但是', '因为', '所以', '虽然', '的', '了', '是', '在', '有']
        is_chinese = any(p in line for p in chinese_patterns) or has_chinese_only
        
        # 特殊处理：以"本内容由"开头的行
        if '本内容由' in line or '@' in line:
            continue
        
        if is_chinese and not has_kana:
            translation_lines.append(line)
        else:
            japanese_lines.append(line)
    
    return '\n'.join(japanese_lines), '\n'.join(translation_lines)


def clear_materials_table():
    """清空 StudyMaterial 表"""
    print(f"Clearing materials table in {DB_PATH}")
    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()
    
    # 删除所有记录
    cursor.execute("DELETE FROM StudyMaterial")
    deleted = cursor.rowcount
    
    conn.commit()
    conn.close()
    
    print(f"Deleted {deleted} records from StudyMaterial")
    return deleted


def import_materials(materials: List[Dict]):
    """导入素材到数据库"""
    print(f"Importing {len(materials)} materials to {DB_PATH}")
    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()
    
    for m in materials:
        cursor.execute("""
            INSERT OR REPLACE INTO StudyMaterial 
            (id, title, collection, japanese, translation, textStatus, metadata, createdAt, updatedAt)
            VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
        """, (
            m['id'],
            m['title'],
            m['collection'],
            m.get('japanese'),
            m.get('translation'),
            m.get('textStatus', 'ready'),
            json.dumps(m.get('metadata', {}), ensure_ascii=False)
        ))
    
    conn.commit()
    conn.close()
    
    print(f"Imported {len(materials)} materials")


def process_pdfs():
    """处理所有 PDF 文件"""
    print(f"Scanning PDFs in {PDF_BASE}")
    
    dirs = sorted([d for d in PDF_BASE.iterdir() if d.is_dir()])
    print(f"Found {len(dirs)} directories")
    
    materials = []
    
    for i, dir_path in enumerate(dirs):
        number = extract_number(dir_path.name)
        if number is None:
            continue
        
        # 提取标题（去掉编号）
        title = dir_path.name.split('.', 1)[1] if '.' in dir_path.name else dir_path.name
        
        # 查找 PDF 文件
        pdf_files = [f for f in dir_path.iterdir() if f.suffix.lower() == '.pdf']
        if not pdf_files:
            print(f"[{number:3d}] {title} - No PDF found")
            continue
        
        pdf_path = pdf_files[0]
        print(f"[{number:3d}/{len(dirs)}] Processing: {title}")
        
        # OCR 提取文本
        raw_text = ocr_pdf(pdf_path)
        if not raw_text:
            print(f"  Warning: OCR returned empty text")
            continue
        
        # 分离日文和翻译
        japanese_text, translation_text = split_japanese_and_translation(raw_text)
        
        # 添加假名注音
        japanese_annotated = add_furigana(japanese_text)
        
        material = {
            'id': f'material-{number:03d}',
            'title': title,
            'collection': '附赠100篇',
            'japanese': japanese_annotated,
            'translation': translation_text if translation_text else None,
            'textStatus': 'ready',
            'metadata': {
                'number': number,
                'sourceDir': dir_path.name,
                'pdfFile': pdf_path.name,
                'ocrProcessed': True
            }
        }
        
        materials.append(material)
        print(f"  Extracted {len(japanese_annotated)} chars Japanese, {len(translation_text)} chars translation")
    
    return materials


def main():
    print("=" * 60)
    print("素材阅读馆数据导入工具")
    print("=" * 60)
    
    # 检查 OCR 工具
    if not OCR_TOOL.exists():
        print(f"Error: OCR tool not found at {OCR_TOOL}")
        print("Please compile /tmp/jp_ocr.swift first")
        sys.exit(1)
    
    # 检查数据库
    if not DB_PATH.exists():
        print(f"Error: Database not found at {DB_PATH}")
        sys.exit(1)
    
    # 1. 清空表
    deleted = clear_materials_table()
    
    # 2. 处理 PDF
    materials = process_pdfs()
    
    if not materials:
        print("No materials extracted")
        sys.exit(1)
    
    # 3. 导入数据库
    import_materials(materials)
    
    # 4. 验证
    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM StudyMaterial WHERE collection='附赠100篇'")
    count = cursor.fetchone()[0]
    conn.close()
    
    print("=" * 60)
    print(f"SUCCESS: Imported {count} materials")
    print("=" * 60)


if __name__ == '__main__':
    main()
