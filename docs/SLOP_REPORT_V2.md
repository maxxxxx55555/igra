# Slop report v2: sweep at `ce782f8`

Fix table for Local to apply. The cloud pass applied none of it. The old report
(`docs/SLOP_REPORT.md`, closed at base `c73cf7c`) is not repeated here.

**Method.** Two passes, both static:
- **Diff read.** Every shipped script changed in `c73cf7c..ce782f8`: 52 files, 1661 insertions,
  with `scripts/tools`, `scripts/security` and `tools/` counted separately.
- **Whole-tree sweep** of `scripts/**` outside `scripts/tools`. Grep for `print(`, commented-out code,
  TODO/FIXME/HACK/XXX, BOM and single-use identifiers. Then a reference scan: every `.gd` whose
  `res://` path or `class_name` appears in no shipped scene, script, `project.godot` or data file,
  after also checking format-string and concatenated `load()` calls.

**Clean at HEAD:** 0 TODO/FIXME/HACK/XXX, 0 commented-out code, 0 BOM in shipped scripts.

**Removal rule** (CLAUDE.md: never delete a file unless it is dead *and* not a planned feature):
QUARANTINE means `git mv` under `_QUARANTINE/` (export-excluded, `export_presets.cfg:3`). Then run the
compile gate, `boot_check` and the suite. Delete only after a release with no regression.

## A. New code since the old report

| # | Where | Slop | Minimal fix |
|---|---|---|---|
| A1 | `scripts/systems/footstep_system.gd:176-204` | `demo()` and `check_surface_speeds()` are QA helpers with 3 `print`s, shipped in the game. The only caller is `scripts/tools/_footstep_check.gd:12-13` | Move both functions into `_footstep_check.gd`, taking the FootstepSystem node as a parameter; they only read `_streams`, `_step_sample()` and `_step_pitch()` |
| A2 | `ui/toast_manager.gd:99`, `ui/quest_tracker_hud.gd:19`, `ui/hud_3d.gd:637`, `weapons/weapon_base.gd:146`, `systems/wow_director.gd:64`, `systems/uisfx.gd:97`, `core/camera_follow_3d.gd:79` (every frame), `i18n/localization_manager.gd:169` | 8 copies of `get_node_or_null("/root/SettingsManager")` + `has_method("get_setting")` around an autoload that always exists | Call `SettingsManager.get_setting(...)` directly, as `player_3d.gd:1141` already does |
| A3 | `systems/new_game_plus.gd:209,245`, `systems/flashlight_upgrade_manager.gd:139,160`, `systems/achievements_manager.gd:199,217`, `systems/daily_challenge_manager.gd:185,196` | The same `{"hmac": SaveSystem.call("_sign", body), "data_json": body}` write and verify, copy-pasted 4 times, each calling a private method by string | Add public `SaveSystem.write_signed(path, data) -> bool` and `read_signed(path) -> Variant` next to `_sign` (`save_system.gd:23`) and replace the 8 sites. Keep achievements' legacy branch as is |
| A4 | `ui/hud_3d.gd:640` | `get_first_node_in_group("player")` on every frame in `_process_noise_vignette` | Cache the player in a member and re-fetch only when `not is_instance_valid()` |
| A5 | `systems/settings_manager.gd:434-439` | `_particle_ratio()` runs `load()` plus a dictionary lookup for every GPUParticles3D that enters the tree | Keep the ratio in a member, set in `_ready` and `set_graphics_tier` |
| A6 | `player/player_3d.gd:247` | `apply_flashlight_upgrades(fl_up._levels)` reads another autoload's private field | `fl_up.to_dict()`, added in `b8b20c0` for exactly this |
| A7 | `enemies/base_monster.gd:684,690`; `ui/hud_3d.gd:643,944` | Magic numbers in new code: hit-flash emission 2.0 and restore delay 0.1; vignette pulse rate `0.006`; map button position `(16, 216)` | Named consts next to `_HIT_FLASH_COLOR` and `_VIGNETTE_EMBER` |
| A8 | `core/qa_launch_guard.gd:55,70` | `print` in a shipped autoload | Low. It runs only in debug builds since `a6f4fdb`; use `print_verbose` if the "no shipped prints" rule is read strictly |

## B. Dead code in live files

