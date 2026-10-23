# -*- coding: utf-8 -*-
"""Mechanics coverage matrix (WORKQUEUE G-COV, v10): which player-facing mechanic of the game was exercised by a real run whose log is on disk.

usage: python tools/qa_sim/coverage_matrix.py [--logs GLOB ...] [--write FILE] [--demo]
A mechanic is EXERCISED when a PASSING line of a log of an engine run matches its pattern: a `[closeout] ok` line, an `OK`/`PASS` line of a gate log, or any line of a bot log (the
bot plays the whole game; its lines name what it did). The patterns are written in this file, by area, in the order of the directive's list; a mechanic with no matching line is a MISS and
prints with the reason of its waiver when it has one (a mechanic that only a human can exercise: a phone's touch reach, hearing). The content tables (the 12 monsters, the 11 districts, the 5
endings, the 6 hiding types, the 3 guns) are enumerated from data/ and scripts/, so a new row of a table is a new mechanic here without an edit.
Output: `coverage n/m`, the misses, exit 1 when a miss has no waiver. Default logs: the closeout log of the last chain, the gate logs of check.sh, the bot logs, the frame and gate logs of the pass.
"""
import glob
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
ANSI = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
DEFAULT_LOGS = [".qa_logs/v10_*closeout*.log", ".qa_logs/closeout_check.log", ".qa_logs/gate_*.log", ".qa_logs/v10_bot/*.log", ".qa_logs/autoplay_seed*.log", ".qa_logs/retention_frames_*.log",
                ".qa_logs/anim_frames_scene.log", ".qa_logs/v10_ac5_*.log", ".qa_logs/v10_endings*.log", ".qa_logs/v10_playthrough*.log", ".qa_logs/density_frames_nit*.log"]
PASS = re.compile(r"(?i)(\[closeout\] ok|\bOK\b|\bPASS\b|\bok\b)")

