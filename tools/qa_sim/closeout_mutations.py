"""Synthetic mutations that undo one rc15 fix each, so the closeout's checks for it must fail (the proof that a check bites).

usage: python tools/qa_sim/closeout_mutations.py apply     (breaks the sources, keeps a copy of each file in the temp dir)
       CLOSEOUT_ONLY=combat tools/qa_sim/closeout_check 300   (runs only the rc15 checks; expect "fails=<one per mutated check>")
       python tools/qa_sim/closeout_mutations.py restore   (puts every file back byte for byte)
Output of the sign-off run: docs/artifacts/rc15/closeout_mutation_signoff.txt
"""
import pathlib
import shutil
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
BAK = pathlib.Path(tempfile.gettempdir()) / "tls_closeout_mutations"

MUTATIONS = [
    ("scripts/player/player_3d.gd", "const MELEE_MASK: int = 1 | 2\n", "const MELEE_MASK: int = 1\n"),
    ("scripts/player/player_3d.gd", "\tif _iframes > 0.0 or GameManager.is_win() or hp <= 0.0:  # a dead player is not killed a second time (deaths were counted per hit)\n", "\tif _iframes > 0.0 or GameManager.is_win():\n"),
    ("scripts/enemies/crawler_3d.gd", "\t\tState.IDLE, State.INVESTIGATE:\n\t\t\tsuper._tick_ai(delta)\n", ""),
    ("scripts/ui/tutorial_system.gd", "\telif _waiting_for_action and step[\"trigger\"] == \"action\" and _real_input_done(String(step[\"action\"])):\n\t\t_check_action(String(step[\"action\"]))\n", ""),
    ("scripts/ui/tutorial_system.gd", "\tif step[\"id\"] == \"flashlight\" and player != null and bool(player.get(\"flashlight_enabled\")):\n\t\t_completed_steps.append(step[\"id\"])\n\t\t_current_step += 1\n\t\t_show_step()\n\t\treturn\n", ""),
    ("scripts/player/player_3d.gd", "\t\t\tInputService.request_dodge(dir_2d)\n\t\t\t_tap_age = 99.0\n", "\t\t\t_handle_dodge(dir_2d)\n\t\t\t_tap_age = 99.0\n"),
    ("scripts/world/street_builder.gd", "const MARKING_LIFT: float = 0.02\n", "const MARKING_LIFT: float = 0.0\n"),
    ("scripts/ui/theme_provider.gd", "const SCROLLBAR_MARGIN: float = 5.0\n", "const SCROLLBAR_MARGIN: float = 0.0\n"),
    ("scripts/ui/win_screen.gd", "\tvar endings := get_node_or_null(\"/root/EndingsManager\")\n\tif endings != null:\n\t\tendings.ending_reached.connect(func(_id: StringName) -> void: _refresh())\n", ""),
    ("scripts/ui/tutorial_system.gd", "\tEventBus.district_stage_changed.connect(_on_district_stage_changed)\n", ""),
    ("scripts/ui/help_ui.gd", "{\"action\": \"run\", \"label\": \"HUD_SPRINT\"", "{\"action\": \"sprint\", \"label\": \"HUD_SPRINT\""),
    ("scripts/ui/help_ui.gd", "\"label\": \"PROMPT_INTERACT\"", "\"label\": \"PROMPT_REPAIR\""),
    ("scripts/world_env_setup.gd", "const MOON_SHADOW_MIN: float = 0.2\n", "const MOON_SHADOW_MIN: float = 0.0\n"),
    ("scripts/ui/settings_screen.gd", "[LocalizationManager.t(tier[0]), tier[1]])", "[String(tier[0]).trim_prefix(\"opt_\").capitalize(), tier[1]])"),
    ("scripts/player/player_3d.gd", "{ \"windup\": 0.25, \"active\": 0.15, \"recovery\": 0.15, \"dmg\": 8, ", "{ \"windup\": 0.25, \"active\": 0.15, \"recovery\": 0.15, \"dmg\": 14, "),
    ("scenes/ui/hud_3d.tscn",
     "anchors_preset = 7\nanchor_left = 0.5\nanchor_top = 1.0\nanchor_right = 0.5\nanchor_bottom = 1.0\noffset_left = -192.0\noffset_top = -64.0\noffset_right = 192.0\noffset_bottom = -16.0\ngrow_horizontal = 2\ngrow_vertical = 0\n",
     "anchors_preset = 6\nanchor_top = 1.0\nanchor_bottom = 1.0\noffset_left = -192.0\noffset_top = -64.0\noffset_right = 192.0\noffset_bottom = -16.0\ngrow_vertical = 0\n"),
]


def apply() -> None:
    BAK.mkdir(parents=True, exist_ok=True)
    for rel, old, new in MUTATIONS:
        p = ROOT / rel
        b = BAK / rel.replace("/", "_")
        if not b.exists():
            shutil.copy2(p, b)
        raw = p.read_bytes().decode("utf-8")
        nl = "\r\n" if "\r\n" in raw else "\n"
        s = raw.replace("\r\n", "\n")
        assert s.count(old) == 1, (rel, old[:50], s.count(old))
        p.write_bytes(s.replace(old, new).replace("\n", nl).encode("utf-8"))
    print("applied", len(MUTATIONS), "mutations to", len({m[0] for m in MUTATIONS}), "files")


def restore() -> None:
    for rel in sorted({m[0] for m in MUTATIONS}):
        p = ROOT / rel
        b = BAK / rel.replace("/", "_")
        if not b.exists():
            continue
        shutil.copy2(b, p)
        assert p.read_bytes() == b.read_bytes(), rel
    shutil.rmtree(BAK, ignore_errors=True)
    print("restored every backed-up file")


if __name__ == "__main__":
    {"apply": apply, "restore": restore}[sys.argv[1]]()
