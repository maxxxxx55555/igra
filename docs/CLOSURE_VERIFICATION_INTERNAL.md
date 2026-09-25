# Round 7, HEAD 8c0e01c, tag v8.0.0-rc7

Static verification only. Code and data were read at HEAD, history came from `git show`/`git blame`,
and the python and bash gates were run locally. The Godot binary was not run. Runtime-only numbers
(bot, suite, tz_verify output, draw calls, the full check.sh count) are accepted when the code does
not contradict them. Local and origin tags rc1-rc7 resolve to 27ba1d5 / 5724544 / 5402640 / b8b20c0 /
3ee3568 / 4061f1b / 8c0e01c. Game code is unchanged since rc4 (`git diff b8b20c0..HEAD` touches only
docs, `scripts/tools/`, `tools/`). "n/m lines" means n of the m non-trivial code lines the commit
added (docs excluded) are still present in the same file at HEAD (script). Every ARENA hash exists
and is an ancestor of HEAD.

| Source | Item | Verdict | Evidence |
|---|---|---|---|
| ARENA A | Header "17/17 closed; B7's legacy-achievements half deferred" | CONFIRMED | 16 rows cover 17 items (B9+B14 share a row); the B7 qualifier is now in the header |
| ARENA A | B1 finale boss timing `5e1093b` | CONFIRMED | 79/79 |
| ARENA A | B2 document id `7034bcd` | CONFIRMED | 60/60 |
| ARENA A | B3 skill bonuses `afadb4b` | CONFIRMED | 78/78 |
| ARENA A | B4 progress_hmac `92934a7` (+`ac877a5`) | CONFIRMED | 86/86 and 11/11 |
| ARENA A | B5 NG+ bypasses `fe7ef0e` | CONFIRMED | 103/106. wipe_all_saves resets NG+ and deletes ng_plus_data.json (save_system.gd:575-592) |
| ARENA A | B6 daily signing `e9686d7` | CONFIRMED | 71/71 |
| ARENA A | B7 `bb662b4` payout half + deferred legacy half | CONFIRMED | 48/48. The legacy branch still trusts and re-signs a plain achievements.cfg (achievements_manager.gd:206-211); attack_sim.gd:89-105 locks it; SECURITY_PATCH_SPEC.md:135-136 calls rejection "a UX decision" |
| ARENA A | B8 kills pay wallet `1cf3aaf` | CONFIRMED | 47/47 |
| ARENA A | B9+B14 atomic try_add `36d44be` | CONFIRMED | 151/151 |
| ARENA A | B10 district-enter save `cc1e0b3` | CONFIRMED | 80/80 |
| ARENA A | B11 district lock `d7a0692` | CONFIRMED | 36/36 |
| ARENA A | B12 streetlight event once `c814621` | CONFIRMED | 42/42 |
| ARENA A | B13 import/autosave `a36ac8b` | CONFIRMED | 92/92 |
| ARENA A | B15 fall-recovery net `8c99689` | CONFIRMED | 74/77. The misses are the later P2p sentinel-wait rewrite |
| ARENA A | B16 offline player `cb73c83` | CONFIRMED | 32/32 |
| ARENA A | Q1 heartbeat `a0ec4ee` | CONFIRMED | 60/60 |
| ARENA B | P-01 checksum bypass `92934a7` | CONFIRMED | Present (see B4) |
| ARENA B | P-03 / P-04 / P-06 / P-07 `9b7a46b` | CONFIRMED | 224/224. Flashlight cfg levels clamped to 0..5 (flashlight_upgrade_manager.gd:167,176) |
| ARENA B | P-05 tamper `e9686d7` + wall-clock defer | CONFIRMED | Tamper fix present; wall-clock trust is an inherent client-side limit |
| ARENA B | R-01 watchdog `2278cf9` | CONFIRMED | 21/21. IntegrityGuard autoload at project.godot:113 |
| ARENA B | R-02 defer | CONFIRMED | integrity_guard.gd:83 covers only non-finite position and y <= -50, as the reason says |
| ARENA B | R-08, D-01, D-02 inherent defers | CONFIRMED | Client-side limits |
| ARENA B | D-03 owner defer | CONFIRMED | release_export_check.py rc 0; no key committed |
| ARENA B | R-03 / D-04 `60a289b` | CONFIRMED | 62/62 |
| ARENA B | R-07 LAN `cef6ae6` | CONFIRMED | 48/48 |
| ARENA B | C-08 export gate `a453425` | CONFIRMED | 61/61. Wired at check.sh:255 |
| ARENA C | R0 `bafb740` + numbers | CONFIRMED | 128/128. All 11 `assets/textures/luts/*.import` are `3d_texture`; pin at check.sh:201. Gate on the rc4 frames 0.15-0.42%, G03 1.28%, as stated |
| ARENA C | RENDERING_DIAGNOSIS (b), (d) | CONFIRMED | Covered by bafb740; ssao/ssil/ssr are per-tier keys in visual_quality.tres:9-12 |
| ARENA C | TG gates `5257745`, `4c6ca10` | CONFIRMED | 142/143 and 17/17 |
| ARENA C | CHALLENGE-01 `fe3007a` | CONFIRMED | 86/99. The misses are the reworded phase-8 check (X22) |
| ARENA C | CHALLENGE-02 partial `c783544` | CONFIRMED | 22/22. Residual is matrix X21 BUG |
| ARENA C | CHALLENGE-03 `0f9685a` | CONFIRMED | settings_full.gd absent at HEAD |
| ARENA C | MISSED-00..05 | CONFIRMED | AL35/AL50/AL55/AL57/IN89 are WORKS |
| ARENA C | I18N `43c9ecd` / `21c6563` | CONFIRMED | 159/159 and 209/223 (value edits); truth gate 12/12 now |
| ARENA D | SLOP items 1-15, §2, §3 (9 rows) | CONFIRMED | 855a278 11/11, 1fcf157 9/9, bbdaa8e 24/24, d06fe48 28/28, 53353d5 20/20, 363add0 7/7, 7bbc0ca 6/6 (BLACK_FAIL_PCT 40.0, visual_truth_gate.py:50). BTN_ONE_MORE_RUN has 0 references |
| ARENA Design | P1-P8 (7 rows) | CONFIRMED | 2a88503 15/15, c2dbeb4 93/99, 4e7560e 359/365, f9bbfd7 27/27, 24ceb68 58/61, 8f48faf 46/46, ee273ee 7/7 |
| ARENA | "Open defers" list | PARTIAL | The B7 row now says the legacy-achievements half is deferred as "an owner call" (ARENA_CLOSURE.md:22), but the Open defers summary lists only D-03 as owner-held (ARENA_CLOSURE.md:101), and ORDER_PASS_REPORT.md:82's residual security list also omits it |
| ARENA | "No P0 is deferred" | CONFIRMED | The only P0 (R0) is closed |
| TZ legend | Every verdict in the legend | CONFIRMED | All 48 ledger rows use legend verdicts (qualifiers in parentheses only) |
| TZ sources | tz_verify "17 checks at rc5" | CONFIRMED | 18 `_check` sites, :247 is the exclusive else of :243, so 17 per run. The rc7 runner diff is comments only |
| TZ sources | footstep probe exits 1 | CONFIRMED | footstep_system.gd:190-204 counts duplicate or missing (sample, pitch) keys; _footstep_check.gd quits 1 on fails |
| TZ | A02 MET | CONFIRMED | music_manager.gd:118 FADE_TIME 2.0, used at :209/:262-263; GDD.md:359. tz_verify:105 |
| TZ | A03 DECIDED | CONFIRMED | SPEED_FILE walk/jog/sprint and SPEED_PITCH 0.9/1.0/1.12 (footstep_system.gd:47-49); 18 footsteps/*.wav exist; asphalt/puddle/glass have one file each |
| TZ | A04 MET-STATIC | CONFIRMED | Measured MiB: ambience 46.0 - wav_src 29.9 = 16.1; + sfx 6.3 + one_shots 1.1 = 23.5; music 37.2. wav_src in every exclude_filter |
| TZ | A01 DEFERRED | CONFIRMED | default_bus_layout.tres: Master/Music/SFX/Voice/Ambient/UI/Hum |
| TZ | V02 MET | CONFIRMED | _HIT_FLASH_COLOR #c9a24a and meta restore (base_monster.gd:663-688). P2b fails on the pre-fix pure-white flash (5cf3b27 base_monster.gd:670) |
| TZ | V05 MET | CONFIRMED | project.godot:296 = 2048; GDD.md:317; tz_verify:107-108 |
| TZ | V01 MET-STATIC | CONFIRMED | day_night.gd is a clock only; no environment writer |
| TZ | DECIDED group (D03, G01, G04, G09, G10, G13, G22, G27, G31-33, D02, S01, E05) | CONFIRMED | Each has a TZ_DECISIONS row. Code matches: fps_mode=true (main_3d.tscn:61), REACH 3.2 (interactor.gd:24), drain 100/450 with the 5-min note (player_3d.gd:92-96), battery.tres effect_value 35, combo 14/21 with the comment at player_3d.gd:75-77, JOY_ZONE_RATIO 0.35 (:413), balance_sim 11x200 + 26x50 + 31x100 |
| TZ | GAP-OWNER rows (V03, G28/D04, N01/I02/T01) | CONFIRMED | assets/fonts has only -Regular files; the other reasons are owner text/credential actions |
| TZ | G02 / G03 / G06 MET | CONFIRMED | SPRINT_BOB_AMP 0.1, SPRINT_FOV_BONUS 5 (camera_follow_3d.gd:22-24) match GDD.md:45-46; run 272 = 170 x 1.6 (player_stats.tres:6-7). Checks bounded, non-vacuous (tz_verify:137-140) |
| TZ | G07 split | CONFIRMED | CROUCH_SPEED_MULT 0.4 (:87, used :563), CROUCH_NOISE_MULT 0.3 (:542). CROUCH_VISIBILITY_MULT (:89) has no reader, consistent with the visibility defer |
| TZ | G08 MET / NEEDS-EYES | CONFIRMED | player_3d.tscn Flashlight: colour (0.788,0.635,0.29) = c9a24a, angle 45, energy 24, range 16 |
| TZ | G12b MET | CONFIRMED | Threshold 20 (flashlight_stats.tres:11); cleared at max level (player_3d.gd:1140,1164); drain cut (:760) with LEVEL_BONUSES 0.1-0.5 = GDD.md:88-93; P2r measures the drop through _update_battery and reset_all |
| TZ | G15 split | CONFIRMED | Capsule height 1.6 (player_3d.tscn:9); attack box 1.4x0.8x3.4 (player_3d.gd:311) |
| TZ | G16 MET | CONFIRMED | P2r calls respawn_after_death + Routes.restart_game, the death_screen.gd:53-54 path; RESPAWN_HP_RATIO 0.5 |
| TZ | G17 MET | CONFIRMED | _remove_with_backups covers .bak/.bak2/.bak3 (save_system.gd:556-560); wipe_all_saves -> reset_all clears flashlight (:367); tz_verify:251-261 seeds all backups |
| TZ | G18 / G19 MET-STATIC | CONFIRMED | Script check of enemy_roster_data.gd aliases: all 10 table types + Tvar + boss 800/40 equal GDD.md:169-180; Shadow 30/15 (shadow_3d.gd:13,16) |
| TZ | G20 MET-STATIC | CONFIRMED | boss_3d.gd:48-50 0.70/0.30, BEAM_DAMAGE 40 (:9); GDD.md:190-192 |
| TZ | DEFERRED group (G21, G25, G26, S02, S04-hide, C03, P01) | CONFIRMED | No scene instances weapon_manager or hiding_spot; take_photo has no caller; no enemy reads a visibility factor |
| TZ | G24 DECIDED | CONFIRMED | is_past_no_return needs D1-D9 FULL; P2q asserts both sides |
| TZ | G34 split | CONFIRMED | BUNKER_SECRET_ID secret_power_station_02 (progress_tracker.gd:128); P2q asserts it |
| TZ | S03 MET | CONFIRMED | tz_verify:141 needs vignette r > 0.4 and edge warmth +0.03 |
| TZ | S04 MET-STATIC | CONFIRMED | SEARCH_TIME 10 / RADIUS 5 (base_monster.gd:45-46) = GDD.md:214-215; P2q asserts |
| TZ | E03/T02 split | CONFIRMED | Both cooldowns 3600 (ad_service.gd:27,31); skip_bonus_coins (:111) has no UI caller |
| TZ | C04 MET | CONFIRMED | ru "Слепые псы", en "Blind Dogs", key in all 13 locale files; tz_verify:210 |
| TZ | C06 MET | CONFIRMED | fog_setup.gd has no density write (5cf3b27 had 0.015 at :16); presets 0.012/0.013/0.014/0.015 |
| TZ | P02 NEEDS-MEASUREMENT | CONFIRMED | Honest reason |
| TZ | Footer "Open GAP-DEV rows: 0" | CONFIRMED | All 54 audit GAP-DEV/GAP-OWNER IDs appear in the ledger (script) |
| TZ_DECISIONS | S03 reason: edge share | CONFIRMED | Re-measured: rc2 G03 87.3%, rc2 S03 97.8%, rc4 G03 85.5%, rc4 S03 70.1% |
| TZ_DECISIONS | S03 reason: "lands at hue 320-330°" | PARTIAL | Measured on the four cited frames, only 18-27% of the edge-band hue hits fall in 320-330°; medians are 319/333/335/333° and 55-94% lie in 315-345° (TZ_DECISIONS.md:50) |
| TZ_DECISIONS | All other non-MET reasons | CONFIRMED | Every non-MET ledger row has a matching, code-consistent reason |
| Fix | `0873f38` S03 / G12b / A03 / G17 | CONFIRMED | Present at HEAD. Pre-fix: the vignette shader forced BG_DEEP RGB, the flicker was cleared only at bonus >= 1.0, stealth used the walk sample, and wipe removed only .bak, so each new check fails there |
| Fix | `5402640` upgrades across respawn | CONFIRMED | _ready reapplies from _scene_flashlight_energy/range (player_3d.gd:239-245); 5402640^ has no reapply |
| Fix | `b8b20c0` per-run upgrades, drain, fog, hit flash | CONFIRMED | "flashlight" key on save/load/slot/reset (save_system.gd:293,335,367,490,543). Pre-fix 5cf3b27: no to_dict, fog_setup wrote 0.015, white flash |
| Fix | `5cf3b27` guard wiring | CONFIRMED | Every runner traps `udg_restore \|\| exit 97` (check.sh:274, headless_suite:27, autoplay_bot:23, tz_verify:17). check.sh also counts an explicit restore (:347) |
| Fix | `3ee3568` in-process snapshot + measured drain | CONFIRMED | Snapshot before anything runs (suite:115, tz runner:79); b8b20c0 P2r read the field only (:843). The memory-only limit is now documented in the runner (:8-9) |
| Fix | `4061f1b` abort on failed snapshot | CONFIRMED | Aborts in check.sh:273, bots, tz runner :80-83, suite :116-119. The failed-copy hole now has a demo step |
| Fix | `8c0e01c` trap exit code | CONFIRMED | Reproduced: `trap 'false \|\| exit 97' EXIT; exit 0` gives 97, a passing restore keeps the script's code, TERM then fail gives 97. No automated check pins the trap text |
| Fix | `8c0e01c` partial-snapshot cleanup, demo failed copy, demo temp | CONFIRMED | user_data_guard.sh:43 removes the partial copy; :81 checks mktemp; :90 keeps demo temp inside `$d`. Mutations: dropping :43 or the cp check at :41 each make `--demo` FAIL; 0 tls_udg dirs left in TEMP |
| Fix | `8c0e01c` tz_verify crash-safe restore | PARTIAL | The wrapper works (tools/qa_sim/tz_verify:15-23). But scripts/tools/_tz_verify.gd:6 still documents the direct `godot --path . ... tz_verify_scene.tscn` run, and _tz_verify_runner.gd has no abort or timeout handler, so that path still loses the profile on a crash or closed window. The wrapper is also committed 100644 (siblings are 100755), so its own usage line `tools/qa_sim/tz_verify` gets "Permission denied" on a POSIX checkout |
| Fix | `8c0e01c` check.sh label | CONFIRMED | check.sh:190-192 call the r0_after run a self-check; the pin is at :201 |
| Guard | user_data_guard.sh: set -u, quoting, restore safety | CONFIRMED | All expansions guarded; restore refuses a missing or incomplete snapshot (:57-61) and removes only unlisted files. Profile path from config/name (no custom user dir) |
| Guard | _user_data_snapshot.gd | CONFIRMED | Unchanged since 3ee3568. take() nulls on any unreadable file; restore() refuses null and counts set mismatch. No save-on-quit hook runs after restore |
| CORRECTION_LOG | Header "Oldest first" | CONFIRMED | git blame: 648cfd2/27ba1d5 (1-14) → 0873f38 (15-21, and the #8 edit) → 5402640 (22) → b8b20c0 (23-28) → 3ee3568 (29-31) → 4061f1b (32-33) → 8c0e01c (34) |
| CORRECTION_LOG | #1-#7 | CONFIRMED | bafb740 LUT fix; 37581d7 commits 528 .import files; 2547fff visual_quality fog; 0d3d533 X22/X20 and the matrix UNTESTED rows |
| CORRECTION_LOG | #8 | CONFIRMED | `_ensure_playing` first appears in 9fc8665 (`git log -S`) |
| CORRECTION_LOG | #9-#14 | CONFIRMED | 4bb5772 adds the A04 row; d06fe48 body item "6." is the btn_d StyleBox; ad051fc says "all PASS"; ae410b9 says "C06 ultra tier 0.66% FAIL"; c00f118 adds the S01 row |
| CORRECTION_LOG | #15 | CONFIRMED | rc2 frames re-measured 0.17-0.46%, G03 1.01% |
| CORRECTION_LOG | #16-#21 | CONFIRMED | Matches the 0873f38 pre-fix code above; matrix 58 AL + 32 IN + 24 X |
| CORRECTION_LOG | #22-#28 | CONFIRMED | Matches the 5402640 / b8b20c0 diffs; origin rc4 peels to b8b20c0 |
| CORRECTION_LOG | #29-#33 | CONFIRMED | b8b20c0 P2r read the field; b8b20c0 header said "Newest first" and its message says 42; 4061f1b^ had an unchecked `cp -p` and no null check after take(); 13.19% and V02 hue-only 0.01% re-measured |
| CORRECTION_LOG | #34 | CONFIRMED | Every listed rc6 fact matches 4061f1b and every fix is in the 8c0e01c diff |
| MATRIX | Status recount by script | CONFIRMED | 114 rows: WORKS 99, FIXED 6, CTH 6, BDL 1, PARTIAL 1, BUG 1, UNTESTED 0. This equals the footer (FUNCTION_MATRIX.md:153) |
| MATRIX | Spine/extra header and totals | CONFIRMED | AL01-58, IN58-89 (32), X01-24, no duplicates; project.godot has 58 autoloads and 29 input actions; 3 IN rows FIXED |
| ORDER_PASS | Candidate line (:4) | CONFIRMED | Points at the last C8 row, which names rc7 |
| ORDER_PASS | check.sh counts (42 / 44 / 24 static) | CONFIRMED | 20 run_gate calls, 2 of them windowed skips; 24 static + reimport + 18 + restore = 44; the static run here gives 24 |
| ORDER_PASS | Verifier rounds 1-6 figures | CONFIRMED | 79/7/3, 128/6/0, 145/14/0, 186/12/0, 132/4/0, 94/10/0 match each committed CLOSURE_VERIFICATION_INTERNAL (round 6: 94 + 10 table rows) |
| ORDER_PASS | Correction count and ranges (:42, :65) | CONFIRMED | 34 rows; 23-28 and the per-round split match git blame |
| ORDER_PASS | Visual row (:32) and rc2 evidence (:47-51) | CONFIRMED | 10/11 PASS 0.15-0.42%, G03 1.28% at 85%, 13.19%; rc2 0.17-0.46%, G03 1.01% at 87%; lock wording now says the LUT pin |
| ORDER_PASS | Round-6 row (:45) | CONFIRMED | Each listed fix is in 8c0e01c (the wrapper caveat is under Fix above) |
| ORDER_PASS | tz_verify counts (:28, :43, :44) and V02 frame note (:61) | CONFIRMED | 14 / 15 / 17 by the `_check` count; V02 hue-only 0.01%, gate 0.42% |
| Gate | `i18n_truth_gate.py` | CONFIRMED | 12/12 locales PASS, rc 0 |
| Gate | `hardcoded_text_gate.py` and `--demo` | CONFIRMED | 0 hits rc 0; demo OK rc 0 |
| Gate | `visual_truth_gate.py` tzverify + known-bad | CONFIRMED | 10/11 PASS 0.15-0.42%; G03 FAIL 1.28%; magenta_corruption 13.19% FAIL; rc 1 as expected. Matches ORDER_PASS, ARENA R0 and TZ_DECISIONS S03 |
| Gate | `user_data_guard.sh --demo` | CONFIRMED | demo OK, rc 0, no tls_udg dirs left in TEMP |
| Gate | `TLS_SKIP_REIMPORT=1 check.sh --static` | CONFIRMED | "Всё зелёное", 24 passed, 0 FAIL. `git status`: only the pre-existing ` M project.godot` |

CONFIRMED=105 PARTIAL=3 FAKE=0
