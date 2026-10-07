# -*- coding: utf-8 -*-
"""Counts the proven rows of docs/ACCEPTANCE_CHECKLIST.md (rc16 S9): a row is proven when its Result starts with PASS, BATTERY or PT.

usage: python tools/accept_count.py [--demo]
Prints "accept=<proven>/<rows>" and the Result of every row that is not proven, one per line (id, result). Exit 1 when no row is found.
OWNER, NOT-VERIFIABLE, ROADMAP, DECIDED, BY-DESIGN-ABSENT and OPEN rows are the not-proven ones.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
ROW = re.compile(r"^\| ([A-Za-z0-9.]+) \|")
PROVEN = re.compile(r"(PASS|BATTERY|PT)\b")


def count(text):
    proven, other = 0, []
    for line in text.splitlines():
        if line.startswith("## rc16 gap table"):
            break  # the gap table repeats the open rows; it is not part of the 200
        m = ROW.match(line)
        if not m or m.group(1) == "ID":
            continue
        result = line.rstrip().rstrip("|").split("|")[-1].strip()
        if PROVEN.match(result):
            proven += 1
        else:
            other.append((m.group(1), result))
    return proven, other


def demo():
    sample = "| ID | Promise | GDD | Proof | Result |\n|---|---|---|---|---|\n| A1 | x | 1 | p | PASS(closeout) |\n| A2 | x | 1 | p | BATTERY |\n| A3 | x | 1 | p | PT-A06 |\n| A4 | x | 1 | p | DECIDED |\n| A5 | x | 1 | p | OWNER |\n"
    proven, other = count(sample)
    ok = proven == 3 and [i for i, _ in other] == ["A4", "A5"]
    print("accept_count demo: %s" % ("3 proven, 2 not" if ok else "WRONG %s %s" % (proven, other)))
    return 0 if ok else 1


def main(argv):
    if "--demo" in argv:
        return demo()
    proven, other = count((ROOT / "docs" / "ACCEPTANCE_CHECKLIST.md").read_text(encoding="utf-8"))
    print("accept=%d/%d" % (proven, proven + len(other)))
    for row_id, result in other:
        print("%-8s %s" % (row_id, result))
    return 0 if proven else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
