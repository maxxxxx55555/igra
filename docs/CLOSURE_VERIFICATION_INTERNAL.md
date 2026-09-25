# Round 5, HEAD 3ee3568, tag v8.0.0-rc5

Static verification only: code and data read at HEAD, history via `git show`, python and bash gates
run locally. The Godot binary was not run. Runtime-only numbers (bot, suite, tz_verify output, draw
calls, full check.sh count) are accepted when the code does not contradict them. Local and origin
tags rc1-rc5 resolve to 27ba1d5 / 5724544 / 5402640 / b8b20c0 / 3ee3568.

| Source | Item | Verdict | Evidence |
|---|---|---|---|
| ARENA A | B1 finale boss timing `5e1093b` | CONFIRMED | Commit exists, ancestor of HEAD, 36/36 added code lines still at HEAD |
| ARENA A | B2 document id `7034bcd` | CONFIRMED | Exists, 26/26 lines present |
| ARENA A | B3 skill bonuses `afadb4b` | CONFIRMED | Exists, 40/40 |
| ARENA A | B4 progress_hmac `92934a7` (+`ac877a5`) | CONFIRMED | 42/42 and 4/4; save_system.gd:131-138 signs progress, :222 rejects a missing hmac |
| ARENA A | B5 NG+ bypasses `fe7ef0e` | CONFIRMED | 51/53; wipe_all_saves also resets NG+ (save_system.gd:586-590) |
| ARENA A | B6 daily signing `e9686d7` | CONFIRMED | 27/27 |
| ARENA A | B7 duplicate autoloads `bb662b4` | CONFIRMED | 20/20; project.godot has 58 unique autoloads |
| ARENA A | B8 kills pay wallet `1cf3aaf` | CONFIRMED | 25/25 |
| ARENA A | B9+B14 atomic try_add `36d44be` | CONFIRMED | 72/72 |
| ARENA A | B10 district-enter save `cc1e0b3` | CONFIRMED | 41/41 |
| ARENA A | B11 district lock `d7a0692` | CONFIRMED | 20/20 |
| ARENA A | B12 streetlight event `c814621` | CONFIRMED | 21/21 |
| ARENA A | B13 import/autosave `a36ac8b` | CONFIRMED | 40/40 |
| ARENA A | B15 fall-recovery `8c99689` | CONFIRMED | 29/31 |
| ARENA A | B16 offline player `cb73c83` | CONFIRMED | 13/13 |
| ARENA A | Q1 heartbeat `a0ec4ee` | CONFIRMED | 32/32; 16 rows cover 17 items (B9+B14 merged) |
| ARENA B | P-01 `92934a7` | CONFIRMED | As B4 |
| ARENA B | P-03 / P-04 / P-06 / P-07 `9b7a46b` | CONFIRMED | 112/112; the per-run "flashlight" key sits inside the HMAC envelope (save_system.gd:143, :199) |
| ARENA B | P-05 tamper `e9686d7`, clock defer | CONFIRMED | Tamper signing present; wall-clock trust cannot be fixed offline, honest defer |
| ARENA B | R-01 watchdog `2278cf9` | CONFIRMED | 10/10 |
| ARENA B | R-02 defer | CONFIRMED | Reason matches code: integrity_guard.gd:83 checks only non-finite position and y <= -50 |
| ARENA B | R-08 / D-01 / D-02 defers | CONFIRMED | Inherent client-side limits; docs/SECURITY_THREAT_MODEL.md exists |
| ARENA B | D-03 owner defer | CONFIRMED | release_export_check.py forbids a committed PCK key |
| ARENA B | R-03 / D-04 `60a289b` | CONFIRMED | 36/36 |
| ARENA B | R-07 `cef6ae6` | CONFIRMED | 26/26 |
| ARENA B | C-08 `a453425` | CONFIRMED | 45/45; gate green in the static run |
| ARENA C | R0 `bafb740` + numbers | CONFIRMED | 11/11 LUT imports `importer="3d_texture"`, pinned at check.sh:201. Gate on the committed frames: 10/11 PASS 0.15-0.42%, G03 FAIL 1.28% (86% of hits in the outer 15% band), known-bad 13.19% |
| ARENA C | (b) Lossless test set | CONFIRMED | Folded into `bafb740`; no contrary code |
| ARENA C | (d) SSR/SSAO | CONFIRMED | Tier-driven from visual_quality.tres (ssao/ssr keys per tier) |
| ARENA C | TG gates `5257745`, `4c6ca10` | CONFIRMED | 104/105 and 5/5; LUT pin present |
| ARENA C | CHALLENGE-01 `fe3007a` | CONFIRMED | 17/19 |
| ARENA C | CHALLENGE-02 partial `c783544` | CONFIRMED | Honestly partial; X21 still BUG in the matrix |
| ARENA C | CHALLENGE-03 `0f9685a` | CONFIRMED | scripts/ui/settings_full.gd absent at HEAD |
| ARENA C | MISSED-00..05 `0d3d533` | CONFIRMED | AL50/AL57/IN89 rows present with stated methods |
| ARENA C | I18N `43c9ecd`, `21c6563` | CONFIRMED | 159/159, 185/186; truth gate 12/12 this run |
| ARENA D | 1,6 `855a278`; 2 `1fcf157`; 3 `bbdaa8e` | CONFIRMED | 5/5, 1/1, 11/11 |
| ARENA D | 4,5,7,9,10,11,14,15 `d06fe48` | CONFIRMED | 15/15 |
| ARENA D | 8 `53353d5`; 12 `2948e23`; 13 `363add0` | CONFIRMED | 13/13; BTN_ONE_MORE_RUN absent everywhere; 3/3 |
| ARENA D | §2 BLACK_FAIL_PCT `7bbc0ca` | CONFIRMED | visual_truth_gate.py:50 = 40.0 |
| ARENA D | §3 symptom masks | CONFIRMED | Review only; no code claim |
| ARENA Design | P1 `2a88503`, P2 `c2dbeb4`/`4e7560e`, P3 `4e7560e` | CONFIRMED | 2/2, 68/74, 305/311 |
| ARENA Design | P4 `f9bbfd7`, P5 `24ceb68` | CONFIRMED | 9/9; refresh_battery_max recomputes from both sources (player_3d.gd:1184) |
| ARENA Design | P6/P7 `8f48faf`, P8 `ee273ee`/`24ceb68` | CONFIRMED | 29/29, 2/2 |
| ARENA | Open defers summary, "No P0 is deferred" | CONFIRMED | Matches the table rows |
| TZ | Legend covers every verdict | CONFIRMED | Script: every ledger verdict token is one of the 8 legend verdicts |
| TZ | "17 checks at rc5" | CONFIRMED | _tz_verify_runner.gd has 17 `_check` call sites that run (tutorial pair is either/or), incl. :53 restore and :96 C06 at load |
| TZ | Footer "Every GAP-DEV/GAP-OWNER audit row has a verdict" | CONFIRMED | Script: 54 GAP rows in TZ_COMPLIANCE_AUDIT.md, 0 missing from the ledger |
| TZ | Non-MET rows have a TZ_DECISIONS reason | CONFIRMED | Every DECIDED/DEFERRED/NEEDS/GAP/BY-DESIGN-ABSENT row has a matching TZ_DECISIONS row |
| TZ | A02 MET | CONFIRMED | music_manager.gd:118 FADE_TIME 2.0; tz :99 |
| TZ | A03 DECIDED (DR-A03) | CONFIRMED | SPEED_PITCH 0.9/1.0/1.12, SPEED_VOLUME 0.3/1.0/1.5 (footstep_system.gd:48-49); probe exits 1 on fewer than 3 distinct steps (_footstep_check.gd) |
| TZ | A04 MET-STATIC | CONFIRMED | wav_src in every exclude_filter; sfx 6.6 + one_shots 1.1 + ambience-without-wav_src 16.8 MB (decimal), music 39.0 MB |
| TZ | A01 DEFERRED-STRUCTURAL | CONFIRMED | Reason in TZ_DECISIONS |
| TZ | V02 MET | CONFIRMED | Hit flash #c9a24a with meta-kept original (base_monster.gd:663-688); P2b asserts the restore (fails on the pre-fix duplicate). Brass itself is static only |
| TZ | V05 MET | CONFIRMED | project.godot:296 = 2048; tz :102 |
| TZ | V01 MET-STATIC | CONFIRMED | day_night.gd is a clock only |
| TZ | D03, G01, G04, G09, G10, G13, G22, G27, D02, G31-G33, E05 DECIDED | CONFIRMED | Values match the decisions: drain 100/450, battery item 35, combo 14/21/35, JOY_ZONE_RATIO 0.35, box 1.4x0.8x3.4 |
| TZ | V03 GAP-OWNER | CONFIRMED | assets/fonts has only -Regular files |
| TZ | G02 MET | CONFIRMED | camera_follow_3d.gd:22 SPRINT_BOB_AMP 0.1; tz :133 |
| TZ | G03 MET | CONFIRMED | SPRINT_FOV_BONUS 5.0; tz :131 (asserts > 3) |
| TZ | G06 MET | CONFIRMED | player_stats.tres walk 170, run 272 |
| TZ | G07 split verdict | CONFIRMED | CROUCH_SPEED_MULT 0.4, CROUCH_NOISE_MULT 0.3 applied (player_3d.gd:542, 563) |
| TZ | G08 MET / NEEDS-EYES | CONFIRMED | tz :106 colour and angle; range/energy decision recorded |
| TZ | G12b MET | CONFIRMED | Threshold 20 (flashlight_stats.tres:11); cleared at max level (player_3d.gd:1164); tz :166/:177; P2r respawn/drain/reset |
| TZ | G15 MET-STATIC / DECIDED | CONFIRMED | player_3d.tscn capsule r 0.3 h 1.6 |
| TZ | G16 MET | CONFIRMED | respawn_after_death + Routes.restart_game is exactly the death-screen button (death_screen.gd:52-54); P2r drives it |
| TZ | G17 MET | CONFIRMED | Hardcore death -> wipe_all_saves -> _remove_with_backups + reset_all (game_manager.gd:172, save_system.gd:556-579); tz :255 seeds .bak-.bak3 |
| TZ | G18 / G19 MET-STATIC | CONFIRMED | All 12 HP/damage pairs match GDD.md:170-181 via the alias map. Note: TZ_DECISIONS.md:36 cites GDD.md:167-178, which omits the Hound/Tvar/Architect rows |
| TZ | G20 MET-STATIC | CONFIRMED | boss_3d.gd:48/50 0.70/0.30, :9 BEAM_DAMAGE 40 |
| TZ | G21, G25, G26, S02, S04-hide, C03, A01, P01 DEFERRED | CONFIRMED | Reasons present; hiding_spot.gd kept; no scene instances weapon_manager |
| TZ | G24 DECIDED | CONFIRMED | district_manager.gd:32-42; suite :766-778 asserts both sides |
| TZ | G28/D04, N01, I02, T01 GAP-OWNER | CONFIRMED | Reasons present |
| TZ | G34 MET / DECIDED | CONFIRMED | progress_tracker.gd:124-129 bunker = secret_power_station_02 (in content/secrets.json); suite :780-783 |
| TZ | S01 DECIDED | CONFIRMED | No hit/dodge noise in code; reason recorded |
| TZ | S03 MET | CONFIRMED | Shader keeps COLOR.rgb (post_process_overlay.gd:141); pulse on the 0-1 noise scale (hud_3d.gd:642-645); tz :135 measures edge warmth |
| TZ | S04 MET-STATIC | CONFIRMED | base_monster.gd:45-46 10 s / 5 m; suite :764 |
| TZ | E03 / T02 | CONFIRMED | COOLDOWN_SEC and INTERSTITIAL 3600 (ad_service.gd:27, :31), skip_bonus_coins :111; suite :762 |
| TZ | C04 MET | CONFIRMED | ru.json:276 "Слепые псы"; tz :204 |
| TZ | C06 MET | CONFIRMED | fog_setup.gd no longer writes density; tiers 0.012/0.013/0.014/0.015, particle_ratio 0.5-1.5; tz :96, :149, :155. Other fixed-fog writers only on the unreachable procedural path (11/11 district scenes exist) |
| TZ | P02 NEEDS-MEASUREMENT | CONFIRMED | Reason present |
| TZ_DECISIONS | S03 reason "87-98% in the outer 15% band"; "blocking R0 gate runs on the evidence frames" | PARTIAL | On the committed rc4 frames G03 reads 86% (ORDER_PASS says 85%), below the stated 87-98%. The "blocking R0 gate" (check.sh:189) re-measures `r0_after_*.png`, the `24116c4` frames that CORRECTION_LOG #1 says were clean because textures never loaded, so it cannot catch a regression. The LUT pin is the real lock (TZ_DECISIONS.md:50) |
| Fix 0873f38 | S03 vignette | CONFIRMED | Present at HEAD; pre-fix shader wrote BG_DEEP, so tz :135 warmth delta fails |
| Fix 0873f38 | G12b L5 clear | CONFIRMED | Keyed on level == max; pre-fix L5 bonus 0.5 < 1.0 keeps flicker, tz :177 fails |
| Fix 0873f38 | A03 mapping + probe | CONFIRMED | Pre-fix probe printed fails=0 unconditionally; now returns check_surface_speeds() |
| Fix 0873f38 | G17 backups | CONFIRMED | All deletes via _remove_with_backups; tz seeds .bak2/.bak3 so pre-fix fails |
| Fix 5402640 | Upgrades reapplied in _ready from scene base | CONFIRMED | player_3d.gd:239-247, :1160, :1196; P2r fails without the reapply. Its cross-run leak is logged (#25) and closed by b8b20c0 |
| Fix b8b20c0 | Per-run upgrades | CONFIRMED | "flashlight" in both save writers and loaders (save_system.gd:293, 335, 490, 543), cleared by reset_all :367; covers New Game, hardcore wipe, Continue, slots; legacy saves keep the cfg (commented) |
| Fix b8b20c0 | Stability drain | CONFIRMED | player_3d.gd:760; table 0.1-0.5 matches GDD §3.3 |
| Fix b8b20c0 | Tier fog at load | CONFIRMED | fog_setup.gd density line removed; tz :96 compares to the tier preset (catches the old 0.015 unless the owner's tier is ultra) |
| Fix b8b20c0 | Hit flash | CONFIRMED | Overlapping hits restore the original; P2b fails on the pre-fix code |
| Fix 5cf3b27 | Guard: what restore removes, saves/ | CONFIRMED | Only files absent from the list, top level + saves/ (recursive); engine dirs untouched; the game writes no other user:// subdir in play (take_photo has no caller) |
| Fix 5cf3b27 | Guard: set -u, spaces, traps | CONFIRMED | Tested in a scratch dir with spaces under `set -uo pipefail`: restore byte-identical; TERM, INT and HUP all ran the EXIT restore; bash waits for the Godot child before the trap runs |
| Fix 5cf3b27 | Wiring check.sh / autoplay_bot / headless_suite | CONFIRMED | Snapshot before any Godot call, EXIT trap plus INT/TERM -> exit 130, explicit restore counted as a gate (check.sh:272-275, :347) |
| Fix 3ee3568 | Lost-snapshot refusal | CONFIRMED | user_data_guard.sh:49-53; spliced the 5cf3b27 restore into the current demo: "demo FAIL: restore succeeded without a snapshot" |
| Fix 3ee3568 / 5cf3b27 | Snapshot read failure | PARTIAL | A failed snapshot never stops the run. Shell: `cp -p` at user_data_guard.sh:37 is unchecked and check.sh:273 ignores the result, so the gates overwrite the profile and restore then refuses (partial snapshot kept on disk). In-process: take() returns null (_user_data_snapshot.gd:25), but _tz_verify_runner.gd:77 and _qa_headless_suite_runner.gd:115 continue, and restore() returns -1 after the run. The snapshot is in memory only, so the profile is lost |
| Fix 3ee3568 | In-process snapshot: suite and tz_verify | CONFIRMED | Taken before start_game/P1 (tz :77 before :79). Restored on every in-process exit (tz :83, :258; suite _finish :1176, including the hard timeout). Autoload writes before the snapshot are only the legacy achievements migration. No save on quit. The bot and other gate scenes run directly remain unguarded (not claimed) |
| Fix 3ee3568 | P2r measured drain | CONFIRMED | _update_battery(1.0) on the respawned player (suite :850-856); the early return or the deleted line gives cut 1.0 or 0.0, which fails |
| CORRECTION_LOG | Header "Oldest first" | CONFIRMED | Rows #1-#31 ascending |
| CORRECTION_LOG | #1 R0 `bafb740` | CONFIRMED | LUT imports are 3d_texture; r0_after frames come from `24116c4` |
| CORRECTION_LOG | #2 `37581d7` | CONFIRMED | 528 .import files regenerated |
| CORRECTION_LOG | #3 `2547fff` | CONFIRMED | settings_manager/visual_quality changes; later corrected by #24 |
| CORRECTION_LOG | #4 V05 | CONFIRMED | 2048 at HEAD |
| CORRECTION_LOG | #5-#7 `0d3d533` | CONFIRMED | Message: UIManager._is_open(&"death"), PAUSED branch; matrix 0 UNTESTED |
| CORRECTION_LOG | #8 `ac877a5`, `9fc8665` | CONFIRMED | `_ensure_playing` is added in 9fc8665 |
| CORRECTION_LOG | #9 `4bb5772` | CONFIRMED | Docs commit as cited; its fact is superseded by #23 |
| CORRECTION_LOG | #10 d06fe48 "item 6" | CONFIRMED | Body lists the btn_d fix as "6." |
| CORRECTION_LOG | #11 ad051fc / `ae410b9` | CONFIRMED | ad051fc says "all PASS"; its V02 frame reads 0.59% hue-only (gate 1.00% FAIL) |
| CORRECTION_LOG | #12 ae410b9 "C06 ultra" | CONFIRMED | On ae410b9 frames S03 = 0.66% FAIL, C06 ultra 0.31% PASS |
| CORRECTION_LOG | #13 P01 246 | CONFIRMED | Consistent with TZ P01 and ORDER_PASS |
| CORRECTION_LOG | #14 `c00f118` | CONFIRMED | c00f118 adds the S01 row to TZ_DECISIONS |
| CORRECTION_LOG | #15 visual numbers | CONFIRMED | rc1 frames 0.17-0.66% (S03 0.66); rc2 frames 0.17-0.46%, G03 1.01% |
| CORRECTION_LOG | #16-#20 | CONFIRMED | See the 0873f38 rows; G24 DECIDED and C03 DEFERRED in the ledger |
| CORRECTION_LOG | #21 | CONFIRMED | 58 AL + 32 IN, 24 X; tz_verify 14 at 27ba1d5, 15 at 5724544 |
| CORRECTION_LOG | #22-#26 | CONFIRMED | See the 5402640/b8b20c0 rows; music layers in music/, ambience/ without wav_src 16.8 MB |
| CORRECTION_LOG | #27 | CONFIRMED | ORDER_PASS Applied/Decided lists and the C5 row are fixed |
| CORRECTION_LOG | #28 rc4 tag | CONFIRMED | origin v8.0.0-rc4^{} = b8b20c0; the mis-push history cannot be checked |
| CORRECTION_LOG | #29, #30 | CONFIRMED | Code matches; see the 3ee3568 rows |
| CORRECTION_LOG | #31 "All corrected" | PARTIAL | "42 checks predates the guard gates", yet ORDER_PASS still credits rc4 (`b8b20c0`) with 42 (ORDER_PASS_REPORT.md:23, :42). check.sh at b8b20c0 is byte-identical to HEAD (static 24 + reimport + 18 + guard = 44). Other items fixed (CORRECTION_LOG.md:38) |
| MATRIX | Status recount by script | CONFIRMED | 114 rows: WORKS 99, FIXED 6, CTH 6, BDL 1, PARTIAL 1, BUG 1, UNTESTED 0 |
| MATRIX | Footer / breakdown / totals | CONFIRMED | 90 spine (58 AL + 32 IN), 24 X, 114 total match the rows |
| MATRIX | Header spine line | CONFIRMED | project.godot: 58 autoloads, 29 input actions (+3 removed = 32 IN rows) |
| ORDER_PASS | Candidate "rc5 at the last update" | CONFIRMED | HEAD tagged rc5 |
| ORDER_PASS | Phase deltas (Applied/Decided/C03) | CONFIRMED | Matches the ledger verdicts |
| ORDER_PASS | check.sh "rc1-rc4: 42 checks" / round 3 "rc4: check.sh full 42 green" | PARTIAL | rc4 already had the guard demo and restore checks (added by its parent `5cf3b27`), so a green rc4 run is 44 (ORDER_PASS_REPORT.md:23, :42). rc5 44 matches the code |
| ORDER_PASS | Static only all green | CONFIRMED | This run: 24 passed, 0 failed |
| ORDER_PASS | Visual row and frames section | CONFIRMED | 10/11, 0.15-0.42%, G03 1.28%, known-bad 13.19%, V02 hue-only 0.01% / gate 0.42%, all reproduced |
| ORDER_PASS | C8 loop rounds 1-4 (totals, tags) | CONFIRMED | Totals match the four prior report versions (79/7/3, 128/6/0, 145/14/0, 186/12/0); tags match |
| ORDER_PASS | Round 4 "44 green", "tz_verify 17 checks" | CONFIRMED | 24 + 1 + 18 + 1 = 44 from check.sh; 17 checks in the runner |
| ORDER_PASS | rc2 evidence paragraph | CONFIRMED | rc2 frames 0.17-0.46%, G03 1.01% reproduced |
| ORDER_PASS | Corrections "31 entries" and split | CONFIRMED | 31 rows; 14 / 15-21 / 22 / 23-28 / 29-31 |
| ORDER_PASS | Residual deferred list | CONFIRMED | Matches the DEFERRED-STRUCTURAL rows |
| Gate | i18n_truth_gate.py | CONFIRMED | 12/12 locales PASS, rc 0 |
| Gate | hardcoded_text_gate.py | CONFIRMED | 0 hits, rc 0 |
| Gate | hardcoded_text_gate.py --demo | CONFIRMED | demo OK, rc 0 |
| Gate | visual_truth_gate.py (12 frames) | CONFIRMED | 10 PASS 0.15-0.42%; FAIL G03 1.28%, known-bad 13.19%; matches ORDER_PASS:32 and ARENA R0 |
| Gate | user_data_guard.sh --demo | CONFIRMED | demo OK, rc 0 |
| Gate | TLS_SKIP_REIMPORT=1 check.sh --static | CONFIRMED | "Всё зелёное", 24 passed, 0 FAIL lines; git status: only ` M project.godot` (pre-existing), nothing reverted |

CONFIRMED=132 PARTIAL=4 FAKE=0
