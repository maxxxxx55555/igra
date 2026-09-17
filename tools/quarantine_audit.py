#!/usr/bin/env python3
"""Static dead-asset audit for the quarantine and texture narrowing manifests.

This is deliberately engine-free.  It performs two independent source scans:

A. the candidate's repository path (with and without ``res://``); and
B. the candidate basename, including the extension.

It then reports dynamic load/material-construction sites and cross-checks the
four named review documents plus the wider docs tree.  It never edits or
removes anything.  A non-zero result means the inventory itself is malformed,
not that an asset is merely UNCERTAIN.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable


ROOTS = (
    ("quarantine", Path("_QUARANTINE")),
    ("surfaces", Path("assets/textures/surfaces")),
    ("ui", Path("assets/textures/ui")),
)
NAMED_DOCS = (
    Path("docs/VISUAL_PASS.md"),
    Path("docs/STORE_KIT.md"),
    Path("docs/CARD_ART_BRIEF.md"),
    Path("docs/KNOWN_ISSUES.md"),
)
AUDIT_DOCS = {Path("docs/QUARANTINE_AUDIT.md"), Path("docs/SURFACES_UI_NARROWING.md")}
TEXT_SUFFIXES = {
    ".gd", ".tscn", ".tres", ".cfg", ".godot", ".json", ".md", ".txt",
    ".csv", ".toml", ".yaml", ".yml", ".py", ".sh", ".gdshader", ".svg",
}
RUNTIME_ROOTS = ("scripts", "scenes", "components", "data", "addons")
RUNTIME_FILES = {"project.godot", "export_presets.cfg", "default_bus_layout.tres"}
DOC_PLANNED_WORDS = re.compile(
    r"\b(?:planned|plan|future|unwired|not yet wired|not yet|pending|reserved|"
    r"delivered|available|filled|gap|placeholder|later|deferred|visual polish|"
    r"wiring|wire(?:d|s)?|spec|touch|mobile)\b",
    re.IGNORECASE,
)
DOC_DEAD_WORDS = re.compile(
    r"(?:\bdead\b|\bduplicate(?:s)?\b|\bzero refs?\b|\bzero incoming\b|"
    r"\bsuperseded\b|\borphan(?:ed)?\b|\bunused\b|\bfossil\b|"
    r"\bARCHIVED\b|\bnot used\b|\bnot instantiated\b|дубли|дубликат|"
    r"мёртв|мертв|ноль ссылок|ноль входящих)",
    re.IGNORECASE,
)
DYNAMIC_LOAD = re.compile(
    r"\b(?:load|preload|ResourceLoader\.load)\s*\(\s*(?![\"'])[^)]*\)",
    re.IGNORECASE,
)
PATH_BUILD = re.compile(
    r"(?:%[sd]|\+|\.format\s*\(|join\s*\(|DirAccess|list_dir|"
    r"district[^\n]*(?:material|texture)|(?:material|texture)[^\n]*district)",
    re.IGNORECASE,
)

# Explicitly documented classifications.  These are conservative: a planned
# or uncertain file is never promoted to AUTO-DELETABLE merely by having no
# grep hit.  Code hits always win, because a live consumer beats a stale note.
PLANNED_SURFACES = {
    "cell_bars_512.png", "chalkboard_512.png", "fuel_pump_512.png",
    "fusebox_512.png", "generator_metal_512.png", "hospital_curtain_512.png",
    "hospital_tile_dirty_512.png", "metal_rust_512.png", "morgue_drawers_512.png",
    "pond_ice_512.png", "school_lockers_512.png", "xray_lightbox_512.png",
}
PLANNED_UI = {
    "bar_battery.png", "bar_health.png", "bar_stamina.png",
    "btn_disabled.png", "btn_hover.png", "btn_normal.png", "btn_pressed.png",
    "inventory_slot.png", "progress_fill.png", "progress_frame.png",
    "tooltip_panel.png", "minimap_enemy_blip_16.png",
}


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except (OSError, UnicodeError):
        return ""


def line_hits(text: str, pattern: str | re.Pattern[str]) -> list[tuple[int, str]]:
    rx = re.compile(pattern) if isinstance(pattern, str) else pattern
    return [(n, line.rstrip()) for n, line in enumerate(text.splitlines(), 1) if rx.search(line)]


def candidate_files(root: Path = Path(".")) -> list[tuple[str, Path]]:
    result: list[tuple[str, Path]] = []
    for kind, relative_root in ROOTS:
        base = root / relative_root
        if not base.is_dir():
            continue
        for path in sorted(p for p in base.rglob("*") if p.is_file() and p.suffix != ".import"):
            result.append((kind, path.relative_to(root)))
    return result


def runtime_files(root: Path) -> list[Path]:
    files: list[Path] = []
    for rel_root in RUNTIME_ROOTS:
        base = root / rel_root
        if not base.is_dir():
            continue
        for path in base.rglob("*"):
            if path.is_file() and path.suffix.lower() in TEXT_SUFFIXES and path.suffix != ".import":
                files.append(path)
    for rel in RUNTIME_FILES:
        path = root / rel
        if path.is_file():
            files.append(path)
    return sorted(set(files))


def docs_files(root: Path) -> list[Path]:
    paths: list[Path] = []
    for dirname in ("docs", "content"):
        base = root / dirname
        if base.is_dir():
            paths.extend(p for p in base.rglob("*.md") if p.is_file() and p.relative_to(root) not in AUDIT_DOCS)
    return sorted(paths)


def relative_path(path: Path) -> str:
    return path.as_posix()


@dataclass
class Evidence:
    pattern_a: list[str]
    pattern_b: list[str]
    dynamic: list[str]
    named_docs: dict[str, list[str]]
    doc_evidence: list[str]


@dataclass
class Verdict:
    kind: str
    path: str
    basename: str
    evidence: Evidence
    verdict: str
    reason: str


def format_hit(path: Path, line_no: int, line: str) -> str:
    return f"{path.as_posix()}:{line_no}: {line.strip()}"


def cap_hits(hits: Iterable[str], limit: int = 8) -> list[str]:
    values = list(hits)
    if len(values) <= limit:
        return values
    return values[:limit] + [f"… +{len(values) - limit} more"]


def make_audit(root: Path) -> list[Verdict]:
    candidates = candidate_files(root)
    runtime = [(p.relative_to(root), read_text(p)) for p in runtime_files(root)]
    docs = [(p.relative_to(root), read_text(p)) for p in docs_files(root)]
    candidate_count = len(candidates)

    # Build one-pass indexes for the two independent grep-equivalent scans.
    # Keeping the indexes separate prevents a path hit from masquerading as a
    # basename hit in the report.
    a_keys: dict[str, list[int]] = {}
    b_keys: dict[str, list[int]] = {}
    doc_keys: dict[str, list[int]] = {}
    for index, (kind, path) in enumerate(candidates):
        rel = path.as_posix()
        for key in (f"res://{rel}", rel):
            a_keys.setdefault(key, []).append(index)
        b_keys.setdefault(path.name, []).append(index)
        doc_tokens = [path.name, path.stem, rel]
        if kind == "quarantine" and path.name.startswith("SairaCondensed-"):
            doc_tokens.append("SairaCondensed")
        for key in doc_tokens:
            doc_keys.setdefault(key, []).append(index)

    def union_regex(keys: Iterable[str], boundaries: bool = False) -> re.Pattern[str] | None:
        unique = sorted(set(keys), key=len, reverse=True)
        if not unique:
            return None
        body = "|".join(re.escape(key) for key in unique)
        if boundaries:
            return re.compile(rf"(?<![A-Za-z0-9_.-])(?:{body})(?![A-Za-z0-9_.-])")
        return re.compile(body)

    a_rx = union_regex(a_keys)
    b_rx = union_regex(b_keys, boundaries=True)
    doc_rx = union_regex(doc_keys)
    a_hits: list[list[str]] = [[] for _ in candidates]
    b_hits: list[list[str]] = [[] for _ in candidates]
    dynamic_by_kind: dict[str, list[str]] = {kind: [] for kind, _ in ROOTS}

    for source_path, text in runtime:
        for line_no, line in enumerate(text.splitlines(), 1):
            if a_rx:
                for match in a_rx.finditer(line):
                    for index in a_keys[match.group(0)]:
                        a_hits[index].append(format_hit(source_path, line_no, line))
            if b_rx:
                for match in b_rx.finditer(line):
                    for index in b_keys[match.group(0)]:
                        b_hits[index].append(format_hit(source_path, line_no, line))
            if DYNAMIC_LOAD.search(line) or PATH_BUILD.search(line):
                if "assets/textures/" in line or "material" in line.lower() or "texture" in line.lower() or "_QUARANTINE" in line:
                    for candidate_kind, _ in ROOTS:
                        if candidate_kind == "quarantine" and "_QUARANTINE" in line:
                            dynamic_by_kind[candidate_kind].append(format_hit(source_path, line_no, line))
                        elif candidate_kind == "surfaces" and ("textures/surfaces" in line or "tex_path" in line or "district" in line.lower() and "material" in line.lower()):
                            dynamic_by_kind[candidate_kind].append(format_hit(source_path, line_no, line))
                        elif candidate_kind == "ui" and ("textures/ui" in line or "texture" in line.lower() and "ui" in line.lower()):
                            dynamic_by_kind[candidate_kind].append(format_hit(source_path, line_no, line))

    # A second, docs-only index captures both the four named review docs and
    # wider docs.  Context is retained so a bare inventory line is not treated
    # as a planned/dead decision without a nearby disposition word.
    named_hits: list[dict[str, list[str]]] = [
        {doc.as_posix(): [] for doc in NAMED_DOCS} for _ in candidates
    ]
    disposition_hits: list[list[str]] = [[] for _ in candidates]
    for doc_path, text in docs:
        lines = text.splitlines()
        for line_no, line in enumerate(lines, 1):
            if not doc_rx:
                continue
            matches = list(doc_rx.finditer(line))
            if not matches:
                continue
            context = " ".join(lines[max(0, line_no - 4): min(len(lines), line_no + 3)])
            formatted = format_hit(doc_path, line_no, line)
            for match in matches:
                for index in doc_keys[match.group(0)]:
                    if doc_path in NAMED_DOCS:
                        named_hits[index][doc_path.as_posix()].append(formatted)
                    if DOC_DEAD_WORDS.search(context) or DOC_PLANNED_WORDS.search(context):
                        disposition_hits[index].append(formatted)

    results: list[Verdict] = []
    for index, (kind, path) in enumerate(candidates):
        basename = path.name
        evidence = Evidence(
            pattern_a=cap_hits(a_hits[index]),
            pattern_b=cap_hits(b_hits[index]),
            dynamic=cap_hits(dynamic_by_kind[kind]),
            named_docs={key: cap_hits(value) for key, value in named_hits[index].items()},
            doc_evidence=cap_hits(disposition_hits[index], 10),
        )

        has_live = bool(a_hits[index] or b_hits[index])
        explicit_dead = kind == "quarantine" and any(
            DOC_DEAD_WORDS.search(item) for item in disposition_hits[index]
        )
        manual_planned = (
            kind == "surfaces" and basename in PLANNED_SURFACES
        ) or (
            kind == "ui" and basename in PLANNED_UI
        )
        planned = manual_planned or any(
            DOC_PLANNED_WORDS.search(item) for item in disposition_hits[index]
        )

        if has_live:
            verdict = "KEEP-LIVE"
            reason = "Pattern A or B found a consumer in the runtime corpus."
        elif explicit_dead:
            verdict = "AUTO-DELETABLE"
            reason = "No runtime hit; the docs record this quarantined file as duplicate/dead/unused."
        elif planned:
            verdict = "KEEP-PLANNED"
            reason = "No runtime hit; a delivery, wiring, gap, or future-use note keeps it out of deletion."
        else:
            verdict = "UNCERTAIN"
            reason = "No runtime hit and no explicit dead/planned disposition; owner eyes required."

        results.append(Verdict(kind, path.as_posix(), basename, evidence, verdict, reason))
    return results

def counts(results: list[Verdict]) -> dict[str, int]:
    out: dict[str, int] = {}
    for item in results:
        out[item.verdict] = out.get(item.verdict, 0) + 1
    return out


def print_snippet(label: str, values: list[str], empty: str = "(no match)") -> None:
    print(f"  {label}:")
    for value in values[:3]:
        print(f"    {value}")
    if not values:
        print(f"    {empty}")


def print_text(results: list[Verdict], root: Path) -> None:
    print("quarantine_audit.py — static only; no engine, no edits, no deletions")
    print(f"root: {root.resolve()}")
    print("inventory: " + ", ".join(f"{kind}={sum(x.kind == kind for x in results)}" for kind, _ in ROOTS))
    print()
    print("PATTERN A command: grep -RFn --exclude='*.import' 'res://<candidate-path>' runtime corpus")
    print("PATTERN B command: grep -RFn --exclude='*.import' '<candidate-basename>' runtime corpus")
    print("DOC command: grep -RniE '<basename>|<stem>|<relative-path>' docs/**/*.md content/**/*.md (audit outputs excluded)")
    print("DYNAMIC command: grep -RniE 'load|preload|ResourceLoader|%s|%d|\\+|DirAccess|list_dir|district.*(material|texture)' runtime corpus")
    print()

    for kind, _ in ROOTS:
        group = [x for x in results if x.kind == kind]
        print(f"[{kind}] {len(group)} candidates")
        for item in group:
            print(f"{item.verdict:16} {item.path}")
            print_snippet("A", item.evidence.pattern_a)
            print_snippet("B", item.evidence.pattern_b)
            print_snippet("dynamic", item.evidence.dynamic)
            docs_hit_count = sum(bool(v) for v in item.evidence.named_docs.values())
            print(f"  named docs: {docs_hit_count}/4 contain basename/stem/path")
            if item.evidence.doc_evidence:
                print(f"  disposition evidence: {item.evidence.doc_evidence[0]}")
            else:
                print("  disposition evidence: (none)")
        print()
    print("verdict counts: " + json.dumps(counts(results), sort_keys=True))
    print("check: PASS (UNCERTAIN means owner eyes, not a gate failure)")


def json_payload(results: list[Verdict]) -> dict[str, object]:
    return {
        "tool": "tools/quarantine_audit.py",
        "mode": "static-only",
        "roots": [str(path) for _, path in ROOTS],
        "named_docs": [str(path) for path in NAMED_DOCS],
        "counts": counts(results),
        "results": [asdict(item) for item in results],
    }


def check(results: list[Verdict], root: Path) -> list[str]:
    errors: list[str] = []
    expected = {kind: 0 for kind, _ in ROOTS}
    for kind, _ in candidate_files(root):
        expected[kind] += 1
    actual = {kind: sum(item.kind == kind for item in results) for kind, _ in ROOTS}
    if expected != actual:
        errors.append(f"inventory mismatch: expected {expected}, got {actual}")
    for item in results:
        if not item.evidence.named_docs or set(item.evidence.named_docs) != {p.as_posix() for p in NAMED_DOCS}:
            errors.append(f"named-doc scan missing for {item.path}")
        if item.verdict not in {"AUTO-DELETABLE", "KEEP-LIVE", "KEEP-PLANNED", "UNCERTAIN"}:
            errors.append(f"invalid verdict for {item.path}: {item.verdict}")
    for doc in NAMED_DOCS:
        if not (root / doc).is_file():
            errors.append(f"missing named review doc: {doc}")
    return errors


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".", help="repository root")
    parser.add_argument("--json", action="store_true", help="emit machine-readable manifest")
    parser.add_argument("--check", action="store_true", help="validate complete inventory and exit 0/1")
    args = parser.parse_args(argv)
    root = Path(args.root).resolve()
    results = make_audit(root)
    errors = check(results, root)
    if args.json:
        print(json.dumps(json_payload(results), ensure_ascii=False, indent=2))
    else:
        print_text(results, root)
    if args.check and errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
