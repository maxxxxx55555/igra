# Round 12, HEAD b8abb2e, tag v8.0.0-rc12

| Source | Item | Verdict | Evidence |
|---|---|---|---|
| ARENA A | Header "17/17 closed; B7's legacy half deferred" | CONFIRMED | 16 rows cover 17 items (B9+B14 share a row). Every ARENA hash exists and is an ancestor of HEAD (`git merge-base --is-ancestor`). "n/m" below = n of the m added non-doc code lines (length >= 4, not comments) of that commit still present in the same file at HEAD (script) |
| ARENA A | B1 `5e1093b` | CONFIRMED | 45/45 |
| ARENA A | B2 `7034bcd` | CONFIRMED | 37/37 |
| ARENA A | B3 `afadb4b` | CONFIRMED | 50/50 |
| ARENA A | B4 `92934a7` + note `ac877a5` | CONFIRMED | 49/49 and 4/4; CORRECTION_LOG #8 cites ac877a5 |
| ARENA A | B5 `fe7ef0e` | CONFIRMED | 68/71; the 3 misses are attack_sim NG+ test-file writes later moved into a helper |
| ARENA A | B6 `e9686d7` | CONFIRMED | 35/35 |
| ARENA A | B7 `bb662b4` + deferred legacy half | CONFIRMED | 21/21. Legacy branch trusts and re-signs a plain achievements.cfg (achievements_manager.gd:206-211); attack_sim.gd:33, :89 locks it; listed in the open defers (ARENA_CLOSURE.md:101) |
| ARENA A | B8 `1cf3aaf` | CONFIRMED | 30/30 |
| ARENA A | B9+B14 `36d44be` | CONFIRMED | 92/92 |
| ARENA A | B10 `cc1e0b3` | CONFIRMED | 54/54 |
| ARENA A | B11 `d7a0692` | CONFIRMED | 26/26 |
| ARENA A | B12 `c814621` | CONFIRMED | 26/26; streetlight_activated only on the STREETS crossing (power_grid.gd:62-66) |
| ARENA A | B13 `a36ac8b` | CONFIRMED | 55/57; misses are the P2m lines rewritten by b8abb2e's retry (check still present) |
| ARENA A | B15 `8c99689` | CONFIRMED | 40/42; misses are the P2p check later rewritten |
| ARENA A | B16 `cb73c83` | CONFIRMED | 18/18 |
| ARENA A | Q1 `a0ec4ee` | CONFIRMED | 38/38 |
| ARENA B | P-01 `92934a7` | CONFIRMED | As B4 |
| ARENA B | P-03 / P-04 / P-06 / P-07 `9b7a46b` | CONFIRMED | 141/141 |
| ARENA B | P-05 tamper `e9686d7` + wall-clock defer | CONFIRMED | Tamper fix present (35/35); wall clock is an inherent client limit, listed (:100) |
| ARENA B | R-01 `2278cf9` | CONFIRMED | 13/13 |
| ARENA B | R-02 defer reason | CONFIRMED | integrity_guard.gd:83 checks only non-finite position and y <= -50; listed (:102) |
| ARENA B | R-08, D-01, D-02 inherent defers | CONFIRMED | Client-side limits; listed (:100) |
| ARENA B | D-03 owner defer | CONFIRMED | release_export_check.py:37-40 fails on a committed encryption_key; PASS in this run's static battery; listed (:101) |
| ARENA B | R-03 / D-04 `60a289b` | CONFIRMED | 41/41 |
| ARENA B | R-07 `cef6ae6` | CONFIRMED | 29/29 |
| ARENA B | C-08 `a453425` | CONFIRMED | 60/60; wired at check.sh:255 |
| ARENA B | Every SECURITY_PATCH_SPEC P1 item has a row | CONFIRMED | P1 or P1/P2 headings (SECURITY_PATCH_SPEC.md:104-407): P-01, P-03..P-07, R-01, R-02, R-08, D-01..D-03, all in the table |
| ARENA C | R0 `bafb740` + figures | CONFIRMED | bafb740 (7/7) flips `importer` to `3d_texture` on the 11 LUT imports; all 11 are 3d_texture at HEAD (pin check.sh:201, PASS). 13% -> 0.01-0.30% is bafb740's recorded A/B. Gate this run: the 12 non-running rc12 frames 0.14-0.46%, G03 0.79%, S03 1.02% |
| ARENA C | RENDERING_DIAGNOSIS (b), (d) | CONFIRMED | bafb740 message records Lossless/S3TC ruled out; ssao/ssil/ssr per tier in visual_quality.tres:9-12 |
| ARENA C | TG gates `5257745`, `4c6ca10` | CONFIRMED | 118/119 and 7/7 |
| ARENA C | CHALLENGE-01 `fe3007a` | CONFIRMED | 20/22; misses are the phase-8 lines reworded by 0d3d533 (X22) |
| ARENA C | CHALLENGE-02 partial `c783544` | CONFIRMED | 10/10; residual is matrix X21 BUG, listed in the open defers |
| ARENA C | CHALLENGE-03 `0f9685a` | CONFIRMED | 0f9685a deletes scripts/ui/settings_full.gd (70 lines); file absent, no code references |
| ARENA C | MISSED-00..05 | CONFIRMED | MISSED-00 is the matrix itself (arena REDTEAM_CHALLENGE.md:131); AL50 / IN89 / AL35 / AL55 / AL57 are WORKS |
| ARENA C | I18N `43c9ecd` / `21c6563` | CONFIRMED | 159/159 value edits still equal at HEAD (JSON script); 21c6563 63/64; truth gate 12/12 this run |
| ARENA D | SLOP 1-15, §2 | CONFIRMED | 855a278 5/5, 1fcf157 3/3, bbdaa8e 11/11, d06fe48 16/16, 53353d5 13/13, 363add0 3/3, 7bbc0ca 1/1 (BLACK_FAIL_PCT 40.0, visual_truth_gate.py:50); 2948e23 holds (0 BTN_ONE_MORE_RUN refs) |
| ARENA D | §3 symptom masks | CONFIRMED | Park "inf" case re-diagnosed in 0d3d533 (83/83); matrix X20 PARTIAL |
| ARENA Design | P1-P8 | CONFIRMED | 2a88503 2/2, c2dbeb4 36/36, 4e7560e 95/96, f9bbfd7 18/18, 24ceb68 36/39 (literal became BATTERY_PER_SKILL_LVL, player_3d.gd:1182-1186), 8f48faf 32/35 (flat-reward lines replaced by the E05 curve in b8abb2e; coin reporting kept), ee273ee 4/4 |
| ARENA | Open-defers list | CONFIRMED | P-05, R-08, D-01, D-02, D-03, B7 legacy half, R-02, X21 = every deferred row |
| ARENA | "No P0 is deferred" | CONFIRMED | R0 is the only P0; no P0 tag in BREAK_REPORT, SECURITY_PATCH_SPEC, SLOP_REPORT, DESIGN_AUDIT_ARENA or the arena docs |
| TZ | Legend covers every verdict | CONFIRMED | 48 ledger rows; every verdict token outside parentheses is one of the 8 legend verdicts (script) |
| TZ | tz_verify "19 checks at rc12" | CONFIRMED | 17 `_check` call sites run per completed run (:242/:246 exclusive), :159 runs 3 times (D03 loop) = 19; restore check gone with _user_data_snapshot.gd |
| TZ | footstep probe exits 1 | CONFIRMED | _footstep_check.gd quits 1 on fails; check_surface_speeds counts a missing or duplicate (sample, pitch) step (footstep_system.gd:190-204) |
| TZ | A02 MET | CONFIRMED | FADE_TIME 2.0 (music_manager.gd:118) used at :209, :262-263; GDD.md:359; tz_verify :91 fails at the old 2.2 |
| TZ | A03 DECIDED (DR-5) | CONFIRMED | SPEED_FILE walk/jog/sprint, volume 0.3/1.0/1.5, pitch 0.9/1.0/1.12 (footstep_system.gd:47-49); asphalt/puddle/glass map to single step_* samples (:15-21); not counted MET |
| TZ | A04 MET-STATIC | CONFIRMED | MiB: sfx 6.33 + one_shots 1.07 + (ambience 45.97 - wav_src 29.94) = 23.4 (ui/jingles/ending_music add 0.6); music 37.2; wav_src and _pre_norm in all 3 exclude_filters (export_presets.cfg:3, :43, :67) |
| TZ | A01 DEFERRED-STRUCTURAL | CONFIRMED | default_bus_layout.tres:15-54 = Master/Music/SFX/Voice/Ambient/UI/Hum |
| TZ | V02 MET | CONFIRMED | Hit flash #c9a24a, original kept in meta and restored (base_monster.gd:663-689); P2b asserts the restore (suite :290-303; the brass colour itself is a code constant, not asserted); boss ball light #c9a24a (boss_3d.gd:293); no Color.WHITE in wow_director.gd |
| TZ | V05 MET | CONFIRMED | project.godot:297 = 2048 and no `.mobile` key; engine `.mobile` default 2048 (godot-docs class_projectsettings.rst:12605); tz_verify :93-95 fails on c46d8a3's 1024 override (project.godot:297 there) |
| TZ | V01 MET-STATIC | CONFIRMED | day_night.gd has no environment writer (31 lines, header :5-6) |
| TZ | D03 MET (GDD.md:107-110) | PARTIAL | Values match GDD 4.2 (world_env_setup.gd:19-27, apply_for_stage :108-136, no scene override) and tz_verify :153-160 fails on the parent's 0.12/0.09. But the cited range is off by one: GDD.md:107 is the table separator, DARK/STREETS/FULL sit on :108/:110/:111, so FULL (0.16/0.40) is outside "107-110" (TZ_COMPLIANCE.md:36; same cite in world_env_setup.gd:17 and _tz_verify_runner.gd:151) |
| TZ | V03 GAP-OWNER | CONFIRMED | assets/fonts has only -Regular files. The tracked _QUARANTINE/assets/fonts/bebas_neue_bold.ttf is Impact by its name table (PIL getname), not Bebas Neue Bold |
| TZ | G01 / G27 / G31-33 / D02 DECIDED (DR-2) | CONFIRMED | fps_mode=true, fov 80 (main_3d.tscn:57, :61); JOY_ZONE_RATIO 0.35 (player_3d.gd:413); _determine_ending hope for any missing docs, survivor only on death (endings_manager.gd:107-125); powered_by graph = TZ_DECISIONS D02 (data/districts/*.tres) |
| TZ | G02 / G03 / G06 MET | CONFIRMED | SPRINT_BOB_AMP 0.1, SPRINT_FOV_BONUS 5 (camera_follow_3d.gd:22-24); run 272 = 170 x 1.6 (player_stats.tres:6-7); checks :124-127 fail without the feature |
| TZ | G04 DECIDED (DR-1) | CONFIRMED | REACH 3.2 (interactor.gd:24); PICKUP_TOUCH tightening is on the REJECTED list (EXEC_PLAN.md:248) |
| TZ | G07 split | CONFIRMED | CROUCH_SPEED_MULT used :563; noise 0.4 x 0.3 (:542); CROUCH_VISIBILITY_MULT (:89) unread; capsule 1.6 |
| TZ | G08 MET / NEEDS-EYES | CONFIRMED | Colour (0.788, 0.635, 0.29) = c9a24a, angle 45, energy 24, range 16 (player_3d.tscn:179-185); runtime angle 45 + bonus (player_3d.gd:1161) |
| TZ | G09 / G10 / G13 DECIDED (DR-3) | CONFIRMED | Drain 100/450 with the recorded failure note (player_3d.gd:92-96); battery.tres effect_value 35; combo 14/21/35 with the note (:75-81); balance_sim: +35 gives 12.8 min, +25 gives 11.25 min < 12.6 |
| TZ | G12b MET | CONFIRMED | Threshold 20, intensity 0.35 (flashlight_stats.tres:11-12); cleared at max level (player_3d.gd:1140, :1164); drain cut :760 with Stability 0.1-0.5 (flashlight_upgrade_manager.gd:42); tz_verify :171, :182; P2r :863-871, :886 |
| TZ | G15 split | CONFIRMED | Capsule 1.6 (player_3d.tscn:9); attack box 1.4x0.8x3.4 (player_3d.gd:311); melee sphere 2.7 (:326) |
| TZ | G16 MET | CONFIRMED | P2r drives respawn_after_death + Routes.restart_game (suite :836-837) = death_screen.gd:53-54; RESPAWN_HP_RATIO 0.5 (game_manager.gd:110) |
| TZ | G17 MET | CONFIRMED | _remove_with_backups (save_system.gd:551-560) on main and every slot (wipe_all_saves :575-579); hardcore path game_manager.gd:172-173; tz_verify seeds .bak/.bak2/.bak3 (:252-260) |
| TZ | G18 / G19 MET-STATIC | CONFIRMED | dog 50/20, sniper 80/12, runner 120/35, armored 200/25, sharpshooter 60/50, brute 350/30, burner 90/15, rotter 140/10, hound 40/18, tvar 1200/40, beast 800/40 (enemy_roster_data.gd) = GDD.md:170-181; Shadow 30/15, vision 0 (shadow_3d.gd:13-20) |
| TZ | G20 MET-STATIC | CONFIRMED | boss_3d.gd:46-50 0.70/0.30, BEAM_DAMAGE 40 (:5); GDD.md:190-192 |
| TZ | G21 / G25 / S04-hide / C03 DEFERRED-STRUCTURAL | CONFIRMED | workbench.gd:14-23 has none of the 5 blueprints; no scene or script instances weapon_manager.gd or a weapon scene (only scripts/tools/_probe_inst.gd); HidingSpot is never spawned; melee sphere 2.7 regardless of facing |
| TZ | G22 GAP-OWNER (DR-6) | CONFIRMED | PLAN.md:1303-1313 "В. План работ", "Этап 1 — decisions needed", "DECIDED: archive" for the save-slot screens |
| TZ | G24 DECIDED (DR-2) | CONFIRMED | district_manager.gd:25-42; P2q asserts both sides (suite :769-781) |
| TZ | G26 DEFERRED-STRUCTURAL (DR-5) | CONFIRMED | photo_mode.gd take_photo() has no caller; album total hard-coded 200 (photo_album.gd:56-57) |
| TZ | GAP-OWNER rows G28/D04, N01, I02, T01 | CONFIRMED | power_grid.gd:84-92 calls trigger_win only without FinaleDirector; GDD.md:652, :22, :669 are what the rows say; 1301 keys in each of the 13 locale files |
| TZ | G34 MET (bunker) / MET-STATIC (lore notes) | CONFIRMED | BUNKER_SECRET_ID (progress_tracker.gd:128); the live win screen uses EndingsManager, whose Truth needs the bunker (endings_manager.gd:117); 22 audio_log + 24 photo notes, all 88 note ids in DistrictLoot.LORE_DOCS, counted by Endings.get_total_documents (endings.gd:15-22); P2q :782-787 |
| TZ | S01 DECIDED (DR-3, measured) | CONFIRMED | No hit/dodge noise branch (player_3d.gd:538-543); bisect recorded in TZ_DECISIONS S01 (added in c00f118) |
| TZ | S02 DEFERRED-STRUCTURAL | CONFIRMED | GDD modifiers absent; only the low_profile sight cut (base_monster.gd:526-534) |
| TZ | S03 MET | CONFIRMED | Shader keeps COLOR.rgb; pulse on the 0-1 noise scale; check needs r > 0.4 and edge warmth +0.03 (:128). Warmth from committed frames: rc2 -0.015 -> 0.065, rc12 -0.015 -> 0.168 (the row quotes the rc2 run's 0.066) |
| TZ | S04 MET-STATIC | CONFIRMED | SEARCH_TIME 10 / SEARCH_RADIUS 5 (base_monster.gd:45-46); P2q (suite :767-768) |
| TZ | E03/T02 split | CONFIRMED | Both cooldowns 3600 (ad_service.gd:27, :31); skip_bonus_coins (:111-116) has no caller; P2q (:765-766); GDD.md:613-616 names no trigger |
| TZ | E05 MET (DR-4) | CONFIRMED | 200 + 100 x DISTRICTS index (rewards_manager.gd:3-8, :20-24); P2q :788-799 fails on the flat 200; balance_sim 11 x 200..1200 = 7700. 3439 is in the local .qa_logs/c8_rc12_coins_s2.log; 3439 + 5500 from the curve = 8939, inside 8718-8975 |
| TZ | C04 MET | CONFIRMED | ru "Слепые псы"; MONSTER_CRAWLER_ARACHNOPHOBIA in all 13 locale files; tz_verify :209 |
| TZ | C06 MET | CONFIRMED | Fog 0.012/0.013/0.014/0.015 and particle_ratio 0.5-1.5 (visual_quality.tres:9-12); fog_setup.gd writes no density; _scale_emitter (settings_manager.gd:441). Fog-at-load check weakness: see Fix b8b20c0 |
| TZ | P01 DEFERRED-STRUCTURAL / P02 NEEDS-MEASUREMENT | CONFIRMED | 246/253 figures consistent across TZ_COMPLIANCE, TZ_DECISIONS, ORDER_PASS and matrix X24; drawcall_estimate PASS (~38 residual) |
| TZ | Footer "Open GAP-DEV rows: 0" | CONFIRMED | All 54 audit GAP-DEV/GAP-OWNER IDs appear in the ledger; audit totals 20/49/5/3 as EXEC_PLAN.md:15 says (script) |
| TZ_DECISIONS | Every non-MET ledger row has a matching row | CONFIRMED | A01, A03, V03, G01, G04, G07, G08, G09, G10, G13/G15, G21, G22, G24, G25, G26, G27, G28/D04, G31-33, S01, S02, S04-hide, D02, E03/T02, C03, P01, P02, N01, I02, T01 |
| TZ_DECISIONS | DR labels vs EXEC_PLAN §2 | CONFIRMED | DR-1 G04 (PICKUP_TOUCH); DR-2 G01/D02/G27/G28/G31-33/G24 (conflict with the all-11-FULL finale); DR-3 G09/G10/G13/G15/S01 with recorded evidence; DR-4 rows change code to the GDD value; DR-5 A03 (samples) and G26 (photo spots); DR-6 V03/G22/N01/I02/T01; DR-7 A04/G18/G19; S03 is a note on a MET row |
| TZ_DECISIONS | S03 note figures | CONFIRMED | Band 260-345 (visual_truth_gate.py:52). Hue-band hits, edge share: rc2 G03 87.3, rc2 S03 97.8, rc4 G03 85.5, rc4 S03 70.1, rc12 G03 98.1, rc12 S03 87.9%; median hue 319-333 |
| TZ_DECISIONS | D03 / V01 DR-4 | CONFIRMED | The old DR-3 cited the 0.01/0.03 rejection (world_env_setup.gd:5-8), not the GDD values; D03 frames 0.24/0.31/0.46%, black 0.00% this run |
| TZ_DECISIONS | E05 DR-4 | CONFIRMED | GDD.md:221 and :229 fix no per-district reward; the change is IRON-RULE-run (ORDER_PASS row 11) |
| TZ_DECISIONS | G22 DR-6, G34 DR-4, S02 reason, V05-mobile DR-4, A03 DR-5 | CONFIRMED | PLAN.md:1313; lore-note counts above; base_monster.gd:526-534; project.godot has no `.mobile` override; missing per-speed samples |
| TZ_DECISIONS | Cited GDD lines and code lines | CONFIRMED | 22, 52-59, 68, 76, 119, 168-181, 221, 229, 261, 317, 341, 359-362, 613-616, 652 hold the quoted text; GDD.md:3-7 only ranks the GDD above its appendices; player_3d.gd:92-95 and :75-77 hold the notes |
| Fix | `0873f38` S03 / G12b / A03 / G17 | CONFIRMED | Parent: shader forced BG_DEEP RGB (edge-warmth check fails); flicker cleared at bonus >= 1.0 with L5 = 0.5 (L5 spread check fails); probe quit(0) unconditionally; wipe removed only .bak (.bak2/.bak3 check fails) |
| Fix | `5402640` upgrades across respawn | CONFIRMED | Parent: energy 1.0 x (1 + b), range 8.0, applied only at purchase, so P2r `maxed` / `want_energy >= 20` fail; HEAD reapplies from the scene base (player_3d.gd:239-247) |
| Fix | `b8b20c0` per-run upgrades, drain, fog, hit flash | PARTIAL | Fixes are real (save key + reset_all clear, drain cut, fog line removed, brass flash with restore). But the fog regression is vacuous at Ultra: the removed fixed value (5cf3b27:scripts/fog_setup.gd:16, 0.015) equals the Ultra preset (visual_quality.tres:12), and tz_verify compares against the profile's own tier (_tz_verify_runner.gd:85-88), so on an Ultra profile the check passes on pre-fix code |
| Fix | `5cf3b27` guard around QA runs | CONFIRMED | Wrapped paths correct at HEAD (check.sh:272-276, headless_suite:25-29, autoplay_bot:21-25). Its lost-snapshot, unchecked-copy and trap-exit holes were closed by 3ee3568/4061f1b/8c0e01c; direct scenes/tools launches are now covered by QaLaunchGuard (remaining gap: see Guard coverage row) |
| Fix | `3ee3568` lost snapshot, in-process snapshot, measured drain | CONFIRMED | Lost snapshot, bash test: 5cf3b27's restore returns 0 and deletes the profile, 3ee3568's returns 1 and keeps it. In-process snapshot superseded by QaLaunchGuard at HEAD. P2r measures drain through _update_battery (suite :863-871) |
| Fix | `4061f1b` abort on failed snapshot | CONFIRMED | HEAD demo on 5cf3b27's and 3ee3568's functions -> "demo FAIL: snapshot succeeded without a dir"; udg_snapshot checks mktemp and cp && cmp (user_data_guard.sh:32, :41) |
| Fix | `8c0e01c` trap exit code, partial cleanup, wrapper | CONFIRMED | HEAD demo on 4061f1b's functions -> "demo FAIL: partial snapshot left in temp"; 8c0e01c's and HEAD's -> demo OK; every EXIT trap is `udg_restore \|\| exit 97` (check.sh:274, headless_suite:27, autoplay_bot:23, guarded_windowed:25) |
| Fix | `9936ab3` tz_verify refuses an unguarded launch | CONFIRMED | Refusal real at 9936ab3 (_tz_verify_runner.gd:71-74 there); superseded by QaLaunchGuard in b8abb2e; wrapper 100755 (100644 at 8c0e01c) |
| Fix | `1430516` windowed probes, V05 mobile 2048, FIXED commits | CONFIRMED | V05 check fails on c46d8a3's size.mobile=1024; perf/audio refusals superseded by QaLaunchGuard, which now covers the capture_stills/boot_check/gameplay_shot/--shot launches round 11 found unguarded |
| Guard | QaLaunchGuard: can it delete or overwrite owner data? | PARTIAL | Yes, on edge paths. (1) restore() trusts any existing .qa_snapshot dir; there is no manifest (qa_launch_guard.gd:81-98), and every unguarded launch incl. normal play runs it (:22-32). A snapshot left partial or empty by a kill or failed delete inside remove_tree after a verified restore (:96-97, :101-108) makes the next launch delete every profile file it does not list and report success. Python port: empty snapshot -> profile emptied; partial -> settings.cfg and saves/slot1.save deleted. user_data_guard.sh refuses this case (:57-61). (2) No lock: two concurrent unguarded QA launches, or an unguarded one then a shell-guarded one, leave QA data in tls_savegame.save and no snapshot (port; the second restore returns -1 while the error says the copy is kept). (3) On snapshot failure quit(3) (:38-39) only acts at the end of the iteration (SceneTree.quit docs), so attack_sim resumes on the first process_frame and runs its whole battery on the un-snapshotted profile (clears achievements.cfg attack_sim.gd:62-65, wipe_all_saves :524), then its quit(0/1) (:51) overwrites exit code 3. (4) snapshot() never compares bytes with the source (:72-75), unlike udg_snapshot's cp && cmp (user_data_guard.sh:41). (5) A failed startup restore does not stop a normal launch, so progress saved in that session is reverted by the next launch's retry |
| Guard | QaLaunchGuard: covers every documented QA launch | PARTIAL | Every scenes/tools/* and --shot launch is matched (qa_launch_guard.gd:50-54; get_cmdline_args keeps the scene path; run_gates.ps1 and finish_project.ps1 use scenes/tools). Not matched: `--headless --path . res://tools/autopilot/autopilot.tscn` (docs/FINAL_REPORT.md:52, tools/autopilot/autopilot_main.gd:6). It writes and deletes user://tls_savegame_slot99.save (:187-199), and its load_slot(99) rewrites user://flashlight_upgrades.cfg (save_system.gd:543 -> flashlight_upgrade_manager.gd:174-177) |
| Guard | QaLaunchGuard in release builds and the editor | CONFIRMED | Ships (scripts/core is not in exclude_filter; scenes/tools/** and scripts/tools/** are). With no QA argument and no snapshot dir it only checks for dirs, so it is inert. The editor does not instantiate the (non-@tool) autoload; Run Scene passes the scene path; a Stop kill leaves the copy for the next unguarded launch |
| Guard | Interaction with user_data_guard.sh and TLS_UDG_GUARDED | CONFIRMED | TLS_UDG_GUARDED=1 is exported only after a successful udg_snapshot (check.sh:273-276, headless_suite:26-29, autoplay_bot:22-25, guarded_windowed:24-27). Guarded launches skip the autoload and leave any crash copy for the next unguarded launch (:23-26). The .qa_snapshot sibling dir is outside the shell guard's list. Concurrency caveat is in the row above |
| Guard | `_qa_guard_check.gd` as its regression | PARTIAL | It only drives the static helpers on a synthetic dir (_qa_guard_check.gd:33-54). _enter_tree/_exit_tree/_is_qa_launch (crash-copy recovery, guarded skip, quit on failure) are exercised by no gate, since every engine gate runs with TLS_UDG_GUARDED=1; a guard whose _is_qa_launch() always returned false would still pass. It has no incomplete-snapshot case. On pre-fix code it fails only because the preloaded script is missing |
| Guard | user_data_guard.sh, guarded_windowed, tz_verify wrapper | CONFIRMED | Restore refuses a missing or incomplete snapshot and verifies with cmp and the file set; guarded_windowed deletes the log before any exit (:16), so tz_verify (:11) no longer prints a stale run; modes 100755 |
| Fix | `b8abb2e` D03 stage lighting vs GDD | CONFIRMED | DARK/PARTIAL 0.03/0.12, STREETS 0.11/0.25, FULL 0.16/0.40 = GDD.md:108, :110, :111 (PARTIAL has no GDD numbers, :109); export defaults 0.03/0.12, no scene override; tz_verify D03 fails on 1430516's 0.12/0.09. The off-by-one comment cite is counted in the TZ D03 row |
| Fix | `b8abb2e` E05 reward curve vs GDD | CONFIRMED | rewards_manager.gd:4-8 and balance_sim.py [7] cite GDD.md:229, which holds the curve; P2q fails on the flat 200; no other reward site |
| Fix | `b8abb2e` X12, P2m retry, exit-3 skip, labels | CONFIRMED | P2r :874-880 fails with XpManager.reset() removed from reset_all (level stays > 1); P2m retries 3 x behind _ensure_playing (:561-570); headless_suite:62; TZ_DECISIONS relabels at :32, :42, :47, :48, :50, :54 |
| Fix | `94af752` round-8 docs | CONFIRMED | Docs only; round-7 row, G18/G19 168-181 and the R-02 residual (ORDER_PASS_REPORT.md:90) hold |
| Fix | `c46d8a3` round-9 docs | CONFIRMED | Docs only; G28/D04 cite, I02 1301 and the FIXED/PARTIAL legend hold; its V05-mobile DR-3 row was superseded at rc11 |
| CORRECTION_LOG | Header "Oldest first" | CONFIRMED | git blame: 1-14 648cfd2/27ba1d5 (#8 edited by 0873f38), 15-21 0873f38, 22 5402640, 23-28 b8b20c0, 29-31 3ee3568, 32-33 4061f1b, 34 8c0e01c, 35 9936ab3, 36 94af752, 37 c46d8a3, 38 1430516, 39 b8abb2e |
| CORRECTION_LOG | #1-#7 | CONFIRMED | bafb740 importer flip and message; 37581d7 commits 528 .import files; 2547fff per-tier fog; 0d3d533 X22/X20/footer |
| CORRECTION_LOG | #8 | PARTIAL | CORRECTION_LOG.md:15 says P2m was root-caused and fixed by the bounded PLAYING wait (9fc8665). That fix left the second `await _ensure_playing()` unchecked (1430516 suite :568), and b8abb2e's own comment records a rc11 direct-run P2m failure, 1 of 3, from the same MENU window (_qa_headless_suite_runner.gd:559-560). No log row corrects #8 |
| CORRECTION_LOG | #9-#14 | CONFIRMED | 4bb5772 is the A04 DR-7 docs commit (superseded by #23); d06fe48 body item "6." is the StyleBox fix and predates the pass base; ad051fc says "all PASS visual_truth_gate"; ae410b9 names "C06 ultra tier 0.66% FAIL" but rc1 S03 reads 0.66%; c00f118 adds S01 DR-3 |
| CORRECTION_LOG | #15 | CONFIRMED | This run: rc1 frames 0.17-0.66% (S03 FAIL); rc2 0.17-0.46% with G03 1.01% |
| CORRECTION_LOG | #16-#21 | CONFIRMED | 0873f38 parent code as stated; `_ensure_playing` first appears in 9fc8665; tz_verify 14 at 27ba1d5, 15 at 0873f38 |
| CORRECTION_LOG | #22-#28 | CONFIRMED | 5402640 parent base 1.0/8 m; b8b20c0 diff adds the "flashlight" key, removes fog 0.015 and the softness write; rc4 tag peels to b8b20c0 |
| CORRECTION_LOG | #29-#35 | CONFIRMED | P2r measured drain; 5cf3b27 lost-snapshot deletion (bash); 3ee3568 unchecked `cp -p` (:37) and mktemp; 4061f1b trap without exit code (check.sh:274 there); tz_verify 100644 at 8c0e01c; 320-330 share 18-24% |
| CORRECTION_LOG | #36-#37 | CONFIRMED | _compile_gate.gd scans res:// and loads every .gd (:16, :51); 94af752 range fix; c46d8a3 project.godot had size.mobile=1024 |
| CORRECTION_LOG | #38 | CONFIRMED | True for 1430516 (perf/audio refusals, guarded_windowed, V05 override removed, FIXED cites); its narrow scope is recorded by #39 |
| CORRECTION_LOG | #39 | CONFIRMED | QaLaunchGuard matches scenes/tools/* and --shot (qa_launch_guard.gd:50-54), restores at exit (:41-48), crash copy restored on the next unguarded launch (:22-32); _user_data_snapshot.gd and the refusals removed in b8abb2e; relabels, G34 counts, S02 text, X12 P2r and X24 text all present |
| MATRIX | Status recount by script | CONFIRMED | 115 rows, 115 unique IDs: WORKS 100, FIXED 6, CTH 6, BDL 1, PARTIAL 1, BUG 1, UNTESTED 0 = footer (FUNCTION_MATRIX.md:156) |
| MATRIX | Header lines and totals | CONFIRMED | 59 AL + 32 IN = 91 spine (29 live [input] actions + the 3 removed), X01-X24 = 24, 115 total |
| MATRIX | AL rows vs project.godot [autoload] | CONFIRMED | Same 59 names and entry paths (script). Order differs only because QaLaunchGuard is first in project.godot but AL59 in the matrix, as disclosed at FUNCTION_MATRIX.md:8 (gen_function_matrix.py would now number it AL01) |
| MATRIX | FIXED rows cite a commit containing the fix | CONFIRMED | IN67/IN84/IN86 `0d3d533` removes the 3 input maps; X08 `0f9685a` deletes settings_full.gd; X19 `fe3007a` phase-7 harness; X22 `0d3d533` adds UIManager._is_open(&"death") |
| MATRIX | Legend, open list, X12 / X24 / AL59 rows | CONFIRMED | Every status used is defined (:21-25); X21 BUG and X20 PARTIAL are the only open rows; X12 cites the P2r assert; X24 cites 246/253; AL59 describes a synthetic-dir check (see Guard rows for its limits) |
| ORDER_PASS | Candidate line | CONFIRMED | The last C8 row verifies rc11 and names rc12 = HEAD tag (origin rc12 peels to b8abb2e) |
| ORDER_PASS | C4 phase row | PARTIAL | ORDER_PASS_REPORT.md:11 lists D03 and E05 under "Decided with evidence" and notes only C03's C8 move. At HEAD both are applied DR-4 and MET (TZ_COMPLIANCE.md:36, :70), and TZ_DECISIONS.md:32, :42, :47 say D03, E05 and G22 had no measured evidence |
| ORDER_PASS | Other phase rows (R0, Save, C5, C6, UI, C9 prep) | CONFIRMED | Hashes contain the stated changes; truth gate 12/12 this run |
| ORDER_PASS | Battery table | PARTIAL | ORDER_PASS_REPORT.md:23 gives 44 checks "rc4 tag onward", but rc12 has 21 run_gate calls (check.sh:309-348) -> 45, as its own row 11 (:50) says. :33 names c00f118/97c8bf4 as the latest shipped trees, and :28 lists tz_verify only at 14/15 checks; rc12 has a 2/3 IRON RULE run and 19 checks |
| ORDER_PASS | Visual row | PARTIAL | ORDER_PASS_REPORT.md:32: "G03_sprint_fov 0.79% (98% of hits in the outer 15% edge band)". 98.1% is the edge share of the hue-band hits only (0.51% of the world band). The gate's 0.79% also counts 0.28% saturation outliers (median hue 120°, green, 6% at the edge), so 65% of the gate's hits are in the edge band. The S03 1.02% / 88% figure is exact. Other figures hold (12/14 PASS 0.14-0.46%, known-bad 13.19%) |
| ORDER_PASS | Perf numbers (246 C7, 253 rc11) | CONFIRMED | Same in TZ_COMPLIANCE.md:74, TZ_DECISIONS P01, CORRECTION_LOG #38 and FUNCTION_MATRIX X24 |
| ORDER_PASS | Verifier rounds 1-11 figures and tags | CONFIRMED | 79/7/3, 128/6/0, 145/14/0, 186/12/0, 132/4/0, 94/10/0, 105/3/0, 106/3/0, 114/4/0, 121/3/0, 121/15/0 = each committed CLOSURE_VERIFICATION_INTERNAL totals line; rc1-rc11 peel to the listed hashes |
| ORDER_PASS | Round 10 row label | PARTIAL | ORDER_PASS_REPORT.md:49 still says the mobile override removal is "(GDD 2048, DR-1)". Round 11 flagged exactly this; the fix changed TZ_DECISIONS.md:54 and CORRECTION_LOG #39 to DR-4 but left this row |
| ORDER_PASS | Round 11 row "Root fix for every QA launch" | PARTIAL | ORDER_PASS_REPORT.md:50. The documented autopilot launch (docs/FINAL_REPORT.md:52) is not matched and writes the profile (see Guard coverage). On a failed snapshot the guard does not stop first-frame QA work (see Guard safety). Its other items hold (exit-3 skip, P2m retry, stale log, 45 = 24 + 1 + 19 + 1, bot log 2/3 with the s2 power_station spine stall in the local .qa_logs/c8_rc12_bot.log) |
| ORDER_PASS | Correction count and ranges | CONFIRMED | 39 rows; the per-round split matches git blame; the "two wrong claims in this pass's own commit messages" are #11 and #12 (d06fe48 predates base c73cf7c) |
| ORDER_PASS | check.sh counts (42 / 44 / 45, static 24) | CONFIRMED | Static 24 this run; 20 run_gate calls at rc11 and 21 at rc12, minus 2 windowed skips: 23+1+18 = 42, 24+1+18+1 = 44, 24+1+19+1 = 45 |
| ORDER_PASS | Frames list and rc2 evidence | CONFIRMED | Listed frames exist; D03 dark/full show silhouettes, road edges, the tree and a lit street; rc2 frames 10/11 PASS 0.17-0.46%, G03 1.01% at 87.3% edge; V02 rc12 hue-only 0.008%, gate 0.37% |
| ORDER_PASS | Residual vs ARENA open defers and TZ GAP-OWNER / DR-5 rows | CONFIRMED | X21 (:86), R-02 (:90), P-05/R-08/D-01/D-02/D-03/B7 (:91); V03 (:82), G28/D04/N01/I02 (:83), G22 (:84), A03 (:85), T01 (:78-79), G26 in the structural list (:89). The E03 modal is BY-DESIGN-ABSENT, not a residual |
| Gate | `i18n_truth_gate.py` | CONFIRMED | 12/12 locales PASS, rc 0 |
| Gate | `hardcoded_text_gate.py` and `--demo` | CONFIRMED | 0 hits, rc 0; demo OK, rc 0 |
| Gate | `visual_truth_gate.py` tzverify + known-bad | CONFIRMED | 12/14 PASS (0.14-0.46%), G03 0.79% FAIL, S03 1.02% FAIL, magenta_corruption_suburbs 13.19% FAIL, rc 1 as expected. Matches ARENA R0, TZ_DECISIONS S03 (edge 98.1/87.9%) and the ORDER_PASS counts |
| Gate | `user_data_guard.sh --demo` | CONFIRMED | demo OK, rc 0; no tls_udg dirs left in temp |
| Gate | `balance_sim.py` | CONFIRMED | PASS; "11 x 200..1200 = 7700" matches TZ E05 and TZ_DECISIONS E05; battery budget 12.8 min vs need 12.6 (G10) |
| Gate | `TLS_SKIP_REIMPORT=1 check.sh --static` | CONFIRMED | "Всё зелёное", 24 passed, 0 FAIL, rc 0; `git status --short` empty afterwards (docs/artifacts/content-depth/i18n_only_texts.md rewritten byte-identical) |

CONFIRMED=132 PARTIAL=11 FAKE=0