| # | Where | Slop | Minimal fix |
|---|---|---|---|
| B1 | `player/player_3d.gd:91`, `:103`, `:648-650` | `DEBUG_FLASHLIGHT = true` and `_battery_log_timer` only reset a timer; the log line they guarded is gone | Delete the const, the var and the 3 lines |
| B2 | `player/player_3d.gd:32` | `detection_state` is declared and never read or written | Delete |
| B3 | `ui/theme_provider.gd:20`, `:24` | `COLOR_STAMINA` and `FONT_SIZE_HUGE` are unused (the stamina colour stays canon in the bible) | Delete |
| B4 | `ui/touch_calibration_overlay.gd:16` | `_dot_labels` is unused | Delete |
| B5 | `world_env_setup.gd:161-163` | The comment says "tier 3/Ultra reuses 'high'"; line 170 and C06 contradict it | Change it to "each tier has its own preset" |
| B6 | `assets/config/visual_quality.tres:9-12` | 21 of 52 tier keys are read by no shipped script: `ash_amount, asphalt_reflection, asphalt_wetness, auto_exposure, bg_mode, contact_shadows, dust_amount, env_preset, exposure_multiplier, fog_cards, fog_height_density, foliage_sway, hum_sync, lamp_flicker, menu_parallax, moon_bias_mult, particle_fixed_fps, rain_amount, ssr_enabled, strobe_amount, ui_transitions`. `ssil_enabled` and `volumetric_fog_enabled` are applied (`world_env_setup.gd:186-187`) but do nothing on `gl_compatibility` (godot-docs renderers table) | Delete the unread keys and the two no-op toggles. Switching desktop to Forward+ is a design call, not slop |
| B7 | `player/player_3d.gd:89` (`CROUCH_VISIBILITY_MULT`), `enemies/shadow_3d.gd:6` (`TELEPORT_RANGE`) | Unused | **Keep:** G07 visibility is DEFERRED-STRUCTURAL; the Shadow teleport is GDD canon (`GDD.md:190`, `:368`) and not built |
| B8 | `economy/coin_wallet.gd` `spend_clamped`, `monetization/ad_service.gd:105-116` `skip_bonus_coins` | No caller | **Keep:** the TZ E03/T02 mechanism is MET-STATIC and its trigger is BY-DESIGN-ABSENT |

## C. Config and export

| # | Where | Slop | Minimal fix |
|---|---|---|---|
| C1 | `project.godot:67` `ShotTool="*res://scripts/tools/shot_tool.gd"` | The script is export-excluded (`scripts/tools/**`, `export_presets.cfg:3`), so every release boot logs "Failed to instantiate an autoload". Nothing shipped uses it | Remove the autoload line. In `QaLaunchGuard._enter_tree` (debug builds only), when a `--shot` arg is present, add `load("res://scripts/tools/shot_tool.gd").new()` named `ShotTool` under `/root` |
| C2 | `project.godot:302` `scaling_3d/fsr_upscale=true` | Not a Godot setting; FSR needs Forward+ and Compatibility uses bilinear | Delete the line |
| C3 | `export_presets.cfg:39` `texture_format/etc2_astc=true` | The Android exporter reads the project setting, not this key | Enable `rendering/textures/vram_compression/import_etc2_astc` (see `docs/RELEASE_RUNBOOK.md` step 1) |

## D. Doc correction this sweep implies

| # | Where | Now | Should say |
|---|---|---|---|
| D1 | `docs/ARENA_CLOSURE.md:93` (Design P4) | "Closed `f9bbfd7`" | "No-op: `f9bbfd7` edits `scripts/audio/proc_audio.gd`, which nothing instantiates (S6 below). The live audio layers keep their documented pause policy (`audio_manager`, `music_manager` and `streetlight_hum_pool` are `PROCESS_MODE_ALWAYS` by design; footsteps stop with the player)." Add a CORRECTION_LOG row. The old SLOP item 8 (`53353d5`) also polished this dead file. `docs/CLOUD_AUDIT.md` counted P4 CONFIRMED from line presence; its addendum corrects that |

## S. Shipped scripts nothing references (64)

No shipped scene, script, autoload, preload or data file names these paths or class names.
QUARANTINE = dead and superseded; KEEP-PLANNED = a deferred GDD feature (leave alone);
UNCERTAIN = not placed or wired and not in the TZ ledger, so the owner decides; MOVE = a QA or dev
tool in a shipped folder.

