# Cleanup manifest: Session 26 (`v9.0.0-universe`)

The manifest comes first and the sweep follows it: every file or function the pass touched has a row in `docs/artifacts/rc16/cleanup_manifest_s26.tsv` (1040 rows) with a
verdict and the evidence for it. Baseline `041ce03` (`v8.1.0-premium.1`). The rule of `CLAUDE.md` holds throughout: a file or function goes only when it is dead *and* not a
planned feature; a planned feature is one a document that is not a log of what was done names, or an owner row.

## 1. What the sweep did

| Step | Result |
|---|---|
| C1 assets (918 tracked under `assets/`) | 515 KEEP-LIVE, 36 KEEP-QA, 367 KEEP-PLANNED, **0 deleted**: the tool's 86 AUTO-DELETE rows each sit in a directory a planning or hand-off document names (section 2) |
| C2 scripts reached by nothing (19 of 255) | 2 quarantined (`behavior_node.gd`, `weight_bar.gd`), 17 kept with a citation (section 3); `_QUARANTINE/scripts/world/ftue_generator.gd` deleted |
| C3 functions never named anywhere (86 candidates, one more after the first round) | **58 deleted** (234 function lines), 26 kept with a citation, 3 moved whole with their file; 3 members that only the deleted functions read went too (section 4) |
| C4 documents named by no other file (25) | 11 moved to `docs/_archive/` with `docs/_archive/PROVENANCE.md`, 14 stay with the reason below (section 6) |
| C5 sidecars of a source that is gone | 118 ignored `.import`/`.uid` files deleted (119,633 bytes, copied first); tracked: none; `android/build/` left alone |
| C6 `.gitignore` | 5 tool-cache patterns added; `tools/qa_sim/gitignore_check.py` holds 2 more must-ignore paths (31 / 8 / 0 faults); no tracked file is matched by a rule |

Freed: 1 tracked script, 118 ignored sidecars, 234 + 9 lines of code; **0.12 MB**. The size of the bundle does not move: no shipped asset was deleted and the quarantine is outside the export.

## 2. Assets

`python -I` over `assets/` with the two patterns of `docs/SIZE_BUDGET.md` (a path, a basename) plus the format strings and prefixes the runtime builds paths with. Result: KEEP-LIVE 515 (74.6 MB), KEEP-QA 36 (4.3 MB), KEEP-PLANNED 367 (51.2 MB). The tool flagged 86 files AUTO-DELETE and 1 UNCERTAIN; the table gives the directory-level citation under which each stays.

| Directory (files the tool flagged) | Citation | What the document says |
|---|---|---|
| `assets/store/storyboard/` (10) | `docs/ASSET_PROMPT_PACK.md:406` | listed with the store directories of the hand-off |
| `assets/store/v2/itch/` (3) | `docs/RELEASE_FINAL.md:135` | the itch page files |
| `assets/store/v2/storyboard/` (10) | `docs/REPORT_STORE_V2.md:53` | the trailer frames (T5) |
| `assets/textures/picto_v2/` (13) | `docs/BUGS_FOR_CLAUDE.md:19` | the pictograms, a wiring row |
| `assets/textures/items/` (7) | `docs/ASSET_MANIFEST.md:14` | the item icons, referenced by path from `data/items/*.tres` |
| `assets/textures/tiles/` (6) | `docs/ASSET_LICENSES.md:15` | the lit tiles of the districts |
| `assets/textures/ui/` (16) | `docs/ASSET_HANDOFF.md:10` | the UI hand-off list |
| `assets/textures/ui_v2/` (16) | `docs/REPORT_UI_V2.md:3` | delivered additive, "no code/scene/data touched" |
| `assets/textures/icons_v2/` (1) | `docs/REPORT_ICONS_V2.md:7` | the line-art icons |
| `assets/ui/ui_*.svg` (3) | `RELEASE_NOTES.md:48` | the HUD icon set |
| `assets/env/night_environment_desktop.tres` (1) | `docs/ASSET_SHOPPING_LIST.md:50` | the night environment; the loader builds the name from `night_environment_` (`docs/VISUAL_PASS.md:168`) |
| `assets/models/kenney/README.txt` (1) | - | the owner's instruction to fetch the Kenney packs; no document names the path (UNCERTAIN in the tool) |

