#!/usr/bin/env python3
"""Key-hint binding gate (T3, RELEASE_GAP_FINAL §1).

A hint that names a control must name the control the player actually has. Sixteen strings shipped with a literal
"WASD", "Tab", "SPACE", "F", "(E)", "Press F" and "Right-click" baked into the sentence: after Settings > Controls >
Key Bindings changed a key the hint kept the letter project.godot shipped with, and a Russian line carried an English
mouse name ("docs/KNOWN_ISSUES.md:1831"). The fix reads the live InputMap (`InputRemap.action_text/move_text/
mouse_text`) into a `%s` template at the call site.

Two rules, both static:

  A. A string a real UI path shows (its key occurs as a literal in scripts/ or scenes/) must not name a remappable
     key or a mouse button literally. Esc, Del and the keyboard's own named keys are not remappable in this game
     (the UI closes on Escape, Delete drops the selected stack - `inventory_ui.gd:92`), so they are not tokens here.
  B. A key that carries a format specifier must never be handed to t(), only to tf(): t() would print the "%s" the
     player is supposed to be shown a key in. The existing i18n_placeholder_fuzz checks the arity of the tf() calls;
     this rule closes the other half - the bare t() that fills nothing.

Run: python tools/qa_sim/hint_binding_check.py        (--demo: self-check on synthetic text)
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
LOCALES = [ROOT / "data" / "i18n" / "en.json", ROOT / "data" / "i18n" / "ru.json"]

# A key name is a small closed vocabulary, not "any capitalised word": "COINS: 0" and "SS-1" are not key hints.
KEYS = {"W", "A", "S", "D", "E", "F", "R", "M", "J", "K", "C", "V", "Q", "T", "G", "H", "Z", "X",
        "WASD", "TAB", "SPACE", "SHIFT", "CTRL", "ALT", "ENTER", "DEL"}
MOUSE = re.compile(r"\b(?:Left|Right)[- ]click\b|\bЛКМ\b|\bПКМ\b")
NAMED = re.compile(r"\b(WASD|Tab|TAB|Space|SPACE|Shift|SHIFT|Ctrl|CTRL|Alt)\b")
SHAPED = [
    re.compile(r"\(\s*([A-Z]{1,5})\s*\)"),                   # "Close (E)"
    re.compile(r"\[\s*([A-Z]{1,6})\s*\]"),                   # "SKIP [SPACE]"
    re.compile(r"^\s*([A-Z]{1,6})\s*[-—:/]"),                 # "WASD - move", "Tab — inventory"
    re.compile(r"[А-Яа-яA-Za-z]\s*[-—]\s*([A-Z]{1,5})\s*$"), # "... — E" / "move - W"
    re.compile(r"\b(?:Press|press|Нажми|нажми)\s+([A-ZА-Я]{1,6})\b"),  # "Press F to switch it on"
]
# The keys that own a mouse name or a key name on purpose: the value IS the name, it is not a sentence about it.
NAME_KEYS = {"KEY_MOUSE_LEFT", "KEY_MOUSE_RIGHT", "KEY_DOUBLE_TAP", "KEY_MOVE_UP", "KEY_MOVE_DOWN",
             "KEY_MOVE_LEFT", "KEY_MOVE_RIGHT", "KEY_RUN", "KEY_STEALTH", "KEY_JUMP", "KEY_ATTACK",
             "KEY_RELOAD", "KEY_INVENTORY"}
SPEC = re.compile(r"%[-+0#]*\d*(?:\.\d+)?[sdifxXc]|\{\w+\}")

SOURCES = (".gd", ".tscn")


def live_keys() -> set:
    """Every locale key that some script or scene names as a literal - i.e. a string a real path can show."""
    used = set()
    for path in list(ROOT.rglob("*.gd")) + list(ROOT.rglob("*.tscn")):
        rel = path.relative_to(ROOT)
        if rel.parts[0] in ("docs", ".git", "_BACKUPS", "_QUARANTINE", "tools"):
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r'"([A-Za-z][A-Za-z0-9_]{2,})"', text):
            used.add(m.group(1))
    return used


def hardcoded(value: str) -> list:
    """The key names this value bakes into its sentence. Shapes whose capture is not a key name do not count."""
    found = [m for m in NAMED.findall(value)]
    for pattern in SHAPED:
        for m in pattern.findall(value):
            token = m.upper()
            if token in KEYS:
                found.append(token)
    if MOUSE.search(value):
        found.append(MOUSE.search(value).group(0))
    return found


def check_strings(strings: dict, live: set) -> list:
    out = []
    for key, value in strings.items():
        if not isinstance(value, str) or key not in live or key in NAME_KEYS:
            continue
        bad = hardcoded(value)
        if bad:
            out.append((key, value, bad))
    return out


def check_bare_t(strings, sources: dict) -> list:
    templated = {k for k, v in strings.items() if isinstance(v, str) and SPEC.search(v)}
    out = []
    for name, text in sources.items():
        for n, line in enumerate(text.splitlines(), 1):
            for m in re.finditer(r'(?<!f)LocalizationManager\.t\(\s*"([A-Za-z0-9_]+)"', line):
                if m.group(1) not in templated:
                    continue
                # t(KEY) % args is the older manual form of tf() and fills the specifier too.
                if re.search(r'\)\s*%', line[m.end() - 1:]):
                    continue
                out.append((name, n, m.group(1)))
    return out


def demo() -> int:
    live = {"A_HINT", "B_HINT", "C_HINT", "D_HINT"}
    strings = {
        "A_HINT": "Tab — inventory. Watch your weight",   # literal named key
        "B_HINT": "Close (E)",                            # literal one-letter key in a hint shape
        "C_HINT": "%s / Esc: close · Del: drop",          # templated, Esc/Del are not remappable
        "D_HINT": "Press F to switch it on.",             # literal key after "Press"
        "E_HINT": "Open the map",                         # untouched, and not live anyway
    }
    bad = {k for k, _, _ in check_strings(strings, live)}
    assert bad == {"A_HINT", "B_HINT", "D_HINT"}, bad
    bare = check_bare_t({"T_HINT": "%s here"}, {"x.gd": '\tlabel.text = LocalizationManager.t("T_HINT")'})
    assert bare == [("x.gd", 1, "T_HINT")], bare
    ok = check_bare_t({"T_HINT": "%s here"}, {"x.gd": '\tlabel.text = LocalizationManager.tf("T_HINT", ["E"])'})
    assert ok == [], ok
    print("hint_binding_check demo ok (literal keys and a bare t() of a template bite; Esc/Del and tf() pass)")
    return 0


def main() -> int:
    if "--demo" in sys.argv:
        return demo()
    live = live_keys()
    sources = {}
    for path in list(ROOT.rglob("*.gd")) + list(ROOT.rglob("*.tscn")):
        rel = path.relative_to(ROOT)
        if rel.parts[0] in ("docs", ".git", "_BACKUPS", "_QUARANTINE", "tools"):
            continue
        # The QA harnesses under scripts/tools/ are not player-facing: _playthrough_runner.gd splits
        # MAP_LOCKED_BY on "%" to read its prefix, which is a use of the template, not a broken fill.
        if rel.parts[0] == "scripts" and len(rel.parts) > 1 and rel.parts[1] == "tools":
            continue
        sources[str(rel)] = path.read_text(encoding="utf-8", errors="replace")

    fails = 0
    for locale in LOCALES:
        strings = json.loads(locale.read_text(encoding="utf-8"))
        for key, value, bad in check_strings(strings, live):
            fails += 1
            tokens = ", ".join(sorted(set(map(str, bad))))[:60]
            print(f"FAIL {locale.name}: {key} names a control literally [{tokens}] - {value[:70]}")
        for name, line, key in check_bare_t(strings, sources):
            fails += 1
            print(f"FAIL {locale.name}: {key} has a format specifier but {name}:{line} shows it through t()")
    if fails:
        print(f"hint_binding_check: {fails} failing string(s)")
        return 1
    print("hint_binding_check: every live key hint is binding-aware and every template goes through tf()")
    return 0


if __name__ == "__main__":
    sys.exit(main())
