#!/usr/bin/env python3
"""
Audio processing pipeline for Japanese learning dataset.

Scans MP3 files from 附赠100篇 and MP4 files from 短文视频,
normalizes them to 128kbps MP3 with audio-{NNN}.mp3 naming,
and writes a manifest.

Numbering:
  附赠100篇 directories (1..100) → audio-001 .. audio-100
  短文视频   files     (1..101) → audio-101 .. audio-201

Note: directory 42 (天气预报) has no audio, so audio-042 is skipped.
Total produced: 99 + 101 = 200 files.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Optional

FFMPEG = "/Users/harisucici/.hermes/tools/ffmpeg-9.0.1-darwin-arm64/ffmpeg"
SRC_MP3_DIR = Path("/Volumes/Mac Data/Documents/附赠100篇（音频+PDF）")
SRC_MP4_DIR = Path("/Volumes/Mac Data/Documents/短文视频")
OUT_DIR = Path(
    "/Volumes/Mac Data/Documents/StudioProjects/"
    "japanese-learning/ja-learning-backend/data/audio"
)
MANIFEST_PATH = OUT_DIR / "audio-manifest.json"


def find_mp3_in_dir(d: Path) -> Optional[Path]:
    """Return the audio file inside a 附赠100篇 sub-directory (case-insensitive)."""
    for entry in d.iterdir():
        if entry.is_file() and entry.suffix.lower() == ".mp3":
            return entry
    return None


def parse_dir_number(name: str) -> Optional[int]:
    """Extract leading integer from directory name like '1.暑假里想做的事'."""
    m = re.match(r"(\d+)", name)
    return int(m.group(1)) if m else None


def parse_file_number(name: str) -> Optional[int]:
    """Extract leading integer from filename like '01马.mp4' or '100相机.mp4'."""
    stem = Path(name).stem
    m = re.match(r"(\d+)", stem)
    return int(m.group(1)) if m else None


def title_from_dir(name: str) -> str:
    """Strip leading 'NN.' from directory name to get the title."""
    return re.sub(r"^\d+\.", "", name)


def title_from_file(name: str) -> str:
    """Strip leading digits from filename stem to get the title."""
    stem = Path(name).stem
    return re.sub(r"^\d+", "", stem)


def convert_to_mp3(src: Path, dst: Path) -> None:
    """Convert source audio (MP3 or MP4) to 128kbps MP3 using ffmpeg."""
    cmd = [
        FFMPEG,
        "-y",
        "-i", str(src),
        "-vn",
        "-acodec", "libmp3lame",
        "-b:a", "128k",
        "-ar", "44100",
        "-ac", "2",
        str(dst),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(
            f"ffmpeg failed on {src.name}: {result.stderr.strip().splitlines()[-1] if result.stderr else 'unknown error'}"
        )


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    manifest = []
    processed = 0
    errors = []

    # ── Part 1: 附赠100篇 (MP3) → audio-001 .. audio-100 ──
    print("=== Scanning 附赠100篇 ===")
    src_dirs = sorted(
        [d for d in SRC_MP3_DIR.iterdir() if d.is_dir()],
        key=lambda d: parse_dir_number(d.name) or 0,
    )
    for src_dir in src_dirs:
        num = parse_dir_number(src_dir.name)
        if num is None:
            continue
        mp3 = find_mp3_in_dir(src_dir)
        if mp3 is None:
            print(f"  SKIP (no audio): {src_dir.name}")
            continue
        audio_num = num  # 1..100
        out_name = f"audio-{audio_num:03d}.mp3"
        out_path = OUT_DIR / out_name
        title = title_from_dir(src_dir.name)
        try:
            convert_to_mp3(mp3, out_path)
            size = out_path.stat().st_size
            manifest.append({
                "id": f"audio-{audio_num:03d}",
                "number": audio_num,
                "source": str(mp3),
                "source_type": "mp3",
                "source_group": "附赠100篇",
                "title": title,
                "filename": out_name,
                "size_bytes": size,
            })
            processed += 1
            print(f"  [{processed:3d}] {out_name} <- {src_dir.name}/{mp3.name}")
        except RuntimeError as e:
            errors.append({"file": out_name, "source": str(mp3), "error": str(e)})
            print(f"  ERROR: {e}")

    # ── Part 2: 短文视频 (MP4) → audio-101 .. audio-201 ──
    print("\n=== Scanning 短文视频 ===")
    mp4_files = sorted(
        [f for f in SRC_MP4_DIR.iterdir() if f.suffix.lower() == ".mp4"],
        key=lambda f: parse_file_number(f.name) or 0,
    )
    for mp4 in mp4_files:
        num = parse_file_number(mp4.name)
        if num is None:
            continue
        audio_num = num + 100  # 01→101, ..., 101→201
        out_name = f"audio-{audio_num:03d}.mp3"
        out_path = OUT_DIR / out_name
        title = title_from_file(mp4.name)
        try:
            convert_to_mp3(mp4, out_path)
            size = out_path.stat().st_size
            manifest.append({
                "id": f"audio-{audio_num:03d}",
                "number": audio_num,
                "source": str(mp4),
                "source_type": "mp4",
                "source_group": "短文视频",
                "title": title,
                "filename": out_name,
                "size_bytes": size,
            })
            processed += 1
            print(f"  [{processed:3d}] {out_name} <- {mp4.name}")
        except RuntimeError as e:
            errors.append({"file": out_name, "source": str(mp4), "error": str(e)})
            print(f"  ERROR: {e}")

    # ── Write manifest ──
    manifest.sort(key=lambda m: m["number"])
    MANIFEST_PATH.write_text(
        json.dumps(
            {
                "version": 1,
                "total_files": len(manifest),
                "total_errors": len(errors),
                "files": manifest,
                "errors": errors,
            },
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )

    print(f"\n=== Done ===")
    print(f"Processed : {processed}")
    print(f"Errors    : {len(errors)}")
    print(f"Manifest  : {MANIFEST_PATH}")
    print(f"Output dir: {OUT_DIR}")

    return 0 if len(errors) == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
