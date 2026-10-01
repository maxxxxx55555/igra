#!/usr/bin/env python3
"""project.godot input-map gate (rc15, CORRECTION_LOG 58).

An action block (`name={"deadzone": ..., "events": [...]}`) is an InputMap action only inside [input]. Ten of them
sat in [application] for weeks (sprint, crouch, melee, attack, flashlight, reload, strobe): inert config that
masked missing actions from every grep-based check. Fails when such a block is outside [input], and when an action
the scripts read is not defined in [input].

Run: python tools/qa_sim/project_input_check.py        (--demo: self-check on synthetic text)
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
BLOCK = re.compile(r'^([A-Za-z_0-9]+)=\{\s*\n"deadzone"', re.M)
READ = re.compile(r'is_action_(?:just_)?(?:pressed|released)\(\s*"([a-z_0-9]+)"')
READ_INPUT = re.compile(r'Input\.(?:is_action_pressed|is_action_just_pressed|is_action_just_released|get_action_strength)\(\s*"([a-z_0-9]+)"')


def sections(text: str) -> dict:
    out, name, start = {}, None, 0
    for m in re.finditer(r"^\[([a-z_]+)\]\s*$", text, re.M):
        if name is not None:
            out[name] = text[start:m.start()]
        name, start = m.group(1), m.end()
    if name is not None:
        out[name] = text[start:]
    return out


def check(text: str, script_actions: set) -> list:
    errors = []
    secs = sections(text)
    for name, body in secs.items():
        if name != "input":
            for m in BLOCK.finditer(body):
                errors.append("action block '%s' sits in [%s], not [input]" % (m.group(1), name))
    defined = {m.group(1) for m in BLOCK.finditer(secs.get("input", ""))}
    builtin = {a for a in script_actions if a.startswith("ui_")}
    for action in sorted(script_actions - defined - builtin):
        errors.append("scripts read action '%s' but [input] does not define it" % action)
    return errors


def script_actions() -> set:
    seen = set()
    for gd in ROOT.glob("scripts/**/*.gd"):
        if "tools" in gd.parts:
            continue
        body = gd.read_text(encoding="utf-8")
        seen.update(READ.findall(body))
        seen.update(READ_INPUT.findall(body))
    return seen


def demo() -> int:
    good = '[application]\nconfig/name="x"\n\n[input]\n\njump={\n"deadzone": 0.5,\n"events": []\n}\n'
    bad = '[application]\nconfig/name="x"\njump={\n"deadzone": 0.5,\n"events": []\n}\n\n[input]\n'
    assert check(good, {"jump"}) == [], check(good, {"jump"})
    assert any("not [input]" in e for e in check(bad, {"jump"})), check(bad, {"jump"})
    assert any("does not define" in e for e in check(good, {"jump", "reload"})), "undefined action not caught"
    print("project_input_check --demo: ok")
    return 0


def main() -> int:
    if "--demo" in sys.argv:
        return demo()
    text = (ROOT / "project.godot").read_text(encoding="utf-8")
    errors = check(text, script_actions())
    for e in errors:
        print("FAIL", e)
    print("project_input_check:", "FAIL" if errors else "ok")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
