# -*- coding: utf-8 -*-
"""AF2 for Sessions 26 to 28, one launch row: undo one fix or one handler of the pass per check and see that exactly that check fails. A set runs the closeout group of its session
(s26, s27, s28) or, for the group "attack", the attack simulation; the tool name keeps the number of the pass that wrote it.

usage: python tools/qa_sim/s26_mutations.py run [--tag s26] [--audio]   applies each set, runs the s26 closeout group through proof_run --launch (one chain), restores the files byte for byte, judges;
                                                                          --audio adds the windowed audio truth gate on the unmutated tree as the last step of the same chain
       python tools/qa_sim/s26_mutations.py judge LOG0 LOG1    re-judges the two saved runs (no engine)
       python tools/qa_sim/s26_mutations.py apply N | restore  only the two halves, for a chain that runs the group itself (the tree must be clean before `apply`)
       python tools/qa_sim/s26_mutations.py --demo
A mutation is a one-line change that puts back what a fix changed or switches off what a handler does. The run is judged against two sets: every check named by a mutation of the set
must FAIL, and every other check must be ok. Two sets, because two mutations of the same function hide each other: ACHRUN1 (the marks stay) and ACHRUN2 (the counters go) both live in
reset_run_marks and need their own run. DAILY2 and DAILY3 hide each other the same way in the daily manager: with the selector's walk-past
switched off no two days share a template, so DAILY3's mutation only shows with the selector intact (launch 10 read it ok in one set with DAILY2's, CORRECTION_LOG 280); it runs with ACHRUN2. Together with the green run of the same group on the unmutated tree (check.sh --all) that is the both-ways proof of AF2.
"""
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
BAK = pathlib.Path(tempfile.gettempdir()) / "tls_s26_mutations"
ACH = "scripts/systems/achievements_manager.gd"
MARKS = 'if String(key).begins_with("seen_") or String(key).begins_with("hurt_"):'
# (file, old text, new text, the check that must fail), one list per run
SETS = [
    [
        (ACH, '_check_unlock(&"ach_01", true)', "pass", "ACHSIG1"),
        (ACH, '_check_unlock(&"ach_02", true)', "pass", "ACHSIG2"),
        (ACH, '_check_unlock(&"ach_03", _all_districts_full())', "pass", "ACHSIG3"),
        (ACH, '_check_unlock(&"ach_05", 50)', '_check_unlock(&"ach_05", 51)', "ACHSIG4"),
        (ACH, '_check_unlock(&"ach_04", _all_docs_collected())', "pass", "ACHSIG5"),
        (ACH, '_check_unlock(&"ach_15", EndingsManager.get_ending() == &"dark")', '_check_unlock(&"ach_15", true)', "ACH15"),
        (ACH, MARKS, "if false:", "ACHRUN1"),
        ("scripts/systems/daily_challenge_manager.gd", 'if not (String(t.get("type", "")) in PER_RUN_TYPES and int(t.get("target", 0)) > DistrictManager.DISTRICTS.size()):', "if true:", "DAILY2"),
        ("default_bus_layout.tres", "bus/1/effect/2/enabled = true", "bus/1/effect/2/enabled = false", "AUD6"),
        ("scripts/core/game_manager.gd", "EventBus.game_over.connect(_on_player_game_over)", "EventBus.player_died.connect(_on_player_game_over)", "ACH15M"),
    ],
    [
        (ACH, MARKS, "if true:", "ACHRUN2"),
        ("scripts/systems/daily_challenge_manager.gd", "elif _progress_day == day and _today_id == _id_for_day(day):", "elif _today_id == _id_for_day(day):", "DAILY3"),
    ],
    [  # Session 27, the closeout group s27: ten files, nothing one mutation changes is read by another's check
        ("scripts/world/street_builder.gd", "const MARK_WIDTH: float = 0.16", "const MARK_WIDTH: float = 4.0", "SOV1"),
        ("scripts/world/skyline.gd", 'float(clampi(int(SettingsManager.get_setting("graphics_tier", 2)), 0, 2))', "2.0", "SOV2"),
        ("scripts/world/district_landmark.gd", "const HALO_SIZE := Vector2(64.0, 52.0)", "const HALO_SIZE := Vector2(110.0, 100.0)", "SOV3"),
        ("scripts/world/dead_grass.gd", "const PER_COURTYARD: Array[int] = [0, 8, 16]", "const PER_COURTYARD: Array[int] = [16, 16, 16]", "SOV5"),
        ("scripts/world/skyline.gd", "const FACADE_GAIN: Array[float] = [0.16, 0.19, 0.22, 0.26]", "const FACADE_GAIN: Array[float] = [0.16, 0.19, 0.22, 0.05]", "SOV6"),
        ("scripts/ui/menu_fog.gd", "visible = int(SettingsManager.get_setting(\"graphics_tier\", 2)) > 0", "visible = true", "SOV7"),
        ("scripts/enemies/boss_3d.gd", "EventBus.boss_phase_changed.emit(3)", "pass", "MUS1"),
        ("scripts/systems/music_manager.gd", '&"police": "res://assets/audio/music/police.ogg",', '&"police": "res://assets/audio/music/police_x.ogg",', "MUS2"),
        ("data/i18n/en.json", '"CREDITS_MUSIC": "Music (partly AI, Google Lyria) and SFX: TLS Team"', '"CREDITS_MUSIC": "Music and SFX: TLS Team"', "CRED1"),
        ("scripts/systems/music_manager.gd", "func _on_game_started() -> void:\n\t_leave_boss()\n", "func _on_game_started() -> void:\n\tpass\n", "MUS3"),
        ("scripts/systems/music_manager.gd", "func _on_district_entered(district_id: StringName) -> void:\n\t_leave_boss()\n", "func _on_district_entered(district_id: StringName) -> void:\n\tpass\n", "MUS4"),
        ("scripts/ui/main_menu.gd", "\t_refresh_daily_card(vb as VBoxContainer)", "\tpass", "MENU2"),
    ],
    [  # Session 27, the closeout group s27 again: the verifier's round found two sign words cut off. SOV4's mutation (one more word) also fails SOV8's check (the run of Session 28 read a widest word of 183 px and 0 long words drawn smaller), so in set 2 it read "SOV8 failed without a mutation" (v10 R5); the two sit together here and both must fail; they mutate different functions, and SOV8's check against its own mutation alone is the line of the run of Session 27
        ("scripts/world/soviet_signs.gd", "found.assign(WORDS.get(district_id, WORDS[&\"suburbs\"]))", "found.assign(WORDS.get(district_id, WORDS[&\"suburbs\"]) + [\"\\u13a0\"])", "SOV4"),
        ("scripts/world/soviet_signs.gd", "return mini(FONT_PX, int(FONT_PX * ATLAS_W / (wide * 1.06)))", "return FONT_PX", "SOV8"),
    ],
    [  # Session 28, the closeout group s28 (D1): each fix of the difficulty pass undone in its own function or table row, so no mutation can hide another
        ("scripts/enemies/base_monster.gd", "\t\t_telegraph.warn(_deal_damage)\n", "\t\t_deal_damage()\n", "TEL1"),
        ("scripts/enemies/crawler_3d.gd", "\t\t\t\t_telegraph.cue()\n", "\t\t\t\tpass\n", "TEL2"),
        ("scripts/enemies/boss_3d.gd", "this phase never read\n\t\t\t_telegraph.warn(_perform_melee)\n", "this phase never read\n\t\t\t_perform_melee()\n", "TEL3"),
        ("scripts/components/visibility_enabler.gd", "@export var wake_m: float = 10.0", "@export var wake_m: float = 0.0", "WAKE1"),
        ("scripts/enemies/boss_3d.gd", "\t\t\t\tattack_timer = attack_cooldown * 0.5\n\t\t\t\t_telegraph.warn(_perform_melee)\n", "\t\t\t\tattack_timer = attack_cooldown * 0.5\n\t\t\t\t_perform_melee()\n", "BAT0"),
        ("scripts/pickups/item_pickup_3d.gd", "\tif not inventory.try_add(item_id, amount):\n", "\tif false:\n", "PICK1"),
        ("scripts/core/save_system.gd", "no position, a load takes the spawn.\n\treturn []\n", "no position, a load takes the spawn.\n\treturn [0.0, 0.0, 0.0]\n", "SAVE1"),
        ("scripts/world/lamp_details.gd", "_cones.visible = strength > 0.0", "_cones.visible = true", "V1A"),
        ("scripts/world/window_halos.gd", "const RENDER_PRIORITY: int = 5", "const RENDER_PRIORITY: int = 0", "V1B"),
        ("scripts/effects/vfx_burst.gd", "m.billboard_keep_scale = true", "m.billboard_keep_scale = false", "BURST1"),
        ("scripts/effects/dust_motes.gd", "quad_mat.billboard_keep_scale = true", "quad_mat.billboard_keep_scale = false", "MOTE1"),
        ("scripts/systems/endings_manager.gd", "\"color\": Color(0.62, 0.45, 0.70)", "\"color\": Color(0.2, 0.1, 0.2)", "ENDC1"),
        ("scripts/world/story_props.gd", "const MAX_SCENES: int = 3", "const MAX_SCENES: int = 0", "STORY1"),
        ("scripts/systems/music_manager.gd", "turn * 0.618034", "turn * 0.0", "MUS5"),
        ("scripts/systems/music_manager.gd", "\t_layer_target[\"threat_high\"] = smoothstep(0.45, 0.85, _threat)\n", "\t_layer_target[\"threat_high\"] = 0.0\n", "MUS6"),
        ("scripts/enemies/boss_3d.gd", "\tbeam.tree_exited.connect(ring.queue_free)\n", "\tring.queue_free()\n", "TEL4"),
        ("scripts/enemies/boss_3d.gd", "\t_telegraph.cue()\n\tvar beam := FallingBeam.new(BEAM_DAMAGE)\n", "\tvar beam := FallingBeam.new(BEAM_DAMAGE)\n", "TEL5"),
        ("scripts/enemies/boss_3d.gd", "const BEAM_FALL_SPEED: float = 14.0", "const BEAM_FALL_SPEED: float = 20.0", "TEL6"),
        ("scripts/enemies/enemy_roster_data.gd", '"speed": 2.8, "attack_range": 6.0, "detect_range": 8.0,', '"speed": 2.8, "attack_range": 18.0, "detect_range": 8.0,', "TEL7"),
        ("scripts/systems/settings_manager.gd", '"damage_cap": [1.0, 1.0, 1.25],', '"damage_cap": [1.0, 1.0, 1.0],', "DIF1"),
        ("scripts/systems/settings_manager.gd", '"monster_hp": [0.7, 1.0, 1.3],', '"monster_hp": [0.7, 1.0, 1.0],', "DIF2"),
        ("scripts/player/player_3d.gd", " * NewGamePlus.get_enemy_damage_multiplier()) / SettingsManager.difficulty_scale(\"player_hp\")", ") / SettingsManager.difficulty_scale(\"player_hp\")", "DIF3"),
        ("scripts/enemies/enemy_pool.gd", "\tVector3(8.0, 0.0, 8.0),\n", "\tVector3(-12.0, 0.0, -10.0),\n", "ESC1"),
        ("scripts/core/game_manager.gd", "const RESPAWN_BATTERY_FLOOR: float = 25.0", "const RESPAWN_BATTERY_FLOOR: float = 0.0", "RET1"),
    ],
    [  # Session 28, the attack simulation (S1): the game code of each fix put back, the case of scripts/tools/rc16/s28_attack_cases.gd must fail
        ("scripts/systems/integrity_guard.gd", "\t\tflag(\"speed\", \"time scale %.2f\" % Engine.time_scale)\n\t\tEngine.time_scale = 1.0\n", "\t\tflag(\"speed\", \"time scale %.2f\" % Engine.time_scale)\n\t\tpass\n", "SPD1"),
        ("scripts/systems/integrity_guard.gd", "\t\tflag(\"vitals\", \"%s %.0f over its maximum %.0f\" % [property_name, number, maximum])\n", "\t\tpass\n", "VIT1"),
        ("scripts/systems/integrity_guard.gd", "\t\tflag(\"economy\", \"wallet %d outside 0..%d\" % [CoinWallet.get_coins(), MAX_COINS])\n", "\t\tpass\n", "ECO1"),
        ("scripts/systems/xp_manager.gd", "\t_level = clampi(int(data.get(\"level\", 1)), 1, MAX_LEVEL)\n", "\t_level = clampi(int(data.get(\"level\", 1)), 1, 9999)\n", "SAV2"),
        ("scripts/systems/daily_challenge_manager.gd", "\tif SaveSystem.daily_counted_today():\n\t\t_save_state()\n", "\tif false:\n\t\t_save_state()\n", "DLY4"),
        ("scripts/economy/rewards_manager.gd", "\tif not CoinWallet.add_once(\"ach_\" + String(achievement_id), amount):\n\t\treturn\n", "\tCoinWallet.add(amount)\n", "ACH2"),
        ("scripts/systems/settings_manager.gd", "\t_settings[\"difficulty\"] = _difficulty_index(_settings.get(\"difficulty\", 1))\n", "\tpass\n", "CFG1"),
        ("scripts/security/integrity_scan.gd", "if not FileAccess.file_exists(path) or hash_of(path) != String(files[path]):", "if not FileAccess.file_exists(path) or hash_of(path) == String(files[path]):", "OVL1"),
    ],
    [  # Session 28, the attack simulation again: NGB1 shares a function with ECO1 and DLY5 a file with DLY4, so each goes into a run of its own
        ("scripts/systems/integrity_guard.gd", "\tif is_instance_valid(NewGamePlus) and NewGamePlus.enforce_bounds():\n", "\tif false:\n", "NGB1"),
        ("scripts/systems/daily_challenge_manager.gd", "\treturn _completed_today or SaveSystem.daily_counted_today()\n", "\treturn _completed_today\n", "DLY5"),
    ],
    [  # Session 28, the closeout group s28 again (W1): the trigger of a story scene shares a file with STORY1, which would make STORY2 fail under its mutation too
        ("scripts/world/story_props.gd", "\tarea.collision_mask = 1\n", "\tarea.collision_mask = 0\n", "STORY2"),
    ],
    [  # Session 29 (v10 R6 and F19), the closeout group s29: the placeholder close button of the screens put back, and the flicker clock back at 0 (two files, nothing one mutation changes is read by the other's check)
        ("scripts/ui/screens.gd", '"close_btn": close_btn, "title_lbl": title_lbl,', '"close_btn": close_btn if close_btn else Button.new(), "title_lbl": title_lbl,', "LEAK1"),
        ("scripts/world/streetlight_3d.gd", "var _t: float = -1.0\n", "var _t: float = 0.0\n", "LAMP2"),
    ],
    [  # Session 29 (v10 R2), the closeout group s29, the LightLimiter: the cap of eight put up by one, and the hiding of a light of no energy left out (they live in different rows of one function, nothing one changes is read by the other's check)
        ("scripts/systems/light_limiter.gd", "\t\tif i < MAX_VISIBLE:\n", "\t\tif i < MAX_VISIBLE + 1:\n", "LIMIT1"),
        ("scripts/systems/light_limiter.gd", "\t\t\tlit.append(light)\n\t\telse:\n\t\t\t_hide(light)\n", "\t\t\tlit.append(light)\n\t\telse:\n\t\t\tpass\n", "LIMIT2"),
    ],
    [  # Session 29 (v10 R2), the closeout group s29 again: the return of a light that was hidden for want of energy left out, which would hide the second mutation of the set above (the light of no energy would never be hidden, so it would never need to return)
        ("scripts/systems/light_limiter.gd", "\t\t\tif _hidden.erase(light.get_instance_id()):\n\t\t\t\tlight.visible = true\n", "\t\t\tif false:\n\t\t\t\tlight.visible = true\n", "LIMIT3"),
    ],
    [  # Session 29 (v10 M4, M6), the closeout group s29: the music probe, first half: the tense stem's curve, the phase of the boss, the wind stem and the name of the sting of a restored district (four rows of three functions and a file: nothing one changes is read by another's check)
        ("scripts/systems/music_manager.gd", "\t_layer_target[\"threat_low\"] = clampf(1.0 - absf(_threat - 0.4) / 0.4, 0.0, 1.0)\n", "\t_layer_target[\"threat_low\"] = clampf(1.0 - absf(_threat - 0.4) / 0.8, 0.0, 1.0)\n", "LAY1"),
        ("scripts/systems/music_manager.gd", "\t_boss_phase = clampi(phase, 1, BOSS_PHASES.size())\n", "\t_boss_phase = 1\n", "LAY3"),
        ("scripts/systems/music_manager.gd", "\t_layer_target[\"wind\"] = 1.0 if _weather_id == WeatherSystem.Weather.WIND else 0.0\n", "\t_layer_target[\"wind\"] = 1.0 if _weather_id == WeatherSystem.Weather.FOG else 0.0\n", "LAY6"),
        ("scripts/systems/uisfx.gd", "play_ui(\"district_restored_sting\"))", "play_ui(\"district_restored_stingx\"))", "ONE2"),
    ],
    [  # Session 29 (v10 M4, M6), the closeout group s29 again, second half: the fall of the hunted level, the calm delay, the swap of the two players, the death cue and the tick of the XP
        ("scripts/systems/music_manager.gd", "const THREAT_FALL: float = 0.25", "const THREAT_FALL: float = 0.1", "LAY2"),
        ("scripts/systems/music_manager.gd", "const CALM_DELAY: float = 6.0", "const CALM_DELAY: float = 3.0", "LAY4"),
        ("scripts/systems/music_manager.gd", "\tvar next: AudioStreamPlayer = _b if _active == _a else _a\n", "\tvar next: AudioStreamPlayer = _a\n", "LAY5"),
        ("scripts/systems/music_manager.gd", "EventBus.game_over.connect(func() -> void: _play_wow_cue(\"death\"))", "EventBus.game_over.connect(func() -> void: pass)", "ONE3"),
        ("scripts/systems/uisfx.gd", "_play(\"ui_xp_tick\", 1800.0, 0.03))", "_play(\"ui_xp_tickx\", 1800.0, 0.03))", "ONE4"),
    ],
    [  # Session 29 (v10 E1), the closeout group s29: the file of a monster cue and the loop of the wind layer (two files, nothing one changes is read by the other's check)
        ("scripts/enemies/base_monster.gd", "for ext: String in [\".ogg\", \".wav\"]:", "for ext: String in [\".wav\"]:", "SFX1"),
        ("scripts/systems/audio_manager.gd", "\t_wind.stream = _force_loop(WIND_SFX)\n", "\t_wind.stream = WIND_SFX\n", "WIND1"),
    ],
    [  # Session 29 (v10 G-RED2), the closeout group s29: the key of the saves, the manifest scan, the pack's remove and the debug surface (four files, nothing one changes is read by another's check)
        ("scripts/core/save_system.gd", "key[i] = _KEY_A[i] ^ _KEY_B[i]", "key[i] = _KEY_A[i]", "SECV9"),
        ("scripts/security/integrity_scan.gd", "or hash_of(path) != String(files[path])", "or false", "SECV7"),
        ("scripts/inventory/inventory_manager.gd", "if amount <= 0 or not has(item_id, amount):", "if not has(item_id, amount):", "SECV2"),
        ("scripts/systems/integrity_guard.gd", "\t\tif not OS.is_debug_build():\n", "\t\tif OS.is_debug_build():\n\t\t\tCoinWallet.add(999)\n\t\tif not OS.is_debug_build():\n", "SECV8"),
    ],
    [  # Session 29 (v10 G-RED2) again: the string literal of the key, the craft's cap and the language list
        ("scripts/core/save_system.gd", "static func _sign(body: String) -> String:", "const _HMAC_KEY: String = \"TLS-savegame-v1-4f1c9e6b2a8d5f03\"\n\nstatic func _sign(body: String) -> String:", "SECV9L"),
        ("scripts/crafting/workbench_logic.gd", "qty <= 0 or qty > MAX_QTY or", "qty <= 0 or", "SECV2B"),
        ("scripts/i18n/localization_manager.gd", "\tif lang in SUPPORTED:\n", "\tif true:\n", "SECV6"),
        ("scripts/systems/endings_manager.gd", "\t\treturn &\"light\"\n", "\t\treturn &\"hope\"\n", "END5"),
        ("scripts/enemies/base_monster.gd", "if global_position.distance_to(player_ref.global_position) <= attack_range + 0.5:", "if true:", "DODGE1"),
    ],
]
## The closeout group each set runs (CLOSEOUT_ONLY): the sets of Session 26 run `s26`, those of Session 27 `s27`, those of Session 28 `s28`, those of Session 29 `s29`.
GROUP = ["s26", "s26", "s27", "s27", "s28", "attack", "attack", "s28", "s29", "s29", "s29", "s29", "s29", "s29", "s29", "s29"]
LINE = re.compile(r"^\[(?:closeout|attack-sim)\] (ok  |OK  |FAIL) +(\S+)")
## What a group of sets runs and the log it leaves: the closeout groups run `closeout_check`, the group "attack" the attack simulation (Session 28).
RUN = {"attack": ("bash tools/qa_sim/guarded_headless res://scenes/tools/attack_sim_scene.tscn 120", ".qa_logs/attack_sim_scene.log")}


