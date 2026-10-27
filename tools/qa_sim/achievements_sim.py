# -*- coding: utf-8 -*-
"""Achievement reachability (Session 23, S2): can every achievement of scripts/systems/achievements_manager.gd be unlocked from a real path of the running game?

For each id of the ACHIEVEMENTS table the tool finds the trigger: a _check_unlock call in the manager (its function, the EventBus signal that function is connected to, and the
first place that emits the signal), a poll in _process, or an AchievementManager.unlock call of another script (the photo milestones, the progress tracker). A signal nothing emits,
a function nothing connects and an id with no trigger are findings, listed with file:line. A few triggers also need a thing to exist (the monster of "kill 50 shadows"): REQUIRES.

usage: python tools/qa_sim/achievements_sim.py [--write docs/ACHIEVEMENT_TRIGGER_SPEC.md] [--demo]
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
MANAGER = "scripts/systems/achievements_manager.gd"
BUS = "scripts/events/event_bus.gd"
SKIP = ("scripts/tools/", "scenes/tools/", "scripts/security/")
# id -> (file, text that must be in it, why)
REQUIRES = {
    "ach_05": ("scripts/enemies/shadow_3d.gd", "shadow", "the monster of the kill count exists as the scene shadow_3d"),
    "ach_14": ("scripts/systems/endings_manager.gd", '"truth"', "the ending the unlock waits for exists"),
}


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n").split("\n")


def table_ids(lines):
    text = "\n".join(lines)
    return re.findall(r'^\t"(ach_\w+)": \{', text, re.M)


def functions(lines):
    """[(name, first line, last line)] of the script's functions, 1-based."""
    heads = [(i + 1, re.match(r"func (\w+)", ln).group(1)) for i, ln in enumerate(lines) if re.match(r"func \w+", ln)]
    return [(name, start, (heads[k + 1][0] - 1 if k + 1 < len(heads) else len(lines))) for k, (start, name) in enumerate(heads)]


def enclosing(funcs, line):
    for name, a, b in funcs:
        if a <= line <= b:
            return name
    return ""


def manager_triggers(lines):
    """[(achievement id or pattern, line, function)] of every _check_unlock in the manager."""
    funcs = functions(lines)
    out = []
    for number, text in enumerate(lines, 1):
        if text.strip().startswith("func _check_unlock"):
            continue
        m = re.search(r'_check_unlock\(&"(ach_\w+)"', text)
        if m:
            out.append((m.group(1), number, enclosing(funcs, number)))
        elif re.search(r'_check_unlock\(StringName\("(ach_district_)" \+', text):
            out.append(("ach_district_*", number, enclosing(funcs, number)))
    return out


def connections(lines):
    """{function name or 'line N': signal} from EventBus.<signal>.connect(...) lines (a lambda that calls _check_unlock is keyed by its line)."""
    out = {}
    for number, text in enumerate(lines, 1):
        m = re.search(r"EventBus\.(\w+)\.connect\(([^)]*)", text)
        if not m:
            continue
        target = re.match(r"(\w+)$", m.group(2).strip())
        out[target.group(1) if target else "line %d" % number] = m.group(1)
    return out


