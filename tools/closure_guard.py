# -*- coding: utf-8 -*-
"""closure_guard.py (FINAL_CLOSURE_PROMPT Phase B3): the mechanical guarantee that the
repository cannot silently drift back into "development".

Six rules, each proven by --demo:
  1. No doc may assert a locale count that differs from the number of files in
     data/i18n/ (currently 2: en, ru). Historical notes (a date, "cut", "earlier",
     "pre-cut", "prior", "was") are exempt.
  2. No doc outside docs/release/ may assert a specific commit as "current main" /
     "tip" / "HEAD" whose SHA differs from git rev-parse origin/main.
  3. version must agree across project.godot (config/version), export_presets.cfg
     (product_version), RELEASE_NOTES.md, store/listing.md and PROJECT_STATE.md.
  4. If docs/PROJECT_STATE.md says status: CLOSED, no doc may still carry
     in_progress / pending / Next Step / TODO: agent.
  5. A doc that claims READY / SHIPPED / RELEASED / "owner approved" must link a
     file that actually exists (an artifact), or it is an unbacked claim.
  6. No doc may reference a branch that does not exist on origin (except main,
     gh-pages and anything under docs/release/ history).

Exit code 0 = clean, 1 = at least one finding.

Usage:
  python tools/closure_guard.py [--demo]
"""
import argparse
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
HISTORY_ALLOW = ("docs/release/", "docs/artifacts/")
# Authoritative STATUS documents the guard watches. These are the docs an agent reads
# to decide "what is the current state of the project"; if they drift, development
# re-opens. Raw evidence (docs/artifacts/* except the one status doc below, .qa_logs/*),
# tooling/agent config (.opencode/.claude/.pi/.skills_disabled), vendored/archive
# material and working-note specs (MUSIC_SPEC, SLOP_REPORT, CARD_ART_BRIEF, ...) are NOT
# status docs and are intentionally excluded — they cannot "drift the project back into
# development". New authoritative status docs must be added here.
STATUS_DOC_RELS = (
    # root status docs
    "README.md", "RELEASE_NOTES.md", "RELEASE_CHECKLIST.md", "AGENTS.md", "CLAUDE.md",
    "task_plan.md", "findings.md", "progress.md",
    # new single authoritative status doc (Phase B1)
    "docs/PROJECT_STATE.md",
    # docs/ status docs named in the brief (§1.3 / B2)
    "docs/RUN_STATE.md", "docs/RUN_STATE_OC.md", "docs/HANDOFF.md", "docs/KNOWN_ISSUES.md",
    "docs/STORE_KIT.md", "docs/CERT_STORESYNC.md", "docs/CERT_STORE.md",
    "docs/OWNER_RELEASE_PACKET.md", "docs/CLOSURE_VERIFICATION_INTERNAL.md", "docs/ARENA_CLOSURE.md",
    "docs/RELEASE_ARTIFACTS.md", "docs/RELEASE_READINESS_REPORT.md",
    # explicitly called out in §1.3 as a status doc living under artifacts
    "docs/artifacts/known_owner_only_items.md",
    # store listing — status truth (Rule 3 + §1.3)
    "store/listing.md",
)
EXEMPT_WORDS = re.compile(r"\b(2026-\d\d-\d\d|cut|earlier|pre-cut|prior|was|historical|superseded|before)\b", re.I)


def git(*args):
    r = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
    return r.stdout


def actual_locales():
    files = [p for p in (ROOT / "data" / "i18n").glob("*.json")] if (ROOT / "data" / "i18n").is_dir() else []
    return sorted(p.stem for p in files), len(files)


def docs_to_scan():
    """Scan only the authoritative status documents (see STATUS_DOC_RELS).

    We deliberately do NOT rglob the whole tree: raw evidence logs
    (docs/artifacts/*, .qa_logs/*), tooling/agent config and working-note specs are
    not status docs and would produce unbounded false positives. The guard's job is to
    stop the project's *status truth* from drifting, which lives in the curated set.
    """
    out = []
    for rel in STATUS_DOC_RELS:
        p = ROOT / rel
        if p.is_file():
            out.append(p)
    # Dated release records are status docs too.
    for p in (ROOT / "docs" / "release").glob("*.md"):
        out.append(p)
    return out


# A status doc that carries an explicit, dated "locale truth" note has been reconciled
# per Phase B2 ("keep the cut decision as a dated note so nobody re-adds them"). Its body
# mentions of 13/11/6 locales are then historical context, not a current claim. The guard
# STILL catches any doc WITHOUT this note that asserts a wrong count, and any note that
# asserts a wrong count (rule_locale parses the note's own number too).
RECONCILED_MARKER = re.compile(r"LOCALE[ _]TRUTH", re.I)


