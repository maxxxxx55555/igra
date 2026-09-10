#!/usr/bin/env python
"""Apply the native-QA locale fix rows from docs/PROSE_CHANGES.md
"## Locale native-QA fixes" into data/i18n/<locale>.json.

Row format (KEY may contain spaces):
    [C|H] <KEY> | <LOCALE> | <old_en_or_-> | <new_localized_text>

Text-only. Refuses any row whose KEY is absent in that locale, or whose
new text changes the %s/%d/%.1f/%.2f/%% placeholder multiset vs en.json.
en and ru are never touched (they don't appear in the rows).

    python tools/apply_native_qa_locale_fixes.py --check   # parse + validate only
    python tools/apply_native_qa_locale_fixes.py           # apply + rewrite jsons
"""
import json, re, sys, pathlib, collections

ROOT = pathlib.Path(__file__).resolve().parents[1]
PROSE = ROOT / "docs" / "PROSE_CHANGES.md"
I18N = ROOT / "data" / "i18n"
MARKER = "## Locale native-QA fixes"
PLACE = re.compile(r"%%|%[-+ #0]*\d*(?:\.\d+)?[sdfx]")
SUPPORTED = {"ar", "de", "es", "fr", "it", "ja", "ko", "pt_BR", "tr", "zh", "zh_TW"}


def parse_rows():
    txt = PROSE.read_text(encoding="utf-8")
    sec = txt[txt.index(MARKER):]
    rows = []
    for ln in sec.splitlines():
        m = re.match(r"^\[([CH])\]\s+(.*)$", ln)
        if not m:
            continue
        pri, rest = m.group(1), m.group(2)
        parts = rest.split(" | ")
        if len(parts) < 4:
            rows.append(("BAD", ln))
            continue
        # KEY | LOCALE | old | new  — new may itself contain " | ", so
        # take field 0/1/2 from the left and rejoin the remainder as new.
        key, loc, old = parts[0].strip(), parts[1].strip(), parts[2].strip()
        new = " | ".join(parts[3:]).strip()
        rows.append((pri, key, loc, old, new))
    return rows


def run(apply):
    rows = parse_rows()
    en = json.load(open(I18N / "en.json", encoding="utf-8"))
    caches = {}
    errors, applied = [], collections.Counter()
    bad = [r for r in rows if r[0] == "BAD"]
    for b in bad:
        errors.append(f"unparseable row: {b[1][:120]}")
    for pri, key, loc, old, new in (r for r in rows if r[0] != "BAD"):
        if loc not in SUPPORTED:
            errors.append(f"{key} | {loc}: locale not shipped")
            continue
        d = caches.setdefault(loc, json.load(open(I18N / f"{loc}.json", encoding="utf-8")))
        if key not in d:
            errors.append(f"{key} | {loc}: key absent in locale json")
            continue
        want = collections.Counter(PLACE.findall(en.get(key, "")))
        got = collections.Counter(PLACE.findall(new))
        if want != got:
            errors.append(f"{key} | {loc}: placeholder mismatch en={sorted(want.elements())} new={sorted(got.elements())}")
            continue
        if d[key] != new:
            d[key] = new
            applied[loc] += 1
    print(f"rows: {len([r for r in rows if r[0]!='BAD'])} parsed, {len(bad)} unparseable")
    print("would apply per locale:" if not apply else "applied per locale:", dict(sorted(applied.items())))
    print(f"total string changes: {sum(applied.values())}")
    if errors:
        print(f"\n{len(errors)} ERROR(S):")
        for e in errors[:40]:
            print("  ", e)
    if apply and not errors:
        for loc, d in caches.items():
            (I18N / f"{loc}.json").write_text(
                json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print("\njsons rewritten:", ", ".join(sorted(caches)))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(run(apply="--check" not in sys.argv))