def emitters(signal):
    found = []
    for f in sorted((ROOT / "scripts").rglob("*.gd")):
        rel = f.relative_to(ROOT).as_posix()
        if rel.startswith(SKIP) or rel == MANAGER:
            continue
        for number, text in enumerate(f.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            if re.search(r"EventBus\.%s\.emit\(" % re.escape(signal), text):
                found.append((rel, number))
    return found


def external_unlocks():
    """{achievement id: (file, line)} from AchievementManager.unlock calls of other scripts, resolved through the manager's short-id map and the photo milestones."""
    manager = "\n".join(read(MANAGER))
    short = dict(re.findall(r'"(\w+)": &"(ach_\w+)"', manager))
    out = {}
    for f in sorted((ROOT / "scripts").rglob("*.gd")):
        rel = f.relative_to(ROOT).as_posix()
        if rel.startswith(SKIP) or rel == MANAGER:
            continue
        text = f.read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n")
        lines = text.split("\n")
        for number, ln in enumerate(lines, 1):
            if "AchievementManager.unlock(" not in ln:
                continue
            literal = re.search(r'unlock\("(\w+)"\)', ln)
            if literal:
                out[short.get(literal.group(1), literal.group(1))] = (rel, number)
            for key, value in re.findall(r'(\d+): "(ach_\w+)"', text):
                if "PHOTO_MILESTONES" in text:
                    out.setdefault(value, (rel, number))
            for name in re.findall(r"unlock\((\w+)\)", ln):
                for value in re.findall(r'"(\w+)"', "\n".join(l for l in lines if "_grant(" in l)):
                    out.setdefault(short.get(value, value), (rel, number))
    return out


def analyse():
    lines = read(MANAGER)
    ids = table_ids(lines)
    triggers = manager_triggers(lines)
    links = connections(lines)
    external = external_unlocks()
    rows, bad = [], ["%s:%d: unknown external achievement %s" % (rel, line, aid)
                     for aid, (rel, line) in external.items() if aid not in ids]
    for aid in ids:
        found = [t for t in triggers if t[0] == aid or (t[0] == "ach_district_*" and aid.startswith("ach_district_"))]
        if found:
            _, number, func = found[0]
            if func == "_process":
                rows.append((aid, "polled once a second in `_process`", MANAGER, number, "", "", ""))
                continue
            signal = links.get(func) or links.get("line %d" % number)
            if signal is None:
                bad.append("%s: %s (line %d) is connected to no EventBus signal" % (aid, func or "?", number))
                continue
            where = emitters(signal)
            if not where:
                bad.append("%s: nothing emits EventBus.%s" % (aid, signal))
            rows.append((aid, "`%s`" % signal, MANAGER, number, where[0][0] if where else "", where[0][1] if where else "", signal))
        elif aid in external:
            rows.append((aid, "an AchievementManager.unlock call", external[aid][0], external[aid][1], "", "", ""))
        else:
            bad.append("%s: no trigger found" % aid)
            rows.append((aid, "none", "", 0, "", "", ""))
    for aid, (rel, needle, why) in REQUIRES.items():
        if needle not in "\n".join(read(rel)):
            bad.append("%s: %s (%s has no %s)" % (aid, why, rel, needle))
    return ids, rows, bad


def write(path, ids, rows, bad):
    text = ["# Achievement triggers (Session 23)", "",
            "Generated by `python tools/qa_sim/achievements_sim.py --write docs/ACHIEVEMENT_TRIGGER_SPEC.md`; the same tool is a static gate of `tools/check.sh`. %d achievements in the table of `%s`." % (len(ids), MANAGER), "",
            "| Id | Trigger | Where it is checked | First emitter of the signal |", "|---|---|---|---|"]
    for aid, how, rel, number, e_rel, e_line, signal in rows:
        site = "`_check_unlock` at `%s:%d`" % (rel, number) if rel == MANAGER and number else ("`unlock` at `%s:%d`" % (rel, number) if rel else "none")
        emit = "`EventBus.%s.emit` at `%s:%d`" % (signal, e_rel, e_line) if e_rel else ""
        text.append("| %s | %s | %s | %s |" % (aid, how, site, emit))
    text += ["", "Findings: %s." % ("none: every achievement has a trigger that a running game reaches" if not bad else "; ".join(bad))]
    pathlib.Path(path).write_text("\n".join(text) + "\n", encoding="utf-8")


def main(argv):
    if "--demo" in argv:
        lines = ["const ACHIEVEMENTS: Dictionary = {", '\t"ach_01": {', '\t"ach_02": {', "}", "func _on_a() -> void:", '\t_check_unlock(&"ach_01", true)', "func _on_b() -> void:", '\t_check_unlock(&"ach_02", true)']
        assert table_ids(lines) == ["ach_01", "ach_02"]
        t = manager_triggers(lines)
        assert t == [("ach_01", 6, "_on_a"), ("ach_02", 8, "_on_b")]
        assert connections(["EventBus.x.connect(_on_a)", "EventBus.y.connect(func() -> void: _check_unlock(&\"ach_02\", true))"]) == {"_on_a": "x", "line 2": "y"}
        print("achievements_sim demo: ids, triggers and signal links are read from a fixture")
        return 0
    ids, rows, bad = analyse()
    for line in bad:
        print("FAIL", line)
    if "--write" in argv:
        write(argv[argv.index("--write") + 1], ids, rows, bad)
    print("achievements_sim: %d achievement(s), %d finding(s)" % (len(ids), len(bad)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
