#!/usr/bin/env python
"""Verify-agent pass 1 — store/listing.md structural + claim + ASO audit.

Runs as the independent check for TASK 1 (final-shipped-claims, 13-locale
parity, short<=80 script-verified, no unbacked promises) and TASK 2 (per-
locale keyword density sanity, no stuffing). Static-only, no engine.

Run:  python3 docs/artifacts/store-sync/verify_listing.py
"""
import re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[3]
T = (ROOT / "store" / "listing.md").read_text(encoding="utf-8")

LOCALES = ["en", "ru", "es", "de", "fr", "it", "pt_BR", "tr", "ja", "ko", "zh", "zh_TW", "ar"]
fails, notes = [], []

# ---------------------------------------------------------------- structure
secs = re.findall(r"^### ([\w_]+) — ", T, re.M)
if len(set(secs)) != 13 or any(l not in secs for l in LOCALES):
    fails.append(f"locale sections: expected 13 unique, got {secs}")

# short lines: every "**Short (N/80):**" label must equal the real len and be <=80
shorts = re.findall(r"\*\*Short \((\d+)/80\):\*\* (.+)", T)
for label, val in shorts:
    val = val.strip()
    if int(label) != len(val):
        fails.append(f"short label {label} != real {len(val)}: {val[:40]}")
    if len(val) > 80:
        fails.append(f"short >80 ({len(val)}): {val[:50]}")
notes.append(f"short lines checked (generated block + master labels): {len(shorts)}")

# master short labels: **EN (n/80 chars):** `x` / **RU (n/80):** `x`
for pat in (r"\*\*EN \((\d+)/80 chars\):\*\* `([^`]+)`", r"\*\*RU \((\d+)/80\):\*\* `([^`]+)`"):
    m = re.search(pat, T)
    if not m:
        fails.append(f"master short label missing for pattern {pat}")
        continue
    if int(m.group(1)) != len(m.group(2)):
        fails.append(f"master short label {m.group(1)} != real {len(m.group(2))}")
    if len(m.group(2)) > 80:
        fails.append("master short >80")

# titles <=30 everywhere (master pair + generated)
for t in re.findall(r"\*\*Title:\*\* (.+)", T):
    if len(t.strip()) > 30:
        fails.append(f"title >30: {t.strip()}")

# ---------------------------------------------------------------- full descriptions
# master EN/RU fences
master = re.findall(r"### EN\n\n```\n(.*?)\n```|### RU\n\n```\n(.*?)\n```", T, re.S)
master_fulls = [a or b for a, b in master][:2]
# generated per-locale fences
gen_fulls = []
blocks = re.split(r"^### ", T, flags=re.M)
by_loc, fulls = {}, {}
for b in blocks:
    m = re.match(r"([\w_]+) — ", b)
    if m and m.group(1) in LOCALES:
        by_loc.setdefault(m.group(1), b)
for loc, b in by_loc.items():
    f = re.search(r"```\n(.*?)\n```", b, re.S)
    if not f:
        if loc not in ("en", "ru"):
            fails.append(f"{loc}: no full-description fence")
        continue
    gen_fulls.append(f.group(1))
    fulls[loc] = f.group(1)
    # bullets = "  - " lines under Feature bullets
    bl = re.search(r"\*\*Feature bullets:\*\*\n((?:  - .+\n?)+)", b)
    n = 0 if not bl else len([x for x in bl.group(1).splitlines() if x.strip().startswith("-")])
    if loc not in ("en", "ru") and n != 8:
        fails.append(f"{loc}: {n} feature bullets, expected 8")

for name, txt in [("master-EN", master_fulls[0] if master_fulls else ""),
                  ("master-RU", master_fulls[1] if len(master_fulls) > 1 else "")]:
    if not txt:
        fails.append(f"{name}: master full-description fence not found")
        continue
    if len(txt) > 4000:
        fails.append(f"{name} full description {len(txt)} > 4000 (Play limit)")
    nlist = len([x for x in txt.splitlines() if x.startswith("- ")])
    if nlist != 9:
        fails.append(f"{name} WHAT'S INSIDE list has {nlist} lines, expected 9 (8+daily/ach/NG+)")
for loc in LOCALES:
    txt = fulls.get(loc)
    if txt is None:
        continue  # en/ru generated blocks point at master by design
    if len(txt) > 4000:
        fails.append(f"{loc} full description {len(txt)} > 4000 (Play limit)")
    nlist = len([x for x in txt.splitlines() if x.startswith("- ")])
    if nlist != 9:
        fails.append(f"{loc} WHAT'S INSIDE list has {nlist} lines, expected 9")