def apply(index):
    BAK.mkdir(parents=True, exist_ok=True)
    for rel, old, new, _ in SETS[index]:
        path = ROOT / rel
        backup = BAK / rel.replace("/", "_")
        if not backup.exists():
            shutil.copy2(path, backup)
        raw = path.read_bytes().decode("utf-8")
        newline = "\r\n" if "\r\n" in raw else "\n"
        text = raw.replace("\r\n", "\n")
        assert text.count(old) == 1, (rel, old[:60], text.count(old))
        path.write_bytes(text.replace(old, new).replace("\n", newline).encode("utf-8"))


def restore():
    for rel in sorted({m[0] for s in SETS for m in s}):
        path = ROOT / rel
        backup = BAK / rel.replace("/", "_")
        if backup.exists():
            shutil.copy2(backup, path)
            assert path.read_bytes() == backup.read_bytes(), rel
    shutil.rmtree(BAK, ignore_errors=True)


def parse(text):
    seen = {}
    for line in text.splitlines():
        m = LINE.match(line)
        if m and re.fullmatch(r"[A-Z][A-Z0-9.]*", m.group(2)):
            seen[m.group(2)] = "FAIL" if (m.group(1) == "FAIL" or seen.get(m.group(2)) == "FAIL") else "ok"
    return seen