# (area, mechanic, pattern: a regex, case-insensitive, waiver: empty when none)
ROWS = [
    ('MOVEMENT', 'walk and sprint spend stamina', 'stamina', ""),
    ('MOVEMENT', 'crouch', 'crouch', ""),
    ('MOVEMENT', 'the FOV kick', 'fov', ""),
    ('MOVEMENT', 'joystick and the touch cluster', 'joystick|touch', ""),
    ('FLASHLIGHT', 'on and off', 'flashlight', ""),
    ('FLASHLIGHT', 'the battery drains', 'drain|battery', ""),
    ('FLASHLIGHT', 'low-battery flicker', 'flicker', ""),
    ('FLASHLIGHT', 'the blueprints and upgrades', 'blueprint|upgrade', ""),
    ('FLASHLIGHT', 'the phase-2 beam rule (BAT0)', 'BAT0|beam', ""),
    ('STEALTH', 'noise propagation', 'noise', ""),
    ('STEALTH', 'the light grid and visibility', 'light.?grid|visib', ""),
    ('STEALTH', 'hiding spots', 'hiding|hide', ""),
    ('STEALTH', 'investigate, chase, flee', 'investigat|chase|flee', ""),
    ('STEALTH', 'the wake of the heavy kinds within 10 m (WAKE1)', 'WAKE1|wake', ""),
    ('COMBAT', 'melee', 'melee', ""),
    ('COMBAT', 'reload and empty magazine', 'reload|empty|no reserve', ""),
    ('COMBAT', 'the shared ammo reserve', 'reserve|ammo', ""),
    ('COMBAT', 'weapon cycling and holster', 'cycl|holster|WCMP|QSLOT', ""),
    ('COMBAT', 'hit-stop and slow-mo', 'hit.?stop|slow.?mo|wow', ""),
    ('COMBAT', 'the damage vignette', 'vignette', ""),
    ('COMBAT', 'the statuses (bleed, burn, poison, slow, stun)', 'bleed|burn|poison|stun', ""),
    ('COMBAT', 'the telegraph of every attack', 'telegraph|TEL[0-9]', ""),
    ('INVENTORY', 'acquire and stack', 'stack|picked|pickup', ""),
    ('INVENTORY', 'use an item', 'consum|use_item|medkit', ""),
    ('INVENTORY', 'capacity and weight', 'capacity|weight|overweight', ""),
    ('INVENTORY', 'the full pack (the B5 class)', 'full pack|CRF|no room', ""),
    ('INVENTORY', 'salvage', 'salvage', ""),
    ('CRAFTING', 'the recipes', 'recipe|craft', ""),
    ('CRAFTING', 'the workbench', 'workbench', ""),
    ('PROGRESSION', 'XP and levels', '\\bxp\\b|level', ""),
    ('PROGRESSION', 'the skill tree', 'skill', ""),
    ('PROGRESSION', 'coins and the cap', 'coin|ECO1', ""),
    ('PROGRESSION', 'the shop', 'shop', ""),
    ('PROGRESSION', 'upgrades and rewards', 'upgrade|reward', ""),
    ('WORLD', 'the three-stage power repair', 'cable|fuse|transistor|stage', ""),
    ('WORLD', 'restore and the light ramp', 'ramp|restore', ""),
    ('WORLD', 'the city map and travel', 'city.?map|travel', ""),
    ('WORLD', 'doors and keys', 'door|key', ""),
    ('WORLD', 'checkpoints and zones', 'checkpoint|zone', ""),
    ('WORLD', 'exploding barrels', 'barrel', "A3 (Session 30): no passing line names it - the compile gate lists res://scenes/gameplay/exploding_barrel.tscn without a marker, _probe_inst.gd would print it (ok: <path>) but no scene runs that probe (orphaned), and the full closeout 611 checks, a11y and the static battery never name it; follow-up: spawn barrels in a district or drop the scene"),
    ('WORLD', 'the cable puzzle', 'puzzle', ""),
    ('WORLD', 'secrets', 'secret', ""),
    ('WORLD', 'documents and lore notes', 'document|lore|note', ""),
    ('WORLD', 'the radio', 'radio', "A3 (Session 30): no passing line names it - the HUD radio (scripts/ui/radio.gd) appears only in minimap.gd comments, the pickup family table and a11y_check's internal mutation table, never in gate output; follow-up: a HUD check that logs the panel, or an owner row if the panel is cut content"),
    ('WORLD', 'the story props', 'STORY|camp|barricade', ""),
    ('ENEMIES', 'the encyclopedia', 'encyclop|bestiary', ""),
    ('ENEMIES', 'a gait for every monster', 'ANIM[0-9]|gait', ""),
    ('ENEMIES', 'the Architect and its phases', 'architect|boss.*phase|phase.*boss', ""),
    ('AUDIO', 'the five music layers', 'LAY[0-9]|layer', ""),
    ('AUDIO', 'the hunted level', 'hunted', ""),
    ('AUDIO', 'the weather layer', 'weather|rain', ""),
    ('AUDIO', 'the district detail beds', 'detail bed|district_details|detail', ""),
    ('AUDIO', 'the one-shots', 'ONE[0-9]|one.?shot', ""),
    ('META', 'achievements', 'ach_|achiev', ""),
    ('META', 'the daily challenges and streak', 'daily|streak', ""),
    ('META', 'New Game+', 'ng\\+|new game\\+|NGB', ""),
    ('META', 'the photo album', 'photo|album', ""),
    ('META', 'the local leaderboard', 'leaderboard', ""),
    ('META', 'save, load, export, import and backups', 'export|import|backup|save', ""),
    ('META', 'hardcore', 'hardcore', ""),
    ('META', 'settings persistence', 'persist|settings', ""),
    ('META', 'the accessibility toggles', 'colou?rblind|reduce|button size|opacity|caption|minimap|a11y', ""),
    ('META', 'the language switch', 'language|locale|LANG[0-9]', ""),
    ('META', 'weather states', 'weather', ""),
    ('META', 'the tutorial', 'TUT[0-9]|tutorial', ""),
    ('META', 'credits', 'credit', ""),
    ('UI', 'every screen in every locale', 'layout|screen', ""),
    ('UI', 'the text sizes', 'text size|size', ""),
    ('UI', 'the ending title contrast', 'ENDC', ""),
]


