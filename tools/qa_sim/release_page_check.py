# -*- coding: utf-8 -*-
"""Release landing page gate (2026-11-15): the page must be self-contained and
canon-correct. Four rules, each with a biting mutant in --demo:

  L1 no external URL in index.html, styles.css or main.js: the fonts are local
     OFL copies, so the page renders offline with no third-party request.
  L2 every local src/href and every CSS url() resolves to a file on disk, and
     the three local font files are present (no broken media).
  L3 the name is "Last Streetlight", never "The Last Streetlight" with a
     capital T (owner, Session 23; tools/qa_sim/title_check.py). Lower-case
     "the last streetlight" refers to the lamp in the world and is allowed.
  L4 :focus-visible outlines are defined for keyboard users (WCAG 2.4.7).

usage: python tools/qa_sim/release_page_check.py [--root DIR] [--demo]
"""
import pathlib
import re
import shutil
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
PAGE = pathlib.Path("web/store")
HTML = "index.html"
CSS = "assets/css/styles.css"
JS = "assets/js/main.js"
FONTS = ("BebasNeue-Regular.ttf", "RobotoCondensed-Full-VF.ttf", "ShareTechMono-Regular.ttf")
EXTERNAL = re.compile(r"https?://", re.I)
CDN = re.compile(r"fonts\.googleapis|fonts\.gstatic", re.I)
BAD_TITLE = re.compile(r"\bThe[ \xa0-]*Last[ \xa0-]*Streetlight\b")
ASSET_REF = re.compile(r'(?:src|href)="([^"#]+)"')
CSS_URL = re.compile(r'url\(\s*["\']?([^"\')]+)["\']?\s*\)')


def read(root, rel):
    p = root / rel
    return p.read_text(encoding="utf-8", errors="replace") if p.is_file() else ""


def findings(root):
    out = []
    page = root / PAGE
    html = read(page, HTML)
    css = read(page, CSS)
    js = read(page, JS)
    if not html:
        return ["L0 index.html missing"]

    # L1: no network dependency at all.
    for name, text in ((HTML, html), (CSS, css), (JS, js)):
        if EXTERNAL.search(text):
            out.append("L1 external URL in %s" % name)
        if CDN.search(text):
            out.append("L1 font CDN reference in %s" % name)
    for name in FONTS:
        if not (page / "assets" / "fonts" / name).is_file():
            out.append("L2 local font %s missing" % name)
    if "@font-face" not in css or css.count("@font-face") < len(FONTS):
        out.append("L2 @font-face is not declaring all %d local fonts" % len(FONTS))

    # L2: every referenced local asset resolves.
    for ref in ASSET_REF.findall(html):
        if EXTERNAL.search(ref):
            continue
        if not (page / ref).is_file():
            out.append("L2 broken reference %s in %s" % (ref, HTML))
    for ref in CSS_URL.findall(css):
        if EXTERNAL.search(ref):
            continue
        if not (page / CSS).parent.joinpath(ref).resolve().is_file():
            out.append("L2 broken CSS url() %s" % ref)

    # L3: the owner's title canon, in the page and in its metadata.
    for i, line in enumerate(html.splitlines(), 1):
        if BAD_TITLE.search(line):
            out.append("L3 'The Last Streetlight' at %s:%d" % (HTML, i))

    # L4: keyboard focus is visible.
    if ":focus-visible" not in css or "outline:" not in css:
        out.append("L4 no visible focus-visible outline in %s" % CSS)
    return out


def demo():
    """The unmutated page passes; each of the four mutants must bite."""
    with tempfile.TemporaryDirectory() as tmp:
        base = pathlib.Path(tmp) / "repo" / PAGE
        shutil.copytree(ROOT / PAGE, base)
        repo = pathlib.Path(tmp) / "repo"
        real = findings(repo)
        mutants = {}

        def mutant(name, edit):
            dst = pathlib.Path(tmp) / name / PAGE
            shutil.copytree(ROOT / PAGE, dst)
            edit(dst)
            mutants[name] = findings(pathlib.Path(tmp) / name)

        # M1: the Google Fonts CDN link comes back.
        def m1(d):
            p = d / HTML
            p.write_text(p.read_text(encoding="utf-8").replace(
                '<link rel="stylesheet" href="assets/css/styles.css" />',
                '<link href="https://fonts.googleapis.com/css2?family=Bebas+Neue" rel="stylesheet" />\n'
                '<link rel="stylesheet" href="assets/css/styles.css" />'), encoding="utf-8")
        mutant("external_font", m1)

        # M2: a media reference points at a file that does not exist.
        def m2(d):
            p = d / HTML
            p.write_text(p.read_text(encoding="utf-8").replace(
                'src="assets/images/01_main_menu', 'src="assets/images/99_missing'), encoding="utf-8")
        mutant("missing_asset", m2)

        # M3: the old "The Last Streetlight" spelling returns.
        def m3(d):
            p = d / HTML
            p.write_text(p.read_text(encoding="utf-8").replace(
                "Last Streetlight — A first-person", "The Last Streetlight — A first-person"), encoding="utf-8")
        mutant("bad_title", m3)

        # M4: the focus outline is removed.
        def m4(d):
            p = d / CSS
            p.write_text(p.read_text(encoding="utf-8").replace(":focus-visible", ":focus-lost"), encoding="utf-8")
        mutant("no_focus", m4)

        bitten = {k: len(v) for k, v in mutants.items() if v}
        ok = not real and len(bitten) == len(mutants)
        print("release_page_check --demo: real=%s %s -> %s" % (
            "PASS" if not real else "FAIL", bitten, "BITES" if ok else "VACUOUS"))
        return 0 if ok else 1


def main(argv):
    if "--demo" in argv:
        return demo()
    root = pathlib.Path(argv[argv.index("--root") + 1]) if "--root" in argv else ROOT
    bad = findings(root)
    for f in bad:
        print("FAIL", f)
    print("release_page_check: %d finding(s)" % len(bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
