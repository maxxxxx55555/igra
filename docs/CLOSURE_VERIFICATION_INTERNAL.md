# Round 11, HEAD 1430516, tag v8.0.0-rc11

| Source | Item | Verdict | Evidence |
|---|---|---|---|
| ARENA A | Header "17/17 closed; B7's legacy half deferred" | CONFIRMED | 16 rows cover 17 items (B9+B14 share a row). Every ARENA hash exists and is an ancestor of HEAD (`git merge-base --is-ancestor`). "n/m" below = n of the m added non-doc code lines (length >= 4, not comments) of that commit still present in the same file at HEAD (script) |
| ARENA A | B1 `5e1093b` | CONFIRMED | 45/45 |
| ARENA A | B2 `7034bcd` | CONFIRMED | 37/37 |
| ARENA A | B3 `afadb4b` | CONFIRMED | 50/50 |
| ARENA A | B4 `92934a7` + note `ac877a5` | CONFIRMED | 49/49 and 4/4; CORRECTION_LOG #8 cites ac877a5 |
| ARENA A | B5 `fe7ef0e` | CONFIRMED | 69/71; the 2 misses are attack_sim test writes later moved into `_write_ngp_test_file` |
| ARENA A | B6 `e9686d7` | CONFIRMED | 35/35 |
| ARENA A | B7 `bb662b4` + deferred legacy half | CONFIRMED | 21/21. Legacy branch trusts and re-signs a plain achievements.cfg (achievements_manager.gd:205-211); attack_sim.gd:89 locks it; listed in the open defers |
| ARENA A | B8 `1cf3aaf` | CONFIRMED | 30/30 |
| ARENA A | B9+B14 `36d44be` | CONFIRMED | 92/92 |
| ARENA A | B10 `cc1e0b3` | CONFIRMED | 54/54; save after placement (world_runtime.gd:66-76) |
| ARENA A | B11 `d7a0692` | CONFIRMED | 26/26 |
| ARENA A | B12 `c814621` | CONFIRMED | 26/26 |
| ARENA A | B13 `a36ac8b` | CONFIRMED | 57/57 |
| ARENA A | B15 `8c99689` | CONFIRMED | 40/42; misses are the suite P2p check later rewritten to a sentinel (suite :682-693) |
| ARENA A | B16 `cb73c83` | CONFIRMED | 18/18 |
| ARENA A | Q1 `a0ec4ee` | CONFIRMED | 38/38 |
| ARENA B | P-01 `92934a7` | CONFIRMED | As B4 |
| ARENA B | P-03 / P-04 / P-06 / P-07 `9b7a46b` | CONFIRMED | 141/141 |
| ARENA B | P-05 tamper `e9686d7` + wall-clock defer | CONFIRMED | Tamper fix present (35/35); wall clock is an inherent client limit, listed in the open defers |
| ARENA B | R-01 `2278cf9` | CONFIRMED | 13/13 |
| ARENA B | R-02 defer reason | CONFIRMED | integrity_guard.gd:83 checks only non-finite position and y <= -50; listed |
| ARENA B | R-08, D-01, D-02 inherent defers | CONFIRMED | Client-side limits; listed |
| ARENA B | D-03 owner defer | CONFIRMED | release_export_check.py:37-40 rejects a committed encryption_key; PASS this run |
| ARENA B | R-03 / D-04 `60a289b` | CONFIRMED | 41/41 |
| ARENA B | R-07 `cef6ae6` | CONFIRMED | 29/29 |
| ARENA B | C-08 `a453425` | CONFIRMED | 60/60; wired at check.sh:255 |
| ARENA C | R0 `bafb740` + figures | CONFIRMED | bafb740 flips `importer="texture"` to `"3d_texture"` on the 11 LUT imports; all 11 are 3d_texture at HEAD (pin check.sh:201, PASS). 13% -> 0.01-0.30% is bafb740's recorded A/B. Gate this run: rc4 frames 0.15-0.42%, G03 1.28% |
| ARENA C | RENDERING_DIAGNOSIS (b), (d) | CONFIRMED | Covered by bafb740; ssao/ssil/ssr per tier in visual_quality.tres:9-12 |
| ARENA C | TG gates `5257745`, `4c6ca10` | CONFIRMED | 118/119 and 7/7 |
| ARENA C | CHALLENGE-01 `fe3007a` | CONFIRMED | 20/22; misses are the phase-8 lines reworded by 0d3d533 (X22) |
| ARENA C | CHALLENGE-02 partial `c783544` | CONFIRMED | 10/10; residual is matrix X21 BUG, listed in the open defers |
| ARENA C | CHALLENGE-03 `0f9685a` | CONFIRMED | settings_full.gd not tracked, 0 references |
| ARENA C | MISSED-00..05 | CONFIRMED | AL35 / AL50 / AL55 / AL57 / IN89 are WORKS |
| ARENA C | I18N `43c9ecd` / `21c6563` | CONFIRMED | 159/159 and 219/220; truth gate 12/12 this run |
| ARENA D | SLOP 1-15, §2, §3 | CONFIRMED | 855a278 5/5, 1fcf157 3/3, bbdaa8e 11/11, d06fe48 16/16, 53353d5 13/13, 363add0 3/3, 7bbc0ca 1/1 (BLACK_FAIL_PCT 40.0, visual_truth_gate.py:50); 2948e23 holds (0 BTN_ONE_MORE_RUN refs) |
| ARENA Design | P1-P8 | CONFIRMED | 2a88503 2/2, c2dbeb4 82/88 and 4e7560e 337/343 (misses are later i18n value edits), f9bbfd7 18/18, 24ceb68 36/39 (literal became BATTERY_PER_SKILL_LVL, player_3d.gd:1182-1186), 8f48faf 35/35, ee273ee 4/4 |
| ARENA | Open-defers list | CONFIRMED | P-05, R-08, D-01, D-02, D-03, B7 legacy half, R-02, X21 = every deferred row |
| ARENA | "No P0 is deferred" | CONFIRMED | R0, the only P0, is closed |
| TZ | Legend covers every verdict | CONFIRMED | 48 ledger rows; every verdict token outside parentheses is one of the 8 legend verdicts (script) |
| TZ | tz_verify "17 checks at rc5" | CONFIRMED | 19 `_check(` lines = def + 18 sites; :252 is the exclusive else of :248, so 17 per completed run (incl. restore :55, fog at load :106). Same count gives 14 at 27ba1d5, 15 at 0873f38, 16 at b8b20c0 |
| TZ | footstep probe exits 1 | CONFIRMED | _footstep_check.gd quits 1 on fails; check_surface_speeds counts a missing or duplicate (sample, pitch) step (footstep_system.gd:190-204) |
| TZ | A02 MET | CONFIRMED | FADE_TIME 2.0 (music_manager.gd:118) used at :209, :262-263; GDD.md:359; tz_verify :109 |
| TZ | A03 code facts | CONFIRMED | SPEED_FILE walk/jog/sprint, pitch 0.9/1.0/1.12 (footstep_system.gd:47-49); asphalt/puddle/glass map to single step_* samples (:15-21). DR label: see TZ_DECISIONS A03 |
| TZ | A04 MET-STATIC | CONFIRMED | MiB: sfx 6.33 + one_shots 1.07 + (ambience 45.97 - wav_src 29.94) = 23.4; music 37.2; wav_src and _pre_norm in all 3 exclude_filters |
| TZ | A01 DEFERRED-STRUCTURAL | CONFIRMED | default_bus_layout.tres: Master/Music/SFX/Voice/Ambient/UI/Hum |
| TZ | V02 MET | CONFIRMED | Hit flash #c9a24a, original kept in meta and restored (base_monster.gd:663-690); P2b asserts the restore (suite :299-312); boss ball light #c9a24a (boss_3d.gd:293) |
| TZ | V05 MET | CONFIRMED | project.godot:296 = 2048 and no `.mobile` key (removed by 1430516); the engine's `.mobile` default is 2048 (godot-docs class_projectsettings.rst:12605); tz_verify :111-113 checks both and fails on the old 1024 override |
| TZ | V01 MET-STATIC | CONFIRMED | day_night.gd has no environment writer |
| TZ | GAP-OWNER rows (V03, N01, I02, T01, G28/D04) | CONFIRMED | assets/fonts has only -Regular files; power_grid.gd:85-92 routes the win through FinaleDirector; the rest are owner text or credential actions |
| TZ | G02 / G03 / G06 MET | CONFIRMED | SPRINT_BOB_AMP 0.1, SPRINT_FOV_BONUS 5 (camera_follow_3d.gd:22-24); fov 80 (main_3d.tscn:57); run 272 = 170 x 1.6 (player_stats.tres:6-7); checks :142-145 fail without the feature |
| TZ | G07 split | CONFIRMED | CROUCH_SPEED_MULT used :563; noise 0.4 x 0.3 (:542); CROUCH_VISIBILITY_MULT (:89) unread; capsule 1.6 |
| TZ | G08 MET / NEEDS-EYES | CONFIRMED | Colour (0.788, 0.635, 0.29) = c9a24a, angle 45, energy 24, range 16 (player_3d.tscn:179-184) |
| TZ | G12b MET | CONFIRMED | Threshold 20, intensity 0.35 (flashlight_stats.tres:11-12); cleared at max level (player_3d.gd:1140, :1164); drain cut :760; tz_verify :177, :188; P2r :862-871 |
| TZ | G15 split | CONFIRMED | Capsule 1.6 (player_3d.tscn:9); attack box 1.4x0.8x3.4 (player_3d.gd:311) with the recorded winnability note (:307-310) |
| TZ | G16 MET | CONFIRMED | P2r drives respawn_after_death + Routes.restart_game = death_screen.gd:53-54; RESPAWN_HP_RATIO 0.5 (game_manager.gd:110) |
| TZ | G17 MET | CONFIRMED | _remove_with_backups (save_system.gd:556-560) on main and every slot; hardcore path game_manager.gd:172-173; tz_verify seeds .bak/.bak2/.bak3 (:256-266) |
| TZ | G18 / G19 MET-STATIC | CONFIRMED | Script: the 11 GDD types (via AI_TO_ROSTER + sharpshooter/brute/burner/rotter/hound/tvar) and beast 800/40 equal GDD.md:168-181; Shadow 30/15 (shadow_3d.gd:13,16) |
| TZ | G20 MET-STATIC | CONFIRMED | boss_3d.gd:48-50 0.70/0.30, BEAM_DAMAGE 40 (:9) |
| TZ | G24 DECIDED (DR-2) | CONFIRMED | district_manager.gd:30-42; P2q asserts both sides (suite :775-782) |
| TZ | G34 MET (bunker) | CONFIRMED | BUNKER_SECRET_ID (progress_tracker.gd:128); P2q (suite :784-787); endings_sim "all 5 GDD endings reachable" this run. DR-5 half: see TZ_DECISIONS G34 |
| TZ | S03 MET | CONFIRMED | Shader keeps COLOR.rgb; pulse on the 0-1 noise scale; check needs r > 0.4 and edge warmth +0.03 (:146). Edge warmth recomputed from committed frames: rc2 -0.015 -> 0.065, rc4 -0.015 -> 0.176 |
| TZ | S04 MET-STATIC | CONFIRMED | SEARCH_TIME 10 / SEARCH_RADIUS 5 (base_monster.gd:45-46); P2q (suite :768) |
| TZ | E03/T02 split | CONFIRMED | Both cooldowns 3600 (ad_service.gd:27,31); skip_bonus_coins has no caller; P2q (:766) |
| TZ | C04 MET | CONFIRMED | ru "Слепые псы" (ru.json:276); key in all 13 locale files |
| TZ | C06 MET | CONFIRMED | Fog 0.012/0.013/0.014/0.015 and particle_ratio 0.5-1.5 (visual_quality.tres:9-12); fog_setup.gd writes no density; _scale_emitter (settings_manager.gd:441) |
| TZ | DEFERRED group (G21, G25, G26, S04-hide, C03, P01) | CONFIRMED | No scene references weapon_manager.gd or hiding_spot.gd; take_photo has no caller; album total hard-coded 200 (photo_album.gd:57); melee sphere 2.7 (player_3d.gd:326) |
| TZ | S02 DEFERRED-STRUCTURAL verdict | CONFIRMED | GDD visibility modifiers (flashlight x2, darkness 3 m, run +20%, crouch x0.5) are absent. Reason text: see TZ_DECISIONS S02 |
| TZ | P02 NEEDS-MEASUREMENT | CONFIRMED | Honest; headless reports no particle or memory figures |
| TZ | DECIDED group (G01, G04, G09, G10, G13, G27, G31-33, D02, S01) | CONFIRMED | fps_mode=true (main_3d.tscn:61), REACH 3.2 (interactor.gd:24), drain 100/450 (player_3d.gd:96, note :92-95), battery.tres 35, combo 14/21/35 (note :75-77), JOY_ZONE_RATIO 0.35 (:413), S01 not applied |
| TZ | Footer "Open GAP-DEV rows: 0" | CONFIRMED | All 54 audit GAP-DEV/GAP-OWNER IDs appear in the ledger (script) |
| TZ_DECISIONS | S03 reason figures | CONFIRMED | Band 260-345 (visual_truth_gate.py:52). Hue-band hits: median hue 332/319/333/332, edge share 87.3/97.8/85.5/70.1% (rc2 G03, rc2 S03, rc4 G03, rc4 S03) |
| TZ_DECISIONS | S03 label "DR-1 over the visual gate" | PARTIAL | TZ_DECISIONS.md:50. DR-1 is the REJECTED list: PICKUP_TOUCH tightening or a NavigationAgent3D nav change (EXEC_PLAN.md:67, :246-249). Keeping the canon ember tint involves neither, so DR-1 does not apply |
| TZ_DECISIONS | V05-mobile "SUPERSEDED (C8 rc11, DR-1)" | PARTIAL | TZ_DECISIONS.md:54; also ORDER_PASS_REPORT.md:49 "(GDD 2048, DR-1)". Removing the override so mobile follows the GDD value is DR-4 VERBATIM (EXEC_PLAN.md:70). DR-1 means no code change for a REJECTED-list item (EXEC_PLAN.md:67) |
| TZ_DECISIONS | A03 "DR-A03 via criterion 3" (TZ_COMPLIANCE.md:30 "DECIDED (DR-A03)") | PARTIAL | EXEC_PLAN §2 defines only DR-1..DR-7 (EXEC_PLAN.md:67-73). Criterion 3 (DR-3) needs a measured rejection, but the stated reason is "smallest reversible diff with existing assets" plus an owner audio-asset residual. That is DR-5, missing samples (EXEC_PLAN.md:71) |
| TZ_DECISIONS | G22 DR-3 (TZ_COMPLIANCE.md:55) | PARTIAL | TZ_DECISIONS.md:42 cites only the "ARCHIVED (PLAN.md Stage 1, decided)" note (KNOWN_ISSUES.md:1244). That records a decision, not a measurement. DR-3 says "Opinion does not count" (EXEC_PLAN.md:69), and the G22 plan row says "A measured reason -> DR-3. Otherwise DR-4" (EXEC_PLAN.md:135) |
| TZ_DECISIONS | E05 DR-3 (TZ_COMPLIANCE.md:70) | PARTIAL | TZ_DECISIONS.md:47. The balance_sim ledger (6600) measures the shortfall, not a harm from the 8000+ curve. The "retain" rationale is DESIGN_AUDIT_ARENA P6, whose numbers are "recommendations, not measured outcomes" (DESIGN_AUDIT_ARENA.md:12). No measured rejection exists (EXEC_PLAN.md:69) |
| TZ_DECISIONS | D03 half of "D03 / V01 DR-3 + DR-4" (TZ_COMPLIANCE.md:36) | PARTIAL | TZ_DECISIONS.md:32. The recorded rejection is of ambient 0.01 / moon 0.03 (world_env_setup.gd:5-7). The GDD canon is DARK 0.03/0.12, STREETS 0.11/0.25, FULL 0.16/0.40 (GDD.md:108-111), and none of those values was tried. Live moon 0.09/0.14/0.20 (world_env_setup.gd:23-25) is below canon at every stage, which a too-dark rejection cannot justify. EXEC_PLAN.md:105 carries the same premise. The V01 DR-4 half holds |
| TZ_DECISIONS | G34 DR-5 for the aliased audio logs (TZ_COMPLIANCE.md:62) | PARTIAL | TZ_DECISIONS.md:34. DR-5 requires that the content does not exist in-tree (EXEC_PLAN.md:71). Yet 22 lore notes with `"item_type": "audio_log"` (2 in each content/districts/*/lore_notes.json) spawn in play (district_loot.gd:177-180) and count as documents. The stated reason covers photos only. For audio logs the alias is a superset condition (effectively met), not DR-5 |
| TZ_DECISIONS | S02 / G07-visibility reason | PARTIAL | TZ_DECISIONS.md:40 says "Monsters read no player visibility factor at all", but base_monster.gd:531-537 cuts both sight ranges by 10% per low_profile level when the player sneaks with the flashlight off (c2dbeb4). The GDD modifiers themselves are absent, so the verdict stands |
| TZ_DECISIONS | G18 / G19 lines 168-181 | CONFIRMED | Table header through the Architect row |
| TZ_DECISIONS | G28 / D04 reason | CONFIRMED | GDD.md:3-7 only ranks the GDD above its appendices; §12.3 Act III (GDD.md:337-341); GDD:119 trigger_win |
| TZ_DECISIONS | I02 reason | CONFIRMED | 1301 keys in each of the 13 data/i18n/*.json; GDD.md:22 "198 ключей" |
| TZ_DECISIONS | G09 / G13 code cites | CONFIRMED | player_3d.gd:92-95 drain note, :75-77 combo note |
| TZ_DECISIONS | Other cited GDD lines | CONFIRMED | 22, 52-59, 68, 76, 119, 147, 168-181, 261, 317, 341, 359-362, 613-616, 652 hold the quoted text |
| TZ_DECISIONS | All other DR labels and reasons | CONFIRMED | V03/N01/I02/T01 DR-6; G01/D02/G27/G31-33/G24/G28 DR-2; A04/G18/G19 DR-7; G04 DR-1 (PICKUP_TOUCH); G09/G10/G13/G15/S01 DR-3 with recorded bot or sim evidence; DR-4 rows match the code. Every non-MET ledger row has a matching row |
| Fix | `0873f38` S03 / G12b / A03 / G17 | CONFIRMED | Parent: shader forced BG_DEEP RGB (edge-warmth check fails); cleared at bonus >= 1.0 with L5 = 0.5 (L5 spread check fails); probe quit(0) unconditionally; wipe removed only .bak (.bak2/.bak3 check fails) |
| Fix | `5402640` upgrades across respawn | CONFIRMED | Parent: energy 1.0 x (1 + b), range 8.0, applied only from the purchase path (flashlight_upgrade_manager.gd:127-128), so P2r `maxed` and `want_energy >= 20` fail; HEAD re-applies from the scene base |
| Fix | `b8b20c0` per-run upgrades, drain, fog, hit flash | CONFIRMED | Parent: no "flashlight" save key and reset_all left upgrades (P2r cleared check fails); fog_setup.gd:16 set 0.015 (fog-at-load check fails); flash Color(1,1,1) and duplicate-on-restore (P2b fails) |
| Fix | `5cf3b27` guard around QA runs | PARTIAL | Wrapped paths are correct (check.sh:272-276, headless_suite:25-29, autoplay_bot:21-25). Documented direct launches still run the game on the real profile with no snapshot. EXEC_PLAN.md:35: attack_sim calls wipe_all_saves (attack_sim.gd:524) and clears achievements.cfg (:62-65), restoring only main/.bak and NG+. EXEC_PLAN.md:38: game_test_3d runs save_slot/delete_slot(3) (_game_test_3d.gd:113-119), and its shop buy (:128) fires purchase_success, which calls SaveSystem._save(). RUN_STATE.md:28: bot seed re-run. RC_OWNER_CHECKLIST.md:55-57: every *_check_scene directly, incl. boot_check. EXEC_PLAN.md:36 runs the suite under `timeout 120`, below its 260 s hard timeout, and calls 124 clean, so a kill skips the in-process restore |
| Fix | `3ee3568` lost-snapshot hole, in-process snapshot, measured drain | CONFIRMED | Lost snapshot: with 5cf3b27's functions, restore returns rc 0 and deletes all owner files (bash test); with 3ee3568's, rc 1 and the files are kept. The suite snapshots first (runner :115), the tz runner before start_game (:83); P2r measures drain through _update_battery (rc4 read the field only) |
| Fix | `4061f1b` abort on failed snapshot | CONFIRMED | 5cf3b27's and 3ee3568's functions under the HEAD demo -> "demo FAIL: snapshot succeeded without a dir"; runners stop on a null snapshot (suite :116, tz :84) |
| Fix | `8c0e01c` trap exit code, partial cleanup, wrapper | CONFIRMED | 4061f1b's functions under the HEAD demo -> "demo FAIL: partial snapshot left in temp"; 8c0e01c's -> demo OK; every EXIT trap at HEAD is `udg_restore \|\| exit 97` |
| Fix | `9936ab3` tz_verify refuses an unguarded launch | CONFIRMED | _tz_verify_runner.gd:71-74 quits 2 before the snapshot and start_game; wrapper 100755 (8c0e01c: 100644) |
| Fix | `1430516` "guard every windowed probe", V05 mobile 2048, FIXED commits | PARTIAL | The perf/audio refusal is real and runs first in `_run` (_perf_check_runner.gd:15-18, audio_truth_gate.gd:51-54). No gate exercises it, since every wrapper exports the flag. The V05 check fails on the old 1024 override. "Every windowed probe" is false: these start a New Game with no refusal and no snapshot. capture_stills: OWNER_HANDOFF.md:72, KNOWN_ISSUES.md:322, EXEC_PLAN.md:46, capture_stills.gd:6, via the autoplay runner's Routes.start_game (:128). boot_check: README.md:94 `--windowed`; _boot_check_runner.gd:67, :123. gameplay_shot: PLANS.md:207; runner :38. ShotTool `--shot-scenario`: shot_tool.gd:6, :85-86. guarded_windowed:2-5 names only three probes |
| Fix | `94af752` round-8 docs | CONFIRMED | Docs only; its 3 fixes hold (round-7 row, G18/G19 168-181, R-02 residual ORDER_PASS_REPORT.md:86) |
| Fix | `c46d8a3` round-9 docs | CONFIRMED | Docs only; the G28/D04 cite, I02 1301 and the legend entries hold; its V05-mobile DR-3 row was superseded at rc11 |
| Guard | user_data_guard.sh | CONFIRMED | Restore refuses a missing or incomplete snapshot, removes only unlisted files, and verifies with cmp and the file set; a failed copy drops the partial dir; --demo covers all four paths |
| Guard | guarded_windowed | CONFIRMED | Resolves Godot, `udg_snapshot \|\| exit 99`, EXIT trap `udg_restore \|\| exit 97`, INT/TERM -> 130, exports TLS_UDG_GUARDED=1, `timeout`, `--windowed`; mode 100755 |
| Guard | tz_verify wrapper | PARTIAL | New regression in 1430516: tz_verify:10-12 greps .qa_logs/tz_verify_scene.log even when guarded_windowed exits 99 before launching Godot (no Godot, or the snapshot failed). It then prints the previous run's "[tzv] DONE fails=0". Simulated with a stub launcher: rc 99 plus stale OK/DONE lines. 9936ab3 exited before the grep |
| Guard | _user_data_snapshot.gd | CONFIRMED | take() returns null on any unreadable file; restore() refuses a non-Dictionary; no save-on-quit hook in game scripts |
| Guard | check.sh / bot / suite / runner guard wiring | CONFIRMED | A snapshot failure exits before any engine gate. The explicit udg_restore (check.sh:348) clears UDG_ACTIVE, so the trap keeps `exit $FAIL`. The suite's _finish restores on every in-process path, including its hard timeout |
| Guard | perf / audio runner refusal | CONFIRMED | The refusal precedes Routes.start_game in both. Autoload _ready does not write the profile (the only boot write is the legacy achievements re-sign) |
| Wiring | headless_suite perf self-skip (header :12-13) | PARTIAL | _perf_check_runner.gd:60 quits 3 under headless, but run_scene counts any rc != 0 as FAIL (headless_suite:61-62, gate :81). The suite therefore always reports at least 1 failure, and the owner pre-flight CHK002 "both must be green" (RC_OWNER_CHECKLIST.md:40-44) cannot pass. Pre-existing since 1fcf157, not caused by 1430516 |
| CORRECTION_LOG | Header "Oldest first" | CONFIRMED | git blame: 648cfd2/27ba1d5 (1-14; #8 edited by 0873f38) -> 0873f38 (15-21) -> 5402640 (22) -> b8b20c0 (23-28) -> 3ee3568 (29-31) -> 4061f1b (32-33) -> 8c0e01c (34) -> 9936ab3 (35) -> 94af752 (36) -> c46d8a3 (37) -> 1430516 (38) |
| CORRECTION_LOG | #1-#7 | CONFIRMED | bafb740 importer flip and message; 37581d7 (528 .import files); 2547fff fog; 0d3d533 X22/X20/footer |
| CORRECTION_LOG | #8 | CONFIRMED | `git log -S _ensure_playing` first hit is 9fc8665 |
| CORRECTION_LOG | #9-#14 | CONFIRMED | d06fe48 body item "6." is the StyleBox fix. ad051fc says "all PASS visual_truth_gate". ae410b9 names "C06 ultra tier 0.66% FAIL", but its frames (identical to rc1's) show S03 at 0.66% this run. c00f118 adds S01 DR-3 |
| CORRECTION_LOG | #15 | CONFIRMED | This run: rc1 frames 0.17-0.66% (S03 FAIL); rc2 0.17-0.46% with G03 1.01% |
| CORRECTION_LOG | #16-#21 | CONFIRMED | 0873f38 parent code as stated (S03 check `vig_a > 0`); tz_verify 14 at 27ba1d5, 15 at 0873f38; 90 spine + 24 X rows |
| CORRECTION_LOG | #22-#28 | CONFIRMED | 5402640 parent: base 1.0 / 8 m, purchase-only apply. b8b20c0 parent: fog 0.015, white flash, no flashlight key. rc4 tag peels to b8b20c0 |
| CORRECTION_LOG | #29-#35 | CONFIRMED | rc4 P2r read only the field. 5cf3b27: lost-snapshot deletion (bash test) and tz backup taken after start_game. 3ee3568: unchecked `cp -p` (:37) and S03 "87–98%"; 4061f1b: "85–98%" and a trap without an exit code. 8c0e01c: wrapper 100644 and the "320–330" text; the hue-band share in 320-330 is 18-28% on the 4 cited frames |
| CORRECTION_LOG | #36 | CONFIRMED | _compile_gate.gd scans res:// and loads every .gd (:16, :51); the 94af752 diff makes the stated fixes |
| CORRECTION_LOG | #37 | CONFIRMED | The c46d8a3 diff makes each stated change; c46d8a3 project.godot had `size.mobile=1024` |
| CORRECTION_LOG | #38 | PARTIAL | CORRECTION_LOG.md:45. The new fact names only the perf and audio probes, but other documented QA launches still start a game on the real profile with no snapshot (see the Fix 5cf3b27 and 1430516 rows). "guarded_windowed is the documented launcher" is contradicted by the direct perf/audio launches still in EXEC_PLAN.md:48-49, HANDOFF.md:413, KNOWN_ISSUES.md:1137 and QA_MATRIX.md:210 (they now exit 2) |
| MATRIX | Status recount by script | CONFIRMED | 114 rows, 114 unique IDs: WORKS 99, FIXED 6, CTH 6, BDL 1, PARTIAL 1, BUG 1, UNTESTED 0 = footer (FUNCTION_MATRIX.md:155) |
| MATRIX | Header lines and totals | CONFIRMED | AL01-AL58 = the 58 project.godot autoloads, names in order; IN58-IN89 = 32 rows (29 live actions + shop_toggle/close_screen/settings removed); X01-X24 |
| MATRIX | FIXED rows cite a commit containing the fix | CONFIRMED | IN67/IN84/IN86 `0d3d533` (removes the 3 input maps from project.godot); X08 `0f9685a` (deletes settings_full.gd); X19 `fe3007a` (phase-7 harness); X22 `0d3d533` (UIManager._is_open(&"death"), _game_test_3d.gd:255) |
| MATRIX | Rows vs status legend | PARTIAL | The legend defines WORKS as "verified this pass, method stated" (FUNCTION_MATRIX.md:21). X12 is WORKS yet says "not re-verified this pass" (FUNCTION_MATRIX.md:137), and no probe asserts that reset_all clears XP or skill points (P2q only calls XpManager.reset() directly, suite :735-742) |
| MATRIX | X24 perf row text | PARTIAL | FUNCTION_MATRIX.md:147 says the D1 <200 target "hasn't been re-measured with a real GPU this pass". The same pass measured D1 at 246 (C7) and 253 (rc11) windowed (ORDER_PASS_REPORT.md:30, TZ_COMPLIANCE.md:74) |
| MATRIX | Open list (X21 BUG, X20 PARTIAL) | CONFIRMED | Matches the only BUG and PARTIAL rows |
| ORDER_PASS | Candidate line | CONFIRMED | The last C8 row verifies rc10, and its action names rc11 = HEAD tag, the same pattern as rows 1-9 |
| ORDER_PASS | check.sh counts (42 / 44 / static 24) | CONFIRMED | Static 24 this run; 20 run_gate calls - 2 windowed skips = 18; 23+1+18 = 42, 24+1+18+1 = 44 |
| ORDER_PASS | Verifier rounds 1-10 figures and tags | CONFIRMED | 79/7/3, 128/6/0, 145/14/0, 186/12/0, 132/4/0, 94/10/0, 105/3/0, 106/3/0, 114/4/0, 121/3/0 = each committed CLOSURE_VERIFICATION_INTERNAL totals line; tags rc1-rc10 peel to the listed hashes |
| ORDER_PASS | Correction count and ranges | CONFIRMED | 38 rows; the per-round split matches git blame |
| ORDER_PASS | Visual row, rc2 evidence, V02 note | CONFIRMED | This run: rc4 10/11 PASS 0.15-0.42%, G03 1.28% at 85.5% edge, known-bad 13.19%; rc2 0.17-0.46%, G03 1.01% at 87.3%; V02 hue-only 0.007%, gate 0.42% |
| ORDER_PASS | tz_verify counts (14 / 15 / 17) | CONFIRMED | Per-run call sites at 27ba1d5 / 0873f38 / 3ee3568 onward |
| ORDER_PASS | Perf numbers (246 C7, 253 rc11) | CONFIRMED | Same figures in TZ_COMPLIANCE.md:74, TZ_DECISIONS P01 and CORRECTION_LOG #38 (FUNCTION_MATRIX X24 disagrees; see its row) |
| ORDER_PASS | Residual list vs ARENA open defers | CONFIRMED | X21 (:82), R-02 (:86), P-05/R-08/D-01/D-02/D-03/B7 (:87) |
| ORDER_PASS | Deferred structural residual (:85) | CONFIRMED | Matches every DEFERRED-STRUCTURAL ledger row (G07 visibility folded into S02) |
| ORDER_PASS | C4 Applied / Decided lists | CONFIRMED | Applied = the changed MET/MET-STATIC rows. The "Decided with evidence" list matches the ledger; the D03/G22/E05/A03 label gaps are counted in their TZ_DECISIONS rows |
| Gate | `i18n_truth_gate.py` | CONFIRMED | 12/12 locales PASS, rc 0 |
| Gate | `hardcoded_text_gate.py` and `--demo` | CONFIRMED | 0 hits, rc 0; demo OK, rc 0 |
| Gate | `visual_truth_gate.py` tzverify + known-bad | CONFIRMED | 10/11 PASS 0.15-0.42%; G03 FAIL 1.28%; magenta_corruption 13.19% FAIL; rc 1 as expected. Matches ORDER_PASS_REPORT.md:32, ARENA R0 and TZ_DECISIONS S03 |
| Gate | `user_data_guard.sh --demo` | CONFIRMED | demo OK, rc 0; no tls_udg dirs left in temp |
| Gate | `TLS_SKIP_REIMPORT=1 check.sh --static` | CONFIRMED | "Всё зелёное", 24 passed, 0 FAIL, rc 0; `git status --short` empty |

CONFIRMED=121 PARTIAL=15 FAKE=0
