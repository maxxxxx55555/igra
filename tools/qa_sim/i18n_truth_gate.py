#!/usr/bin/env python3
"""P0 truth gate: static, per-string checks across all 13 locale JSON files
in data/i18n/ that tools/flow_check.py doesn't do (flow_check only proves
audio files referenced in code exist on disk, plus signal/bus wiring - it
never opens the locale JSONs). Checks, per the ponytail order-pass spec:
  - zero missing keys (every en.json key present and non-empty elsewhere)
  - zero mixed-script strings (CJK+Cyrillic+Arabic never combine in one
    string - Latin is exempted: brand names/tech tokens staying Latin in a
    translation is this project's own documented convention, e.g.
    settings_screen.gd's untranslated "30fps, 720p" graphics-tier labels)
  - length ratio <= 1.6x English (catches overflow-prone translations)

NOT covered here (needs a live engine, see tools/qa_sim/gui_explore_runner.gd
for the runtime half of this gate - it already proves the Settings title
differs per locale and survives a live language switch for 13/13 locales):
  - "differs from previous locale" - only meaningfully spot-checked live so
    far, not swept across all 1291 keys.
  - "survives save/reload" - needs an actual process restart, not built yet.

Usage: python tools/qa_sim/i18n_truth_gate.py [data/i18n]
Exit 0 if every locale passes every check, 1 otherwise.
"""
import json
import re
import sys
from pathlib import Path

LENGTH_RATIO_MAX = 1.6
# Below this many characters, the 1.6x ratio is noise, not signal: a 4-letter
# English word ("Save") routinely becomes 8-11 letters in Russian/German/
# French ("Сохранить"/"Speichern"/"Sauvegarder") in a perfectly normal,
# correct translation - standard l10n QA practice gives short strings more
# expansion room. Found by hand-checking the first real run's flagged
# strings (all short single words, all natural translations) before trusting
# the raw ratio - a naive 1.6x-on-everything gate would permanently FAIL on
# fine translations across 8 of 12 locales.
SHORT_STRING_FLOOR = 12
# The short-string exemption above was originally uncapped: any base string
# under SHORT_STRING_FLOOR chars could translate to ANY length with zero
# signal, which is real l10n practice for normal expansion (4-11 char words
# routinely 2-3x) but would also wave through a genuinely broken/garbage
# translation of a short string. A looser hard ratio still catches that
# without re-flagging the legitimate short-word expansions this floor exists
# for (measured against the first real run's flagged strings, all comfortably
# under 3x).
SHORT_STRING_RATIO_CAP = 3.0
BASE_LOCALE = "en"
SUPPORTED = ["ru", "en", "es", "de", "fr", "it", "pt_BR", "tr", "ja", "ko", "zh", "zh_TW", "ar"]

SCRIPT_RANGES = {
    "cjk": (0x4E00, 0x9FFF),
    "cyrillic": (0x0400, 0x04FF),
    "arabic": (0x0600, 0x06FF),
}


def _scripts_in(s: str) -> set[str]:
    found = set()
    for ch in s:
        cp = ord(ch)
        for name, (lo, hi) in SCRIPT_RANGES.items():
            if lo <= cp <= hi:
                found.add(name)
    return found


def _is_mixed_script(s: str) -> bool:
    return len(_scripts_in(s)) > 1


def load_locale(i18n_dir: Path, code: str) -> dict:
    path = i18n_dir / f"{code}.json"
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def check_locale(base: dict, code: str, strings: dict) -> dict:
    missing = []
    mixed = []
    overflow = []
    for key, base_val in base.items():
        val = strings.get(key)
        if val is None or str(val).strip() == "":
            missing.append(key)
            continue
        val = str(val)
        if _is_mixed_script(val):
            mixed.append(key)
        base_len = len(str(base_val))
        ratio = len(val) / base_len
        ratio_max = LENGTH_RATIO_MAX if base_len >= SHORT_STRING_FLOOR else SHORT_STRING_RATIO_CAP
        if ratio > ratio_max:
            overflow.append(key)
    return {"locale": code, "missing": missing, "mixed": mixed, "overflow": overflow}


def run(i18n_dir: Path) -> tuple[bool, list[dict]]:
    base = load_locale(i18n_dir, BASE_LOCALE)
    results = []
    all_ok = True
    for code in SUPPORTED:
        if code == BASE_LOCALE:
            continue
        strings = load_locale(i18n_dir, code)
        r = check_locale(base, code, strings)
        ok = not (r["missing"] or r["mixed"] or r["overflow"])
        all_ok &= ok
        r["ok"] = ok
        results.append(r)
    return all_ok, results


def main(argv: list[str]) -> int:
    i18n_dir = Path(argv[1]) if len(argv) > 1 else Path("data/i18n")
    all_ok, results = run(i18n_dir)
    for r in results:
        status = "PASS" if r["ok"] else "FAIL"
        print("%s %s -- missing=%d mixed=%d overflow=%d" % (
            status, r["locale"], len(r["missing"]), len(r["mixed"]), len(r["overflow"])))
        # Full lists, not a [:3] sample - a truncated log hid the real scale
        # of a red gate (e.g. fr's 49 overflow flags read as "a handful").
        for key in r["missing"]:
            print("    missing: %s" % key)
        for key in r["mixed"]:
            print("    mixed-script: %s" % key)
        for key in r["overflow"]:
            print("    overflow (>%.1fx): %s" % (LENGTH_RATIO_MAX, key))
    n_pass = sum(1 for r in results if r["ok"])
    print("%d/%d locales PASS" % (n_pass, len(results)))
    return 0 if all_ok else 1


def _demo() -> None:
    """ponytail self-check: synthetic in-memory locales, no fixtures needed."""
    base = {"A": "Hello", "B": "World"}
    good = {"A": "Hola", "B": "Mundo"}
    bad = {"A": "Привет мир一"}  # mixed cyrillic+cjk, and B missing entirely
    r_good = check_locale(base, "xx", good)
    r_bad = check_locale(base, "yy", bad)
    assert not r_good["missing"] and not r_good["mixed"] and not r_good["overflow"], r_good
    assert "B" in r_bad["missing"], r_bad
    assert "A" in r_bad["mixed"], r_bad
    overflow_case = check_locale({"A": "Hello there friend"}, "zz", {"A": "H" * 40})
    assert "A" in overflow_case["overflow"], overflow_case
    # Short-string exemption is bounded, not a blank check: a normal 2-3x
    # short-word expansion still passes, but a short string blown out past
    # SHORT_STRING_RATIO_CAP is still caught.
    short_ok = check_locale({"A": "Save"}, "ww", {"A": "Sauvegarder"})  # 4 -> 11 chars, 2.75x
    assert "A" not in short_ok["overflow"], short_ok
    short_bad = check_locale({"A": "Save"}, "vv", {"A": "S" * 20})  # 4 -> 20 chars, 5x
    assert "A" in short_bad["overflow"], short_bad
    print("demo OK")


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--demo":
        _demo()
        sys.exit(0)
    sys.exit(main(sys.argv))
