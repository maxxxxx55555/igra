# Round 9, HEAD 94af752, tag v8.0.0-rc9

Static verification only. Code and data were read at HEAD, history came from `git show`/`git blame`/`git log -S`,
and the python and bash gates were run locally. The Godot binary was not run. Runtime-only numbers
(bot, suite, tz_verify output, draw calls, the full check.sh count) are accepted when the code does
not contradict them. Tags rc1-rc9 resolve to 27ba1d5 / 5724544 / 5402640 / b8b20c0 / 3ee3568 /
4061f1b / 8c0e01c / 9936ab3 / 94af752. 94af752 changes docs only (5 files), so the code under test is
the rc8 code. "n/m lines" = n of the m added non-doc lines (length >= 4, not comments) of that commit
still present in the same file at HEAD (script). Every ARENA hash exists and is an ancestor of HEAD.

| Source | Item | Verdict | Evidence |
|---|---|---|---|
| ARENA A | Header "17/17 closed; B7's legacy-achievements half deferred" | CONFIRMED | 16 rows cover 17 items (B9+B14 share a row) |
| ARENA A | B1 finale boss timing `5e1093b` | CONFIRMED | 45/45 |
| ARENA A | B2 document id `7034bcd` | CONFIRMED | 37/37 |
| ARENA A | B3 skill bonuses `afadb4b` | CONFIRMED | 50/50 |
| ARENA A | B4 progress_hmac `92934a7` (+`ac877a5`) | CONFIRMED | 49/49 and 4/4 |
| ARENA A | B5 NG+ bypasses `fe7ef0e` | CONFIRMED | 69/71 (2 misses are attack_sim.gd rewording); wipe_all_saves resets NG+ and deletes ng_plus_data.json (save_system.gd:575-592) |
| ARENA A | B6 daily signing `e9686d7` | CONFIRMED | 35/35 |
| ARENA A | B7 `bb662b4` payout half + deferred legacy half | CONFIRMED | 21/21. Legacy branch still trusts and re-signs a plain achievements.cfg (achievements_manager.gd:206-211); attack_sim.gd:89 locks it |
| ARENA A | B8 kills pay wallet `1cf3aaf` | CONFIRMED | 30/30 |
| ARENA A | B9+B14 atomic try_add `36d44be` | CONFIRMED | 92/92 |
| ARENA A | B10 district-enter save `cc1e0b3` | CONFIRMED | 54/54 |
| ARENA A | B11 district lock `d7a0692` | CONFIRMED | 26/26 |
| ARENA A | B12 streetlight event once `c814621` | CONFIRMED | 26/26 |
| ARENA A | B13 import/autosave `a36ac8b` | CONFIRMED | 57/57 |
| ARENA A | B15 fall-recovery net `8c99689` | CONFIRMED | 40/42; misses are the later suite-runner rewrite |
| ARENA A | B16 offline player `cb73c83` | CONFIRMED | 18/18 |
| ARENA A | Q1 heartbeat `a0ec4ee` | CONFIRMED | 38/38 |
| ARENA A | B4 note (`ac877a5` signature fix) | CONFIRMED | 4/4; CORRECTION_LOG row exists |
| ARENA B | P-01 checksum bypass `92934a7` | CONFIRMED | Present (see B4) |
| ARENA B | P-03 / P-04 / P-06 / P-07 `9b7a46b` | CONFIRMED | 141/141; flashlight cfg signed and clamped 0..5 (flashlight_upgrade_manager.gd:150-176) |
| ARENA B | P-05 tamper `e9686d7` + wall-clock defer | CONFIRMED | Tamper fix present; wall clock is an inherent client limit |
| ARENA B | R-01 watchdog `2278cf9` | CONFIRMED | 13/13 |
| ARENA B | R-02 defer reason | CONFIRMED | integrity_guard.gd:83 covers only non-finite position and y <= -50 |
| ARENA B | R-08, D-01, D-02 inherent defers | CONFIRMED | Client-side limits |
| ARENA B | D-03 owner defer | CONFIRMED | release_export_check passes in the static run; `.signing/` gitignored (.gitignore:85), no keystore tracked |
| ARENA B | R-03 / D-04 `60a289b` | CONFIRMED | 41/41 |
| ARENA B | R-07 LAN `cef6ae6` | CONFIRMED | 29/29 |
| ARENA B | C-08 export gate `a453425` | CONFIRMED | 60/60; wired at check.sh:255 |
| ARENA C | R0 `bafb740` + numbers | CONFIRMED | 113/113; 11 `assets/textures/luts/lut_*.png.import` are `3d_texture`, pin at check.sh:201. Gate: rc4 frames 0.15-0.42%, G03 1.28% (this run). Unused `grading/lut_night.png.import` is `texture` (outside the pinned glob, no reader) |
| ARENA C | RENDERING_DIAGNOSIS (b), (d) | CONFIRMED | Covered by bafb740; ssao/ssil/ssr per tier in visual_quality.tres:9-12 |
| ARENA C | TG gates `5257745`, `4c6ca10` | CONFIRMED | 118/119 and 7/7 |
| ARENA C | CHALLENGE-01 `fe3007a` | CONFIRMED | 20/22; misses are the reworded phase-8 check (X22) |
| ARENA C | CHALLENGE-02 partial `c783544` | CONFIRMED | 10/10; residual is matrix X21 BUG |
| ARENA C | CHALLENGE-03 `0f9685a` | CONFIRMED | settings_full.gd absent, 0 references |
| ARENA C | MISSED-00..05 | CONFIRMED | AL35/AL50/AL55/AL57/IN89 WORKS |
| ARENA C | I18N `43c9ecd` / `21c6563` | CONFIRMED | 159/159 and 219/220; truth gate 12/12 |
| ARENA D | SLOP items 1-15, §2, §3 (9 rows) | CONFIRMED | 855a278 5/5, 1fcf157 3/3, bbdaa8e 11/11, d06fe48 16/16, 53353d5 13/13, 363add0 3/3, 7bbc0ca 1/1 (BLACK_FAIL_PCT 40.0, visual_truth_gate.py:50); 2948e23 removal holds (0 BTN_ONE_MORE_RUN refs) |
| ARENA Design | P1-P8 (7 rows) | CONFIRMED | 2a88503 2/2, c2dbeb4 82/88, 4e7560e 337/343 (misses are later i18n value edits), f9bbfd7 18/18, 24ceb68 36/39 (misses: a literal became BATTERY_PER_SKILL_LVL, player_3d.gd:1186; composition via refresh_battery_max kept, skill_tree_manager.gd:262-263), 8f48faf 35/35, ee273ee 4/4 |
| ARENA | "Open defers" list | CONFIRMED | P-05, R-08, D-01, D-02, D-03, B7 legacy half, R-02, X21 = every deferred row (ARENA_CLOSURE.md:99-102) |
| ARENA | "No P0 is deferred" | CONFIRMED | The only P0 (R0) is closed |
| TZ legend | Every verdict in the legend | CONFIRMED | 48 ledger rows, all verdict tokens in the legend (script; qualifiers in parentheses only) |
| TZ sources | tz_verify "17 checks at rc5" | CONFIRMED | 19 `_check(` lines = def + 18 sites; :251 is the exclusive else of :247, so 17 per run (rc1 14, rc2 15, rc4 16, rc5 17 by the same count) |
| TZ sources | footstep probe exits 1 | CONFIRMED | `_footstep_check.gd:13-14` quits 1 on fails; check_surface_speeds counts missing or duplicate (sample, pitch) keys (footstep_system.gd:190-204) |
| TZ | A02 MET | CONFIRMED | FADE_TIME 2.0 (music_manager.gd:118) used at :209/:262-263; GDD.md:359 |
| TZ | A03 DECIDED | CONFIRMED | SPEED_FILE walk/jog/sprint, pitch 0.9/1.0/1.12 (footstep_system.gd:47-49); concrete/wood/metal have 3 files; asphalt/puddle/glass single samples |
| TZ | A04 MET-STATIC | CONFIRMED | MiB: sfx 6.3 + one_shots 1.1 + (ambience 46.0 - wav_src 29.9) = 23.5; music 37.2; wav_src in all 3 exclude_filters |
| TZ | A01 DEFERRED | CONFIRMED | default_bus_layout.tres buses Master/Music/SFX/Voice/Ambient/UI/Hum |
| TZ | V02 MET | CONFIRMED | _HIT_FLASH_COLOR #c9a24a + meta restore (base_monster.gd:663-690); b8b20c0^ set pure white and restored a duplicate of the flash |
| TZ | V05 MET | PARTIAL | Desktop 2048 holds (project.godot:296, tz_verify:112). But project.godot:297 sets `directional_shadow/size.mobile=1024`, and Android is the primary platform (GDD.md:19) of a section titled for the mobile renderer (GDD.md:314-317, no mobile exception for the moon shadow). The runner comment admits it (_tz_verify_runner.gd:110); TZ_COMPLIANCE.md:34 and TZ_DECISIONS.md:27 do not |
| TZ | V01 MET-STATIC | CONFIRMED | day_night.gd has no environment writer |
| TZ | DECIDED group (D03, G01, G04, G09, G10, G13, G22, G27, G31-33, D02, S01, E05) | CONFIRMED | fps_mode=true (main_3d.tscn:61), REACH 3.2 (interactor.gd:24), drain 100/450 (player_3d.gd:95, note :91-94), battery.tres 35, combo 14/21/35 (:79-81, note :75-77), JOY_ZONE_RATIO 0.35 (:413), powered_by graph = the stated tree, balance_sim 11x200 + 26x50 + 31x100 |
| TZ | GAP-OWNER rows (V03, N01, I02, T01) | CONFIRMED | assets/fonts has only -Regular files; the others are owner text/credential actions |
| TZ | G02 / G03 / G06 MET | CONFIRMED | SPRINT_BOB_AMP 0.1, SPRINT_FOV_BONUS 5 (camera_follow_3d.gd:22-24); run 272 = 170 x 1.6 (player_stats.tres:6-7); checks bounded (tz_verify:141-144) |
| TZ | G07 split | CONFIRMED | CROUCH_SPEED_MULT 0.4 (:87, used :563), noise 0.4 x 0.3 (:542); CROUCH_VISIBILITY_MULT (:89) unread; capsule 1.6 |
| TZ | G08 MET / NEEDS-EYES | CONFIRMED | Flashlight colour (0.788,0.635,0.29) = c9a24a, angle 45, energy 24, range 16 (player_3d.tscn:179-184). GDD's flashlight shadow-size clause (GDD.md:77) is not scored by the row; no false claim |
| TZ | G12b MET | CONFIRMED | Threshold 20 (flashlight_stats.tres:11); cleared at level >= max (player_3d.gd:1140,1164); drain cut (:760) with stability 0.1-0.5 = GDD.md:90-94; P2r measures the drop through _update_battery; L5 spread check follows the > 0.01 check (non-vacuous) |
| TZ | G15 split | CONFIRMED | Capsule height 1.6 (player_3d.tscn:9); attack box 1.4x0.8x3.4 (player_3d.gd:311) |
| TZ | G16 MET | CONFIRMED | P2r drives respawn_after_death + Routes.restart_game = death_screen.gd:53-54; RESPAWN_HP_RATIO 0.5 (game_manager.gd:110) |
| TZ | G17 MET | CONFIRMED | _remove_with_backups (save_system.gd:556-560) on main + every slot; wipe -> reset_all -> FlashlightUpgradeManager.from_dict({}) (:367); game_manager.gd:172-173; tz_verify seeds .bak/.bak2/.bak3 and filters every tls_savegame path |
| TZ | G18 / G19 MET-STATIC | CONFIRMED | All 10 table types via aliases + Tvar 1200/40 + boss 800/40 equal GDD.md:170-181; Shadow 30/15 (shadow_3d.gd:13,16) |
| TZ | G20 MET-STATIC | CONFIRMED | boss_3d.gd:48-50 0.70/0.30, BEAM_DAMAGE 40 (:9); GDD.md:190-192 |
| TZ | DEFERRED group (G21, G25, G26, S02, S04-hide, C03, P01) | CONFIRMED | No scene/script instances weapon_manager or hiding_spot (consumers only); take_photo has no caller; no enemy reads a visibility factor; melee sphere 2.7 (player_3d.gd:326) |
| TZ | G24 DECIDED | CONFIRMED | NO_RETURN_DISTRICT substation = D10; gate needs indices 0-8 FULL (district_manager.gd:30-42); P2q asserts both sides (suite :770-782) |
| TZ | G28 / D04 GAP-OWNER | CONFIRMED | power_grid.gd:88-92 routes the win through FinaleDirector; trigger_win only as fallback |
| TZ | G34 split | CONFIRMED | BUNKER_SECRET_ID secret_power_station_02 (progress_tracker.gd:128); P2q asserts (suite :785-787); endings_sim "all 5 GDD endings reachable" (this run) |
| TZ | S03 MET | CONFIRMED | Shader keeps COLOR.rgb; pulse on the 0-1 noise scale; tz_verify:145 needs vignette r > 0.4 and edge warmth +0.03 |
| TZ | S04 MET-STATIC | CONFIRMED | SEARCH_TIME 10 / RADIUS 5 (base_monster.gd:45-46) = GDD.md:215; P2q asserts (suite :768) |
| TZ | E03/T02 split | CONFIRMED | Both cooldowns 3600 (ad_service.gd:27,31); skip_bonus_coins (:111) has no caller; P2q asserts (:766) |
| TZ | C04 MET | CONFIRMED | ru "Слепые псы", en "Blind Dogs"; key in 13 locale files |
| TZ | C06 MET | CONFIRMED | fog_setup.gd has no density write (b8b20c0^ wrote 0.015 at :16); presets 0.012/0.013/0.014/0.015; weather_vfx.gd fog writes target /root/WorldEnvironment (null in play, :15) |
| TZ | P02 NEEDS-MEASUREMENT | CONFIRMED | Honest reason |
| TZ | Footer "Open GAP-DEV rows: 0" | CONFIRMED | All 54 audit GAP-DEV/GAP-OWNER IDs appear in the ledger (script) |
| TZ_DECISIONS | S03 reason (hue band, medians, edge share) | CONFIRMED | Band 260-345 (visual_truth_gate.py:52). PIL HSV as the gate: medians 332/319/333/332 (rc2 G03, rc2 S03, rc4 G03, rc4 S03), inside the stated 319-335; left/right 15% share 87.3/97.8/85.5/70.1% |
| TZ_DECISIONS | G18 / G19 line reference (round-8 fix) | CONFIRMED | Now GDD.md:168-181 = table header through the Architect row |
| TZ_DECISIONS | G28 / D04 reason | PARTIAL | TZ_DECISIONS.md:14 cites `GDD.md:3-6` for "the file wins over its own less-specific lines". GDD.md:3-7 says only that the GDD prevails over its appendices (ART_UI_STYLE, UI_SPEC, GDD_SUPPLEMENT); it has no specific-over-general rule. The §12.3 half (GDD.md:337-340, boss in Act III) and GDD:119 are accurate |
| TZ_DECISIONS | I02 reason | PARTIAL | TZ_DECISIONS.md:16 gives the real count as "1291 keys x 13 locales" for the owner to write into the GDD; every data/i18n/*.json has 1301 keys at HEAD |
| TZ_DECISIONS | Other cited GDD lines | CONFIRMED | 22, 52-59, 68, 76, 119, 261, 317, 359-362, 613-616, 652 all hold the quoted text |
| TZ_DECISIONS | All other non-MET reasons | CONFIRMED | Every non-MET ledger row has a matching, code-consistent reason |
| Fix | `0873f38` S03 / G12b / A03 / G17 | CONFIRMED | Pre-fix: shader forced BG_DEEP RGB (edge warmth check fails), flicker cleared only at bonus >= 1.0 with L5 = 0.5 (spread_l5 check fails), probe quit 0 unconditionally, wipe removed only .bak (seeded .bak2/.bak3 check fails) |
| Fix | `5402640` upgrades across respawn | CONFIRMED | _ready reapplies from scene base (player_3d.gd:239-245); 5402640^ used energy 1.0 / range 8 and had no reapply, so P2r's `want_energy >= 20` and maxed checks fail there |
| Fix | `b8b20c0` per-run upgrades, drain, fog, hit flash | CONFIRMED | "flashlight" key on save/load/slot/reset (save_system.gd:293,335,367,490,543); drain cut at :760; fog_setup and hit flash as above. Pre-rc4 saves without the key keep the in-memory levels (`data.get("flashlight", to_dict())`, :335), a migration choice, not a leak on new saves |
| Fix | `5cf3b27` guard wiring | CONFIRMED | check.sh:272-275, headless_suite:25-28, autoplay_bot:21-24, tz_verify:15-18 |
| Fix | `3ee3568` in-process snapshot + measured drain | CONFIRMED | Suite snapshots first (runner:115), tz runner before start_game (:83); P2r measures the battery drop; b8b20c0 P2r read the field (:843) |
| Fix | `4061f1b` abort on failed snapshot | CONFIRMED | check.sh:273, bots `|| exit 99`, suite :116-119, tz runner :84-87. Mutation: 3ee3568's functions under the HEAD demo -> "demo FAIL: snapshot succeeded without a dir" |
| Fix | `8c0e01c` trap exit code, partial cleanup, demo | CONFIRMED | `trap "f \|\| exit 97" EXIT; exit 0` with failing f gives 97, passing f keeps 5, TERM gives 130 (bash test). Mutation: 4061f1b's functions under the HEAD demo -> "demo FAIL: partial snapshot left in temp" |
| Fix | `9936ab3` tz_verify refuses unguarded launch | CONFIRMED | _tz_verify_runner.gd:71-74 quits 2 before the snapshot and start_game; wrapper exports TLS_UDG_GUARDED after udg_snapshot (tz_verify:16-19); mode 100755 (8c0e01c had 100644) |
| Fix | `94af752` round-8 docs | CONFIRMED | Docs only; each of the 3 round-8 PARTIALs is fixed in the diff |
| Guard | user_data_guard.sh | CONFIRMED | No new defects: restore refuses a missing or incomplete snapshot; removes only unlisted files; failed copy drops the partial dir. Covers top level + saves/ only (user://screenshots/ is written only by the uncalled take_photo) |
| Guard | tz_verify wrapper | CONFIRMED | set -uo pipefail, snapshot before export and launch, restore trap `\|\| exit 97`, INT/TERM -> 130 -> EXIT trap, `timeout 300` |
| Guard | _user_data_snapshot.gd | CONFIRMED | null on unreadable file; restore refuses non-Dictionary; no save-on-quit hook in game scripts |
| Guard | check.sh / bot / suite wiring | CONFIRMED | Final explicit udg_restore clears UDG_ACTIVE, so the EXIT trap keeps `exit $FAIL`; snapshot failure exits before any engine gate |
| CORRECTION_LOG | Header "Oldest first" | CONFIRMED | git blame: rows 1-14 648cfd2/27ba1d5/0873f38 (#8 edit) -> 0873f38 (15-21) -> 5402640 (22) -> b8b20c0 (23-28) -> 3ee3568 (29-31) -> 4061f1b (32-33) -> 8c0e01c (34) -> 9936ab3 (35) -> 94af752 (36) |
| CORRECTION_LOG | #1-#7 | CONFIRMED | bafb740 LUT fix; 37581d7 .import commit; 2547fff fog; 0d3d533 X22/X20; 0d3d533^ rows recount 61 WORKS / 40 UNTESTED vs footer 43 |
| CORRECTION_LOG | #8 | CONFIRMED | `_ensure_playing` first appears in 9fc8665 (`git log -S`); c00f118 is docs only |
| CORRECTION_LOG | #9-#14 | CONFIRMED | d06fe48 body item "6." = btn_d; ad051fc "all PASS visual_truth_gate" while its V02 frame is 0.59% hue-only; ae410b9 "C06 ultra tier 0.66% FAIL" while rc1 S03 is the 0.66% frame |
| CORRECTION_LOG | #15 | CONFIRMED | rc1 frames 0.17-0.66% (S03 FAIL); rc2 frames 0.17-0.46%, G03 1.01% (this run) |
| CORRECTION_LOG | #16-#21 | CONFIRMED | Match 0873f38 pre-fix code (noise / 10.4 gives 0.08 at RUN 0.8); tz_verify 14 at rc1, 15 at rc2; matrix 58 AL + 32 IN + 24 X |
| CORRECTION_LOG | #22-#28 | CONFIRMED | 5402640^ base 1.0 / 8 m; b8b20c0 diffs match; rc4 tag peels to b8b20c0 |
| CORRECTION_LOG | #29-#35 | CONFIRMED | b8b20c0 P2r read the field; 5cf3b27 message "only removes files the run itself created"; b8b20c0 message "42 green"; 4061f1b^ unchecked cp; 4061f1b demo mktemp unchecked and trap without exit code; 4061f1b S03 "85-98%"; 8c0e01c S03 "hue 320-330" and wrapper 100644 |
| CORRECTION_LOG | #36 | CONFIRMED | 94af752 diff fixes the round-7 row, the G18/G19 range and the R-02 residual; the compile gate loads every .gd (_compile_gate.gd:49-51) |
| MATRIX | Status recount by script | CONFIRMED | 114 rows, no duplicate IDs: WORKS 99, FIXED 6, CTH 6, BDL 1, PARTIAL 1, BUG 1, UNTESTED 0 = footer (FUNCTION_MATRIX.md:153) |
| MATRIX | Spine/extra header and totals | CONFIRMED | AL01-AL58, IN58-IN89, X01-X24 = 58 + 32 + 24; project.godot 58 autoloads and 29 input actions; the 3 FIXED IN rows (IN67 shop_toggle, IN84 close_screen, IN86 settings) are absent from project.godot |
| MATRIX | Status legend | PARTIAL | The legend (FUNCTION_MATRIX.md:21-25) defines WORKS, BUG, CANNOT-TEST-HEADLESS, BY-DESIGN-LIMIT and UNTESTED only; FIXED (6 rows) and PARTIAL (X20) are used and counted in the footer but not defined |
| ORDER_PASS | Candidate line (:4) | CONFIRMED | Last C8 row names rc9 = HEAD tag |
| ORDER_PASS | check.sh counts (42 / 44 / static 24) | CONFIRMED | Static 24 at HEAD (this run); 5402640..HEAD adds one static ok (guard demo); 20 run_gate calls, 2 windowed skips: 23+1+18 = 42, 24+1+18+1 = 44 |
| ORDER_PASS | Verifier rounds 1-8 figures | CONFIRMED | 79/7/3, 128/6/0, 145/14/0, 186/12/0, 132/4/0, 94/10/0, 105/3/0, 106/3/0 match each committed CLOSURE_VERIFICATION_INTERNAL |
| ORDER_PASS | Round-7 row (fixed in round 8) | CONFIRMED | Now states the wrong premise and cites CORRECTION_LOG 36 |
| ORDER_PASS | Correction count and ranges (:67-68) | CONFIRMED | 36 rows; per-round split matches git blame. "two wrong claims in this pass's own commit messages" is non-exhaustive: #11, #12, #30 and #31 each correct a pass commit message |
| ORDER_PASS | Visual row (:32), rc2 evidence (:51-52), V02 note (:62) | CONFIRMED | rc4 10/11 PASS 0.15-0.42%, G03 1.28% at 85.5% edge, known-bad 13.19%; rc2 0.17-0.46%, G03 1.01% at 87.3%; V02 hue-only 0.007%, gate 0.42% |
| ORDER_PASS | tz_verify counts (:28, :43) | CONFIRMED | 14 / 15 / 17 per run by call sites |
| ORDER_PASS | Residual list vs ARENA open defers | CONFIRMED | X21, R-02 (:84), P-05/R-08/D-01/D-02/D-03/B7 (:85) = every ARENA open defer |
| ORDER_PASS | Deferred structural residual (:83) | CONFIRMED | Matches every DEFERRED-STRUCTURAL ledger row (G07 visibility folded into S02) |
| ORDER_PASS | C4 phase row "Applied" list | CONFIRMED | Matches the ledger's MET/MET-STATIC rows (V05's mobile caveat is the V05 row above) |
| Gate | `i18n_truth_gate.py` | CONFIRMED | 12/12 locales PASS, rc 0 |
| Gate | `hardcoded_text_gate.py` and `--demo` | CONFIRMED | 0 hits rc 0; demo OK rc 0 |
| Gate | `visual_truth_gate.py` tzverify + known-bad | CONFIRMED | 10/11 PASS 0.15-0.42%; G03 FAIL 1.28%; magenta_corruption 13.19% FAIL; rc 1 as expected. Matches ORDER_PASS, ARENA R0, TZ_DECISIONS S03 |
| Gate | `user_data_guard.sh --demo` | CONFIRMED | demo OK, rc 0; no tls_udg dirs left in temp |
| Gate | `TLS_SKIP_REIMPORT=1 check.sh --static` | CONFIRMED | "Всё зелёное", 24 passed, 0 FAIL, rc 0. `git status --short`: only the pre-existing ` M project.godot` |

CONFIRMED=114 PARTIAL=4 FAKE=0