def judge(index, text):
    seen = parse(text)
    expected = {m[3] for m in SETS[index]}
    rows, bad = [], 0
    for check in sorted(expected):
        state = seen.get(check, "missing")
        verdict = "BITES" if state == "FAIL" else ("NOT RUN" if state == "missing" else "VACUOUS")
        bad += verdict != "BITES"
        rows.append("set %d %-8s mutated: %s -> %s" % (index, check, state, verdict))
    stray = sorted(c for c, s in seen.items() if s == "FAIL" and c not in expected)
    bad += len(stray)
    done = [ln for ln in text.splitlines() if ln.startswith(("[closeout] DONE", "[attack-sim] DONE"))]
    rows.append("set %d failed without a mutation: %s" % (index, ", ".join(stray) or "nothing"))
    rows.append("set %d run: %s" % (index, done[-1] if done else "no DONE line"))
    return rows, bad


def verdict(texts):
    rows, bad = [], 0
    for i, t in enumerate(texts):
        r, b = judge(i, t)
        rows += r
        bad += b
    rows.append("S26 MUTATIONS verdict=%s mutations=%d bad=%d" % ("PASS" if bad == 0 else "FAIL", sum(len(s) for s in SETS), bad))
    return rows, bad


def run(tag, audio=False):
    dirty = [x for x in subprocess.run(["git", "status", "--porcelain"], cwd=ROOT, capture_output=True, text=True).stdout.splitlines() if not x.startswith("??")]
    if dirty:
        raise SystemExit("the tree has modified tracked files, commit first: %s" % dirty[:3])
    run_id = "%s_mutations" % tag
    steps = []
    for i in range(len(SETS)):
        cmd, log = RUN.get(GROUP[i], ("CLOSEOUT_ONLY=%s bash tools/qa_sim/closeout_check 400" % GROUP[i], ".qa_logs/closeout_check.log"))
        steps.append("python tools/qa_sim/s26_mutations.py apply %d; bash tools/qa_sim/guarded_headless res://scenes/tools/compile_gate_scene.tscn 120; "
                     "%s; cp %s .qa_logs/%s_set%d.log; python tools/qa_sim/s26_mutations.py restore" % (i, cmd, log, run_id, i))
    if audio:
        steps.append("bash tools/qa_sim/guarded_windowed res://scenes/tools/audio_truth_gate_scene.tscn 120")
    attach = []
    for i in range(len(SETS)):
        attach += ["--attach", ".qa_logs/%s_set%d.log" % (run_id, i)]
    if audio:
        attach += ["--attach", ".qa_logs/audio_truth_gate_scene.log"]
    try:
        subprocess.run(["bash", "tools/qa_sim/proof_run", "--launch"] + attach + [run_id, "--", "bash", "-c", "; ".join(steps)], cwd=ROOT)
    finally:
        restore()
    texts = [(ROOT / ".qa_logs" / "proofs" / ("%s.attach.%s_set%d.log" % (run_id, run_id, i))).read_text(encoding="utf-8", errors="replace") for i in range(len(SETS))]
    rows, bad = verdict(texts)
    out = "\n".join(rows)
    print(out)
    (ROOT / "docs" / "artifacts" / "rc16" / ("%s_mutations.txt" % tag)).write_text(out + "\n", encoding="utf-8", newline="\n")
    return 1 if bad else 0


