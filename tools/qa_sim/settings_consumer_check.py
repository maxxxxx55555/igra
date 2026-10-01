#!/usr/bin/env python3
"""Settings-consumer gate (rc15, CORRECTION_LOG 59).

Every control on the Settings screen must change something. Five of them stored a value and nothing read it
(Auto-save, Button Size, Crouch Input, Dodge Gesture, mouse Sensitivity) and VSync only applied on the next launch.
The table below names, for each key the screen writes, the file and the text that proves a reader or an applier.
Fails when the screen gains a key with no row, or when a row's proof is gone from its file.

Run: python tools/qa_sim/settings_consumer_check.py        (--demo: self-check on synthetic text)
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCREEN = "scripts/ui/settings_screen.gd"
MANAGER = "scripts/systems/settings_manager.gd"

# key -> (file, text that proves the value is read or applied)
CONSUMERS = {
    "difficulty": ("scripts/enemies/base_monster.gd", 'get_setting("difficulty"'),
    "autosave": ("scripts/core/save_system.gd", 'get_setting("autosave"'),
    "hints": ("scripts/ui/hud_3d.gd", 'get_setting("hints"'),
    "hardcore": ("scripts/core/game_manager.gd", 'get_setting("hardcore"'),
    "objective_markers": ("scripts/ui/quest_tracker_hud.gd", 'get_setting("objective_markers"'),
    "trailer_mode": ("scripts/systems/wow_director.gd", '_setting("trailer_mode"'),
    "share_enabled": ("scripts/ui/win_screen.gd", 'get_setting("share_enabled"'),
    "language": (MANAGER, "_apply_locale(lang)"),
    "sensitivity": ("scripts/player/player_3d.gd", 'get_setting("sensitivity"'),
    "deadzone": (MANAGER, "action_set_deadzone"),
    "crouch_input": ("scripts/player/player_3d.gd", 'get_setting("crouch_input"'),
    "hud_opacity": ("scripts/ui/hud_3d.gd", 'get_setting("hud_opacity"'),
    "button_size": ("scripts/ui/hud_3d.gd", 'get_setting("button_size"'),
    "touch_tuning_preset": (MANAGER, "TOUCH_TUNING_PRESETS"),
    "touch_sensitivity": ("scripts/player/player_3d.gd", "get_touch_sensitivity()"),
    "haptics": ("scripts/ui/virtual_joystick.gd", "haptics_enabled()"),
    "invert_look": ("scripts/player/player_3d.gd", "is_look_inverted()"),
    "graphics_tier": ("scripts/systems/quality_manager.gd", 'get_setting("graphics_tier"'),
    "resolution": (MANAGER, "win.size = RESOLUTIONS[idx]"),
    "render_scale": (MANAGER, "vp.scaling_3d_scale"),
    "vsync": (MANAGER, '"vsync": _apply_vsync()'),
    "fps_cap": (MANAGER, "Engine.max_fps = FPS_STEPS[idx]"),
    "shadows": (MANAGER, "positional_shadow_atlas_size"),
    "textures": (MANAGER, "texture_mipmap_bias"),
    "effects": (MANAGER, "env.ssao_enabled"),
    "draw_distance": (MANAGER, "cam.far = "),
    "master": (MANAGER, "_apply(b)"),
    "music": (MANAGER, "_apply(b)"),
    "sfx": (MANAGER, "_apply(b)"),
    "voice": (MANAGER, "_apply(b)"),
    "ambient": (MANAGER, "_apply(b)"),
    "colorblind": (MANAGER, '"colorblind": _apply_colorblind()'),
    "text_size": (MANAGER, "content_scale_factor"),
    "high_contrast": (MANAGER, "adjustment_contrast"),
    "arachnophobia": ("scripts/i18n/localization_manager.gd", 'get_setting("arachnophobia"'),
    "auto_aim": ("scripts/weapons/weapon_base.gd", 'get_setting("auto_aim"'),
    "reduce_screen_shake": ("scripts/effects/screen_shake.gd", 'get_setting("reduce_screen_shake"'),
    "reduce_flash": ("scripts/effects/damage_indicator.gd", 'get_setting("reduce_flash"'),
    "reduce_time_fx": ("scripts/systems/wow_director.gd", '_setting("reduce_time_fx"'),
    "reduce_ui_motion": ("scripts/ui/toast_manager.gd", 'get_setting("reduce_ui_motion"'),
}
KEY = re.compile(r'\b_(?:toggle|slider|dropdown)\(parent,[^\n]*?\),\s*"([a-z_]+)"')


def screen_keys(text: str) -> set:
    return set(KEY.findall(text))


def check(keys: set, table: dict, read) -> list:
    errors = []
    for key in sorted(keys - set(table)):
        errors.append("Settings screen writes '%s' but the table names no reader" % key)
    for key in sorted(keys & set(table)):
        path, needle = table[key]
        if needle not in read(path):
            errors.append("'%s': %s no longer contains %r" % (key, path, needle))
    return errors


def demo() -> int:
    table = {"a": ("x.gd", "reads a")}
    files = {"x.gd": "func f(): reads a"}
    assert check({"a"}, table, files.get) == []
    assert len(check({"a", "b"}, table, files.get)) == 1, "an unlisted key must fail"
    assert len(check({"a"}, table, {"x.gd": "nothing"}.get)) == 1, "a vanished reader must fail"
    assert screen_keys('_toggle(parent, LocalizationManager.t("Hints"), "hints")') == {"hints"}
    print("settings_consumer_check demo: ok")
    return 0


def main() -> int:
    if "--demo" in sys.argv:
        return demo()
    keys = screen_keys((ROOT / SCREEN).read_text(encoding="utf-8"))
    errors = check(keys, CONSUMERS, lambda p: (ROOT / p).read_text(encoding="utf-8"))
    for e in errors:
        print("FAIL", e)
    print("settings_consumer_check: %d keys, %d problem(s)" % (len(keys), len(errors)))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
