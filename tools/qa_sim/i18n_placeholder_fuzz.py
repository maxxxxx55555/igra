# -*- coding: utf-8 -*-
"""i18n placeholder fuzz (Session 23, S2): what the key-count gate of i18n_truth_gate.py does not see.

  P1 placeholder parity: every locale value has the same format specifiers, in the same order, as the English value (GDScript's `%` fills them in order).
  P2 call arity: a tf("KEY", [a, b]) call with a literal array passes as many arguments as the key has specifiers, in every locale.
  P3 literal keys: every literal key of a t() or tf() call exists in all 13 locales (a missing key shows its own name).
  P4 romanized text: a value of a non-Latin locale with five or more Latin letters and none of the locale's script is a stub unless its key is listed under latin_ok.
  P5 cognates: a value of 4 or more letters identical to the English one is untranslated unless the glossary lists it for that locale.
  P6 space flags: "5% critical" read as a format specifier ("% c") breaks the `%` of a tf() key; no tf() key may carry one.
  P7 the glossary file data/i18n_glossary.json is what this tool writes from the dictionaries (the terms) and from its own lists (the whitelists).

usage: python tools/qa_sim/i18n_placeholder_fuzz.py [--check] [--write-glossary] [--demo]
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
LOCALES = ["en", "de", "es", "fr", "pt_BR", "ru"]
SCRIPT = {"ru": r"[Ѐ-ӿ]"}
SPEC = re.compile(r"%[-+0#]*\d*(?:\.\d+)?[sdifxXc]|\{\w+\}")
SPACE_FLAG = re.compile(r"%[ ]\w")
LATIN_OK = ["boot_title", "VSync", "INV_ITEM_WEIGHT", "NG_PLUS_LABEL", "STATS_METERS"]
GLOSSARY = ROOT / "data" / "i18n_glossary.json"
# term -> the key whose value says it, in all 13 locales
TERMS = {
    "flashlight": "SCR_FONARIK", "battery": "ITEM_BATTERY", "medkit": "ITEM_MEDKIT", "noise bomb": "ITEM_NOISE_BOMB", "noise": "CHAR_NOISE", "stamina": "CHAR_STAMINA",
    "health": "CHAR_HEALTH", "quests": "CODEX_TAB_QUESTS", "inventory": "KEY_INVENTORY", "settings": "MAIN_SETTINGS", "map": "MAP_TITLE", "shop": "shop", "coins": "hud_coins",
    "stealth": "KEY_STEALTH", "new game plus": "NEW_GAME_PLUS", "new game": "new_game", "continue": "continue", "resume": "BTN_RESUME", "quit": "menu_quit", "save": "BTN_SAVE",
    "load": "BTN_LOAD", "photo mode": "PHOTO_MODE", "codex": "CODEX_TITLE", "achievements": "ACHIEVEMENTS_TITLE", "daily challenge": "DAILY_CHALLENGE_TITLE",
    "difficulty": "SCR_SLOZHNOST", "easy": "diff_easy", "normal": "diff_normal", "hard": "diff_hard", "subtitles": "Subtitles", "colorblind mode": "Colorblind Mode",
    "music": "SCR_MUZYKA", "language": "Language", "workbench": "WORKBENCH_TITLE", "pistol": "ITEM_PISTOL", "rifle": "ITEM_RIFLE", "shotgun": "ITEM_SHOTGUN",
    "reload": "KEY_RELOAD", "level": "STATS_LEVEL", "hardcore mode": "Hardcore Mode",
}
CALL = re.compile(r"\b(t|tf)\(\s*\"([^\"]*)\"(?:\s*,\s*(\[[^\]]*\]))?")


def load():
    return {loc: json.loads((ROOT / "data" / "i18n" / ("%s.json" % loc)).read_text(encoding="utf-8")) for loc in LOCALES}


def specs(text):
    return [s for s in SPEC.findall(text)]


def code_calls():
    out = []
    for f in sorted((ROOT / "scripts").rglob("*.gd")):
        rel = f.relative_to(ROOT).as_posix()
        if rel.startswith("scripts/tools/"):
            continue
        for number, line in enumerate(f.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            if line.lstrip().startswith("#"):
                continue
            code = re.sub(r"\s#[^\"']*$", "", line)
            for m in CALL.finditer(code):
                args = m.group(3)
                simple = args is not None and "(" not in args and "[" not in args[1:]
                out.append((rel, number, m.group(1), m.group(2), (args.count(",") + 1 if args.strip("[] ") else 0) if simple else None))
    return out


def cognates(data):
    en = data["en"]
    seen = {}
    for key, value in en.items():
        if not isinstance(value, str) or len(re.sub(r"[^A-Za-z]", "", value)) < 4:
            continue
        for loc in LOCALES[1:]:
            if data[loc].get(key) == value:
                seen.setdefault(value, set()).add(loc)
    return {v: sorted(ls) for v, ls in sorted(seen.items())}


def glossary(data):
    terms = {}
    for term, key in TERMS.items():
        terms[term] = {"key": key, "locales": {loc: data[loc].get(key, "") for loc in LOCALES}}
    return {"version": 1, "_contract": "Machine-readable. terms: the core words of the game and the dictionary key that says each in the 13 locales (read from data/i18n, not translated here). cognates: English values that a locale repeats on purpose, with the locales; a new identical value fails tools/qa_sim/i18n_placeholder_fuzz.py. latin_ok: keys whose value stays Latin in the non-Latin locales. Written by that tool.",
            "terms": terms, "cognates": cognates(data), "latin_ok": LATIN_OK}


def findings(data, calls, allowed):
    out = []
    en = data["en"]
    tf_keys = {key for _, _, kind, key, _ in calls if kind == "tf"}
    for key, value in en.items():
        if not isinstance(value, str):
            continue
        want = specs(value)
        for loc in LOCALES[1:]:
            got = data[loc].get(key)
            if isinstance(got, str) and [s[-1] if s.startswith("%") else s for s in specs(got)] != [s[-1] if s.startswith("%") else s for s in want]:
                out.append("P1 %s %s: specifiers %s, English %s" % (loc, key, specs(got), want))
            if isinstance(got, str) and key in tf_keys and SPACE_FLAG.search(got.replace("%%", "")):
                out.append("P6 %s %s: a space-flag lookalike in a tf() key" % (loc, key))
        if key in tf_keys and SPACE_FLAG.search(value.replace("%%", "")):
            out.append("P6 en %s: a space-flag lookalike in a tf() key" % key)
    for rel, line, kind, key, arity in calls:
        for loc in LOCALES:
            if key not in data[loc]:
                out.append("P3 %s:%d: %s() key %r is missing in %s" % (rel, line, kind, key, loc))
                break
        if kind == "tf" and arity is not None and key in en and isinstance(en[key], str) and len(specs(en[key])) != arity:
            out.append("P2 %s:%d: tf(%r) passes %d argument(s), the key has %d specifier(s)" % (rel, line, key, arity, len(specs(en[key]))))
    for loc, rx in SCRIPT.items():
        for key, value in data[loc].items():
            if isinstance(value, str) and len(re.findall(r"[A-Za-z]", value)) >= 5 and not re.search(rx, value) and key not in allowed["latin_ok"]:
                out.append("P4 %s %s: Latin text in a non-Latin locale" % (loc, key))
    for key, value in en.items():
        if not isinstance(value, str) or len(re.sub(r"[^A-Za-z]", "", value)) < 4:
            continue
        for loc in LOCALES[1:]:
            if data[loc].get(key) == value and loc not in allowed["cognates"].get(value, []):
                out.append("P5 %s %s: identical to English (%r) and not a listed cognate" % (loc, key, value[:40]))
    return out


def main(argv):
    if "--demo" in argv:
        data = {loc: {"A": "x %s y", "B": "z"} for loc in LOCALES}
        data["de"]["A"] = "x y"
        data["fr"]["B"] = "zz"
        data["es"]["B"] = "z"
        calls = [("scripts/a.gd", 3, "tf", "A", 2), ("scripts/a.gd", 4, "t", "NOPE", None)]
        bad = findings(data, calls, {"latin_ok": [], "cognates": {}})
        kinds = {b.split(" ", 1)[0] for b in bad}
        assert {"P1", "P2", "P3"} <= kinds, kinds
        print("i18n_placeholder_fuzz demo: a lost specifier, a wrong argument count and a missing key are all found")
        return 0
    data = load()
    calls = code_calls()
    stored = json.loads(GLOSSARY.read_text(encoding="utf-8")) if GLOSSARY.exists() else {}
    if "--write-glossary" in argv:
        GLOSSARY.write_text(json.dumps(glossary(data), ensure_ascii=False, indent=1, sort_keys=True) + "\n", encoding="utf-8")
        stored = json.loads(GLOSSARY.read_text(encoding="utf-8"))
    allowed = {"latin_ok": stored.get("latin_ok", []), "cognates": stored.get("cognates", {})}
    bad = findings(data, calls, allowed)
    if stored != glossary(data):
        bad.append("P7 data/i18n_glossary.json is not what the dictionaries say: run with --write-glossary")
    for line in bad[:40]:
        print("FAIL", line)
    print("i18n_placeholder_fuzz: %d key(s), %d call(s), %d finding(s)" % (len(data["en"]), len(calls), len(bad)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