| # | File (lines) | Verdict | Why |
|---|---|---|---|
| S1 | `scripts/ai/action_node.gd` (17) | QUARANTINE | behavior-tree framework; monsters run the `base_monster.gd` state machine |
| S2 | `scripts/ai/behavior_tree.gd` (30) | QUARANTINE | same |
| S3 | `scripts/ai/condition_node.gd` (21) | QUARANTINE | same |
| S4 | `scripts/ai/selector_node.gd` (9) | QUARANTINE | same |
| S5 | `scripts/ai/sequence_node.gd` (9) | QUARANTINE | same |
| S6 | `scripts/audio/proc_audio.gd` (300) | QUARANTINE | never instanced (not autoloaded, in no scene); live audio is `music_manager`, `streetlight_hum_pool`, `footstep_system`. ARENA Design P4 (`f9bbfd7`) and SLOP item 8 (`53353d5`) edited this dead file, see row D1 |
| S7 | `scripts/audio_atmosphere.gd` (112) | QUARANTINE | superseded by `audio_manager.gd`/`music_manager.gd` |
| S8 | `scripts/battery_bar.gd` (16) | QUARANTINE | 2D-era HUD; battery lives in `hud_3d.gd` |
| S9 | `scripts/components/attack_component.gd` (27) | QUARANTINE | 2D-era component; combat lives in `player_3d.gd` |
| S10 | `scripts/components/attack_component_3d.gd` (4) | QUARANTINE | its own header says "UNUSED ... do not instance" |
| S11 | `scripts/components/health_component.gd` (23) | QUARANTINE | 2D-era component |
| S12 | `scripts/components/procedural_anim.gd` (86) | QUARANTINE | no AnimationPlayer user |
| S13 | `scripts/core/audio_system.gd` (15) | QUARANTINE | superseded by the audio autoloads |
| S14 | `scripts/core/progression_system.gd` (23) | QUARANTINE | superseded by XpManager/SkillTreeManager |
| S15 | `scripts/core/transition_manager.gd` (46) | QUARANTINE | superseded by the FadeTransition autoload |
| S16 | `scripts/crafting/crafting_manager.gd` (47) | QUARANTINE | superseded by `ui/workbench.gd` + `item_database.gd` recipes |
| S17 | `scripts/cutscenes/cutscene_manager.gd` (60) | UNCERTAIN (owner) | no cutscene path exists; decide if endings get cutscenes |
| S18 | `scripts/effects/ambient_particles.gd` (24) | QUARANTINE | no emitter uses it |
| S19 | `scripts/effects/footstep_dust.gd` (30) | QUARANTINE | header cites `player_fps.gd`, which does not exist |
| S20 | `scripts/effects/hit_spark.gd` (33) | QUARANTINE | hits use `scenes/vfx/vfx_hit_spark.tscn` (`base_monster.gd:736`) |
| S21 | `scripts/effects/muzzle_flash.gd` (42) | KEEP-PLANNED | gun VFX: G25 weapons DEFERRED-STRUCTURAL |
| S22 | `scripts/effects/recoil.gd` (28) | KEEP-PLANNED | gun feel: G25 |
| S23 | `scripts/electronic_door.gd` (72) | UNCERTAIN (owner) | door/puzzle content never placed |
| S24 | `scripts/emergency_lamp.gd` (29) | UNCERTAIN (owner) | light prop never placed |
| S25 | `scripts/enemies/minion.gd` (134) | UNCERTAIN (owner) | not spawned by `boss_3d.gd`; decide if the boss summons |
| S26 | `scripts/environment/world_env.gd` (39) | QUARANTINE | superseded by `world_env_setup.gd` |
| S27 | `scripts/fuse_box.gd` (63) | UNCERTAIN (owner) | power-puzzle prop never placed |
| S28 | `scripts/gameplay/hiding_spot.gd` (99) | KEEP-PLANNED | S04-hide DEFERRED-STRUCTURAL (CLAUDE.md lesson: do not delete) |
| S29 | `scripts/hiding/hiding_spot.gd` (35) | UNCERTAIN (owner) | older duplicate of the planned hiding spot; merge when S04-hide is built |
| S30 | `scripts/i18n/localized_button.gd` (35) | QUARANTINE | UI calls `LocalizationManager.t()` directly |
| S31 | `scripts/i18n/localized_label.gd` (24) | QUARANTINE | same |
| S32 | `scripts/inspectable.gd` (38) | UNCERTAIN (owner) | examine interaction never placed |
| S33 | `scripts/player/death_sequence.gd` (36) | QUARANTINE | death runs through GameManager + `death_screen.gd` |
| S34 | `scripts/searchlight.gd` (23) | UNCERTAIN (owner) | prop never placed |
| S35 | `scripts/security/attack_sim.gd` (557) | MOVE | QA gate outside `scripts/tools/`; already export-excluded (`scripts/security/**`), move to `scripts/tools/` for one convention |
| S36 | `scripts/stress_test.gd` (16) | MOVE | dev tool in the shipped root: move to `scripts/tools/` or delete |
| S37 | `scripts/system/particle_manager.gd` (18) | QUARANTINE | dead, and builds paths by string concatenation |
| S38 | `scripts/systems/difficulty_manager.gd` (34) | QUARANTINE | difficulty lives in `scenes/ui/difficulty_screen.tscn` + settings |
| S39 | `scripts/systems/enemy_health_bar.gd` (39) | QUARANTINE | enemy HP bar lives in `hud_3d.gd` |
| S40 | `scripts/systems/global_managers.gd` (20) | QUARANTINE | empty global-reference holder |
| S41 | `scripts/systems/leaderboard.gd` (34) | QUARANTINE | superseded by `local_leaderboard.gd` (AL50) |
| S42 | `scripts/systems/loot_drop.gd` (28) | UNCERTAIN (owner) | enemy drops never wired; loot comes from `DistrictLoot` |
| S43 | `scripts/systems/save_slot_manager.gd` (54) | KEEP-PLANNED | G22 save-slot UI, GAP-OWNER (DR-6) |
| S44 | `scripts/systems/vibration.gd` (13) | UNCERTAIN (owner) | mobile haptics never wired |
| S45 | `scripts/systems/wave_manager.gd` (145) | QUARANTINE | no wave mode exists |
| S46 | `scripts/systems/weapon_mod_manager.gd` (27) | KEEP-PLANNED | G25 weapons |
| S47 | `scripts/ui/character_screen.gd` (281) | UNCERTAIN (owner) | 5-slot equipment screen not in UIManager |
| S48 | `scripts/ui/controls.gd` (24) | QUARANTINE | 2D-era controls screen; controls live in settings/help |
| S49 | `scripts/ui/hud_panel.gd` (29) | QUARANTINE | 2D-era HUD panel |
| S50 | `scripts/ui/inventory_ui.gd` (58) | QUARANTINE | no inventory screen in UIManager |
| S51 | `scripts/ui/micro_interactions.gd` (29) | QUARANTINE | never attached |
| S52 | `scripts/ui/onboarding.gd` (68) | QUARANTINE | superseded by `tutorial_system.gd` |
| S53 | `scripts/ui/splash.gd` (24) | QUARANTINE | duplicate of the live `scripts/splash.gd` |
| S54 | `scripts/ui/subtitle_manager.gd` (49) | UNCERTAIN (owner) | subtitles never wired |
| S55 | `scripts/ui/ui_theme.gd` (63) | QUARANTINE | superseded by `theme_provider.gd` |
| S56 | `scripts/ui/victory_screen.gd` (50) | QUARANTINE | superseded by `win_screen.gd` (UIManager `&"win"`) |
| S57 | `scripts/ui/world_map.gd` (18) | QUARANTINE | superseded by `city_map.gd` (UIManager `&"city_map"`) |
| S58 | `scripts/visual/moon_disc.gd` (22) | QUARANTINE | superseded by `world_env_setup.gd` night sky |
| S59 | `scripts/visual/night_env.gd` (24) | QUARANTINE | same |
| S60 | `scripts/world/city_decorator.gd` (56) | QUARANTINE | superseded by `street_builder`/`street_props` |
| S61 | `scripts/world/district_layouts.gd` (46) | QUARANTINE | same |
| S62 | `scripts/world/ftue_generator.gd` (24) | QUARANTINE | 2D-era (Area2D) |
| S63 | `scripts/world/ftue_generator_3d.gd` (29) | QUARANTINE | never placed; the tutorial is `tutorial_system.gd` |
| S64 | `scripts/world/interior_zone.gd` (47) | UNCERTAIN (owner) | interiors never placed |