Why no deletion: a delivered image that no scene loads yet is the art half of a wiring row, and the rule keeps it. The 86 are 4.1 MB of which 63 files ship; `docs/SIZE_BUDGET.md` already holds the arithmetic for what the bundle could shed, and each of those rows is an owner decision.

## 3. Scripts reached by nothing in the runtime

The scan (`docs/artifacts/rc16/proofs/s26_c2_orphans.out` prints its own source): a script no scene or resource attaches by path or uid, no script names by its `class_name` as a type, and no runtime file names by file name. 19 of 255 shipped scripts.

| Script | Verdict | Evidence | Action |
|---|---|---|---|
| `scripts/ai/behavior_node.gd` | QUARANTINE | base class of the behavior-tree framework quarantined at docs/SLOP_REPORT_V2.md:69-73; no scene, script or resource reaches it | git mv to _QUARANTINE/scripts/ai/behavior_node.gd; its line left scripts/tools/validate_list.txt |
| `scripts/weight_bar.gd` | QUARANTINE | no scene attaches it and no script uses WeightBar as a type (the HUD's `$WeightBar` is a TextureProgressBar node with no script, scenes/ui/hud_3d.tscn:445); docs/HUD_PLAN.md:69 keeps the node | git mv to _QUARANTINE/scripts/weight_bar.gd; its line left scripts/tools/validate_list.txt |
| `scripts/core/save_data.gd` | KEEP-PLANNED | docs/GDD.md:256 names `SaveData extends Resource` as the save format; docs/GDD_CONFORMANCE.md:27 holds it as PARTIAL | none |
| `scripts/cutscenes/cutscene_manager.gd` | KEEP-PLANNED | owner row docs/SLOP_REPORT_V2.md:85 | none |
| `scripts/effects/muzzle_flash.gd` | KEEP-PLANNED | docs/SLOP_REPORT_V2.md:89 (G25 weapons) | none |
| `scripts/effects/recoil.gd` | KEEP-PLANNED | docs/SLOP_REPORT_V2.md:90 (G25 weapons) | none |
| `scripts/electronic_door.gd` | KEEP-PLANNED | owner row docs/SLOP_REPORT_V2.md:91 | none |
| `scripts/emergency_lamp.gd` | KEEP-PLANNED | owner row docs/SLOP_REPORT_V2.md:92 | none |
| `scripts/enemies/minion.gd` | KEEP-PLANNED | owner row docs/SLOP_REPORT_V2.md:93 | none |
| `scripts/fuse_box.gd` | KEEP-PLANNED | owner row docs/SLOP_REPORT_V2.md:95 | none |
| `scripts/inspectable.gd` | KEEP-PLANNED | owner row docs/SLOP_REPORT_V2.md:100 | none |
| `scripts/searchlight.gd` | KEEP-PLANNED | owner row docs/SLOP_REPORT_V2.md:102 | none |
| `scripts/systems/loot_drop.gd` | KEEP-PLANNED | owner row docs/SLOP_REPORT_V2.md:110 | none |
| `scripts/systems/save_slot_manager.gd` | KEEP-PLANNED | docs/SLOP_REPORT_V2.md:111 (G22 save-slot UI) | none |
| `scripts/systems/vibration.gd` | KEEP-PLANNED | owner row docs/SLOP_REPORT_V2.md:112 | none |
| `scripts/systems/weapon_mod_manager.gd` | KEEP-PLANNED | docs/SLOP_REPORT_V2.md:114 (G25 weapons) | none |
| `scripts/transformer.gd` | KEEP-PLANNED | docs/ART_PROMPTS.md:93 holds the transformer-box prop art; the same family as scripts/fuse_box.gd (docs/SLOP_REPORT_V2.md:95) | none |
| `scripts/ui/panel_card.gd` | KEEP-PLANNED | docs/ROAD_TO_POLISH.md:68-70 (B3: the eight key screens adopt PanelCard) | none |
| `scripts/world/interior_zone.gd` | KEEP-PLANNED | owner row docs/SLOP_REPORT_V2.md:132 | none |
| `_QUARANTINE/scripts/world/ftue_generator.gd` | DELETE | quarantined at `docs/SLOP_REPORT_V2.md:130` as a 2D-era Area2D; the path and the name occur only in logs and in a historical list (`docs/SESSION_REPORT_UX.md:23`); its `set_ftue_objective` has no caller | `git rm` |

## 4. Functions

Candidates: a function of a shipped script (outside `scripts/tools`) whose name occurs nowhere else in a `.gd`, `.tscn`, `.tres`, `.cfg`, `.json`, `.godot` or `.gdshader` file (86, engine virtuals excluded), and in no document or tool that is not a log of what was done. Each body was read. No runtime call builds a method name from a string (the `.call(` sites hold `Callable` variables). A function stays when its file is an owner or planned row, its subsystem is a documented surface, or it is the lifecycle pair of a live function.

### 4.1 Deleted (58 functions, 234 lines; lines are of `041ce03`; `is_move_blocked` is the second round: its one caller was the removed self-test line)

| File | Functions (line at `041ce03`) |
|---|---|
| `scripts/core/game_manager.gd` | `add_kill`@23, `unlock_level`@87, `reset_run`@91 |
| `scripts/core/input_service.gd` | `is_interact_just_pressed`@119 |
| `scripts/core/quest_manager.gd` | `is_completed`@215, `all_completed`@219, `can_progress`@227, `get_active_count`@230, `get_completed_count`@236 |
| `scripts/core/save_system.gd` | `set_quest_data`@518, `get_quest_data`@521, `get_all_slots_info`@689 |
| `scripts/document_pickup.gd` | `set_document`@99 |
| `scripts/enemies/base_monster.gd` | `_state_name`@816 |
| `scripts/enemies/crawler_3d.gd` | `_on_light_tick`@96 |
| `scripts/enemies/enemy_roster_data.gd` | `behavior_name`@164, `status_name`@172 |
| `scripts/events/event_bus.gd` | `emit_coin`@25, `emit_lives`@28 |
| `scripts/i18n/localization_manager.gd` | `cycle_language`@179 |
| `scripts/lighting/light_grid.gd` | `flashlight_dirs`@106, `nearest_flashlight`@114 |
| `scripts/player/flashlight.gd` | `get_flashlight_enabled`@37, `is_point_lit`@39 |
| `scripts/player/player_3d.gd` | `get_cone_code`@237, `_is_touch_device`@418, `is_move_blocked`@749, `_move_selftest`@752, `get_strobe_cooldown_ratio`@1039, `set_battery_params`@1156 |
| `scripts/systems/audio_manager.gd` | `play_music`@263, `set_action_active`@273, `set_action_stream`@276 |
| `scripts/systems/captions_manager.gd` | `get_moments`@64, `is_seen`@67 |
| `scripts/systems/day_night.gd` | `get_hour`@30 |
| `scripts/systems/endings_manager.gd` | `get_all_endings`@141 |
| `scripts/systems/footstep_system.gd` | `register_surface`@202 |
| `scripts/systems/music_manager.gd` | `stop_music`@275 |
| `scripts/systems/photo_mode.gd` | `cycle_filter`@47 |
| `scripts/systems/progress_tracker.gd` | `found_secret_ids`@174 |
| `scripts/systems/settings_manager.gd` | `get_languages`@167, `apply_game`@202, `apply_controls`@238 |
| `scripts/systems/xp_manager.gd` | `get_xp_to_next`@89, `get_xp_progress`@92 |
| `scripts/ui/photo_album.gd` | `_get_collected`@48 |
| `scripts/ui/screen_flow_manager.gd` | `get_state_name`@314, `is_overlay`@317, `is_gameplay_state`@320 |
| `scripts/ui/screens.gd` | `get_screen_names`@1063 |
| `scripts/ui/stats_screen.gd` | `_get_persist`@67 |
| `scripts/ui/theme_provider.gd` | `draw_section_frame`@168 |
| `scripts/world/district_scene_factory.gd` | `district_id_at`@78 |
| `scripts/world/district_themes.gd` | `list_ids`@60, `set_current`@63, `color_of`@67 |
| `scripts/world/puzzle_system.gd` | `get_total_count`@99 |

One deletion is a judgment, not a fact: `SaveSystem.get_all_slots_info` (`core/save_system.gd`@689, an 8-line loop over `get_slot_info`) went although the slot screen it would serve (`scripts/systems/save_slot_manager.gd`, kept as planned at `docs/SLOP_REPORT_V2.md:111`) stays planned. No document names the function, `get_slot_info` stays, `git show 041ce03:scripts/core/save_system.gd` holds the loop, and nothing read it; whether a helper of a planned screen falls under the rule "not a planned feature" is the owner's to overrule, by `git show` and a paste.

### 4.2 Members that only the deleted code read (3 edits, 9 lines)

| File (lines at `041ce03`) | Member | Why |
|---|---|---|
| `scripts/core/input_service.gd`@33,60,145 | `_interact_pressed` | only `is_interact_just_pressed` read it |
| `scripts/player/player_3d.gd`@38,195 | `_cone_shader_code` | only `get_cone_code` read it; `var code`@194 stays: two later lines read it (CORRECTION_LOG 275) |
| `scripts/player/player_3d.gd`@39,291,292,293 | `move_selftest_vel, selftest_vel, blocked` | a velocity computed at every spawn and never read; `is_move_blocked()` result unused |

### 4.3 Kept (26 functions)

| File (line at `041ce03`) | Function | Why | Citation |
|---|---|---|---|
| `scripts/cutscenes/cutscene_manager.gd`@10 | `play_cutscene` | owner row: no cutscene path exists, the owner decides whether endings get cutscenes | docs/SLOP_REPORT_V2.md:85 |
| `scripts/electronic_door.gd`@24 | `set_power` | owner row: the prop was never placed | docs/SLOP_REPORT_V2.md:91 and :95 |
| `scripts/fuse_box.gd`@47 | `remove_fuse` | owner row: the prop was never placed | docs/SLOP_REPORT_V2.md:91 and :95 |
| `scripts/gameplay/hiding_spot.gd`@101 | `is_occupied` | hiding_spot is the file the repository rule was written for | CLAUDE.md:16, README.md:126 |
| `scripts/hiding/hiding_spot.gd`@31 | `get_detection_multiplier` | hiding_spot is the file the repository rule was written for | CLAUDE.md:16, README.md:126 |
| `scripts/hiding/hiding_spot.gd`@34 | `get_hide_duration` | hiding_spot is the file the repository rule was written for | CLAUDE.md:16, README.md:126 |
| `scripts/lighting/light_grid.gd`@40 | `unregister_light` | the lifecycle pair of `register_light` (`scripts/lighting/light_grid.gd:28`) | docs/GDD.md:423 |
| `scripts/monetization/ad_service.gd`@151 | `interstitial_cooldown_left` | AdService and its stub are the wired monetization surface (the SDK key is an owner row) | PLAN.md:1073, README.md:41, RELEASE_CHECKLIST.md:121 |
| `scripts/monetization/stub_crazy_games.gd`@31 | `was_initialized` | AdService and its stub are the wired monetization surface (the SDK key is an owner row) | PLAN.md:1073, README.md:41, RELEASE_CHECKLIST.md:121 |
| `scripts/multiplayer/lan_discovery.gd`@85 | `get_found_hosts` | LAN co-op is a shipped feature of two autoloads (needs two peers to test) | docs/FUNCTION_MATRIX.md:36 and :72, RELEASE_CHECKLIST.md:204 |
| `scripts/net/lan_network.gd`@51 | `is_client` | LAN co-op is a shipped feature of two autoloads (needs two peers to test) | docs/FUNCTION_MATRIX.md:36 and :72, RELEASE_CHECKLIST.md:204 |
| `scripts/net/lan_network.gd`@52 | `is_online` | LAN co-op is a shipped feature of two autoloads (needs two peers to test) | docs/FUNCTION_MATRIX.md:36 and :72, RELEASE_CHECKLIST.md:204 |
| `scripts/net/lan_network.gd`@94 | `broadcast_player_state` | LAN co-op is a shipped feature of two autoloads (needs two peers to test) | docs/FUNCTION_MATRIX.md:36 and :72, RELEASE_CHECKLIST.md:204 |
| `scripts/net/lan_network.gd`@99 | `broadcast_power` | LAN co-op is a shipped feature of two autoloads (needs two peers to test) | docs/FUNCTION_MATRIX.md:36 and :72, RELEASE_CHECKLIST.md:204 |
| `scripts/systems/loot_drop.gd`@6 | `drop_loot` | owner row: enemy drops never wired, loot comes from DistrictLoot | docs/SLOP_REPORT_V2.md:110 |
| `scripts/systems/play_integrity_service.gd`@27 | `request_integrity_token` | the integration point of the Play Integrity SDK (a documented stub) | docs/PRIVACY_AUDIT.md:25, docs/FUNCTION_MATRIX.md:87 |
| `scripts/systems/save_slot_manager.gd`@10 | `save_to_slot` | KEEP-PLANNED: G22 save-slot UI | docs/SLOP_REPORT_V2.md:111 |
| `scripts/systems/settings_manager.gd`@436 | `set_dyslexia_font` | the font file is an owner row | docs/A11Y_PLAN.md:14, docs/DECISIONS_PENDING.md:44 |
| `scripts/systems/settings_manager.gd`@477 | `set_auto_aim` | auto-aim is a plan row of the execution plan | docs/EXEC_PLAN.md:97, docs/GAP_TO_IDEAL.md:107 |
| `scripts/systems/vibration.gd`@13 | `explode` | owner row: mobile haptics never wired | docs/SLOP_REPORT_V2.md:112 |
| `scripts/systems/weapon_mod_manager.gd`@14 | `equip_mod` | KEEP-PLANNED: G25 weapons | docs/SLOP_REPORT_V2.md:114 |
| `scripts/ui/visual_style.gd`@13 | `make_tile_texture` | the VisualStyle helper is a documented surface (silhouettes, tiles, vignette) | docs/UI_CONSISTENCY.md:46, docs/GDD.md:716 |
| `scripts/ui/visual_style.gd`@54 | `draw_monster` | the VisualStyle helper is a documented surface (silhouettes, tiles, vignette) | docs/UI_CONSISTENCY.md:46, docs/GDD.md:716 |
| `scripts/ui/visual_style.gd`@89 | `draw_vignette` | the VisualStyle helper is a documented surface (silhouettes, tiles, vignette) | docs/UI_CONSISTENCY.md:46, docs/GDD.md:716 |
| `scripts/weapons/weapon_base.gd`@153 | `get_ammo_ratio` | G25 weapons are a planned zone of the agent table | docs/AGENT_ZONES.md:18, docs/SLOP_REPORT_V2.md:114 |
| `scripts/weapons/weapon_base.gd`@159 | `get_reload_progress` | G25 weapons are a planned zone of the agent table | docs/AGENT_ZONES.md:18, docs/SLOP_REPORT_V2.md:114 |

`behavior_node.gd` (2 functions) and `weight_bar.gd` (1) went whole to `_QUARANTINE/` (section 3). Members whose declaration is the only occurrence of their name and that were already unread before this pass (ten `EventBus` signals, `DayNight.start_hour`, `screens.gd` `panel_ready`) are not touched: a signal is a contract. Two of them, `coin_changed` and `lives_changed`, were emitted only by `emit_coin` and `emit_lives`, which no script called at `041ce03` and the sweep deleted, so neither fired before it either; `coin_changed` alone is named as a hook point, by `docs/GEMINI_INTEGRATION_REPORT.md:70`.

## 5. Quarantine and sidecars

- `_QUARANTINE/` held 31 scripts; `ftue_generator.gd` is gone and `behavior_node.gd` and `weight_bar.gd` joined it: 32. The other 30 stay: `tools/quarantine_audit.py` (`--check` passes) rates 73 of its rows UNCERTAIN, owner eyes, and `docs/CLEANUP_LEDGER.md` 12.3 keeps three the planning documents still name.
- 118 ignored sidecars of a source that is no longer there: 104 under `store/screenshots/recipes/`, 6 audio files retired in `39b2254`, 6 font imports in `_QUARANTINE/assets/fonts/`, 1 under `docs/`, 1 `scripts/ui/settings_full.gd.uid`. The editor writes them again when a source returns. The copy is in `..\_BACKUPS\2026-10-16_05-10_s26_cleanup` (124 files: these 118 and the 6 sidecars of the three scripts that were deleted or moved).
- `android/build/` (3,302 ignored files, the Gradle project and its intermediates) was not touched: the next export needs it.

## 6. Documents

`docs/` holds 224 top-level documents. 25 are named by no other tracked text file by file name; 24 of those were last committed before the tag of `v8.0.0-shipping`. 11 moved to `docs/_archive/` (none carries a citation, none is named by stem). Left in place: the seven `CONTENT_DISTRICT_*` specs (the family of the three that `content/districts/*/item_spawns.json` and `PLAN.md` name), `CERT_CONTENTDEPTH.md` and `DESIGN_CRITIQUE.md` (named by stem in `docs/KNOWN_ISSUES.md` and `docs/TZ_DECISIONS.md`), `SESSION_REPORT_FINISH.md`, `SESSION_REPORT_UX.md` and `ERROR_LOG_STOREV2.md` (a proof or a report names them), `ROADMAP.md`, and `A2_checkpoints.md` (committed 2026-10-13).

| Archived | Last commit | Bytes (committed) |
|---|---|---|
| `docs/ERROR_LOG_DEVICESV2.md` | 2026-09-08 | 1531 |
| `docs/ERROR_LOG_PLAY_FINAL.md` | 2026-09-08 | 2943 |
| `docs/REPORT_MARKET_V2.md` | 2026-09-08 | 3392 |
| `docs/REPORT_PLAY_FINAL.md` | 2026-09-08 | 3056 |
| `docs/STAGES_REPORT.md` | 2026-08-13 | 10878 |
| `docs/ROLES.md` | 2026-08-07 | 678 |
| `docs/PACKAGES.md` | 2026-08-07 | 590 |
| `docs/PHASE_2_DESIGN_SPEC.md` | 2026-08-08 | 1675 |
| `docs/PHASE_A_DESIGN_SPEC.md` | 2026-08-08 | 800 |
| `docs/CONTEXT_CACHE.md` | 2026-08-23 | 818 |
| `docs/BLOCK4_PROJECTGODOT_PATCH.md` | 2026-08-09 | 671 |

## 7. The 56 citations that moved

Removing lines moves the lines after them, and `tools/af5_check.py` holds every citation a document added since `e4bb4df` against the code at `HEAD`. 56 citations in 16 documents were moved by the line map of `git diff -U0` (an old line `n` maps to `n` plus the lines the earlier hunks added; a line inside a removed range is reported, not guessed: `docs/BEAUTY_RC16.md:28` cited `player_3d.gd:293`-`:294` at `041ce03`, which were the self-test lines, and now cites the shadow lines `scripts/player/player_3d.gd:286-288`). `docs/ACHIEVEMENT_TRIGGER_SPEC.md` was regenerated by `tools/qa_sim/achievements_sim.py --write`.

## 8. Gates after the sweep (C8)

| Gate | Result | Evidence |
|---|---|---|
| `python tools/lint_changed.py` | 0 findings in 144 `.gd`, 51 `.py`, 20 `.sh`, 3 workflows (20 trailing-whitespace findings of three untouched scripts cleaned first, CORRECTION_LOG 272) | run at every commit |
| `bash tools/check.sh --static` | 63 of 63 | `docs/artifacts/rc16/proofs/s26_static.out` (the last run of the pass) |
| `python tools/af5_check.py` | 0 findings in the citations of the documents added since `e4bb4df` | the same run |
| the engine's compile gate, boot flow, the closeout (483 checks, 0 fails), the GOLD MASTER suite, timing equivalence | green at `6734f9c` (before the verifier's fix) | `s26_final_all_6734f9c` (`docs/PROOFS.md`, S26-FINAL and S26-FINAL2) |
| the 3-seed bot | 3 of 3 won, 0 softlocks | `s26_bot_387cbd9` (S26-BOT) |
| the windowed perf gate | D1 152 draw calls, D11 142, no budget exceeded | `s26_windowed_ccc7669` (S26-PERF) |

**What the rule asked and what was done.** C8 says to revert the whole sweep on any gate failure. The first full battery after the sweep failed (8 gates, launch 1, `s26_all_f6e065f`) on one parse error that
the engine's compile gate named to the line: `var code` in `Player._setup_cone`, one of the three second-order edits of section 4.2. The other 57 deletions and the two other members were not named by any
gate. The line was restored (`8c17153`) and the battery run again, green (launch 2), instead of reverting 58 deletions the log did not implicate; a revert would have cost the same launch. The failure is a row of
the correction log (275): the static gates and the lint pass such an edit, and only the engine's compile gate says whether the project still loads.
