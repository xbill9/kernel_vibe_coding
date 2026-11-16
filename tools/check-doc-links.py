#!/usr/bin/env python3
"""check-doc-links — find broken local references in the repo's markdown.

Usage: tools/check-doc-links.py [repo-root]

Checks two kinds of reference in every tracked *.md file:
  - markdown links [text](target) whose target is a local path, resolved
    against the file's own directory (anchors and query strings dropped);
  - backticked repo paths such as `intel/scripts/kernel-build`, resolved
    against the repo root. A path with a placeholder (<...>, *, $) is skipped.

Exit: 0 nothing broken, 1 broken references found.
"""
import re
import subprocess
import sys
from pathlib import Path

TOP_DIRS = ("intel/", "arm/", "articles/", "tools/")
LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
TICK = re.compile(r"`([^`\s]+)`")
FENCE = re.compile(r"^\s*(```|~~~)")


def tracked_md(root: Path) -> list[Path]:
    out = subprocess.run(["git", "-C", str(root), "ls-files", "*.md"],
                         capture_output=True, text=True, check=True).stdout
    return [root / p for p in out.splitlines()
            if "/evidence/" not in p and (root / p).is_file()]


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    files = tracked_md(root)
    broken = 0
    for md in files:
        in_fence = False
        for n, line in enumerate(md.read_text(errors="replace").splitlines(), 1):
            if FENCE.match(line):
                in_fence = not in_fence
                continue
            if in_fence:
                continue
            for target in LINK.findall(line):
                if re.match(r"^[a-z][a-z0-9+.-]*:", target) or target.startswith("#"):
                    continue
                path = target.split("#", 1)[0].split("?", 1)[0]
                if path and not (md.parent / path).exists():
                    print(f"{md.relative_to(root)}:{n}: link -> {target}")
                    broken += 1
            for tok in TICK.findall(line):
                tok = tok.rstrip(".,:;")
                if not tok.startswith(TOP_DIRS) or re.search(r"[<>*${}]", tok):
                    continue
                if not (root / tok).exists():
                    print(f"{md.relative_to(root)}:{n}: path `{tok}`")
                    broken += 1
    print(f"{len(files)} markdown files, {broken} broken reference(s)")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
