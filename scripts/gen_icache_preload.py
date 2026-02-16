#!/usr/bin/env python3
"""
Generate direct I-cache preload files from a readmemh-style BIOS image.

Purpose:
- Convert `bios.hex` (word-addressed readmemh stream) into the six memory init
  files consumed by `cache.v` when `FPGA_ICACHE_PRELOAD=1`.
- Keep boot instructions available without RAM-side preload in FPGA builds.

Outputs:
- icache_way0.mem / icache_way1.mem   (256 lines, 512-bit cache lines)
- icache_tagv0.mem / icache_tagv1.mem (256 lines, 14-bit tag+valid payloads)

Invariants:
- Address split matches cache.v exactly:
  [26:14] tag, [13:6] set, [5:2] word-in-line, [1:0] byte
- Two-way set-associative capacity is enforced at generation time.
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
from dataclasses import dataclass
from typing import Dict, List


NUM_SETS = 256
LINE_WORDS = 16
WORD_MASK = 0xFFFFFFFF
TAG_MASK = (1 << 13) - 1


@dataclass
class TagLine:
    first_word_addr: int
    words: List[int]


def _strip_comments(line: str) -> str:
    line = line.split("//", 1)[0]
    line = line.split("#", 1)[0]
    return line.strip()


def _parse_token_as_int(token: str) -> int:
    token = token.strip().replace("_", "")
    if token.lower().startswith("0x"):
        token = token[2:]
    if not token:
        raise ValueError("empty hex token")
    return int(token, 16)


def parse_readmemh_words(hex_path: pathlib.Path) -> Dict[int, int]:
    """
    Parse a readmemh stream into a sparse word-addressed dictionary.
    Supports '@<addr>' directives and regular hex tokens.
    """
    words: Dict[int, int] = {}
    next_word_addr = 0
    with hex_path.open("r", encoding="utf-8") as f:
        for lineno, raw_line in enumerate(f, start=1):
            line = _strip_comments(raw_line)
            if not line:
                continue
            for token in re.split(r"\s+", line):
                if not token:
                    continue
                if token.startswith("@"):
                    next_word_addr = _parse_token_as_int(token[1:])
                    continue
                try:
                    value = _parse_token_as_int(token) & WORD_MASK
                except ValueError as exc:
                    raise ValueError(
                        f"{hex_path}:{lineno}: invalid token '{token}': {exc}"
                    ) from exc
                words[next_word_addr] = value
                next_word_addr += 1
    return words


def build_set_tag_lines(words: Dict[int, int]) -> List[Dict[int, TagLine]]:
    """
    Group sparse words into cache-set/tag line payloads.
    """
    set_map: List[Dict[int, TagLine]] = [dict() for _ in range(NUM_SETS)]
    for word_addr, value in sorted(words.items()):
        byte_addr = word_addr << 2
        set_idx = (byte_addr >> 6) & 0xFF
        tag = (byte_addr >> 14) & TAG_MASK
        word_idx = (byte_addr >> 2) & 0xF

        tag_lines = set_map[set_idx]
        if tag not in tag_lines:
            tag_lines[tag] = TagLine(first_word_addr=word_addr, words=[0] * LINE_WORDS)
        tag_lines[tag].words[word_idx] = value
    return set_map


def pack_words_to_line(words: List[int]) -> int:
    line_value = 0
    for idx, word in enumerate(words):
        line_value |= (word & WORD_MASK) << (idx * 32)
    return line_value


def write_mem_file(path: pathlib.Path, values: List[int], width_bits: int) -> None:
    width_hex = (width_bits + 3) // 4
    with path.open("w", encoding="utf-8") as f:
        for value in values:
            f.write(f"{value:0{width_hex}x}\n")


def generate_icache_files(input_hex: pathlib.Path, out_dir: pathlib.Path) -> None:
    words = parse_readmemh_words(input_hex)
    set_map = build_set_tag_lines(words)

    way0 = [0] * NUM_SETS
    way1 = [0] * NUM_SETS
    tagv0 = [0] * NUM_SETS
    tagv1 = [0] * NUM_SETS

    overflow_sets: List[str] = []
    for set_idx in range(NUM_SETS):
        tag_lines = set_map[set_idx]
        if not tag_lines:
            continue

        sorted_entries = sorted(
            tag_lines.items(), key=lambda kv: (kv[1].first_word_addr, kv[0])
        )
        if len(sorted_entries) > 2:
            tags_fmt = ", ".join(f"0x{tag:03x}" for tag, _ in sorted_entries)
            overflow_sets.append(f"set 0x{set_idx:02x}: {len(sorted_entries)} tags [{tags_fmt}]")
            continue

        tag0, line0 = sorted_entries[0]
        way0[set_idx] = pack_words_to_line(line0.words)
        tagv0[set_idx] = (1 << 13) | tag0

        if len(sorted_entries) == 2:
            tag1, line1 = sorted_entries[1]
            way1[set_idx] = pack_words_to_line(line1.words)
            tagv1[set_idx] = (1 << 13) | tag1

    if overflow_sets:
        details = "\n".join(overflow_sets[:8])
        if len(overflow_sets) > 8:
            details += f"\n... and {len(overflow_sets) - 8} more set(s)"
        raise RuntimeError(
            "I-cache preload overflow: more than 2 tags mapped to some sets.\n"
            f"{details}"
        )

    out_dir.mkdir(parents=True, exist_ok=True)
    write_mem_file(out_dir / "icache_way0.mem", way0, 512)
    write_mem_file(out_dir / "icache_way1.mem", way1, 512)
    write_mem_file(out_dir / "icache_tagv0.mem", tagv0, 14)
    write_mem_file(out_dir / "icache_tagv1.mem", tagv1, 14)

    used_way0 = sum(1 for entry in tagv0 if (entry >> 13) & 1)
    used_way1 = sum(1 for entry in tagv1 if (entry >> 13) & 1)
    resident_sets = sum(
        1 for i in range(NUM_SETS)
        if (((tagv0[i] >> 13) & 1) or ((tagv1[i] >> 13) & 1))
    )
    print(
        "[gen_icache_preload] wrote preload files from "
        f"{input_hex} to {out_dir}\n"
        f"[gen_icache_preload] words={len(words)} resident_sets={resident_sets} "
        f"way0_sets={used_way0} way1_sets={used_way1}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate I-cache preload mem files from bios.hex"
    )
    parser.add_argument(
        "--input",
        required=True,
        help="Path to readmemh BIOS image (e.g. Dioptase-OS/build/bios.hex)",
    )
    parser.add_argument(
        "--out-dir",
        default="data",
        help="Output directory for icache_*.mem files (default: data)",
    )
    args = parser.parse_args()

    input_hex = pathlib.Path(args.input)
    out_dir = pathlib.Path(args.out_dir)

    if not input_hex.exists():
        print(f"error: input file does not exist: {input_hex}", file=sys.stderr)
        return 1

    try:
        generate_icache_files(input_hex, out_dir)
    except Exception as exc:  # pylint: disable=broad-except
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