Verdict counts: {'QUARANTINE': 44, 'UNCERTAIN (owner)': 13, 'KEEP-PLANNED': 5, 'MOVE': 2}

## F. Scenes (verify-only)

76 `.tscn` files outside `scenes/tools/` have no exact `res://` reference, but most are loaded
indirectly, so this list is **not** a delete list:
- The 10 district scenes load through a format string (`scripts/world/district_scene_factory.gd:13`).
- The 12 `scenes/secrets/secret_room_*.tscn` are documented as empty (`scripts/world/secret.gd:9`).
- The `scenes/ui/*.tscn` screens are 2D-era twins of screens UIManager now builds from scripts
  (`scripts/ui/ui_manager.gd:6-22`).
- Weapons and pickups belong to G25 (planned).
- `vfx_rain`, `vfx_dust` and `vfx_strobe` are never instanced; the strobe belongs to the G21
  blueprints (planned).

Rule for Local: no scene leaves the tree without one Godot pass (compile gate, `boot_check`, suite).

## Order to apply

1. B1–B5, A6, C2: one-line deletions, no behaviour change.
2. A1, A4, A5, A7, B6: local refactors.
3. A2, A3: mechanical multi-file edits. Run `attack_sim` after A3 (it covers every signed file).
4. C1: the release-boot error; check an export boot log after it.
5. S (QUARANTINE rows): one commit, then compile gate, `boot_check` and the suite.
6. D1: docs.
