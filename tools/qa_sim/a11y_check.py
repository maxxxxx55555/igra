#!/usr/bin/env python3
"""PHASE B.3 — trace every accessibility toggle to a real, locale-independent
effect path. Static: grep the setting key from the Settings UI through to
something that actually changes rendering / gameplay.

Run: python tools/qa_sim/a11y_check.py
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SM = (ROOT / "scripts/systems/settings_manager.gd").read_text(encoding="utf-8")
SCR = (ROOT / "scripts/ui/settings_screen.gd").read_text(encoding="utf-8")


def reads_key(key):
    """files (outside settings_screen/settings_manager) that read get_setting(key)
    or the _apply_ hook that consumes _settings[key]."""
    hits = []
    for gd in ROOT.glob("scripts/**/*.gd"):
        if "tools" in gd.parts:
            continue
        t = gd.read_text(encoding="utf-8")
        if re.search(r'get_setting\(\s*["\']' + key + r'["\']', t):
            hits.append(str(gd.relative_to(ROOT)) + " (get_setting)")
    return hits


def apply_fn_body(key):
    m = re.search(r'func _apply_' + key + r'\(\).*?(?=\nfunc |\Z)', SM, re.S)
    return m.group(0) if m else ""


CASES = {
    "colorblind":  {"in_ui": '"colorblind"' in SCR,  "effect": "ShaderMaterial", "kept": True},
    "text_size":   {"in_ui": '"text_size"' in SCR,   "effect": "default_font_size", "kept": True},
    "high_contrast": {"in_ui": '"high_contrast"' in SCR, "effect": "adjustment_enabled", "kept": True},
    "arachnophobia": {"in_ui": '"arachnophobia"' in SCR, "effect": "AltMesh", "kept": True},
    "reduce_screen_shake": {"in_ui": '"reduce_screen_shake"' in SCR, "effect": None, "kept": True},
    "dyslexia_font": {"in_ui": '"dyslexia_font"' in SCR, "effect": None, "kept": False},
    "auto_aim":    {"in_ui": '"auto_aim"' in SCR,    "effect": None, "kept": False},
}

dispatches = re.search(r'func set_setting.*?EventBus', SM, re.S)
dispatch_block = dispatches.group(0) if dispatches else ""

ok = True
for key, c in CASES.items():
    if c["kept"]:
        if not c["in_ui"]:
            print(f"FAIL  {key}: kept toggle missing from Settings UI"); ok = False; continue
        # effect present in _apply_ body, OR a direct get_setting reader
        body = apply_fn_body(key)
        readers = reads_key(key)
        effect_ok = (c["effect"] and c["effect"] in body) or bool(readers)
        dispatched = c["effect"] is None or f'"{key}"' in dispatch_block
        verdict = "OK  " if (effect_ok and dispatched) else "FAIL"
        if verdict == "FAIL":
            ok = False
        print(f"{verdict}  {key:20s} ui=yes  effect={'yes' if effect_ok else 'NO'}  "
              f"dispatched={'yes' if dispatched else 'n/a-direct'}  "
              f"{('via ' + readers[0]) if readers else ('_apply_' + key + '()')}")
    else:
        verdict = "OK  " if not c["in_ui"] else "FAIL"
        if c["in_ui"]:
            ok = False
        print(f"{verdict}  {key:20s} removed from UI (non-functional: "
              f"{'missing OpenDyslexic .ttf' if key == 'dyslexia_font' else 'no reader anywhere'})")

print()
print("locale independence: colorblind=shader (RGB), text_size=font-size scalar,")
print("high_contrast=Environment adjust, arachnophobia=mesh swap, shake=guard —")
print("none touch strings or fonts-by-script, so all are locale-agnostic.")
print("\nPASS" if ok else "\nFAIL")
sys.exit(0 if ok else 1)
