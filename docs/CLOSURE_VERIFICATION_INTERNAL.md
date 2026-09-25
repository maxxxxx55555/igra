# Round 2, HEAD 5724544, tag v8.0.0-rc2

Independent re-check of the rc2 closure claims, done on 2026-09-25. Everything was checked statically; Godot was not run.
Commit existence was checked with `git merge-base --is-ancestor <hash> HEAD`. Fix survival: each cited commit's
non-trivial added lines (>=15 chars, non-comment, non-.md) were looked up in the HEAD copy of the file, and
every line that did not survive was read by hand. For the fixes in `0873f38`, each regression check was compared
with `git show 27ba1d5:<path>` to decide whether it would fail on the pre-fix code. Runtime-only numbers (bot n/3,
suite x3, tz_verify r/warmth values, the D1 draw-call count of 246) were not re-run and are not counted against a row.

The working tree before the run had `M project.godot`, a line-ending-only difference (`git diff` is empty). The same
difference was there after `check.sh`, which touched no tracked file.

| Source | Item | Verdict | Evidence |
|---|---|---|---|
| ARENA A | B1 `5e1093b` | CONFIRMED | ancestor; 39/39 added lines at HEAD |
| ARENA A | B2 `7034bcd` | CONFIRMED | 32/32 |
| ARENA A | B3 `afadb4b` | CONFIRMED | 42/42 |
| ARENA A | B4 `92934a7` + `ac877a5` | CONFIRMED | 45/45, 4/4 |
| ARENA A | B5 `fe7ef0e` | CONFIRMED | 56/58; the 2 misses are attack_sim lines refactored into a helper |
| ARENA A | B6 `e9686d7` | CONFIRMED | 28/28 |
| ARENA A | B7 `bb662b4` | CONFIRMED | 21/21; project.godot has one RewardsManager and one RandomEvents |
| ARENA A | B8 `1cf3aaf` | CONFIRMED | 28/28 |
| ARENA A | B9+B14 `36d44be` | CONFIRMED | 84/84 |
| ARENA A | B10 `cc1e0b3` | CONFIRMED | 46/46 |
| ARENA A | B11 `d7a0692` | CONFIRMED | 22/22 |
| ARENA A | B12 `c814621` | CONFIRMED | 21/21 |
| ARENA A | B13 `a36ac8b` | CONFIRMED | 43/43 |
| ARENA A | B15 `8c99689` | CONFIRMED | 33/35; the 2 misses are a suite assert later reworked to a sentinel check |
| ARENA A | B16 `cb73c83` | CONFIRMED | 14/14 |
| ARENA A | Q1 `a0ec4ee` | CONFIRMED | 35/35 |
| ARENA B | P-01 `92934a7` | CONFIRMED | 45/45 |
| ARENA B | P-03/P-04/P-06/P-07 `9b7a46b` | CONFIRMED | 116/116 |
| ARENA B | P-05 tamper `e9686d7` + wall-clock defer | CONFIRMED | Fix present; the client-clock defer is honest |
| ARENA B | R-01 `2278cf9` | CONFIRMED | 11/11; project.godot:113 IntegrityGuard autoload |
| ARENA B | R-02 defer | CONFIRMED | Honest: integrity_guard.gd:83 checks only non-finite position and y<=-50 |
| ARENA B | R-08 / D-01 / D-02 inherent defers | CONFIRMED | SECURITY_THREAT_MODEL.md:67,81 |
| ARENA B | D-03 owner defer | CONFIRMED | release_export_check.py:37-39 forbids a committed encryption_key |
| ARENA B | R-03 + D-04 `60a289b` | CONFIRMED | 39/39; export_presets.cfg keystore fields are empty; no keystore is tracked |
| ARENA B | R-07 `cef6ae6` | CONFIRMED | 26/26 |
| ARENA B | C-08 `a453425` | CONFIRMED | 52/52; check.sh:250-253 |
| ARENA C | R0 `bafb740` + numbers | CONFIRMED | 112/112; 11/11 lut imports are `3d_texture`/CompressedTexture3D; check.sh:201 pins it. Gate on the rc2 frames: 10 frames 0.17-0.46%, G03 1.01%. Hue-only: 0.00-0.18%, G03 1.01%. Matches the row |
| ARENA C | RENDERING_DIAGNOSIS (b) | CONFIRMED | Part of `bafb740`; the A/B is runtime, not re-run |
| ARENA C | RENDERING_DIAGNOSIS (d) | CONFIRMED | world_env_setup.gd reads the SSAO/SSIL/SSR settings from visual_quality.tres |
| ARENA C | TG gates `5257745`, `4c6ca10` | CONFIRMED | 110/111 (the one miss was replaced by PIL HSV) and 7/7 |
| ARENA C | CHALLENGE-01 `fe3007a` | CONFIRMED | 19/21; 2 message lines reworded |
| ARENA C | CHALLENGE-02 partial `c783544` | CONFIRMED | 8/8; honestly Partial, X21 is BUG |
| ARENA C | CHALLENGE-03 `0f9685a` | CONFIRMED | scripts/ui/settings_full.gd is absent |
| ARENA C | MISSED-00..05 `0d3d533` | CONFIRMED | 80/80; matrix rows present |
| ARENA C | I18N `43c9ecd` / `21c6563` | CONFIRMED | 159/159 and 203/204 (a gate line refactored); gate is 12/12 |
| ARENA D | 1,6 `855a278` | CONFIRMED | 5/5 |
| ARENA D | 2 `1fcf157` | CONFIRMED | 3/3; check.sh:281 treats rc 3 as a skip |
| ARENA D | 3 `bbdaa8e` | CONFIRMED | 11/11 |
| ARENA D | 4,5,7,9,10,11,14,15 `d06fe48` | CONFIRMED | 16/16 |
| ARENA D | 8 `53353d5` | CONFIRMED | 13/13 |
| ARENA D | 12 `2948e23` | CONFIRMED | Key absent |
| ARENA D | 13 `363add0` | CONFIRMED | visual_truth_gate.py uses `img.convert("HSV")` |
| ARENA D | §2 `7bbc0ca` | CONFIRMED | visual_truth_gate.py:50 BLACK_FAIL_PCT = 40.0 |
| ARENA D | §3 reviewed | CONFIRMED | Doc-only; consistent with CORRECTION_LOG #6 |
| ARENA Design | P1 `2a88503` | CONFIRMED | 2/2; player_3d.gd:543-544 |
| ARENA Design | P2 `c2dbeb4`, `4e7560e` | CONFIRMED | 73/79; the misses are later locale rewordings |
| ARENA Design | P3 `4e7560e` | CONFIRMED | 334/340; the misses are locale rewordings |
| ARENA Design | P4 `f9bbfd7` | CONFIRMED | 12/12 |
| ARENA Design | P5 `24ceb68` | CONFIRMED | 31/33; the formula was renamed to BATTERY_PER_SKILL_LVL (player_3d.gd:1173) |
| ARENA Design | P6/P7 `8f48faf` | CONFIRMED | 31/31 |
| ARENA Design | P8 `ee273ee`, `24ceb68` | CONFIRMED | 2/2 |
| TZ MET | A02 crossfade 2.0 | CONFIRMED | music_manager.gd:118,209,262; tz_verify:100 |
| TZ MET-STATIC | A04 audio caps | CONFIRMED | music 38M + ambience 47M < 100; sfx 6.9M + one_shots 1.1M + ui/jingles < 50; _pre_norm is excluded from export |
| TZ MET | V02 no neon | CONFIRMED | boss_3d.gd:293 `#c9a24a`; V02_energy_ball.png PASS 0.33% |
| TZ MET | V05 shadow 2048 | CONFIRMED | project.godot:296; tz_verify:103 |
| TZ MET-STATIC | V01 no day | CONFIRMED | day_night.gd (31 lines) has no environment writer |
| TZ MET | G02 headbob 0.1 | CONFIRMED | camera_follow_3d.gd:22,84. Note: tz_verify:134 only bounds the span to 0.02-0.25 |
| TZ MET | G03 FOV +5 | CONFIRMED | camera_follow_3d.gd:24,91. Note: tz_verify:132 only asserts >3 |
| TZ MET | G06 sprint x1.6 | CONFIRMED | player_stats.tres 170/272; tz_verify:135 is exact |
| TZ MET-STATIC | G07 crouch speed x0.4 / noise x0.3 | CONFIRMED | player_3d.gd:87-88,535,556 |
| TZ MET | G08 colour + 45 degrees | CONFIRMED | player_3d.tscn:179,182; tz_verify:107 |
| TZ MET | G12b flicker <20%, cleared by Stability L5 | PARTIAL | The <20% flicker is real (flashlight_stats.tres:11, player_3d.gd:1126). Clearing is only set inside `apply_flashlight_upgrades` (player_3d.gd:1153), and that function's only caller is `try_purchase` -> `_apply_to_flashlight` (flashlight_upgrade_manager.gd:98,123-128). No _ready, spawn or load path calls it, so `_flashlight_stability_maxed` defaults to false (player_3d.gd:1166) on every fresh player: a new session, and a respawn (suite P2r asserts `q != p`). An L5 player flickers again after any restart. tz_verify:171-172 calls the function by hand, which hides this |
| TZ MET | G15 capsule 1.6 | CONFIRMED | player_3d.tscn:8-9 |
| TZ MET | G16 respawn | CONFIRMED | game_manager.gd:113-133; suite P2r _qa_headless_suite_runner.gd:777-820 |
| TZ MET | G17 hardcore wipe | CONFIRMED | game_manager.gd:172-173 -> save_system.gd:569-570 `_remove_with_backups` (:550-555) removes .bak/.bak2/.bak3 + main for SAVE_PATH and each slot; this covers every loader fallback at :257-263 |
| TZ MET-STATIC | G18/G19 roster + Shadow | CONFIRMED | All 11 GDD.md:170-180 HP/damage pairs match via AI_TO_ROSTER (crawler->dog 50/20 etc.); shadow_3d.gd:13-21 |
| TZ MET-STATIC | G20 boss 70/30, beams 40 | CONFIRMED | boss_3d.gd:9,48,50 |
| TZ MET | G34 bunker = real secret | CONFIRMED | progress_tracker.gd:128-130; secrets.json:400; P2q :763-767; `endings_sim.py` PASS all 5 |
| TZ MET | S03 ember vignette pulse | CONFIRMED | The shader keeps COLOR.rgb (post_process_overlay.gd:141). hud_3d.gd:639-647 lerps bg-deep->ember by the pulse on the 0-1 noise scale (player_3d.gd:532-545: RUN 0.8) |
| TZ MET-STATIC | S04 search 10 s / 5 m | CONFIRMED | base_monster.gd:45-46; P2q :748 |
| TZ MET-STATIC | E03/T02 cooldown + skip | CONFIRMED | ad_service.gd:27,31,111-115; P2q :746 |
| TZ MET | C04 arachnophobia | CONFIRMED | Key present in 13/13 locales, ru "Слепые псы"; tz_verify:205 |
| TZ MET | C06 fog + particles | CONFIRMED | visual_quality.tres:9-12 fog 0.012/0.015, ratio 0.5-1.5; settings_manager.gd:445-447; tz_verify:150,156 |
| TZ evidence | "tz_verify: 15 checks" | CONFIRMED | 16 `_check` call sites; :238/:242 are exclusive branches, so 15 run (27ba1d5 had 14) |
| TZ 0873f38 | S03 check non-vacuous | CONFIRMED | tz_verify:136 needs vig_r>0.4 AND edge warmth +0.03. On 27ba1d5 the shader dropped RGB, so the warmth delta is ~0 and the check fails. The old check (27ba1d5:116 `vig_a > 0`) was vacuous |
| TZ 0873f38 | G12b check non-vacuous | CONFIRMED | tz_verify:178 spread==0 at max level. On 27ba1d5 the bonus 0.5 < 1.0 kept the flicker, so it fails. It covers only the purchase-time path (see G12b) |
| TZ 0873f38 | A03 probe can fail | CONFIRMED | _footstep_check.gd:13-15 quits 1 on fails>0. footstep_system.gd:190-204 counts a missing file or a duplicate (sample,pitch). The 27ba1d5 probe printed fails=0 unconditionally. For single-sample surfaces the distinctness comes only from the SPEED_PITCH constants |
| TZ 0873f38 | G17 check non-vacuous | CONFIRMED | tz_verify:250-258 seeds .bak-.bak3 and asserts no tls_savegame* file is left. The 27ba1d5 wipe left .bak2/.bak3, so it fails; the old check (27ba1d5:220) was main-file-only |
| TZ DECIDED | A03 DR-A03 | CONFIRMED | footstep_system.gd:32,47-49; walk/jog/sprint files exist for concrete/wood/metal (+grass/gravel/tile); asphalt/puddle/glass have one step_*.wav each. The TZ_DECISIONS reason is honest |
| TZ DEFERRED | A01 bus graph | CONFIRMED | TZ_DECISIONS row A01 |
| TZ DECIDED | D03 / V01 | CONFIRMED | TZ_DECISIONS D03/V01 |
| TZ DECIDED | G01 | CONFIRMED | TZ_DECISIONS G01 |
| TZ DECIDED | G04 | CONFIRMED | TZ_DECISIONS G04 |
| TZ DEFERRED | G07 visibility + capsule | CONFIRMED | TZ_DECISIONS S02/G07-visibility, G07-capsule |
| TZ DECIDED | G09 | CONFIRMED | TZ_DECISIONS G09 (recorded, not re-run; stated) |
| TZ DECIDED | G10 | CONFIRMED | TZ_DECISIONS G10 |
| TZ DECIDED | G13 / G15 attack box | CONFIRMED | TZ_DECISIONS G13/G15 |
| TZ DEFERRED | G21 | CONFIRMED | TZ_DECISIONS G21 |
| TZ DECIDED | G22 | CONFIRMED | TZ_DECISIONS G22 |
| TZ DECIDED | G24 DR-2 | CONFIRMED | district_manager.gd:25-42 closes after D1-D9 FULL, used at :88; P2q :750-762 asserts both sides |
| TZ DEFERRED | G25 | CONFIRMED | weapon scenes are referenced only by tools and the unplaced pickup |
| TZ DECIDED | G26 DR-5 | CONFIRMED | TZ_DECISIONS G26 |
| TZ DECIDED | G27 | CONFIRMED | TZ_DECISIONS G27 |
| TZ GAP-OWNER | G28/D04 | CONFIRMED | TZ_DECISIONS G28/D04 |
| TZ DECIDED | G31/G32/G33 | CONFIRMED | TZ_DECISIONS row |
| TZ DR-5 | G34 audio/photos aliased | CONFIRMED | TZ_DECISIONS G34 |
| TZ DECIDED | S01 | CONFIRMED | TZ_DECISIONS S01 (added in `c00f118`) |
| TZ DEFERRED | S02 | CONFIRMED | TZ_DECISIONS S02/G07-visibility |
| TZ DECIDED | D02 | CONFIRMED | TZ_DECISIONS D02 |
| TZ BY-DESIGN-ABSENT | E03 modal | CONFIRMED | TZ_DECISIONS E03 modal |
| TZ DECIDED | E05 | CONFIRMED | TZ_DECISIONS E05 |
| TZ DEFERRED | C03 | CONFIRMED | player_3d.gd:318-320 2.7 m melee sphere; no gameplay weapon (G25) |
| TZ DEFERRED | P01 draw calls | PARTIAL | TZ_COMPLIANCE.md:3 says every non-MET row's reasoning is in TZ_DECISIONS, but TZ_DECISIONS.md has no P01 row. The reason exists only inline (TZ_COMPLIANCE.md:71) and in CORRECTION_LOG #13. The 246 figure is runtime, not re-run. P02's "NEEDS measurement" (:72) is not a verdict in the legend |
| TZ_DECISIONS | C06 (partial) row | PARTIAL | TZ_DECISIONS.md:19 still says particle_ratio is "not applied". That is stale: settings_manager.gd:445-447 applies it, and C06 is MET. It contradicts the ledger |
| CORRECTION_LOG | #1 | CONFIRMED | `bafb740` = LUT Texture3D (11 imports); `24116c4`'s scale change is gone from HEAD |
| CORRECTION_LOG | #2 `37581d7` | CONFIRMED | 528 .import files committed |
| CORRECTION_LOG | #3 `2547fff` | CONFIRMED | visual_quality.tres + world_env_setup.gd:181 single source |
| CORRECTION_LOG | #4 | CONFIRMED | V05 stays 2048 (project.godot:296) |
| CORRECTION_LOG | #5 `0d3d533` | CONFIRMED | Commit subject "X22/X20 root causes"; matrix X22 FIXED |
| CORRECTION_LOG | #6 `0d3d533` | CONFIRMED | X20 PARTIAL with the same wording |
| CORRECTION_LOG | #7 | CONFIRMED | 0 UNTESTED by recount |
| CORRECTION_LOG | #8 `ac877a5`, `9fc8665` | CONFIRMED | `9fc8665` adds `_ensure_playing()`; the x3 suite is runtime, not re-run |
| CORRECTION_LOG | #9 `4bb5772` | CONFIRMED | Adds the A04 DR-7 row |
| CORRECTION_LOG | #10 | CONFIRMED | The `d06fe48` body labels the btn_d change "6."; SLOP_REPORT.md:134 is item 7 |
| CORRECTION_LOG | #11 `ae410b9` | CONFIRMED | The `ad051fc` body says "all PASS". Its V02 frame reads 0.59% hue-only (1.00% gate FAIL); `ae410b9` gives 0.02% |
| CORRECTION_LOG | #12 | CONFIRMED | The `ae410b9` body says "C06 ultra tier 0.66% FAIL"; its frames give S03 0.66% FAIL and C06 ultra PASS |
| CORRECTION_LOG | #13 | CONFIRMED | Ledger row updated; the 246 number is runtime, not re-run |
| CORRECTION_LOG | #14 `c00f118` | CONFIRMED | Adds the S01 DR-3 row |
| CORRECTION_LOG | #15 | CONFIRMED | Gate re-run: 0.17-0.46% + G03 1.01% |
| CORRECTION_LOG | #16 | CONFIRMED | 27ba1d5: shader BG_DEEP-only, /10.4 (RUN 0.8 -> 0.077), alpha max(0.55, <=0.5), `vig_a > 0`. All fixed in `0873f38` |
| CORRECTION_LOG | #17 | PARTIAL | The rc1 fact is right and the level-keyed fix is present. "Through the real upgrade path" covers only the purchase path: a fresh player never gets `apply_flashlight_upgrades` (flashlight_upgrade_manager.gd:98,123-128 are the only caller) |
| CORRECTION_LOG | #18 | CONFIRMED | Matches 27ba1d5 footstep_system/_footstep_check and the HEAD fix |
| CORRECTION_LOG | #19 | CONFIRMED | save_system.gd:545-555 |
| CORRECTION_LOG | #20 | CONFIRMED | Ledger rows G24 DECIDED, C03 DEFERRED |
| CORRECTION_LOG | #21 | CONFIRMED | `9fc8665` has `_ensure_playing`; 58 AL + 32 IN, 24 X; 14 -> 15 checks |
| FUNCTION_MATRIX | Status counts | CONFIRMED | Script recount of 114 rows, no duplicate IDs: WORKS 99, FIXED 6, CANNOT-TEST-HEADLESS 6, BY-DESIGN-LIMIT 1, PARTIAL 1, BUG 1, UNTESTED 0. Equals the footer |
| FUNCTION_MATRIX | Footer spine/extra | CONFIRMED | 58 AL + 32 IN = 90, 24 X (X01-X24) |
| FUNCTION_MATRIX | Header "Current:" line | PARTIAL | "90 spine rows (58 autoloads + 32 ...; 29 live actions)" matches project.godot (58 autoloads, 29 inputs). The same bullet (FUNCTION_MATRIX.md:8) still says "rows AL01-AL57", but AL58 exists (:88) |
| Gate | i18n_truth_gate.py | CONFIRMED | 12/12 locales PASS |
| Gate | hardcoded_text_gate.py | CONFIRMED | 0 hit(s) |
| Gate | hardcoded_text_gate.py --demo | CONFIRMED | demo OK |
| Gate | visual_truth_gate.py tzverify vs ORDER_PASS C8 / R0 | CONFIRMED | 10/11 PASS 0.17-0.46%; G03 FAIL 1.01%, 87% of its hits in the left/right 15% edge band (89% counting all four edges). Matches both docs |
| ORDER_PASS_REPORT | "14 entries in CORRECTION_LOG" | PARTIAL | ORDER_PASS_REPORT.md:60 is stale: CORRECTION_LOG has 21 rows |
| check.sh | `TLS_SKIP_REIMPORT=1 bash tools/check.sh --static` | CONFIRMED | exit 0, `Всё зелёное. Проверок пройдено: 23`, 0 FAIL lines (sub-gate "53 проверок пройдено"); no tracked file touched |

CONFIRMED=128 PARTIAL=6 FAKE=0