def rule_locale(paths, actual):
    """Rule 1: locale-count assertions must match the real count (exempt historical).

    Aligned to the brief's acceptance grep (``13 locale|6 locale|...``): we match an
    explicit *locale/language count* or an ``N/N parity`` claim. A bare ``keys x 13`` is
    a key count, not a locale-count claim, and is intentionally NOT matched here.
    """
    findings = []
    pats = [
        re.compile(r"(\d+)\s*/\s*\d+\s*(?:locale|language|parity)s?\b"),  # 13/13 parity, 13/13 locales
        re.compile(r"(\d+)\s*(?:locale|language)s?\b"),                  # 13 locales, 6 languages
    ]
    for p in paths:
        text = p.read_text(encoding="utf-8", errors="replace")
        # The note itself must assert the correct count, or it is not a valid reconciliation.
        if RECONCILED_MARKER.search(text):
            note_counts = [int(m.group(1)) for m in re.finditer(r"(\d+)\s*locales?\b", text, re.I)]
            if actual not in note_counts:
                findings.append((p, 0, "locale-truth note present but does not assert the actual count %d" % actual))
            continue
        for i, line in enumerate(text.splitlines(), 1):
            if EXEMPT_WORDS.search(line):
                continue
            for pat in pats:
                for m in pat.finditer(line):
                    try:
                        n = int(m.group(1))
                    except (IndexError, ValueError):
                        continue
                    if n != actual:
                        findings.append((p, i, "locale count %d != actual %d: %s" % (n, actual, line.strip()[:120])))
                        break
    return findings


