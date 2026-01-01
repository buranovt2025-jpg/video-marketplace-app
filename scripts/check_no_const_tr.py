#!/usr/bin/env python3
"""
Fail CI if `.tr` is used inside a `const` expression.

Flutter web compilation can fail when using GetX translations (`.tr`, `.trParams`)
inside const widgets/trees. This script is a heuristic scanner that aims to catch
the problematic patterns early and fail fast.
"""

from __future__ import annotations

import pathlib
import re
import sys
from dataclasses import dataclass


RE_CONST_TOKEN = re.compile(r"(^|[^\w])const([^\w]|$)")
RE_TR = re.compile(r"\.tr(Params)?\b")

def strip_line_comments_only(line: str) -> str:
    return re.sub(r"//.*$", "", line)


def strip_strings_and_line_comments(line: str) -> str:
    # Remove // comments (good enough for our use: we only care about `.tr` tokens).
    line = re.sub(r"//.*$", "", line)

    # Remove single-quoted and double-quoted string literals (non-raw, no multiline).
    # This is a best-effort heuristic and intentionally simple.
    line = re.sub(r"'([^'\\]|\\.)*'", "''", line)
    line = re.sub(r'"([^"\\]|\\.)*"', '""', line)
    return line


def paren_delta(line: str) -> int:
    s = strip_strings_and_line_comments(line)
    return s.count("(") - s.count(")")


@dataclass(frozen=True)
class Hit:
    file: pathlib.Path
    const_line: int
    tr_line: int
    tr_text: str


def scan_file(path: pathlib.Path) -> list[Hit]:
    hits: list[Hit] = []
    try:
        text = path.read_text(encoding="utf-8")
    except Exception:
        return hits

    active = False
    balance = 0
    const_start_line = 0
    const_start_col = 0

    lines = text.splitlines()
    for i, raw in enumerate(lines, start=1):
        line_no_comments = strip_line_comments_only(raw)

        if not active:
            # Look for a const expression start on this line.
            # IMPORTANT: search on a string with the same length as `raw`,
            # otherwise match indices won't line up with `raw`.
            m = RE_CONST_TOKEN.search(line_no_comments)
            if not m:
                continue

            const_start_line = i
            const_start_col = m.start(0)
            tail = raw[const_start_col:]

            # Track parentheses only within this const tail.
            balance = paren_delta(tail)
            active = balance > 0

            # Only consider `.tr` that appears *inside* the const tail, not earlier in the line.
            if RE_TR.search(strip_strings_and_line_comments(tail)):
                hits.append(Hit(file=path, const_line=const_start_line, tr_line=i, tr_text=raw.rstrip("\n")))

            # If it was a single-line const (no parens to track), we're done.
            if not active:
                balance = 0
                const_start_line = 0
                const_start_col = 0
            continue

        # We are inside a multi-line const expression.
        if RE_TR.search(strip_strings_and_line_comments(raw)):
            hits.append(Hit(file=path, const_line=const_start_line, tr_line=i, tr_text=raw.rstrip("\n")))

        balance += paren_delta(raw)
        if balance <= 0:
            active = False
            balance = 0
            const_start_line = 0
            const_start_col = 0

    return hits


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    lib = root / "lib"
    if not lib.is_dir():
        return 0

    hits: list[Hit] = []
    for p in lib.rglob("*.dart"):
        hits.extend(scan_file(p))

    if not hits:
        print("OK: no `.tr` inside `const` expressions found.")
        return 0

    print("ERROR: found `.tr` inside `const` expressions (breaks Flutter web build):")
    for h in hits[:100]:
        rel = h.file.relative_to(root)
        print(f"- {rel}:{h.tr_line} (const starts at {h.const_line}): {h.tr_text}")
    if len(hits) > 100:
        print(f"... and {len(hits) - 100} more")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

