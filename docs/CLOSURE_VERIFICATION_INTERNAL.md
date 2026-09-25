# Closure verification (internal)

Independent re-check of the v8.0.0-rc1 closure claims at HEAD `27ba1d5`, done on 2026-09-25.
The method was static only. Commit existence: `git merge-base --is-ancestor <hash> HEAD`. Fix
survival: every non-trivial added line (>=15 chars, non-comment, non-.md) of each cited commit was
looked up in the HEAD version of its file. Lines that did not survive were read by hand. Semantics
were read file by file. Godot was not run, so runtime-only claims (bot n/3, suite `fails=0 x3`,
windowed magenta A/B) are recorded as not re-run and are not counted against a row.

All 47 cited ARENA_CLOSURE commits exist on HEAD. Added-line survival is 90-100% for every
commit, and every line that did not survive was a later i18n value edit or a test refactor. One
side effect: `bash tools/check.sh --static` regenerated `docs/artifacts/content-depth/i18n_only_texts.md`
(112 -> 113 keys, `FIRST_RESTORE`), which means the committed copy is stale. I reverted it to HEAD.

| Source | Item | Verdict | Evidence (file:line / command output) |
|---|---|---|---|
| ARENA A | B1 finale boss timing `5e1093b` | CONFIRMED | 39/39 added lines present |
| ARENA A | B2 document id before add_child `7034bcd` | CONFIRMED | 32/32 |
| ARENA A | B3 skill bonus compounding `afadb4b` | CONFIRMED | 42/42 |
| ARENA A | B4 reject checksum-only / no progress_hmac `92934a7` (+`ac877a5`) | CONFIRMED | save_system.gd:199 rejects missing `hmac`; :222 missing `progress_hmac` resets power/progress. Note: the stale comment at save_system.gd:116-120 still says legacy checksum is accepted |
| ARENA A | B5 NG+ bypasses `fe7ef0e` | CONFIRMED | new_game_plus_ui.gd:55 `at_cap = ng >= max_ng or _activated_this_visit`; 56/58 lines present (2 attack_sim lines refactored into `_write_ngp_test_file`) |
| ARENA A | B6 signed daily `e9686d7` | CONFIRMED | 28/28 |
| ARENA A | B7 duplicate autoloads `bb662b4` | CONFIRMED | HEAD project.godot [autoload] has exactly one RewardsManager (:109) and one RandomEvents (:110) |
| ARENA A | B8 kills pay wallet `1cf3aaf` | CONFIRMED | 28/28 |
| ARENA A | B9+B14 atomic try_add `36d44be` | CONFIRMED | 84/84 |
| ARENA A | B10 district-enter save order `cc1e0b3` | CONFIRMED | 46/46 |
| ARENA A | B11 lock in transition_to `d7a0692` | CONFIRMED | 22/22; district_manager.gd:84-90 |
| ARENA A | B12 streetlight event once `c814621` | CONFIRMED | 21/21 |
| ARENA A | B13 import refresh / autosave slot `a36ac8b` | CONFIRMED | 43/43 |
| ARENA A | B15 fall-recovery net on spawn `8c99689` | CONFIRMED | player_3d.gd:113,360; the suite assertion was reworked to a sentinel check, _qa_headless_suite_runner.gd:662-673 |
| ARENA A | B16 offline not networked `cb73c83` | CONFIRMED | 14/14 |
| ARENA A | Q1 heartbeat split `a0ec4ee` | CONFIRMED | 35/35 |
| ARENA B | P-01 legacy checksum `92934a7` | CONFIRMED | save_system.gd:199 |
| ARENA B | P-03/P-04/P-06/P-07 `9b7a46b` | CONFIRMED | 116/116 |
| ARENA B | P-05 daily tamper `e9686d7` + wall-clock defer | CONFIRMED | Tamper fix present; the defer reason (client clock) is honest |
| ARENA B | R-01 watchdog `2278cf9` | CONFIRMED | HEAD project.godot:113 `IntegrityGuard` autoload |
| ARENA B | R-02 speed watchdog defer | CONFIRMED | Honest: integrity_guard.gd:83 covers only non-finite / y<=-50 |
| ARENA B | R-08, D-01, D-02 inherent defers | CONFIRMED | SECURITY_THREAT_MODEL.md:67,81 document the client-side key limit |
| ARENA B | D-03 PCK key owner defer | CONFIRMED | release_export_check.py:37-40 forbids a committed `encryption_key` |
| ARENA B | R-03 position/district `60a289b` | CONFIRMED | 39/39 |
| ARENA B | D-04 debug keystore creds `60a289b` | CONFIRMED | HEAD export_presets.cfg:23-28 empty; no keystore tracked. The debug creds are still in pre-`60a289b` history |
| ARENA B | R-07 LAN payloads `cef6ae6` | CONFIRMED | 26/26 in lan_network.gd |
| ARENA B | C-08 release-export gate `a453425` | CONFIRMED | tools/check.sh:250-253 |
| ARENA C | R0 magenta, root cause `bafb740` | PARTIAL | The fix is present: all 11 `lut_*.png.import` are `importer="3d_texture"`, and check.sh:200-204 pins it. The claimed "0.01-0.30%" is not what the committed HEAD frames show: `visual_truth_gate.py docs/stills/tzverify/*.png` gives world magenta 0.17-0.66%, 6/11 frames are above 0.30%, and S03_noise_vignette FAILs at 0.66% |
| ARENA C | RENDERING_DIAGNOSIS (b) Lossless A/B | CONFIRMED | Part of `bafb740` (12 files); the A/B is runtime and was not re-run |
| ARENA C | RENDERING_DIAGNOSIS (d) SSR/SSAO tier-driven | CONFIRMED | world_env_setup.gd:182-185 reads ssao/ssil/volumetric from visual_quality.tres |
| ARENA C | TG-SEE/HEAR/PLAY `5257745`,`4c6ca10` | CONFIRMED | 110/111 + 7/7 (the one missing line was replaced by PIL HSV, visual_truth_gate.py:84) |
| ARENA C | CHALLENGE-01 `fe3007a` | CONFIRMED | 19/21, 2 message-format lines reworded |
| ARENA C | CHALLENGE-02 partial `c783544` | CONFIRMED | Stated honestly as Partial; X21 is BUG in the matrix |
| ARENA C | CHALLENGE-03 settings_full deleted `0f9685a` | CONFIRMED | File absent; no non-doc reference |
| ARENA C | MISSED-00..05 | CONFIRMED | FUNCTION_MATRIX AL35/AL50/AL55 are "WORKS (smoke)" and say "NO behavioural assertion"; AL57 P2q; IN89 P1b. Matches the claim wording |
| ARENA C | I18N native pass `43c9ecd` / truth gate `21c6563` | CONFIRMED | 159/159; the gate is 12/12 now |
| ARENA D | Items 1,6 `855a278` | CONFIRMED | 5/5 |
| ARENA D | Item 2 `1fcf157` | CONFIRMED | exit 3 = SKIP in check.sh |
| ARENA D | Item 3 `bbdaa8e` | CONFIRMED | 11/11 |
| ARENA D | Items 4,5,7,9,10,11,14,15 `d06fe48` | CONFIRMED | 16/16 (message mislabel acknowledged in CORRECTION_LOG #10) |
| ARENA D | Item 8 `53353d5` | CONFIRMED | 13/13 |
| ARENA D | Item 12 `2948e23` | CONFIRMED | `BTN_ONE_MORE_RUN` is absent from data/ and scripts/ |
| ARENA D | Item 13 `363add0` | CONFIRMED | visual_truth_gate.py:84 `img.convert("HSV")` |
| ARENA D | §2 BLACK_FAIL_PCT 40 `7bbc0ca` | CONFIRMED | visual_truth_gate.py:50 |
| ARENA D | §3 symptom masks reviewed | CONFIRMED | Doc-only claim, consistent with CORRECTION_LOG #6 |
| ARENA Design | P1 `2a88503` | CONFIRMED | silent_steps now scales speed_noise (player_3d.gd) |
| ARENA Design | P2 `c2dbeb4`,`4e7560e` | CONFIRMED | quiet_pace skill_tree_manager.gd:168,289; player_3d.gd:693 |
| ARENA Design | P3 `4e7560e` | CONFIRMED | 334/340; the missing lines are later locale rewordings |
| ARENA Design | P4 `f9bbfd7` | CONFIRMED | 12/12 |
| ARENA Design | P5 `24ceb68` | CONFIRMED | player_3d.gd:1171-1175 `refresh_battery_max()` composes both sources |
| ARENA Design | P6/P7 `8f48faf` | CONFIRMED | 31/31 |
| ARENA Design | P8 `ee273ee`,`24ceb68` | CONFIRMED | boss energy ball goes through `_telegraph.warn` |
| TZ | A02 crossfade 2.0 | CONFIRMED | music_manager.gd:118 `FADE_TIME = 2.0`, used :209,:262-263; tz_verify :85 |
| TZ | A03 footsteps 6x3, "stealth/walk/run distinct samples" | FAKE | footstep_system.gd:33,129: STEALTH and WALK share the "walk" sample. :35-42: per-speed files exist only for concrete/metal/wood (+grass/gravel/tile); GDD asphalt/puddle/glass have one sample at every speed. The probe _footstep_check.gd:12 prints `DONE fails=0` unconditionally after `demo()` (assert-based), so it cannot fail |
| TZ | A04 audio caps (by role) | CONFIRMED | du: music 38M + ambience 47M = 85M < 100; sfx 7M + one_shots 2M + ui/jingles ~2M < 50; _pre_norm excluded (export_presets.cfg:3) |
| TZ | V02 no neon/#fff | CONFIRMED | boss_3d.gd emission `#b4452f`, energy-ball light `#c9a24a`; V02_energy_ball.png PASS 0.41% |
| TZ | V05 shadow 2048 | CONFIRMED | HEAD project.godot:296 `=2048` (.mobile 1024); tz_verify :88 |
| TZ | V01 no day | CONFIRMED | day_night.gd (31 lines) has no sky/ambient painter left |
| TZ | G02 headbob 0.1 | CONFIRMED | camera_follow_3d.gd:22 `SPRINT_BOB_AMP = 0.1`. tz_verify :114 only bounds the span to 0.02-0.25, which is looser than the claim |
| TZ | G03 sprint FOV +5 | CONFIRMED | camera_follow_3d.gd:24,91. tz_verify :112 only asserts >3 |
| TZ | G06 sprint x1.6 | CONFIRMED | player_stats.tres:6-7 170/272; tz_verify :115 exact |
| TZ | G07 crouch speed x0.4 / noise x0.3 (static) | CONFIRMED | player_3d.gd:87-88,535,556 |
| TZ | G08 colour #c9a24a + cone 45 | CONFIRMED | player_3d.tscn:179,182; player_3d.gd:1148; tz_verify :92. Caveat: Godot `spot_angle` is a half-angle |
| TZ | G12b flicker below 20% | CONFIRMED | flashlight_stats.tres:11 `20.0`; player_3d.gd:1126 |
| TZ | G12b "cleared by Stability L5" | FAKE | player_3d.gd:1127 needs `_flashlight_stability_bonus < 1.0` to be false, but flashlight_upgrade_manager.gd:42 caps stability at 0.5 and get_bonus :72-79 returns the per-level value, so L5 = 0.5 and the flicker is never cleared. The comment at player_3d.gd:1164-1165 wrongly says "bonus 1.0". tz_verify does not test this |
| TZ | G15 capsule 1.6 | CONFIRMED | player_3d.tscn:8-9 r 0.3 / h 1.6 |
| TZ | G16 respawn | CONFIRMED | Suite P2r _qa_headless_suite_runner.gd:777-820 asserts stage kept, HP 50-60%, battery not refilled; game_manager.gd:113-125 |
| TZ | G17 hardcore death deletes save | PARTIAL | game_manager.gd:172-173 calls `wipe_all_saves()`, but save_system.gd:567-572 (+delete_slot :545-552) deletes only the main file and `.bak`. `.bak2`/`.bak3` survive, and `_read_validated` :257-263 falls back to them. tz_verify :220 checks only `has_save()`, which is main-file-only (:105-106) |
| TZ | G18/G19 roster + Shadow | CONFIRMED | enemy_roster_data.gd via AI_TO_ROSTER: every HP/damage matches GDD.md:167-178; shadow_3d.gd:12-21 = 30/15, vision 0, hearing 15 |
| TZ | G20 boss 70/30, beams 40 | CONFIRMED | boss_3d.gd:9,48,50 |
| TZ | G24 point of no return at D10 | PARTIAL | district_manager.gd:25-40: the gate closes only once D1-D9 are FULL, so entering D10 is not a point of no return as GDD.md:341 states. TZ_DECISIONS.md:38 itself files this as DR-2, so the verdict should be DECIDED, not MET. The P2q assert (:752-761) tests the conditional gate |
| TZ | G34 bunker = real secret; endings reachable | CONFIRMED | progress_tracker.gd:128-130; content/secrets.json:397 zone z_bunker; P2q :763-767; `endings_sim.py`: "PASS: all 5 GDD endings reachable." |
| TZ | S03 ember vignette noise pulse | FAKE | hud_3d.gd:648 sets an ember RGB, but the vignette shader post_process_overlay.gd:141 outputs `vec4(BG_DEEP, COLOR.a*v)`, which discards the RGB, so the ember never renders. The base alpha is 0.55 (:125) and hud caps the pulse at 0.5 under `maxf(default_a, …)`, so no visible pulse. tz_verify :116 `vig_a > 0.0` passes with zero noise (vacuous). S03 and G03 frames are visually identical |
| TZ | S04 search 10 s / 5 m | CONFIRMED | base_monster.gd:45-46, used :345,:424,:495,:625; P2q :748 |
| TZ | E03/T02 cooldown 3600 + skip mechanism (static) | CONFIRMED | ad_service.gd:27,31,111-116; P2q :746. The missing modal is stated honestly |
| TZ | C03 auto-aim | PARTIAL | weapon_base.gd:45,143 works on a synthetic WeaponBase (tz_verify :175-188). No gameplay path instantiates a weapon: weapon_*.tscn are referenced only by scripts/tools/_probe_inst.gd:26-28, and TZ G25 itself says "No weapon system in any scene". The setting has no player-visible effect |
| TZ | C04 arachnophobia rename | CONFIRMED | `MONSTER_CRAWLER_ARACHNOPHOBIA` in 13/13 locales (ru "Слепые псы"); tz_verify :171 |
| TZ | C06 tier fog + particles | CONFIRMED | visual_quality.tres low 0.012 / ultra 0.015, particle_ratio 0.5-1.5; world_env_setup.gd:169-181; settings_manager.gd:434-456; tz_verify :129,:135 |
| TZ | Evidence line "tz_verify: 13 checks" | PARTIAL | TZ_COMPLIANCE.md:19 is stale: _tz_verify_runner.gd has 14 `_check` assertions (the tutorial check at :204 was added in `ad051fc`) |
| CORRECTION_LOG | #1 LUTs Texture3D | CONFIRMED | All 11 `lut_*.png.import`: `importer="3d_texture"`, `CompressedTexture3D`, 16 h-slices; PNGs are 256x16; world_env_setup.gd:223-226 |
| CORRECTION_LOG | #2 .import committed (`37581d7`) | CONFIRMED | 539 tracked .import files; all 539 `path=` targets exist in .godot/imported |
| CORRECTION_LOG | #3 fog per tier single source (`2547fff`) | CONFIRMED | visual_quality.tres + world_env_setup.gd:163-187. The other fog writers (weather_vfx.gd:51-64, district_themes) are on the procedural path, which is dead because all 11 scenes/districts/*.tscn exist and contain no WorldEnvironment |
| CORRECTION_LOG | #8 _sign_progress round-trip; P2m fix `c00f118` | PARTIAL | save_system.gd:131-133 signs the `JSON.parse_string(JSON.stringify(...))` copy (correct). But the cited `c00f118` is docs-only (ARENA_CLOSURE/RUN_STATE/TZ_DECISIONS). The P2m `_ensure_playing()` fix (_qa_headless_suite_runner.gd:92,540) landed in `9fc8665` |
| FUNCTION_MATRIX | Footer status counts | CONFIRMED | Script recount of 114 rows: WORKS 99, FIXED 6, CANNOT-TEST-HEADLESS 6, BY-DESIGN-LIMIT 1, PARTIAL 1, BUG 1, UNTESTED 0. Exact match, no duplicate IDs |
| FUNCTION_MATRIX | Footer row breakdown | PARTIAL | FUNCTION_MATRIX.md:153-154 says "Spine: 87 … Extra: 27 X-rows". The real rows are 58 AL + 32 IN = 90 spine and 24 X (X01-X24); the totals only match 114 by coincidence. The header at :13 still says "89 spine rows (57 autoloads…)" |
| i18n | `i18n_truth_gate.py` | CONFIRMED | `12/12 locales PASS` (each missing=0 mixed=0 overflow=0) |
| i18n | `hardcoded_text_gate.py` | CONFIRMED | `hardcoded_text_gate: 0 hit(s)` |
| i18n | `hardcoded_text_gate.py --demo` | CONFIRMED | `demo OK` |
| check.sh | `bash tools/check.sh --static` | CONFIRMED | exit 0; `Всё зелёное. Проверок пройдено: 23`, 0 FAIL lines (sub-gate "53 проверок пройдено") |

CONFIRMED=79 PARTIAL=7 FAKE=3
