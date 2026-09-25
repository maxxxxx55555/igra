# Round 10, HEAD c46d8a3, tag v8.0.0-rc10

Static verification only. Code and data were read at HEAD. History came from `git show`, `git blame` and
`git log -S`, and the python and bash gates were run locally. The Godot binary was not run. Runtime-only
numbers (bot, suite, tz_verify output, draw calls, the full check.sh count) are accepted when the code
does not contradict them. Tags rc1-rc10 resolve to 27ba1d5 / 5724544 / 5402640 / b8b20c0 / 3ee3568 /
4061f1b / 8c0e01c / 9936ab3 / 94af752 / c46d8a3. `git diff --name-only 9936ab3 HEAD` lists 7 docs files
only, so the code under test is the rc8 code. "n/m" = n of the m added non-doc lines (length >= 4, not
comments) of that commit still present in the same file at HEAD (script). Every ARENA hash exists and is
an ancestor of HEAD (`git merge-base --is-ancestor`).

| Source | Item | Verdict | Evidence |
|---|---|---|---|
| ARENA A | Header "17/17 closed; B7's legacy half deferred" | CONFIRMED | 16 rows cover 17 items (B9+B14 share a row) |
| ARENA A | B1 `5e1093b` | CONFIRMED | 45/45 |
| ARENA A | B2 `7034bcd` | CONFIRMED | 37/37 |
| ARENA A | B3 `afadb4b` | CONFIRMED | 50/50 |
| ARENA A | B4 `92934a7` (+ `ac877a5`) | CONFIRMED | 49/49 and 4/4 |
| ARENA A | B5 `fe7ef0e` | CONFIRMED | 68/71 (misses in attack_sim.gd wording); wipe_all_saves resets NG+ and deletes ng_plus_data.json (save_system.gd:586-590) |
| ARENA A | B6 `e9686d7` | CONFIRMED | 35/35 |
| ARENA A | B7 `bb662b4` + deferred legacy half | CONFIRMED | 21/21. Legacy branch trusts and re-signs a plain achievements.cfg (achievements_manager.gd:205-211); attack_sim.gd:89 locks it |
| ARENA A | B8 `1cf3aaf` | CONFIRMED | 30/30 |
| ARENA A | B9+B14 `36d44be` | CONFIRMED | 92/92 |
| ARENA A | B10 `cc1e0b3` | CONFIRMED | 54/54 |
| ARENA A | B11 `d7a0692` | CONFIRMED | 26/26 |
| ARENA A | B12 `c814621` | CONFIRMED | 26/26 |
| ARENA A | B13 `a36ac8b` | CONFIRMED | 57/57 |
| ARENA A | B15 `8c99689` | CONFIRMED | 40/42; misses are the later suite-runner rewrite |
| ARENA A | B16 `cb73c83` | CONFIRMED | 18/18 |
| ARENA A | Q1 `a0ec4ee` | CONFIRMED | 38/38 |
| ARENA A | B4 note (`ac877a5`) | CONFIRMED | 4/4; CORRECTION_LOG #8 cites it |
| ARENA B | P-01 `92934a7` | CONFIRMED | As B4 |
| ARENA B | P-03 / P-04 / P-06 / P-07 `9b7a46b` | CONFIRMED | 141/141; flashlight cfg signed and clamped 0..5 (flashlight_upgrade_manager.gd:148-176) |
| ARENA B | P-05 tamper `e9686d7` + wall-clock defer | CONFIRMED | Tamper fix present; wall clock is an inherent client limit |
| ARENA B | R-01 `2278cf9` | CONFIRMED | 13/13 |
| ARENA B | R-02 defer reason | CONFIRMED | integrity_guard.gd:83 checks only non-finite position and y <= -50 |
| ARENA B | R-08, D-01, D-02 inherent defers | CONFIRMED | Client-side limits |
| ARENA B | D-03 owner defer | CONFIRMED | release_export_check.py:37-40 fails on a committed encryption_key; passes in the static run |
| ARENA B | R-03 / D-04 `60a289b` | CONFIRMED | 41/41 |
| ARENA B | R-07 `cef6ae6` | CONFIRMED | 29/29 |
| ARENA B | C-08 `a453425` | CONFIRMED | 60/60; wired in check.sh static section |
| ARENA C | R0 `bafb740` + numbers | CONFIRMED | 113/113; bafb740 flips `importer="texture"` -> `"3d_texture"`; all 11 `luts/lut_*.png.import` are 3d_texture (pin check.sh:201). Gate this run: rc4 frames 0.15-0.42%, G03 1.28% |
| ARENA C | RENDERING_DIAGNOSIS (b), (d) | CONFIRMED | Covered by bafb740; ssao/ssil/ssr per tier in visual_quality.tres:9-12 |
| ARENA C | TG gates `5257745`, `4c6ca10` | CONFIRMED | 118/119 and 7/7 |
| ARENA C | CHALLENGE-01 `fe3007a` | CONFIRMED | 20/22; misses are the reworded phase-8 check (X22) |
| ARENA C | CHALLENGE-02 partial `c783544` | CONFIRMED | 10/10; residual is matrix X21 BUG and is in the open defers |
| ARENA C | CHALLENGE-03 `0f9685a` | CONFIRMED | settings_full.gd not tracked, 0 references |
| ARENA C | MISSED-00..05 | CONFIRMED | AL35 / AL50 / AL55 / AL57 / IN89 are WORKS |
| ARENA C | I18N `43c9ecd` / `21c6563` | CONFIRMED | 159/159 and 206/220 (misses are trailing-comma lines re-touched by ad051fc's key appends); truth gate 12/12 this run |
| ARENA D | SLOP 1-15, §2, §3 | CONFIRMED | 855a278 5/5, 1fcf157 3/3, bbdaa8e 11/11, d06fe48 16/16, 53353d5 13/13, 363add0 3/3, 7bbc0ca 1/1 (BLACK_FAIL_PCT 40.0, visual_truth_gate.py:50); 2948e23 holds (0 BTN_ONE_MORE_RUN refs) |
| ARENA Design | P1-P8 | CONFIRMED | 2a88503 2/2, c2dbeb4 82/88, 4e7560e 337/343 (i18n value edits), f9bbfd7 18/18, 24ceb68 36/39 (literal became BATTERY_PER_SKILL_LVL, player_3d.gd:1182-1186), 8f48faf 35/35, ee273ee 4/4 |
| ARENA | Open-defers list | CONFIRMED | P-05, R-08, D-01, D-02, D-03, B7 legacy half, R-02, X21 = every deferred row |
| ARENA | "No P0 is deferred" | CONFIRMED | R0, the only P0, is closed |
| TZ | Legend covers every verdict | CONFIRMED | 48 ledger rows; every verdict token (outside parentheses) is one of the 8 legend verdicts (script) |
| TZ | tz_verify "17 checks at rc5" | CONFIRMED | 19 `_check(` lines = def + 18 sites; :251 is the exclusive else of :247, so 17 per completed run. Same count gives 14 at rc1, 15 at rc2, 16 at rc4 |
| TZ | footstep probe exits 1 | CONFIRMED | _footstep_check.gd:12-14; check_surface_speeds counts missing or duplicate (sample, pitch) (footstep_system.gd:190-204) |
| TZ | A02 MET | CONFIRMED | FADE_TIME 2.0 (music_manager.gd:118) used at :209, :262-263; GDD.md:359 |
| TZ | A03 DECIDED | CONFIRMED | SPEED_FILE walk/jog/sprint, pitch 0.9/1.0/1.12 (footstep_system.gd:47-49); asphalt/puddle/glass single samples |
| TZ | A04 MET-STATIC | CONFIRMED | MiB: sfx 6.33 + one_shots 1.07 + (ambience 45.97 - wav_src 29.94) = 23.5; music 37.2 (+ ending_music 0.33); wav_src excluded in all 3 presets |
| TZ | A01 DEFERRED | CONFIRMED | default_bus_layout.tres: Master/Music/SFX/Voice/Ambient/UI/Hum |
| TZ | V02 MET | CONFIRMED | _HIT_FLASH_COLOR #c9a24a, original kept in meta and restored (base_monster.gd:663-690); P2b asserts the restore (suite :303-312) |
| TZ | V05 MET (desktop) | CONFIRMED | project.godot:296 = 2048; tz_verify checks the base setting (runner :110-112) |
| TZ | V05 DECIDED (mobile) | CONFIRMED | project.godot:297 `size.mobile=1024`; ledger now states it (TZ_COMPLIANCE.md:34). Quality of its DR reason: see TZ_DECISIONS V05-mobile |
| TZ | V01 MET-STATIC | CONFIRMED | day_night.gd has no environment writer |
| TZ | DECIDED group (D03, G01, G04, G09, G10, G13, G22, G27, G31-33, D02, S01, E05) | CONFIRMED | world_env_setup.gd:3-8, fps_mode=true (main_3d.tscn:61), REACH 3.2 (interactor.gd:24), drain 100/450 (player_3d.gd:96, note :92-95), battery.tres 35, combo 14/21/35 (:79-81, note :75-77), JOY_ZONE_RATIO 0.35 (:413), balance_sim 11x200 + 26x50 + 31x100 |
| TZ | GAP-OWNER rows (V03, N01, I02, T01) | CONFIRMED | assets/fonts has only -Regular files; the rest are owner text/credential actions |
| TZ | G02 / G03 / G06 MET | CONFIRMED | SPRINT_BOB_AMP 0.1, SPRINT_FOV_BONUS 5 (camera_follow_3d.gd:22-24), fov 80 (main_3d.tscn:57); run 272 = 170 x 1.6; checks bounded (runner :141-144) |
| TZ | G07 split | CONFIRMED | CROUCH_SPEED_MULT used :563, noise 0.4 x 0.3 (:542); CROUCH_VISIBILITY_MULT (:89) unread; capsule 1.6 |
| TZ | G08 MET / NEEDS-EYES | CONFIRMED | Colour (0.788,0.635,0.29) = c9a24a, angle 45, energy 24, range 16 (player_3d.tscn:179-184) |
| TZ | G12b MET | CONFIRMED | Threshold 20, intensity 0.35 (flashlight_stats.tres:11-12); cleared at level >= max (player_3d.gd:1140,1164); drain cut (:760); L5 spread check follows the > 0.01 check |
| TZ | G15 split | CONFIRMED | Capsule 1.6 (player_3d.tscn:9); attack box 1.4x0.8x3.4 |
| TZ | G16 MET | CONFIRMED | P2r calls respawn_after_death + Routes.restart_game = death_screen.gd:52-54; RESPAWN_HP_RATIO 0.5 (game_manager.gd:110) |
| TZ | G17 MET | CONFIRMED | _remove_with_backups (save_system.gd:556-560) on main and every slot; game_manager.gd:172-173; tz_verify seeds .bak/.bak2/.bak3 |
| TZ | G18 / G19 MET-STATIC | CONFIRMED | Script: all 11 GDD types via AI_TO_ROSTER + sharpshooter/brute/burner/rotter/hound/tvar + beast 800/40 equal GDD.md:168-181; Shadow 30/15 (shadow_3d.gd:13,16) |
| TZ | G20 MET-STATIC | CONFIRMED | boss_3d.gd:48-50 0.70/0.30, BEAM_DAMAGE 40 (:9) |
| TZ | DEFERRED group (G21, G25, G26, S02, S04-hide, C03, P01) | CONFIRMED | No scene instances weapon_manager or hiding_spot; take_photo has no caller; melee sphere 2.7 |
| TZ | G24 DECIDED | CONFIRMED | district_manager.gd:30-42; P2q asserts both sides (suite :775-778) |
| TZ | G28 / D04 GAP-OWNER | CONFIRMED | power_grid.gd:88-92 routes the win through FinaleDirector, trigger_win only as fallback |
| TZ | G34 split | CONFIRMED | BUNKER_SECRET_ID (progress_tracker.gd:128); P2q (suite :785); endings_sim "all 5 GDD endings reachable" this run |
| TZ | S03 MET | CONFIRMED | Shader keeps COLOR.rgb; pulse on 0-1 noise scale; check needs r > 0.4 and edge warmth +0.03. Edge warmth recomputed from committed frames: rc2 -0.015 -> 0.065 (ledger -0.015 -> 0.066) |
| TZ | S04 MET-STATIC | CONFIRMED | SEARCH_TIME 10 / RADIUS 5 (base_monster.gd:45-46); P2q (suite :768) |
| TZ | E03/T02 split | CONFIRMED | Both cooldowns 3600 (ad_service.gd:27,31); skip_bonus_coins has no caller; P2q (:766) |
| TZ | C04 MET | CONFIRMED | ru "Слепые псы"; key in 13 locale files |
| TZ | C06 MET | CONFIRMED | Presets 0.012/0.013/0.014/0.015 (visual_quality.tres:9-12); fog_setup no longer writes density |
| TZ | P01 DEFERRED / P02 NEEDS-MEASUREMENT | CONFIRMED | Honest reasons |
| TZ | Footer "Open GAP-DEV rows: 0" | CONFIRMED | All 54 audit GAP-DEV/GAP-OWNER IDs appear in the ledger (script) |
| TZ_DECISIONS | S03 reason | CONFIRMED | Band 260-345 (visual_truth_gate.py:52). Hue-band hits, median hue 332/319/333/332, edge share 87.3/97.8/85.5/70.1% (rc2 G03, rc2 S03, rc4 G03, rc4 S03) |
| TZ_DECISIONS | G18 / G19 lines 168-181 | CONFIRMED | Table header through the Architect row |
| TZ_DECISIONS | G28 / D04 reason (round-9 fix) | CONFIRMED | Now says GDD.md:3-7 only ranks the GDD above appendices; matches the text. §12.3 Act III boss (GDD.md:337-341) accurate |
| TZ_DECISIONS | I02 reason (round-9 fix) | CONFIRMED | 1301 keys in each of the 13 data/i18n/*.json |
| TZ_DECISIONS | V05-mobile reason | PARTIAL | Labelled DR-3 (TZ_DECISIONS.md:54), but DR-3 requires a *measured* rejection of the TZ value, "Opinion does not count" (EXEC_PLAN.md:69). The cited measurement (CORRECTION_LOG #4, desktop) shows 1024 = 2048, which rejects nothing, and P01 is a draw-call count, which the shadow atlas resolution does not change. No mobile measurement of 2048 exists |
| TZ_DECISIONS | G09 / G13 line cites | CONFIRMED | player_3d.gd:92-95 drain note, :75-77 combo note |
| TZ_DECISIONS | Other cited GDD lines | CONFIRMED | 22, 52-59, 68, 76, 119, 261, 317, 341, 359-362, 613-616, 652 hold the quoted text |
| TZ_DECISIONS | All other non-MET reasons | CONFIRMED | Each non-MET ledger row has a matching, code-consistent row |
| Fix | `0873f38` S03 / G12b / A03 / G17 | CONFIRMED | Parent: shader forced BG_DEEP RGB (edge warmth fails), clear at bonus >= 1.0 with L5 = 0.5 (L5 spread fails), probe quit(0) unconditionally, wipe removed .bak only (.bak2/.bak3 check fails) |
| Fix | `5402640` upgrades across respawn | CONFIRMED | Reapply from scene base (player_3d.gd:239-248); parent had base 1.0/8 m and no reapply, so P2r `want_energy >= 20` and `maxed` fail |
| Fix | `b8b20c0` per-run upgrades, drain, fog, hit flash | CONFIRMED | "flashlight" key at save_system.gd:293,335,367,490,543; drain cut :760; P2r measures reset and drain |
| Fix | `5cf3b27` guard around QA runs | PARTIAL | Wired paths are correct (check.sh:272-275, headless_suite:25-28, autoplay_bot:21-24). But check.sh:338 and :344 (and RC_OWNER_CHECKLIST.md:298) tell the owner to launch perf_check_scene / audio_truth_gate_scene directly with `--windowed`; both call Routes.start_game() (_perf_check_runner.gd:21, audio_truth_gate.gd:62) -> SaveSystem.reset_all() (game_manager.gd:102) with no shell or in-process snapshot and no TLS_UDG_GUARDED refusal. The same hole 9936ab3 closed for tz_verify, still open on the only path that measures P01 |
| Fix | `3ee3568` lost-snapshot hole, in-process snapshot, measured drain | CONFIRMED | 5cf3b27's functions: lost snapshot -> restore rc 0 and every profile file deleted (bash test); HEAD refuses. Suite snapshots first (runner :115), tz runner before start_game (:83) |
| Fix | `4061f1b` abort on failed snapshot | CONFIRMED | 3ee3568's functions under the HEAD demo -> "demo FAIL: snapshot succeeded without a dir" |
| Fix | `8c0e01c` trap exit code, partial cleanup, wrapper | CONFIRMED | 4061f1b's functions under the HEAD demo -> "demo FAIL: partial snapshot left in temp"; 8c0e01c's functions -> demo OK; every EXIT trap is `udg_restore \|\| exit 97` |
| Fix | `9936ab3` tz_verify refuses unguarded launch | CONFIRMED | _tz_verify_runner.gd:71-74 quits 2 before snapshot and start_game; wrapper exports TLS_UDG_GUARDED after udg_snapshot (tz_verify:16-19); mode 100755 (8c0e01c: 100644) |
| Fix | `94af752` round-8 docs | CONFIRMED | Docs only; its 3 fixes hold at HEAD |
| Fix | `c46d8a3` round-9 docs | CONFIRMED | Docs only (7 files); each round-9 PARTIAL is addressed (V05 split, G28 cite, I02 1301, legend entries). Content issues in two of the new texts are the V05-mobile and legend rows |
| Guard | user_data_guard.sh | CONFIRMED | Restore refuses a missing or incomplete snapshot, removes only unlisted files, verifies with cmp; a failed copy drops the partial dir. Game writes outside top level + saves/ only via the uncalled take_photo |
| Guard | tz_verify wrapper | CONFIRMED | set -uo pipefail; resolve Godot, snapshot, EXIT trap, INT/TERM -> 130, `timeout 300` |
| Guard | _user_data_snapshot.gd | CONFIRMED | take() returns null on any unreadable file; restore() refuses non-Dictionary; no save-on-quit hook in game scripts (only PREDELETE in player_3d.gd:688, no I/O) |
| Guard | check.sh / bot / suite / runner wiring | CONFIRMED | Snapshot failure exits before any engine gate; the explicit udg_restore (check.sh:347) clears UDG_ACTIVE so the trap keeps `exit $FAIL`; suite _finish restores on every path including hard timeout |
| CORRECTION_LOG | Header "Oldest first" | CONFIRMED | git blame order: 648cfd2/27ba1d5/0873f38 (1-21) -> 5402640 -> b8b20c0 -> 3ee3568 -> 4061f1b -> 8c0e01c -> 9936ab3 -> 94af752 -> c46d8a3 (#37) |
| CORRECTION_LOG | #1-#7 | CONFIRMED | bafb740 importer flip; 37581d7 .import commit (528 files); 2547fff fog; 0d3d533 X22/X20/footer |
| CORRECTION_LOG | #8 | CONFIRMED | `git log -S _ensure_playing` first hit 9fc8665 |
| CORRECTION_LOG | #9-#14 | CONFIRMED | d06fe48 body "6." item; ad051fc "all PASS visual_truth_gate"; ae410b9 "C06 ultra tier 0.66% FAIL" vs rc1 S03 0.66% (re-run) |
| CORRECTION_LOG | #15 | CONFIRMED | Re-run: rc1 frames 0.17-0.66% (S03 fails), rc2 0.17-0.46%, G03 1.01% |
| CORRECTION_LOG | #16-#21 | CONFIRMED | Match 0873f38 parent code; tz_verify 14 at rc1, 15 at rc2 |
| CORRECTION_LOG | #22-#28 | CONFIRMED | 5402640 parent base 1.0/8 m; b8b20c0 diffs match; rc4 tag peels to b8b20c0 |
| CORRECTION_LOG | #29-#35 | CONFIRMED | 5cf3b27 message; b8b20c0 "42 green"; 3ee3568 unchecked `cp -p` (:37); 3ee3568 S03 "87–98%", 4061f1b "85–98%"; 4061f1b trap without exit code; 8c0e01c "320–330" and wrapper 100644 |
| CORRECTION_LOG | #36 | CONFIRMED | 94af752 diff fixes the round-7 row, G18/G19 range and R-02 residual |
| CORRECTION_LOG | #37 | CONFIRMED | c46d8a3 diff makes each stated change |
| MATRIX | Status recount by script | CONFIRMED | 114 rows, 114 unique IDs: WORKS 99, FIXED 6, CTH 6, BDL 1, PARTIAL 1, BUG 1, UNTESTED 0 = footer (FUNCTION_MATRIX.md:153) |
| MATRIX | Header and totals | CONFIRMED | AL01-AL58 (58 = project.godot autoloads, names match), IN58-IN89 (32; 29 live actions; the 3 FIXED rows shop_toggle/close_screen/settings are absent from project.godot), X01-X24 |
| MATRIX | Status legend | PARTIAL | FIXED and PARTIAL are now defined, but the FIXED definition says "commit stated in the row" (FUNCTION_MATRIX.md:24) and none of the 6 FIXED rows (:98, :115, :117, :133, :144, :149) contains a commit hash; X08/X19 give arena labels, the IN rows and X22 give nothing |
| MATRIX | Open list (X21 BUG, X20 PARTIAL) | CONFIRMED | Matches the only BUG and PARTIAL rows |
| ORDER_PASS | Candidate line | CONFIRMED | Last C8 row names rc9 as verified and "rc10: docs only" = HEAD tag, same pattern as rows 1-8 |
| ORDER_PASS | check.sh counts (42 / 44 / static 24) | CONFIRMED | Static 24 this run; 20 run_gate calls - 2 windowed skips = 18; 23+1+18 = 42, 24+1+18+1 = 44 |
| ORDER_PASS | Verifier rounds 1-9 figures | CONFIRMED | 79/7/3, 128/6/0, 145/14/0, 186/12/0, 132/4/0, 94/10/0, 105/3/0, 106/3/0, 114/4/0 = each committed CLOSURE_VERIFICATION_INTERNAL totals line |
| ORDER_PASS | Round-9 row, "nothing outside docs/ changed since 9936ab3" | CONFIRMED | `git diff --name-only 9936ab3 HEAD` = 7 docs files |
| ORDER_PASS | Correction count and ranges | CONFIRMED | 37 rows; per-round split matches git blame |
| ORDER_PASS | Visual row, rc2 evidence, V02 note | CONFIRMED | This run: rc4 10/11 PASS 0.15-0.42%, G03 1.28% at 85.5% edge, known-bad 13.19%; rc2 0.17-0.46%, G03 1.01% at 87.3%; V02 hue-only 0.007%, gate 0.42% |
| ORDER_PASS | tz_verify counts (14 / 15 / 17) | CONFIRMED | Per-run call sites at 27ba1d5 / 0873f38 / 3ee3568+ |
| ORDER_PASS | Residual list vs ARENA open defers | CONFIRMED | X21 (:81), R-02 (:85), P-05/R-08/D-01/D-02/D-03/B7 (:86) |
| ORDER_PASS | Deferred structural residual (:84) | CONFIRMED | Matches every DEFERRED-STRUCTURAL ledger row (G07 visibility folded into S02) |
| ORDER_PASS | C4 "Applied" list | CONFIRMED | Matches MET/MET-STATIC rows; V05's applied half is desktop 2048 |
| Gate | `i18n_truth_gate.py` | CONFIRMED | 12/12 locales PASS, rc 0 |
| Gate | `hardcoded_text_gate.py` and `--demo` | CONFIRMED | 0 hits rc 0; demo OK rc 0 |
| Gate | `visual_truth_gate.py` tzverify + known-bad | CONFIRMED | 10/11 PASS 0.15-0.42%; G03 FAIL 1.28%; magenta_corruption 13.19% FAIL; rc 1 as expected. Matches ORDER_PASS :32, ARENA R0 and TZ_DECISIONS S03 |
| Gate | `user_data_guard.sh --demo` | CONFIRMED | demo OK, rc 0; no tls_udg dirs left in temp |
| Gate | `TLS_SKIP_REIMPORT=1 check.sh --static` | CONFIRMED | "Всё зелёное", 24 passed, 0 FAIL, rc 0. `git status --short`: only the pre-existing ` M project.godot` |

CONFIRMED=121 PARTIAL=3 FAKE=0
