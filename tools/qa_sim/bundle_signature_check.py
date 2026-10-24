# -*- coding: utf-8 -*-
"""s31 (v10.0.0-close): the bundle record's signature honesty.

usage: python tools/qa_sim/bundle_signature_check.py [--artifacts docs/RELEASE_ARTIFACTS.md] [--checklist docs/RELEASE_CHECKLIST.md] [--demo]
FAIL when a bundle the record marks DEBUG-SIGNED is also marked uploadable or shippable in the same file: the debug-signed
bundle must never be uploaded (Play rejects its signature), so the record may only name it with a do-not-upload line.
--demo proves it both ways: a debug line that also says shippable FAILs, the do-not-upload line passes.
"""
import re
import sys

UPLOADABLE = re.compile(r"\b(upload|shippable|ship this|uploadable|to play console|go to play)\b", re.I)
NOT_UPLOAD = re.compile(r"(do not upload|must not be uploaded|never be uploaded)", re.I)
DEBUG = re.compile(r"DEBUG-SIGNED", re.I)


def findings(text):
    out = []
    for line in text.splitlines():
        if not DEBUG.search(line):
            continue
        if UPLOADABLE.search(line) and not NOT_UPLOAD.search(line):
            out.append("FAIL a DEBUG-SIGNED bundle is also marked uploadable/shippable: %s" % line.strip()[:160])
    return out


def demo():
    bad = "- the bundle is DEBUG-SIGNED and shippable to Play."
    good = "- the bundle is DEBUG-SIGNED - DO NOT UPLOAD IT ANYWHERE."
    assert findings(bad) and not findings(good), (findings(bad), findings(good))
    print("bundle_signature_check demo OK (a debug-signed line that says shippable FAILs; the do-not-upload line passes)")
    return 0


def main(argv):
    if "--demo" in argv:
        return demo()
    texts = []
    for flag, default in (("--artifacts", "docs/RELEASE_ARTIFACTS.md"), ("--checklist", "docs/RELEASE_CHECKLIST.md")):
        path = argv[argv.index(flag) + 1] if flag in argv else default
        texts.append((path, open(path, encoding="utf-8").read()))
    fails = [f.replace("FAIL", "FAIL %s:" % p, 1) for p, t in texts for f in findings(t)]
    for f in fails:
        print(f)
    print("bundle_signature_check: %d file(s), %d finding(s)" % (len(texts), len(fails)))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