def demo():
    for i, s in enumerate(SETS):
        sample = "\n".join(["[closeout] ok   %s x" % m[3] for m in s])
        rows, bad = judge(i, sample)
        assert bad == len(s), "a run in which every mutated check is still ok is vacuous"
        broken = sample.replace("[closeout] ok   %s x" % s[0][3], "[closeout] FAIL %s x" % s[0][3]) + "\n[closeout] FAIL STRAY y"
        rows, bad = judge(i, broken)
        assert bad == len(s) - 1 + 1 and any("STRAY" in r for r in rows)
        rows, bad = judge(i, sample.replace("[closeout] ok   %s x" % s[0][3], ""))
        assert bad == len(s) and any("NOT RUN" in r for r in rows), "a check that never ran is not a check that bites"
    ids = [m[3] for s in SETS for m in s]
    assert len(set(ids)) == len(ids), "one mutation per check"
    print("s26_mutations demo: a vacuous check, a biting check and a stray failure are told apart")
    return 0


if __name__ == "__main__":
    args = sys.argv[1:]
    if "--demo" in args:
        sys.exit(demo())
    if args and args[0] == "judge":
        rows, bad = verdict([pathlib.Path(p).read_text(encoding="utf-8", errors="replace") for p in args[1:]])
        print("\n".join(rows))
        sys.exit(1 if bad else 0)
    if args and args[0] == "apply":
        apply(int(args[1]))
        print("s26_mutations: apply %s done (%d mutations)" % (args[1], len(SETS[int(args[1])])))
        sys.exit(0)
    if args and args[0] == "restore":
        restore()
        print("s26_mutations: restore done")
        sys.exit(0)
    if args and args[0] == "run":
        sys.exit(run(args[args.index("--tag") + 1] if "--tag" in args else "s26", "--audio" in args))
    sys.exit("usage: s26_mutations.py run [--tag s26] [--audio] | apply N | restore | judge LOG0 LOG1 | --demo")