# deleted-unbacked-claim scan (paste-ready text only)
for bad in [r"Free updates as the city", r"Бесплатные обновления", r"Actualizaciones gratuitas",
            r"Kostenlose Updates", r"Mises à jour gratuites", r"Aggiornamenti gratuiti",
            r"Atualizações gratuitas", r"Ücretsiz güncellemeler", r"無料アップデート",
            r"무료 업데이트", r"免费更新", r"免費更新", r"تحديثات مجانية",
            r"LAN multiplayer connects"]:
    if re.search(bad, T):
        fails.append(f"unbacked claim still present: /{bad}/")

# ---------------------------------------------------------------- keyword density (TASK 2)
KW = {  # natural per-locale equivalents of: flashlight / blackout / survival puzzle / story-driven / offline
 "en": [r"flashlight", r"blackout", r"survival puzzle", r"story-driven", r"offline"],
 "ru": [r"[Фф]она[рр]", r"блэкаут", r"survival-пазл|головоломк", r"сюжет", r"офлайн"],
 "es": [r"linterna", r"oscuras", r"survival-puzzle", r"historia|narrativo", r"sin conexi[oó]n"],
 "de": [r"Taschenlampe", r"BLACKOUT|Blackout", r"Survival-Puzzle", r"story-getrieben|Geschichte", r"offline"],
 "fr": [r"lampe torche", r"NOIR|noir", r"survival-puzzle", r"intrigue|narratif", r"hors ligne"],
 "it": [r"torcia", r"BUIO|buio", r"survival-puzzle", r"storia|narrativo", r"offline"],
 "pt_BR": [r"lanterna", r"APAG|apag", r"survival-puzzle", r"hist[oó]ria|narrativo", r"offline"],
 "tr": [r"el feneri", r"KARANLIK|karanlık", r"hayatta kalma bulmacas", r"hik", r"[çc]evrimd"],
 "ja": [r"懐中電灯", r"闇|ブラックアウト|停電", r"サバイバルパズル", r"ストーリー", r"オフライン"],
 "ko": [r"손전등", r"정전|블랙아웃", r"생존 퍼즐", r"스토리", r"오프라인"],
 "zh": [r"手电筒", r"停电", r"生存解谜", r"剧情驱动", r"离线"],
 "zh_TW": [r"手電筒", r"停電", r"生存解謎", r"劇情驅動", r"離線"],
 "ar": [r"مصباح", r"ظلام|انقطاع", r"نجاة وألغاز", r"سردية|القصة", r"دون اتصال"],
}
def loc_text(loc):
    b = by_loc.get(loc, "")
    if loc in ("en", "ru"):
        # master full-description fence + master Tags/keywords section + generated pointer section
        seg = T.split("## Full description")[1].split("## Feature bullets")[0]
        head = "### EN\n" if loc == "en" else "### RU\n"
        seg = seg.split(head, 1)[1] if head in seg else ""
        seg = seg.split("```", 2)[1] if "```" in seg else ""
        tagseg = T.split("## Tags / keywords")[1].split("## Category")[0]
        tagseg = tagseg.split("### RU")[0] if loc == "en" else "### RU" + tagseg.split("### RU", 1)[1]
        return seg + "\n" + tagseg + "\n" + b
    return b

for loc in LOCALES:
    txt = loc_text(loc)
    if len(txt) < 200:
        fails.append(f"{loc}: master+generated text too short for keyword audit")
        continue
    for kw in KW[loc]:
        hits = len(re.findall(kw, txt, re.I))
        if hits < 1:
            fails.append(f"{loc}: keyword /{kw}/ missing")
        if hits > 9:  # ~0.6% density on 1500-char copy: above this it reads as stuffing
            fails.append(f"{loc}: keyword stuffing risk /{kw}/ x{hits}")

# leaked-markers scan on paste-ready fields
for m in re.finditer(r"^- \*\*(Title|Tagline|Short [^\n]*?):\*\* (.+)$", T, re.M):
    if re.search(r"\[.*?\]|TODO|FIXME|placeholder", m.group(2)):
        fails.append(f"marker leak in {m.group(1)}: {m.group(2)[:40]}")

print("== verify_listing.py ==")
print("locales with generated section:", len(by_loc), "/ 13")
print("master fences found:", len(master_fulls))
for n in notes: print("note:", n)
if fails:
    print(f"\n{len(fails)} FAIL:")
    for f in fails: print("  -", f)
    sys.exit(1)
print("RESULT: GREEN — 13/13 parity, limits, deleted-claims scan, keyword density all pass")
