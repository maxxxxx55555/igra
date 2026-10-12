# -*- coding: utf-8 -*-
"""Control characters in the documents (Session 21): a Windows path or a regex written through a shell heredoc loses its backslashes.

usage: python tools/qa_sim/doc_ctrl_check.py [--demo]
Scans every .md, .tsv and .json under docs/ plus the root .md files for a control character: C0 except tab, line feed and carriage return
(a backspace, a bell, a form feed, a vertical tab ...) and C1 (U+0080 to U+009F). The Session 21 slip was `..\\_BACKUPS\\2026-10-11_...\\build\\tls.aab`
written through a heredoc: `\\2026` became U+0082 and `\\b` a backspace, in two store-facing documents, and no gate saw it. Exit 1 on a hit, one line per hit.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
CTRL = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\x9f]")


def hits(text):
    return [(text.count("\n", 0, m.start()) + 1, "U+%04X" % ord(m.group())) for m in CTRL.finditer(text)]


def documents():
    out = [p for p in (ROOT / "docs").rglob("*") if p.suffix in (".md", ".tsv", ".json") and p.is_file()]
    return sorted(out + list(ROOT.glob("*.md")))


def demo():
    assert hits("a\tb\r\nc\n") == []
    assert hits("..\\_BACKUPS\x826-10-11\x08uild") == [(1, "U+0082"), (1, "U+0008")]
    assert hits("one\ntwo\x0cthree") == [(2, "U+000C")]
    print("doc_ctrl_check demo OK (tab and line ends pass, a C1 and a backspace and a form feed are found with their line)")


def main():
    if "--demo" in sys.argv:
        demo()
        return 0
    found = 0
    for p in documents():
        for line, code in hits(p.read_text(encoding="utf-8", errors="replace")):
            print("%s:%d %s" % (p.relative_to(ROOT).as_posix(), line, code))
            found += 1
    print("doc_ctrl_check: %d control character(s) in %d document(s)" % (found, len(documents())))
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
