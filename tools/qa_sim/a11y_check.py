#!/usr/bin/env python3
"""Accessibility gate: every accessibility feature traces from its Settings row to something that changes what the player sees, hears or does.

Part 1 (PHASE B.3): the older toggles, traced from the Settings UI to a real effect path.
Part 2 (Session 23, 9 features, docs/A11Y_PLAN.md): each feature names the Settings rows it needs, the readers that make it work (file and text),
the locale keys it shows (present and non-empty in all 13 locales) and the default of each of its settings. A feature passes when every part holds.
Part 3 (--mutations): the gate tests itself. For every reader, row, locale key and default of part 2 it removes that one thing from an in-memory copy
and demands the feature then FAILS; a toggle that could be unwired without the gate noticing would be a defect of the gate.

Run: python tools/qa_sim/a11y_check.py [--mutations]
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
LOCALES = ["ar", "de", "en", "es", "fr", "it", "ja", "ko", "pt_BR", "ru", "tr", "zh", "zh_TW"]
SCREEN = "scripts/ui/settings_screen.gd"
MANAGER = "scripts/systems/settings_manager.gd"
ROW = re.compile(r'\b_(?:toggle|slider|dropdown)\(parent,[^\n]*?\),\s*"([a-z_]+)"')

KEYS_LABELS = ["KEY_MOVE_UP", "KEY_MOVE_DOWN", "KEY_MOVE_LEFT", "KEY_MOVE_RIGHT", "KEY_RUN", "KEY_STEALTH", "KEY_JUMP", "KEY_ATTACK", "KEY_RELOAD",
               "PROMPT_INTERACT", "SCR_FONARIK", "KEY_INVENTORY", "MAP_TITLE", "JOURNAL_TITLE", "Key Bindings", "KEYS_RESET", "KEYS_PRESS"]
CUES = ["SND_NOTICED", "SND_STRIKE", "SND_ROAR", "SND_WHISPER", "SND_FLICKER", "SND_BATTERY_DEAD", "SND_GRID_ON"]

# feature -> (settings rows on the screen, readers [(file, text)], locale keys, settings with a default)
FEATURES = {
    "A1 subtitles (toggle, size S/M/L, background 0/50/100, color white/yellow/cyan)": (
        ["subtitles", "subtitle_size", "subtitle_bg", "subtitle_color"],
        [("scripts/ui/subtitle_manager.gd", 'get_setting("subtitles"'), ("scripts/ui/subtitle_manager.gd", 'get_setting("subtitle_size"'),
         ("scripts/ui/subtitle_manager.gd", 'get_setting("subtitle_bg"'), ("scripts/ui/subtitle_manager.gd", 'get_setting("subtitle_color"'),
         ("scripts/ui/subtitle_manager.gd", "EventBus.toast_requested.connect"), ("scripts/ui/subtitle_manager.gd", "EventBus.voice_line.connect"),
         ("scripts/ui/subtitle_manager.gd", "EventBus.examine_text.connect"), ("scripts/ui/ui_manager.gd", "subtitle_manager.gd"),
         ("scripts/ui/radio.gd", "EventBus.voice_line.emit"), ("scripts/events/event_bus.gd", "signal voice_line")],
        ["Subtitles", "Subtitle Size", "Subtitle Background", "Subtitle Color", "sc_white", "sc_yellow", "sc_cyan", "ts_small", "ts_medium", "ts_large"],
        ["subtitles", "subtitle_size", "subtitle_bg", "subtitle_color"]),
    "A2 control remapping (rebind, persisted, reset to default)": (
        [],
        [("scripts/ui/settings_screen.gd", "_RemapPanel.new()"), ("scripts/ui/remap_panel.gd", "_InputRemap.bind("), ("scripts/ui/remap_panel.gd", "_InputRemap.reset()"),
         ("scripts/ui/remap_panel.gd", 'SettingsManager.set_setting("keybinds"'), ("scripts/systems/input_remap.gd", "static func bind("),
         ("scripts/systems/input_remap.gd", "InputMap.action_add_event"), ("scripts/systems/settings_manager.gd", '_InputRemap.apply(_settings.get("keybinds"')],
        KEYS_LABELS, ["keybinds"]),
    "A3 difficulty presets (Easy, Normal, Hard in spawn, damage, loot and revive code)": (
        ["difficulty"],
        [("scripts/enemies/base_monster.gd", 'difficulty_scale("monster_hp")'), ("scripts/enemies/base_monster.gd", 'difficulty_scale("monster_damage")'),
         ("scripts/player/player_3d.gd", 'difficulty_scale("player_hp")'), ("scripts/world/district_loot.gd", '"difficulty_scale", "extra_parts"'),
         ("scripts/monetization/ad_service.gd", 'difficulty_scale("revive")'), ("scripts/systems/settings_manager.gd", "const DIFFICULTY_PRESETS")],
        ["Difficulty", "diff_easy", "diff_normal", "diff_hard", "DIFF_EASY_DESC", "DIFF_NORMAL_DESC", "DIFF_HARD_DESC"], ["difficulty"]),
    "A4 motion comfort (no shake, no FOV punch, no sprint blur, no landing dip, no rain on the lens)": (
        ["reduce_camera_motion"],
        [("scripts/effects/screen_shake.gd", 'get_setting("reduce_camera_motion"'), ("scripts/systems/wow_director.gd", '_setting("reduce_camera_motion"'), ("scripts/post_process_overlay.gd", 'get_setting("reduce_camera_motion"'),
         ("scripts/core/camera_follow_3d.gd", 'get_setting("reduce_camera_motion"'), ("scripts/effects/rain_lens.gd", 'get_setting("reduce_camera_motion"')],
        ["Motion Comfort", "Reduce Screen Shake"], ["reduce_camera_motion"]),
    "A5 high contrast (the dyslexia font stays an owner row: no font file ships)": (
        ["high_contrast"],
        [(MANAGER, "adjustment_contrast"), (MANAGER, '"high_contrast": _apply_high_contrast()')],
        ["High Contrast"], ["high_contrast"]),
    "A6 clear objectives (cognitive clarity: the objective list and status rows do not fade)": (
        ["clear_objectives"],
        [("scripts/ui/hud_fade.gd", 'get_setting("clear_objectives"'), ("scripts/ui/hud_fade.gd", "var stay: bool = keep or _clear()"),
         ("scripts/ui/quest_tracker_hud.gd", "_FADE.show_for([_container], _SHOW_SEC)")],
        ["Clear Objectives", "Objective Markers"], ["clear_objectives", "objective_markers"]),
    "A7 one-handed mode (buttons beside the joystick, latched sprint, wider double tap)": (
        ["one_handed"],
        [("scripts/ui/hud_3d.gd", 'get_setting("one_handed"'), ("scripts/ui/hud_3d.gd", "_place_action_cluster(factor)"),
         ("scripts/ui/hud_3d.gd", "isv.is_joy_run_held()"), ("scripts/core/input_service.gd", "func is_joy_run_held"),
         ("scripts/ui/virtual_joystick.gd", "double_tap_window()")],
        ["One-Handed Mode"], ["one_handed"]),
    "A8 edge highlight (a bright rim on interactables and pickups in range)": (
        ["edge_highlight"],
        [("scripts/effects/edge_highlight.gd", 'get_setting("edge_highlight"'), ("scripts/effects/edge_highlight.gd", "material_overlay = _material()"),
         ("scripts/player/interactor.gd", "EdgeHighlight.new()")],
        ["Edge Highlight"], ["edge_highlight"]),
    "A9 sound cues (a caption and an edge flash for the sounds of the game)": (
        ["sound_cues"],
        [("scripts/ui/subtitle_manager.gd", 'get_setting("sound_cues"'), ("scripts/ui/subtitle_manager.gd", "EventBus.boss_spawned.connect"),
         ("scripts/ui/subtitle_manager.gd", "EventBus.player_detected.connect"), ("scripts/ui/subtitle_manager.gd", 'get_setting("reduce_flash"')],
        ["Sound Cues"] + CUES, ["sound_cues"]),
}


def real_read(path):
    return (ROOT / path).read_text(encoding="utf-8")


def locale_ok(read, key):
    for loc in LOCALES:
        try:
            data = json.loads(read("data/i18n/%s.json" % loc))
        except (ValueError, OSError):
            return False
        if not str(data.get(key, "")).strip():
            return False
    return True


def feature_problems(name, read):
    rows, readers, keys, defaults = FEATURES[name]
    problems = []
    screen_keys = set(ROW.findall(read(SCREEN)))
    for row in rows:
        if row not in screen_keys:
            problems.append("no Settings row for '%s'" % row)
    for path, needle in readers:
        if needle not in read(path):
            problems.append("%s lost %r" % (path, needle))
    for key in keys:
        if not locale_ok(read, key):
            problems.append("locale key '%s' missing or empty" % key)
    defaults_text = read(MANAGER)
    for setting in defaults:
        if '_settings["%s"] =' % setting not in defaults_text:
            problems.append("no default for '%s'" % setting)
    return problems


def mutations():
    """Every single removal must make its feature fail. Returns (detected, total, undetected)."""
    detected = total = 0
    missed = []
    for name, (rows, readers, keys, defaults) in FEATURES.items():
        cases = []
        for row in rows:
            cases.append(("row " + row, SCREEN, lambda t, r=row: re.sub(r'(\b_(?:toggle|slider|dropdown)\(parent,[^\n]*?\),\s*)"%s"' % r, r'\1"x_%s"' % r, t)))
        for path, needle in readers:
            cases.append(("reader %r in %s" % (needle, path), path, lambda t, n=needle: t.replace(n, "")))
        for setting in defaults:
            cases.append(("default " + setting, MANAGER, lambda t, s=setting: t.replace('_settings["%s"] =' % s, '_removed["%s"] =' % s)))
        for key in keys:
            cases.append(("locale key " + key, "data/i18n/ru.json", lambda t, k=key: t.replace('"%s":' % k, '"x_%s":' % k)))
        for label, path, mutate in cases:
            total += 1
            original = real_read

            def read(p, path=path, mutate=mutate):
                return mutate(original(p)) if p == path else original(p)
            if feature_problems(name, read):
                detected += 1
            else:
                missed.append("%s: %s" % (name.split(" (")[0], label))
    return detected, total, missed


def legacy():
    sm = real_read(MANAGER)
    scr = real_read(SCREEN)

    def reads_key(key):
        hits = []
        for gd in ROOT.glob("scripts/**/*.gd"):
            if "tools" in gd.parts:
                continue
            if re.search(r'get_setting\(\s*["\']' + key + r'["\']', gd.read_text(encoding="utf-8")):
                hits.append(str(gd.relative_to(ROOT)) + " (get_setting)")
        return hits

    def apply_fn_body(key):
        m = re.search(r'func _apply_' + key + r'\(\).*?(?=\nfunc |\Z)', sm, re.S)
        return m.group(0) if m else ""

    cases = {
        "colorblind": {"in_ui": '"colorblind"' in scr, "effect": "ShaderMaterial", "kept": True},
        "text_size": {"in_ui": '"text_size"' in scr, "effect": "default_font_size", "kept": True},
        "high_contrast": {"in_ui": '"high_contrast"' in scr, "effect": "adjustment_enabled", "kept": True},
        "arachnophobia": {"in_ui": '"arachnophobia"' in scr, "effect": "AltMesh", "kept": True},
        "reduce_screen_shake": {"in_ui": '"reduce_screen_shake"' in scr, "effect": None, "kept": True},
        "dyslexia_font": {"in_ui": '"dyslexia_font"' in scr, "effect": None, "kept": False},
        "auto_aim": {"in_ui": '"auto_aim"' in scr, "effect": None, "kept": True},
    }
    m = re.search(r'func set_setting.*?EventBus', sm, re.S)
    dispatch_block = m.group(0) if m else ""
    ok = True
    for key, c in cases.items():
        if c["kept"]:
            if not c["in_ui"]:
                print("FAIL  %s: kept toggle missing from Settings UI" % key)
                ok = False
                continue
            body = apply_fn_body(key)
            readers = reads_key(key)
            effect_ok = (c["effect"] and c["effect"] in body) or bool(readers)
            dispatched = c["effect"] is None or '"%s"' % key in dispatch_block
            good = effect_ok and dispatched
            ok = ok and good
            print("%s  %-20s ui=yes  effect=%s  dispatched=%s  %s" % ("OK  " if good else "FAIL", key, "yes" if effect_ok else "NO",
                  "yes" if dispatched else "n/a-direct", ("via " + readers[0]) if readers else ("_apply_" + key + "()")))
        else:
            good = not c["in_ui"]
            ok = ok and good
            print("%s  %-20s removed from UI (non-functional: missing OpenDyslexic .ttf, an owner row)" % ("OK  " if good else "FAIL", key))
    return ok


def main():
    ok = legacy()
    print()
    functional = 0
    for name in FEATURES:
        problems = feature_problems(name, real_read)
        functional += not problems
        print("%s  %s" % ("OK  " if not problems else "FAIL", name))
        for p in problems:
            print("        " + p)
    ok = ok and functional == len(FEATURES)
    print("\na11y features functional: %d/%d" % (functional, len(FEATURES)))
    if "--mutations" in sys.argv:
        detected, total, missed = mutations()
        print("mutation self-test: %d/%d single removals detected" % (detected, total))
        for m in missed:
            print("  UNDETECTED " + m)
        ok = ok and detected == total
    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