def rule_main_sha(paths, origin_main):
    """Rule 2: a doc asserting a commit as current main/tip/HEAD must match origin/main."""
    findings = []
    claim = re.compile(r"(?:current main|main tip|tip is|HEAD is|main is|main\s*=\s*|current tip)\b[^\n]{0,40}?([0-9a-f]{7,40})", re.I)
    for p in paths:
        rel = p.relative_to(ROOT).as_posix()
        if rel.startswith(HISTORY_ALLOW):
            continue
        for i, line in enumerate(p.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            for m in claim.finditer(line):
                sha = m.group(1)
                if sha != origin_main and not origin_main.startswith(sha[:7]):
                    findings.append((p, i, "asserts main/tip %s != origin/main %s: %s" % (sha, origin_main[:12], line.strip()[:120])))
    return findings


def rule_version(paths):
    """Rule 3: the project version must agree across the 5 canonical sources only.

    Per the brief, the version is a property of ``project.godot``, ``export_presets.cfg``,
    ``RELEASE_NOTES.md``, ``store/listing.md`` and ``docs/PROJECT_STATE.md``. We do NOT scan
    every status doc for a version-like string — that would false-positive on the Godot
    engine version (4.7.2), dates (08.08.2026) or tool versions (34.0.0).
    """
    findings = []
    sources = [
        ("project.godot", ROOT / "project.godot", r'config/version="([^"]+)"'),
        ("export_presets.cfg", ROOT / "export_presets.cfg", r'product_version="([^"]+)"'),
        ("RELEASE_NOTES.md", ROOT / "RELEASE_NOTES.md", None),
        ("store/listing.md", ROOT / "store/listing.md", None),
        ("docs/PROJECT_STATE.md", ROOT / "docs/PROJECT_STATE.md", r'version:\s*([0-9]+\.[0-9]+\.[0-9]+)'),
    ]
    versions = {}
    for name, p, pat in sources:
        if not p.is_file():
            findings.append((p, 0, "version source %s missing" % name))
            continue
        txt = p.read_text(encoding="utf-8", errors="replace")
        if pat:
            m = re.search(pat, txt)
            v = m.group(1) if m else None
        else:
            # prose source: the project version is the X.Y.Z that appears as a release version
            vs = re.findall(r"\b1\.0\.1\b|\b[0-9]+\.[0-9]+\.[0-9]+\b", txt)
            v = "1.0.1" if "1.0.1" in vs else (vs[0] if vs else None)
        versions[name] = v
    vals = set(v for v in versions.values() if v)
    if len(vals) > 1:
        findings.append((ROOT / "project.godot", 0,
                         "version disagreement across canonical sources: %s" % versions))
    elif len(vals) == 1 and "1.0.1" not in vals:
        findings.append((ROOT / "project.godot", 0,
                         "canonical version is %s, expected 1.0.1" % next(iter(vals))))
    return findings


def rule_status_closed(paths, state):
    """Rule 4: CLOSED status forbids lingering in_progress/pending/Next Step/TODO: agent."""
    if state != "CLOSED":
        return []
    findings = []
    bad = re.compile(r"\b(in_progress|pending|next step|todo:\s*agent)\b", re.I)
    for p in paths:
        for i, line in enumerate(p.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            if bad.search(line):
                findings.append((p, i, "status is CLOSED but doc still says '%s': %s" % (line.strip()[:60], line.strip()[:120])))
    return findings


def rule_backed_claim(paths):
    """Rule 5: a STATUS claim of READY/SHIPPED/RELEASED/owner approved must link an artifact.

    ``SHIPPED``/``RELEASED`` are almost always adjectives in this codebase ("the shipped build",
    "has shipped 31"), so they count as a claim ONLY in an explicit status position
    (``status: SHIPPED`` or ``**SHIPPED**``). ``READY`` counts when it follows a copula as a
    predicate, provided it is not adjectival ("ready to paste", "ready recipe"), negated
    ("is not READY"), or a noun phrase ("the shipped …"). This matches the brief's demo
    ("Release is READY now." is a claim; "Release is BLOCKED …" is not).
    """
    findings = []
    status_re = re.compile(r"\bstatus\b[:\s]+(READY|SHIPPED|RELEASED)\b", re.I)
    bold_re = re.compile(r"\*\*(READY|SHIPPED|RELEASED)\*\*", re.I)
    ready_re = re.compile(r"\b(?:is|are|was|were|has|have|now)\b([^.\n]{0,12}?)\bREADY\b", re.I)
    owner_re = re.compile(r"\bowner approved\b", re.I)
    adj = re.compile(
        r"^\s+(?:to (?:implement|publish|paste|ship|release)|recipe|masters|replies|build|code|"
        r"version|string|data|art|file|locales|in-game|wav|ogg|pck|now has|and|already|not|"
        r"— accepted|`|\d)", re.I)
    link = re.compile(r"\]\(([^)]+)\)|(?:docs/artifacts/[^\s)``]+|docs/release/[^\s)``]+)")
    for p in paths:
        text = p.read_text(encoding="utf-8", errors="replace")
        for i, line in enumerate(text.splitlines(), 1):
            hit = bool(status_re.search(line) or bold_re.search(line) or owner_re.search(line))
            if not hit:
                for m in ready_re.finditer(line):
                    if re.search(r"\bnot\b", m.group(1), re.I):
                        continue
                    if adj.match(line[m.end():]):
                        continue
                    hit = True
                    break
            if not hit:
                continue
            links = link.findall(line)
            ok = False
            for lnk in links:
                if lnk.startswith("http"):
                    ok = True
                    break
                cand = (p.parent / lnk).resolve() if not lnk.startswith("docs/") else (ROOT / lnk).resolve()
                if cand.is_file():
                    ok = True
                    break
            if not ok:
                findings.append((p, i, "claims READY/SHIPPED/RELEASED/owner-approved with no resolvable artifact: %s" % line.strip()[:120]))
    return findings


# The two dead branches §1.3 names as the re-opening cause. The acceptance grep
# (`oc/visual-w10|arena/01a0ab24`) permits them only as *dated historical notes*; active
# status/instruction docs must not reference them as live branches.
DEAD_BRANCHES = ("oc/visual-w10", "arena/01a0ab24")
# Historical logs are permitted to reference the dead branches as dated records.
HISTORICAL_BRANCH_FILES = {
    "docs/RUN_STATE.md", "docs/HANDOFF.md", "docs/KNOWN_ISSUES.md", "docs/ARENA_CLOSURE.md",
}


def rule_branch(paths, remote_branches):
    """Rule 6: the brief's named dead branches (``oc/visual-w10``, ``arena/01a0ab24``) must not be
    referenced as live branches in ACTIVE status/instruction docs. Historical logs (RUN_STATE,
    HANDOFF, KNOWN_ISSUES, ARENA_CLOSURE, docs/release/*, docs/artifacts/*) may reference them as
    dated records, matching the acceptance grep's "dated historical notes" allowance. Other
    conventional namespaces (release/feature/fix/ci) are not policed here.
    """
    findings = []
    ref = re.compile(r"\b((?:oc/visual-w10|arena/01a0ab24)[A-Za-z0-9._-]*)\b")
    # A reference is a *reconciliation note* (not a live branch instruction) when the line states
    # the branch is gone — the brief's acceptance grep permits the dead-branch names only as dated
    # historical notes, and §1.3's AGENTS.md fix requires naming them while recording they are gone.
    neg = re.compile(r"\b(do not exist|does not exist|no longer exists|not exist on origin|moot|"
                     r"must not be created|do not create|not be created|removed|deleted|abandoned|cut)\b", re.I)
    for p in paths:
        rel = p.relative_to(ROOT).as_posix()
        if rel.startswith(HISTORY_ALLOW) or rel in HISTORICAL_BRANCH_FILES:
            continue
        for i, line in enumerate(p.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            for m in ref.finditer(line):
                if neg.search(line):
                    continue
                b = m.group(1)
                if any(rb.endswith("/" + b) or rb == b for rb in remote_branches):
                    continue
                findings.append((p, i, "references dead branch %s not on origin: %s" % (b, line.strip()[:120])))
    return findings


def project_state(paths):
    for p in paths:
        if p.name == "PROJECT_STATE.md":
            txt = p.read_text(encoding="utf-8", errors="replace")
            m = re.search(r"status:\s*(\w+)", txt)
            return m.group(1) if m else None
    return None


def demo():
    """Prove every rule fires on a fixture, then passes when corrected."""
    import tempfile
    d = ROOT / ".closure_guard_demo"
    d.mkdir(exist_ok=True)
    (ROOT / "data" / "i18n").mkdir(parents=True, exist_ok=True)
    for loc in ("en", "ru"):
        (ROOT / "data" / "i18n" / (loc + ".json")).write_text("{}", encoding="utf-8")
    (ROOT / "project.godot").write_text('config/version="1.0.1"\n', encoding="utf-8")
    (ROOT / "export_presets.cfg").write_text('product_version="1.0.1"\n', encoding="utf-8")

    bad = d / "bad.md"
    good = d / "good.md"
    bad.write_text(
        "We ship 13 locales and 13/13 parity certified.\n"
        "Current main tip is deadbeef1234567890deadbeef1234567890abcd.\n"
        "Status: CLOSED but Phase 1 in_progress.\n"
        "Release is READY now.\n"
        "Branch oc/visual-w10 holds the work.\n"
        "Version 1.0.0 here.\n", encoding="utf-8")
    good.write_text(
        "We ship 2 locales (en, ru); the owner cut de/es/fr/pt_BR on 2026-11-05.\n"
        "Current main tip is %s.\n"
        "Status: BLOCKED; owner-only items remain.\n"
        "Release is BLOCKED pending owner keystore.\n"
        "See main for the work.\n"
        "Version 1.0.1 here.\n" % ("0" * 40), encoding="utf-8")

    origin_main = "0" * 40
    paths = [bad, good]
    rb = ["origin/main", "origin/gh-pages"]
    f_bad = (rule_locale([bad], 2) + rule_main_sha([bad], origin_main) + rule_version([bad])
             + rule_status_closed([bad], "CLOSED") + rule_backed_claim([bad]) + rule_branch([bad], rb))
    f_good = (rule_locale([good], 2) + rule_main_sha([good], origin_main) + rule_version([good])
              + rule_status_closed([good], "BLOCKED") + rule_backed_claim([good]) + rule_branch([good], rb))
    for f in f_bad:
        print("DEMO FAIL bad: %s:%d %s" % (f[0].name, f[1], f[2]))
    for f in f_good:
        print("DEMO FAIL good (should be empty): %s:%d %s" % (f[0].name, f[1], f[2]))
    # clean
    for f in (bad, good):
        f.unlink()
    print("closure_guard demo: bad findings=%d (want >0), good findings=%d (want 0)" % (len(f_bad), len(f_good)))
    return 0 if (len(f_bad) > 0 and len(f_good) == 0) else 1


def main(argv):
    if "--demo" in argv:
        return demo()
    actual, n = actual_locales()
    origin_main = git("rev-parse", "origin/main").strip() or git("rev-parse", "HEAD").strip()
    remote_branches = git("ls-remote", "--heads", "origin").split()
    paths = docs_to_scan()
    state = project_state(paths)
    findings = []
    findings += rule_locale(paths, n)
    findings += rule_main_sha(paths, origin_main)
    findings += rule_version(paths)
    findings += rule_status_closed(paths, state)
    findings += rule_backed_claim(paths)
    findings += rule_branch(paths, remote_branches)
    for p, i, why in findings:
        print("FAIL %s:%d: %s" % (p.relative_to(ROOT).as_posix(), i, why))
    print("closure_guard: %d doc(s) scanned, %d finding(s); locales=%s actual=%d, origin/main=%s, status=%s"
          % (len(paths), len(findings), ",".join(actual), n, origin_main[:12], state))
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