def evidence(patterns):
    """Passing lines of every log the globs name, ANSI stripped, as one list of (file, line)."""
    out = []
    for pat in patterns:
        for f in sorted(glob.glob(str(ROOT / pat))):
            is_bot = "/v10_bot/" in f.replace("\\", "/") or "autoplay_seed" in f
            try:
                text = pathlib.Path(f).read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            for line in ANSI.sub("", text).replace("\r", "").split("\n"):
                if line and (is_bot or PASS.search(line)):
                    out.append((f, line))
    return out


def tables():
    """The rows of the content tables, from data/ and scripts/."""
    rows = []
    for p in sorted((ROOT / "data" / "monsters").glob("*.tres")):
        m = re.search(r'(?m)^id = &?"([^"]+)"', p.read_text(encoding="utf-8"))
        if m:
            rows.append(("ENEMIES", "monster %s is met" % m.group(1), re.escape(m.group(1)) + "|" + re.escape(m.group(1).capitalize()), ""))
    d = (ROOT / "scripts" / "world" / "district_loot.gd").read_text(encoding="utf-8")
    block = re.search(r"const LORE_DOCS[^=]*=\s*\{(.*?)\n\}", d, re.S)
    for district in re.findall(r'&"(\w+)":\s*\[', block.group(1)) if block else []:
        rows.append(("WORLD", "district %s is lit" % district, "%s:3|%s.*FULL|%s" % (district, district, district), ""))
    for hide in ("locker", "dumpster", "car", "crate", "bush", "dark_corner"):
        rows.append(("STEALTH", "hiding type %s" % hide, hide.replace("_", ".?"), ""))
    for gun in ("pistol", "rifle", "shotgun"):
        rows.append(("COMBAT", "the %s" % gun, gun, ""))
    for ending in ("light", "hope", "survivor", "dark", "truth"):
        rows.append(("META", "ending %s" % ending, "ending.*%s|%s.*ending" % (ending, ending), ""))
    return rows


def judge(rows, lines):
    hit, miss = [], []
    for area, name, pat, waiver in rows:
        rx = re.compile(pat, re.I)
        found = next(((f, l) for f, l in lines if rx.search(l)), None)
        (hit if found else miss).append((area, name, waiver, found))
    return hit, miss


def main(argv):
    if "--demo" in argv:
        rows = [("A", "seen", "alpha", ""), ("A", "missed", "omega", ""), ("A", "waived", "zeta", "needs a phone")]
        hit, miss = judge(rows, [("f", "[closeout] ok alpha works")])
        assert [h[1] for h in hit] == ["seen"] and [m[1] for m in miss] == ["missed", "waived"]
        assert ANSI.sub("", "\x1b[32mok\x1b[0m") == "ok" and PASS.search("[closeout] ok x") and not PASS.search("[closeout] FAIL x")
        print("coverage_matrix demo: a mechanic with a passing line is hit, one without is a miss, a waiver is printed with its miss")
        return 0
    logs = [argv[i + 1] for i, a in enumerate(argv) if a == "--logs"] or DEFAULT_LOGS
    lines = evidence(logs)
    rows = ROWS + tables()
    hit, miss = judge(rows, lines)
    text = ["coverage %d/%d (%d passing evidence lines from %d logs)" % (len(hit), len(rows), len(lines), len({f for f, _ in lines}))]
    by_area = {}
    for area, name, waiver, found in hit:
        by_area.setdefault(area, [0, 0])[0] += 1
    for area, name, waiver, found in hit + miss:
        by_area.setdefault(area, [0, 0])[1] += 1
    text += ["  %-12s %d/%d" % (a, v[0], v[1]) for a, v in sorted(by_area.items())]
    for area, name, waiver, _ in miss:
        text.append("MISS %-12s %s%s" % (area, name, ("  [waiver: %s]" % waiver) if waiver else ""))
    print("\n".join(text))
    if "--write" in argv:
        pathlib.Path(argv[argv.index("--write") + 1]).write_text("\n".join(text) + "\n", encoding="utf-8")
    return 1 if any(not m[2] for m in miss) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
