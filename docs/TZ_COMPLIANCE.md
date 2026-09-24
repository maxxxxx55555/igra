# TZ compliance — live ledger (C4 TZ-CLOSE)

Source: `docs/TZ_COMPLIANCE_AUDIT.md` (static read, 2026-09-21). This file tracks what C4 actually
changed, commit by commit. `docs/TZ_DECISIONS.md` holds the DR reasoning for every non-obvious row.
Verdict legend matches the audit: MET / GAP-DEV / GAP-OWNER / BY-DESIGN / EXTRA, plus this pass's
own DEFERRED-STRUCTURAL (a real gap, correctly out of a mechanical-fix scope this pass).

| ID | Quote (short) | Verdict now | Evidence | Commit |
|---|---|---|---|---|
| A02 | Crossfade 2.0s | MET | `music_manager.gd` `FADE_TIME = 2.0` | `fa5fee4` |
| V02 | No neon/#fff | MET | boss energy-ball + wow_director explosion off pure magenta/white onto ember `#b4452f` | `fa5fee4` |
| V05 | Moon shadow 2048² | MET | `project.godot` `directional_shadow/size=2048`, `.mobile` override 1024 | `fa5fee4` |
| G02 | Headbob 0.1, sprint | MET | `camera_follow_3d.gd` `set_running()`, gated by `reduce_ui_motion` | `fa5fee4` |
| G03 | Sprint FOV +5° | MET | `camera_follow_3d.gd` `_tick_fps()` | `fa5fee4` |
| C06 | Graphics fog/particles 50-150% | MET (fog) / DEFERRED-STRUCTURAL (particles) | `settings_manager.gd` `GRAPHICS_TIERS` `fog_mult`/`particle_ratio` | `f738e99` |
| G17 | Hardcore deletes save on death | MET | `game_manager.gd` `trigger_death()` calls `SaveSystem.wipe_all_saves()` | `f738e99` |
| E03/T02 | Watch +100 / skip -100, 1h cooldown | MET (mechanism) / DR-5 (no modal UI exists) | `ad_service.gd` `COOLDOWN_SEC=3600`, `skip_bonus_coins()`, `coin_wallet.gd` `spend_clamped()` | `f738e99` |
| C04 | Arachnophobia renames Crawler | MET | `localization_manager.gd` `_display_monster_id()`, `MONSTER_CRAWLER_ARACHNOPHOBIA` (13 locales) | `f738e99` |
| S03 | Ember-vignette noise pulse, not a number | MET | `hud_3d.gd` `_process_noise_vignette()`, gated by `reduce_flash` | pending |
| C03 | Auto-aim | MET | `weapon_base.gd` `_apply_auto_aim()`, off by default | pending |
| V03 | Bebas Neue Bold | GAP-OWNER | no Bold font file in `assets/fonts/` | `docs/TZ_DECISIONS.md` |
| G01 | FPS canon / TPS optional | BY-DESIGN (already true) | `fps_mode=true` on the main-scene camera | `docs/TZ_DECISIONS.md` |
| D02 | District unlock graph | BY-DESIGN (already true) | every `powered_by` parent precedes it in D01's order | `docs/TZ_DECISIONS.md` |
| A04 | Audio size caps | MET (re-scored) | ambience/ folder holds A02's 5 music layers, not SFX | `docs/TZ_DECISIONS.md` |
| A03 | Footstep surface x speed | NOT RE-SCORED | `footstep_check_scene.tscn` exists; needs an engine run (C5) | — |
| G28/D04 | Win condition boss requirement | GAP-OWNER (recorded) | §12.3/§6.3 win over §4's line; code already matches the more specific sentence | `docs/TZ_DECISIONS.md` |
| N01 | NG+ carryover rule | GAP-OWNER | GDD:652 is a status checkbox, not a spec | `docs/TZ_DECISIONS.md` |
| I02 | "198 keys" census | GAP-OWNER | stale number; project has 1291 keys x 13 locales legitimately | `docs/TZ_DECISIONS.md` |
| T01 | Signed AAB | GAP-OWNER | keystore/device, owner-only | `docs/TZ_DECISIONS.md` |

## Still open (not yet reached this pass)

GAP-DEV, no DR applied yet: G04, G06, G07, G08, G09, G10, G12b, G13, G15 (capsule + attack box),
G16, G18, G19, G20, G21, G22, G24, G25, G26, G27, G29(BY-DESIGN, trivial), G30(MET already),
G31-G34, D03/V01, S01, S02, S04, A01, A03(re-score pending engine run), V01.

Grouped per `docs/EXEC_PLAN.md` §3 T1 (battery) / T2 (movement) / T3 (combat/noise) / T4 (stealth) /
T5 (flow) / T6 (roster/boss) / T7 (endings) / T8 (content/UI) — each needs its own IRON RULE bot
run before commit, not yet started this session past T0.
