#!/usr/bin/env python
"""Verify-agent pass 2 — every store asset/doc path cited by the synced files
must exist on disk (TASK 3 requirement), at the claimed pixel size where a size
is claimed. Also cross-checks the press-kit content numbers against the shipped
data (TASK 4 requirement). Static-only, no engine.

Run: python3 docs/artifacts/store-sync/verify_paths_and_numbers.py
"""
import re, json, glob, struct, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[3]
fails, table = [], []

CITED_IN = [
    "store/listing.md", "store/press-kit.md", "store/changelog.md",
    "store/privacy-policy-template.md", "store/screenshot-plan-detailed.md",
]
path_re = re.compile(r"`((?:store|content|data|scripts|assets|docs|tools)/[\w/\-.*]+?\.(?:png|md|json|gd|py|tres|cfg|csv|svg))`")

cited = set()
for f in CITED_IN:
    txt = (ROOT / f).read_text(encoding="utf-8")
    for m in path_re.finditer(txt):
        cited.add((f, m.group(1)))

# globs inside backticks like `store/trailer/still_*.png` / data paths with *
star = {(f, p) for f, p in cited if "*" in p}
plain = sorted(p for f, p in cited if "*" not in p)
for f, p in star:
    hits = glob.glob(str(ROOT / p))
    if not hits:
        fails.append(f"{f}: glob matches nothing: {p}")

for rel in plain:
    q = ROOT / rel
    if not q.exists():
        # tolerate refs to owner-side/other-branch files only if clearly historical
        fails.append(f"cited path missing on disk: {rel}")
    else:
        if q.suffix == ".png":
            with open(q, "rb") as fh:
                head = fh.read(26)
            if head[:8] != b"\x89PNG\r\n\x1a\n":
                fails.append(f"not a real PNG: {rel}")
            else:
                w, h = struct.unpack(">II", head[16:24])
                table.append((rel, f"{w}x{h}"))

# screenshot size claims
for rel, size in table:
    if "screenshots/" in rel or "trailer/hero" in rel:
        m = re.search(r"(\d{3,4})x(\d{3,4})", rel)
        if m and (m.group(1), m.group(2)) != (str(size.split('x')[0]), str(size.split('x')[1])):
            fails.append(f"{rel}: filename size {m.group(1)}x{m.group(2)} != IHDR {size}")

# ------------------------------------------------------------ numbers (TASK 4)
def n_districts():  return len(glob.glob(str(ROOT / "data/districts/district_*.tres")))
def n_lore():
    tot = 0
    for f in glob.glob(str(ROOT / "content/districts/*/lore_notes.json")):
        tot += len(json.load(open(f, encoding="utf-8")).get("notes", []))
    return tot
def n_locales():  return len(glob.glob(str(ROOT / "data/i18n/*.json")))
def n_ach():
    src = (ROOT / "scripts/systems/achievements_manager.gd").read_text(encoding="utf-8")
    return len(re.findall(r'"id":\s*&?"?ach_', src))
def n_challenges():  return len(json.load(open(ROOT / "data/daily_challenges.json", encoding="utf-8"))["templates"])
def n_enemies():  return len(glob.glob(str(ROOT / "scripts/enemies/*_3d.gd")))
def n_endings():
    src = (ROOT / "scripts/systems/endings_manager.gd").read_text(encoding="utf-8")
    return len(re.search(r"enum Ending \{([^}]*)\}", src).group(1).split(","))

facts = {
    "11 connected districts": (n_districts(), 11),
    "88 lore notes":          (n_lore(), 88),
    "13 locales":             (n_locales(), 13),
    "31 achievements":        (n_ach(), 31),
    "30 daily challenges":    (n_challenges(), 30),
    "12 enemy scripts":       (n_enemies(), 12),
    "5 endings":              (n_endings(), 5),
}
for what, (got, want) in facts.items():
    if got != want:
        fails.append(f"{what}: recomputed {got}, docs claim {want}")

# final_gate_report quotables present?
fg = (ROOT / "docs/artifacts/final_gate_report.md").read_text(encoding="utf-8")
for needle in ["10/10", "22/23", "MISSING: 0", "3-6h", "11/11"]:
    if needle not in fg:
        fails.append(f"final_gate_report.md missing quotable {needle}")

pk = (ROOT / "store/press-kit.md").read_text(encoding="utf-8")
for claim in ["| 11 |", "| 88 |", "| 13 |", "| 31 |", "| 30 |", "| 12 |", "| 5 |", "| 4 |"]:
    if claim not in pk:
        fails.append(f"press-kit number row not found: {claim}")
if re.search(r"\|\s*20\s*\|\s*Achievements", pk):
    fails.append("press-kit still claims 20 achievements")

print("== verify_paths_and_numbers.py ==")
print(f"cited-path checks: {len(plain)} exact + {len(star)} globs, all backtick paths in: {', '.join(CITED_IN)}")
print("PNG sizes verified via IHDR:", len([t for t in table if t[0].endswith('.png')]))
print("numbers recomputed:", {k: v[0] for k, v in facts.items()})
if fails:
    print(f"\n{len(fails)} FAIL:")
    for f in fails: print("  -", f)
    sys.exit(1)
print("RESULT: GREEN — every cited path exists at claimed size; all press-kit numbers reproduce from source")
