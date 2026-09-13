#!/usr/bin/env python3
"""
check_card_art_changes.py — pre-commit gate for card-art commits/PRs.

Commission: reject card-art PRs where `git diff --stat content/cards/` shows
zero changes. The last card-art branch (`arena/card-unique-rescue`) shipped
zero card changes while certifying art that did not exist; this gate makes
that outcome impossible at commit time (and, with --ci-base, at PR level).

Rule:
  A commit is a *card-art commit* when
    - the branch name contains "card" (case-insensitive), e.g.
      arena/card-art-pipeline, or
    - CARD_ART_FORCE=1 is set (CI/testing), or
    - it is run with --ci-base REF (PR mode: diff <base>...HEAD), or
    - the staged changes already touch content/cards/ (trivially passing).
  When it is one, it must change >= 1 file under content/cards/
  (staged A/C/M/R paths, or <base>...HEAD paths in CI mode).

Bypass:
  CARD_ART_BYPASS="<reason>"  (logged to stderr, passes)
  git commit --no-verify      (the bootstrap commit that installs this gate
                               is the one sanctioned use)

Testing (from repo root):
  CARD_ART_FORCE=1 python3 scripts/check_card_art_changes.py      # must FAIL
  CARD_ART_FORCE=1 CARD_ART_BYPASS="test" python3 ...             # passes
  CARD_ART_BRANCH=card-test python3 ...                           # simulate branch
  python3 scripts/check_card_art_changes.py --ci-base origin/main # PR mode

Stdlib only.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys

CARDS_PATHSPEC = "content/cards/"


def run_git(*args: str) -> tuple[int, str]:
    try:
        p = subprocess.run(
            ["git", *args],
            capture_output=True, text=True, cwd=os.environ.get("IGRA_ROOT") or None,
        )
        return p.returncode, (p.stdout or "") + (p.stderr or "")
    except FileNotFoundError:
        return 127, "git not found"


def current_branch() -> str:
    b = os.environ.get("CARD_ART_BRANCH", "").strip()
    if b:
        return b
    rc, out = run_git("rev-parse", "--abbrev-ref", "HEAD")
    return out.strip() if rc == 0 else ""


def changed_paths(ci_base: str | None) -> tuple[list[str], str]:
    """Return (changed paths, stat text) for the relevant diff."""
    if ci_base:
        rc, out = run_git("diff", "--name-only", f"{ci_base}...HEAD", "--", "content/cards")
        stat_rc, stat = run_git("diff", "--stat", f"{ci_base}...HEAD", "--", "content/cards")
        src = f"git diff --stat {ci_base}...HEAD -- content/cards/"
    else:
        rc, out = run_git("diff", "--cached", "--name-only", "--diff-filter=ACMR",
                          "--", "content/cards")
        stat_rc, stat = run_git("diff", "--cached", "--stat", "--", "content/cards")
        src = "git diff --cached --stat -- content/cards/"
    if rc != 0:
        sys.stderr.write(f"check_card_art_changes: git error: {out.strip()}\n")
        sys.exit(128)
    paths = [l for l in out.splitlines() if l.strip()]
    return paths, (stat or "").strip(), src


def main() -> int:
    ci_base = None
    argv = sys.argv[1:]
    if "--ci-base" in argv:
        i = argv.index("--ci-base")
        if i + 1 >= len(argv):
            sys.exit("check_card_art_changes: --ci-base requires a ref")
        ci_base = argv[i + 1]

    branch = current_branch()
    force = os.environ.get("CARD_ART_FORCE") == "1"
    bypass = os.environ.get("CARD_ART_BYPASS")

    # Staged (or ci) changes anywhere — needed to detect trivially-passing commits.
    if ci_base:
        rc, out = run_git("diff", "--name-only", f"{ci_base}...HEAD", "--diff-filter=ACMR")
        rc2, _ = run_git("diff", "--name-only", f"{ci_base}...HEAD", "--", "content/cards")
    else:
        rc, out = run_git("diff", "--cached", "--name-only", "--diff-filter=ACMR")
        rc2, _ = run_git("diff", "--cached", "--name-only", "--", "content/cards")
    if rc != 0:
        sys.stderr.write(f"check_card_art_changes: git error: {out.strip()}\n")
        return 128
    all_paths = [l for l in out.splitlines() if l.strip()]
    touches_cards = any(p.startswith("content/cards/") or p == "content/cards"
                        for p in all_paths)

    triggered = ci_base is not None or force or touches_cards or re.search(r"card", branch, re.I) is not None

    if not triggered:
        print("check_card_art_changes: not a card-art commit (branch "
              f"'{branch or 'unknown'}', no content/cards/ changes) — pass")
        return 0

    paths, stat, src = changed_paths(ci_base)

    if bypass:
        sys.stderr.write(
            f"check_card_art_changes: BYPASSED on request (reason: {bypass}) — "
            f"zero content/cards/ changes in this {('PR vs ' + ci_base) if ci_base else 'commit'}"
        )
        return 0

    if paths:
        print(f"check_card_art_changes: card-art change detected ({len(paths)} file(s) under content/cards/) — pass")
        return 0

    # Rejected: a card-art commit/PR with zero card changes.
    sys.stderr.write("\n")
    sys.stderr.write("=" * 72 + "\n")
    sys.stderr.write("check_card_art_changes: REJECTED — card-art commit with ZERO\n")
    sys.stderr.write("changes under content/cards/.\n")
    sys.stderr.write("=" * 72 + "\n")
    sys.stderr.write(f"triggered by: {('PR mode vs ' + ci_base) if ci_base else ('CARD_ART_FORCE=1' if force else f'branch name {branch!r}')}\n\n")
    sys.stderr.write(f"$ {src}\n")
    if stat:
        sys.stderr.write(stat + "\n")
    else:
        sys.stderr.write("(no output — the diff under content/cards/ is empty)\n")
    sys.stderr.write("\n")
    sys.stderr.write("Every card-art commit/PR must land at least one graded card\n")
    sys.stderr.write("master in content/cards/ (see docs/CARD_ART_BRIEF.md, section 8).\n")
    sys.stderr.write("Grade raws first:  scripts/regen_cards_v2.py --raw-dir <raws>\n")
    sys.stderr.write("Bypass (logged, rare):  CARD_ART_BYPASS=\"<reason>\" \n")
    sys.stderr.write("or:  git commit --no-verify\n")
    return 1


if __name__ == "__main__":
    sys.exit(main())
