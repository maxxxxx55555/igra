# Round 4, HEAD b8b20c0, tag v8.0.0-rc4

Static verification only: code and data read at HEAD, history via `git show`, python and bash gates
run locally. The Godot binary was not run. Runtime-only numbers (bot, suite, tz_verify output, draw
calls) are accepted when the code does not contradict them. Code outside the 7 scripts and 4 tool
files touched by `5cf3b27`/`b8b20c0` is byte-identical to rc3 (`git diff --stat 5402640 HEAD`), so
rc3 line evidence for untouched files still applies. The values were re-grepped at HEAD anyway.

| Source | Item | Verdict | Evidence |
|---|---|---|---|
| ARENA A | B1 finale boss timing `5e1093b` | CONFIRMED | Ancestor of HEAD; 39/39 added code lines present |
| ARENA A | B2 document id `7034bcd` | CONFIRMED | Ancestor; 33/33 lines present |
| ARENA A | B3 skill compounding `afadb4b` | CONFIRMED | Ancestor; 44/44; player_stats.tres:4 `resource_local_to_scene` |
| ARENA A | B4 checksum-only saves `92934a7` + `ac877a5` | CONFIRMED | Both ancestors; 49/49 and 4/4 present; save_system.gd:199 rejects no-hmac |
| ARENA A | B5 NG+ bypasses `fe7ef0e` | CONFIRMED | Ancestor; 68/70 (2 reworded later); wipe_all_saves removes ng_plus_data.json (save_system.gd:586-590) |
| ARENA A | B6 daily signing `e9686d7` | CONFIRMED | Ancestor; 33/33 |
| ARENA A | B7 duplicate autoloads `bb662b4` | CONFIRMED | Ancestor; 21/21; 58 unique autoloads |
| ARENA A | B8 kills pay wallet `1cf3aaf` | CONFIRMED | Ancestor; 28/28 |
| ARENA A | B9+B14 atomic try_add `36d44be` | CONFIRMED | Ancestor; 88/88 |
| ARENA A | B10 `cc1e0b3` | CONFIRMED | Ancestor; 47/47; world_runtime.gd:72-76 saves after placement |
| ARENA A | B11 `d7a0692` | CONFIRMED | Ancestor; 22/22 |
| ARENA A | B12 `c814621` | CONFIRMED | Ancestor; 23/23 |
| ARENA A | B13 `a36ac8b` | CONFIRMED | Ancestor; 50/50; import calls load_all (save_system.gd:69-70), autosave writes SAVE_PATH (:104) |
| ARENA A | B15 `8c99689` | CONFIRMED | Ancestor; 34/36 (2 reworded) |
| ARENA A | B16 `cb73c83` | CONFIRMED | Ancestor; 14/14 |
| ARENA A | Q1 `a0ec4ee` | CONFIRMED | Ancestor; 35/35 |
| ARENA B | P-01 `92934a7` | CONFIRMED | As B4 |
| ARENA B | P-03 `9b7a46b` | CONFIRMED | Ancestor; 131/131 lines present |
| ARENA B | P-04 `9b7a46b` | CONFIRMED | flashlight_upgrade_manager.gd:132-167 signed envelope + clamp; the levels now also live in the HMAC-signed save (save_system.gd:293) |
| ARENA B | P-05 tamper closed / clock defer | CONFIRMED | `e9686d7` present; wall-clock trust is inherently client-side |
| ARENA B | P-06 slot swap | CONFIRMED | load_slot checks slot_id (save_system.gd:510-511) |
| ARENA B | P-07 semantic validation | CONFIRMED | `9b7a46b` lines present; from_dict clamps every branch (flashlight_upgrade_manager.gd:176) |
| ARENA B | R-01 `2278cf9` | CONFIRMED | Ancestor; 12/12; IntegrityGuard autoload |
| ARENA B | R-02 defer | CONFIRMED | integrity_guard.gd checks only non-finite position and the fall floor, as the reason says |
| ARENA B | R-08 defer | CONFIRMED | Same inherent reason as P-05 |
| ARENA B | D-01 defer | CONFIRMED | Inherent; threat model |
| ARENA B | D-02 defer | CONFIRMED | Inherent; key is client-held (save_system.gd:23) |
| ARENA B | D-03 defer (owner) | CONFIRMED | release_export_check OK in check.sh; .gitignore:85 `.signing/`, nothing tracked |
| ARENA B | R-03 `60a289b` | CONFIRMED | Ancestor; 41/41; district id whitelisted (save_system.gd:327,533) |
| ARENA B | R-07 `cef6ae6` | CONFIRMED | Ancestor; 26/26 |
| ARENA B | D-04 `60a289b` | CONFIRMED | As R-03 |
| ARENA B | C-08 `a453425` | CONFIRMED | Ancestor; 59/59; gate OK in check.sh --static |
| ARENA C | R0 `bafb740` | PARTIAL | Root cause is real: 11/11 LUT .import files are `importer="3d_texture"`, pin OK. But the numbers in ARENA_CLOSURE.md:62 (0.17–0.46%, G03 1.01%) are from the rc2 frames. The committed rc4 frames (refreshed in `b8b20c0`) read 0.15–0.42% and G03 **1.28%**. ORDER_PASS_REPORT.md:32 already has the rc4 numbers |
| ARENA C | RENDERING (b) lossless | CONFIRMED | Folded into `bafb740` (runtime A/B, not contradicted) |
| ARENA C | RENDERING (d) SSR/SSAO | CONFIRMED | visual_quality.tres ssao/ssr per tier |
| ARENA C | TG gates `5257745`, `4c6ca10` | CONFIRMED | Ancestors; 118/119 and 7/7 |
| ARENA C | CHALLENGE-01 `fe3007a` | CONFIRMED | Ancestor; 20/22 |
| ARENA C | CHALLENGE-02 partial `c783544` | CONFIRMED | Ancestor; 10/10; residual honestly tracked as matrix X21 BUG |
| ARENA C | CHALLENGE-03 `0f9685a` | CONFIRMED | scripts/ui/settings_full.gd absent |
| ARENA C | MISSED-00..05 | CONFIRMED | Matrix rows WORKS; `0d3d533` 81/81 lines present |
| ARENA C | I18N `43c9ecd` / `21c6563` | CONFIRMED | 159/159 and 217/218 present; i18n_truth_gate 12/12 PASS now |
| ARENA D | SLOP 1, 6 `855a278` | CONFIRMED | 5/5 present |
| ARENA D | SLOP 2 `1fcf157` | CONFIRMED | 3/3 |
| ARENA D | SLOP 3 `bbdaa8e` | CONFIRMED | 11/11 |
| ARENA D | SLOP 4,5,7,9,10,11,14,15 `d06fe48` | CONFIRMED | 16/16 |
| ARENA D | SLOP 8 `53353d5` | CONFIRMED | 13/13 |
| ARENA D | SLOP 12 `2948e23` | CONFIRMED | BTN_ONE_MORE_RUN absent |
| ARENA D | SLOP 13 `363add0` | CONFIRMED | visual_truth_gate.py:84 PIL HSV |
| ARENA D | SLOP §2 `7bbc0ca` | CONFIRMED | BLACK_FAIL_PCT = 40.0 |
| ARENA D | SLOP §3 reviewed | CONFIRMED | Consistent with X20 row and CORRECTION_LOG #6 |
| ARENA Design | P1 `2a88503` | CONFIRMED | 2/2 |
| ARENA Design | P2 `c2dbeb4`, `4e7560e` | CONFIRMED | 80/86 and 336/342 |
| ARENA Design | P3 `4e7560e` | CONFIRMED | As above |
| ARENA Design | P4 `f9bbfd7` | CONFIRMED | 12/12 |
| ARENA Design | P5 `24ceb68` | CONFIRMED | 35/37; refresh_battery_max recomputes from both sources |
| ARENA Design | P6/P7 `8f48faf` | CONFIRMED | 34/34 |
| ARENA Design | P8 `ee273ee`, `24ceb68` | CONFIRMED | 3/3 |
| ARENA | Open defers / "No P0 deferred" | CONFIRMED | Matches the table rows |
| TZ | Every verdict is in the legend | CONFIRMED | MET, MET-STATIC, DECIDED, DEFERRED-STRUCTURAL, NEEDS-EYES, BY-DESIGN-ABSENT, NEEDS-MEASUREMENT, GAP-OWNER all defined (TZ_COMPLIANCE.md:8-17) |
| TZ | Evidence: "tz_verify 15 checks, fails=0 (C8 rc2 run)" | PARTIAL | The HEAD runner has **16** checks: `b8b20c0` added the C06 at-load check at _tz_verify_runner.gd:104. The C06 and G17 rows (TZ_COMPLIANCE.md) cite an rc4 tz_verify run, but the evidence line at TZ_COMPLIANCE.md:21 still names the rc2 run and 15 checks |
| TZ | Evidence: footstep probe exits 1 | CONFIRMED | _footstep_check.gd:13-15 |
| TZ | Evidence: suite fails=0 | CONFIRMED | Runtime; not contradicted |
| TZ | A02 crossfade 2.0 s | CONFIRMED | music_manager.gd:118, used :209,262 |
| TZ | A03 DECIDED DR-A03 | CONFIRMED | footstep_system.gd:47-49 walk/jog/sprint + pitch 0.9/1.0/1.12 |
| TZ | A04 caps MET-STATIC | CONFIRMED | Tracked sizes: sfx 6.64 MB, one_shots 1.12, ambience non-src 16.8 MB (16.0 MiB), music 39.0 MB (37.2 MiB), wav_src 31.4 MB (29.9 MiB). export_presets.cfg:3 excludes `ambience/wav_src/**` |
| TZ | A01 DEFERRED | CONFIRMED | default_bus_layout.tres:15-54 has 7 buses incl. Hum, as the row now says |
| TZ | V02 no neon / #fff MET | CONFIRMED | base_monster.gd:663-690 brass #c9a24a flash, restores the original via meta; P2b (suite:290-303) |
| TZ | V05 shadow 2048 | CONFIRMED | project.godot:296 |
| TZ | V01 no day | CONFIRMED | day_night.gd is a 31-line clock |
| TZ | D03 DECIDED | CONFIRMED | TZ_DECISIONS D03/V01 row |
| TZ | V03 GAP-OWNER | CONFIRMED | TZ_DECISIONS V03 row |
| TZ | G01 DECIDED | CONFIRMED | main_3d.tscn:61 fps_mode = true |
| TZ | G02 headbob 0.1 | CONFIRMED | camera_follow_3d.gd:22 |
| TZ | G03 FOV +5 | CONFIRMED | camera_follow_3d.gd:24 |
| TZ | G04 DECIDED 3.2 m | CONFIRMED | interactor.gd:24 |
| TZ | G06 sprint ×1.6 | CONFIRMED | player_stats.tres:6-7 170/272 |
| TZ | G07 crouch | CONFIRMED | player_3d.gd:87-88,542,563; deferred halves in TZ_DECISIONS |
| TZ | G08 colour/cone MET, range/energy NEEDS-EYES | CONFIRMED | player_3d.tscn:179-184 (#c9a24a, 45°, 24, 16 m); upgrades now scale from the scene base (player_3d.gd:1160) |
| TZ | G09 DECIDED | CONFIRMED | player_3d.gd:96 100/450 |
| TZ | G10 DECIDED | CONFIRMED | battery.tres:14 effect_value 35 |
| TZ | G12b flicker <20%, cleared by L5 | CONFIRMED | flashlight_stats.tres:11 threshold 20; player_3d.gd:1140 gated on `_flashlight_stability_maxed` (:1164); upgrades restored from the save on respawn/Continue (save_system.gd:335). "L5 cuts drain 50%" is only asserted as a variable (see the b8b20c0 drain-check row) |
| TZ | G13 DECIDED | CONFIRMED | player_3d.gd:79-81 14/21/35 |
| TZ | G15 capsule 1.6 | CONFIRMED | player_3d.tscn:9 |
| TZ | G16 respawn | CONFIRMED | game_manager.gd:113-136 |
| TZ | G17 hardcore wipe | CONFIRMED | game_manager.gd:172-173 -> wipe_all_saves (save_system.gd:575-589): main+slots+.bak..bak3, then reset_all (:579), which clears flashlight (:367). P2r calls reset_all directly; the wipe reaches it transitively |
| TZ | G18/G19 roster | CONFIRMED | Unchanged since rc3 (GDD.md:170-181 values) |
| TZ | G20 boss 70/30, beams 40 | CONFIRMED | boss_3d.gd:9,48,50 |
| TZ | G21 DEFERRED | CONFIRMED | TZ_DECISIONS G21 row |
| TZ | G22 DECIDED | CONFIRMED | TZ_DECISIONS G22 row |
| TZ | G24 DECIDED | CONFIRMED | district_manager.gd:32-42 |
| TZ | G25 DEFERRED | CONFIRMED | weapon_manager not instanced by any scene |
| TZ | G26 DEFERRED | CONFIRMED | take_photo has no caller |
| TZ | G27 DECIDED | CONFIRMED | player_3d.gd:413 JOY_ZONE_RATIO 0.35 |
| TZ | G28/D04 GAP-OWNER | CONFIRMED | TZ_DECISIONS row |
| TZ | G31-33 DECIDED | CONFIRMED | TZ_DECISIONS row |
| TZ | G34 MET / DECIDED | CONFIRMED | progress_tracker.gd:128 bunker secret; now labelled DECIDED (DR-5) |
| TZ | S01 DECIDED | CONFIRMED | No hit/dodge noise in player_3d.gd |
| TZ | S02 DEFERRED | CONFIRMED | base_monster.gd reads no player visibility |
| TZ | S03 ember pulse MET | CONFIRMED | post_process_overlay.gd:141 keeps COLOR.rgb; tz_verify:143 warmth delta |
| TZ | S04 search MET-STATIC | CONFIRMED | base_monster.gd:45-46 10 s / 5 m |
| TZ | S04-hide DEFERRED | CONFIRMED | HidingSpot is referenced by no scene or spawner (only its class file and validate_list) |
| TZ | D02 DECIDED | CONFIRMED | TZ_DECISIONS row |
| TZ | E03/T02 | CONFIRMED | ad_service.gd:27,31,111-115 |
| TZ | E05 DECIDED | CONFIRMED | TZ_DECISIONS E05 row, balance_sim ledger |
| TZ | C03 DEFERRED | CONFIRMED | Melee sphere 2.7 m at player_3d.gd:326; no gameplay weapon |
| TZ | C04 MET | CONFIRMED | ru.json:276 "Слепые псы", en.json:276 "Blind Dogs" |
| TZ | C06 tier fog + particles MET | CONFIRMED | fog_setup.gd no longer writes density; WorldEnvSetup (main_3d.tscn:87) applies the tier. The other fog writers are dead or weather-only: district_grading's Environment branch per KNOWN_ISSUES, and weather_vfx reads `/root/WorldEnvironment` |
| TZ | P01 DEFERRED | CONFIRMED | TZ_DECISIONS P01 row |
| TZ | P02 NEEDS-MEASUREMENT | CONFIRMED | TZ_DECISIONS P02 row |
| TZ | N01 / I02 / T01 GAP-OWNER | CONFIRMED | TZ_DECISIONS rows |
| TZ | Every non-MET row has a TZ_DECISIONS reason | CONFIRMED | All MET-STATIC/DECIDED/DEFERRED/GAP-OWNER/NEEDS-*/BY-DESIGN-ABSENT ids have a row |
| TZ | Footer "Every audit row now has a verdict above" | PARTIAL | 0 GAP-DEV is true. But 27 of the 81 audit rows are not in the ledger: 20 MET (e.g. S05, S06), 4 EXTRA and 3 BY-DESIGN (G29, E02, V08). They keep only the audit's verdict, and EXTRA and BY-DESIGN are not in the ledger legend (TZ_COMPLIANCE.md:78) |
| TZ_DECISIONS | C06 row "SUPERSEDED: C06 is MET since `2547fff`" | PARTIAL | Contradicted by CORRECTION_LOG #24: until `b8b20c0`, fog_setup.gd reset every load to 0.015, so C06 was not met at load from `2547fff` to rc3 (TZ_DECISIONS.md:19) |
| Fix 0873f38 | S03 vignette keeps RGB | CONFIRMED | post_process_overlay.gd:141 still present |
| Fix 0873f38 | S03 check non-vacuous | CONFIRMED | tz_verify:143 needs r>0.4 and warmth +0.03 (27ba1d5 checked `alpha > 0`) |
| Fix 0873f38 | G12b keyed on max level | CONFIRMED | player_3d.gd:1164 |
| Fix 0873f38 | G12b L5 check non-vacuous | CONFIRMED | tz_verify:176-185 |
| Fix 0873f38 | A03 walk/jog/sprint + pitch | CONFIRMED | footstep_system.gd:47-49 |
| Fix 0873f38 | A03 probe can fail | CONFIRMED | _footstep_check.gd:13-15 exits 1 on fails |
| Fix 0873f38 | G17 backups removed | CONFIRMED | save_system.gd:556-560 `_remove_with_backups` |
| Fix 0873f38 | G17 check non-vacuous | CONFIRMED | tz_verify:252-265 seeds .bak..bak3 |
| Fix 5402640 | Reapply upgrades on every player `_ready` | CONFIRMED | player_3d.gd:245-247 |
| Fix 5402640 | Scale from scene base 24 / 16 m | CONFIRMED | player_3d.gd:239-240,1160 |
| Fix 5402640 | P2r respawn check non-vacuous | CONFIRMED | Still fails without the reapply (maxed false) |
| Fix b8b20c0 | "flashlight" key written by `_save` and `save_slot` | CONFIRMED | save_system.gd:293,490; the envelope HMAC covers it |
| Fix b8b20c0 | Load paths: Continue, import, respawn, load_slot | CONFIRMED | load_all :335 (continue_game, respawn_after_death game_manager.gd:119/139, import :69-70), load_slot :543 |
| Fix b8b20c0 | Clear paths: New Game, hardcore wipe, Reset Progress | CONFIRMED | start_new_game -> reset_all :367; trigger_death and settings_screen.gd:344 -> wipe_all_saves -> reset_all (:579) |
| Fix b8b20c0 | Purchase path | CONFIRMED | try_purchase (flashlight_upgrade_manager.gd:85-99) changes the in-memory wallet and levels. Neither reaches the save until the next `_save`, so a death or reload reverts both together. No exploit |
| Fix b8b20c0 | Old save without the "flashlight" key | CONFIRMED | Fallback is `to_dict()` (:335,:543), i.e. the live levels, which always mirror the cfg (every mutation goes through `_save`). Same behavior as before the fix until the first new save writes the key, so no regression. Residual: a legacy slot inherits the active run's levels |
| Fix b8b20c0 | from_dict writes the cfg on every load | CONFIRMED | flashlight_upgrade_manager.gd:177. Harmless extra write; the cfg is now only a mirror and is still signed |
| Fix b8b20c0 | P2r reset/respawn checks fail on pre-fix code | CONFIRMED | At 5cf3b27 the save has no key, so after respawn the zeroed levels stay: maxed=false, FAIL. The reset mutation (keep the key, drop :367) gives stability 5 after reset_all, FAIL. `_flashlight_drain_cut` is missing at the parent |
| Fix b8b20c0 | Stability L1-L5 cut drain 10-50% | CONFIRMED | player_3d.gd:760 `drain *= 1.0 - _flashlight_drain_cut`, set at :1163 from LEVEL_BONUSES 0.1..0.5 (GDD.md:88-93); the dead softness write is removed |
| Fix b8b20c0 | Stability drain regression check | PARTIAL | P2r asserts only the field: suite:843 `q.get("_flashlight_drain_cut") == 0.5`. No battery drain is measured, so removing player_3d.gd:760 still passes P2r. CORRECTION_LOG #25 says "P2r covers ... drain (mutation-tested)" |
| Fix b8b20c0 | fog_setup.gd density line removed | CONFIRMED | fog_setup.gd:16-17 comment only; WorldEnvSetup (tscn:87) runs before FogSetup (:90) |
| Fix b8b20c0 | tz_verify C06 at-load check non-vacuous | CONFIRMED | _tz_verify_runner.gd:99-104. Default tier 2 (and the owner's settings.cfg tier 2) wants 0.014, and pre-fix code gave 0.015, so the check fails. It would be vacuous only at tier 3 (0.015) |
| Fix b8b20c0 | Hit flash brass + restore | CONFIRMED | base_monster.gd:663-690. Overlapping hits restore the original via meta; a stale restore is skipped by `material_override == mat` |
| Fix b8b20c0 | P2b check non-vacuous | CONFIRMED | Pre-fix restore assigned `material_override.duplicate()`, a new object, so suite:299 `!= mats_before[i]` fails. An empty mesh list is a FAIL (:303). Min roster HP 30 > the 25 damage |
| Fix 5cf3b27 | Guard wired into check.sh / headless_suite / autoplay_bot | CONFIRMED | check.sh:272-275,347; headless_suite:23-28; autoplay_bot:19-24. Each cds to the repo root first |
| Fix 5cf3b27 | "never deletes a file the owner had" | PARTIAL | True while the snapshot dir survives. If `$UDG_SNAP` is lost (TEMP cleanup, second run), user_data_guard.sh:48 `grep -qxF -- "$f" "$UDG_SNAP/list" \|\| rm -f` fails open and deletes every profile file. :55 then compares two empty strings and :57 prints "restored byte-identical", rc 0. Reproduced on a scratch dir: 2/2 owner files deleted, success reported |
| Fix 5cf3b27 | Restore on timeout / Ctrl-C | CONFIRMED | EXIT trap + `trap 'exit 130' INT TERM`. Per-gate `timeout` does not end the script; outer TERM/INT reach the EXIT trap. SIGKILL cannot, as with any trap |
| Fix 5cf3b27 | `--demo` exercises the real functions | CONFIRMED | _udg_demo calls the real udg_snapshot/udg_restore. Mutants: no-op restore gives "save not restored" rc 1; no-delete gives rc 1. udg_dir and the trap wiring are not exercised (udg_dir resolved by hand to the 11-file profile) |
| Fix 5cf3b27 | `set -u` / pipefail safety | CONFIRMED | Every optional var is defaulted (`${APPDATA:-}`, `${UDG_ACTIVE:-0}`, `${TMPDIR:-/tmp}`, `${1:-}`); no `set -e` in the callers |
| Fix 5cf3b27 | Coverage of all QA runs that touch the profile | PARTIAL | tz_verify, the main TZ evidence runner (TZ_COMPLIANCE.md:21), is run directly and is not wrapped. Routes.start_game (_tz_verify_runner.gd:88) -> reset_all, and world_runtime.gd:76 save_all overwrites the owner's save before `_backup_saves` runs at :252. Since `b8b20c0`, reset_all also rewrites flashlight_upgrades.cfg, which _save_paths (:40-45) does not cover. A direct suite run is equally unguarded: P2r save_all/reset_all (suite:802,845), then P3 save_all (:858) writes a reset-state save |
| CORRECTION_LOG | Header "Newest first" | PARTIAL | Rows run oldest to newest, #1 to #28 (CORRECTION_LOG.md:3) |
| CORRECTION_LOG | #1 R0 `bafb740` | CONFIRMED | LUT imports are Texture3D; 11 LUT .import changes |
| CORRECTION_LOG | #2 `37581d7` | CONFIRMED | 530 .import paths in the commit |
| CORRECTION_LOG | #3 C06 `2547fff` | CONFIRMED | Commit rebuilt tier fog; "single source" now true at HEAD, and #24 records it was not until rc4 |
| CORRECTION_LOG | #4 V05 | CONFIRMED | project.godot:296 2048 |
| CORRECTION_LOG | #5 X22 `0d3d533` | CONFIRMED | Matrix X22 FIXED (test bug) |
| CORRECTION_LOG | #6 X20 `0d3d533` | CONFIRMED | Matrix X20 PARTIAL |
| CORRECTION_LOG | #7 footer 61/40 | CONFIRMED | As rc3 (0d3d533^ matrix) |
| CORRECTION_LOG | #8 `ac877a5`, `9fc8665` | CONFIRMED | `_ensure_playing` in 9fc8665 |
| CORRECTION_LOG | #9 A04 `4bb5772` | CONFIRMED | Old premise is wrong, but #23 corrects it in the log itself |
| CORRECTION_LOG | #10 `d06fe48` item 6 | CONFIRMED | Body line 14 "6. theme_provider" |
| CORRECTION_LOG | #11 `ad051fc` / `ae410b9` | CONFIRMED | ad051fc body "all PASS visual_truth_gate" |
| CORRECTION_LOG | #12 `ae410b9` | CONFIRMED | As rc3 |
| CORRECTION_LOG | #13 P01 246 | CONFIRMED | Matches TZ P01 / TZ_DECISIONS |
| CORRECTION_LOG | #14 S01 `c00f118` | CONFIRMED | c00f118 adds the S01 DR-3 row |
| CORRECTION_LOG | #15 magenta numbers | CONFIRMED | Labelled rc1/rc2; historical |
| CORRECTION_LOG | #16 S03 | CONFIRMED | As rc3 |
| CORRECTION_LOG | #17 G12b | CONFIRMED | As rc3 |
| CORRECTION_LOG | #18 A03 | CONFIRMED | As rc3 |
| CORRECTION_LOG | #19 G17 | CONFIRMED | As rc3 |
| CORRECTION_LOG | #20 G24 / C03 | CONFIRMED | Ledger DECIDED / DEFERRED-STRUCTURAL |
| CORRECTION_LOG | #21 | CONFIRMED | 58 AL + 32 IN + 24 X; 14/15 checks at rc1/rc2 |
| CORRECTION_LOG | #22 | CONFIRMED | 5402640 diff matches |
| CORRECTION_LOG | #23 A04 reason | CONFIRMED | Sizes above; the ambience/ layer oggs are imports only, and layer_dark/lit live in music/ |
| CORRECTION_LOG | #24 fog_setup | CONFIRMED | b8b20c0 diff removes the density line; C06 at-load check added |
| CORRECTION_LOG | #25 per-run upgrades, Stability drain | PARTIAL | Code matches (see the b8b20c0 rows). "P2r covers ... drain (mutation-tested)" is too strong: only the field is asserted (suite:843), and the drain application (player_3d.gd:760) is unchecked |
| CORRECTION_LOG | #26 hit flash | CONFIRMED | b8b20c0 diff: pure white + duplicate-restore replaced |
| CORRECTION_LOG | #27 ORDER_PASS lists | CONFIRMED | C4 row, C5 row (`0d3d533`, `9fc8665`), visual row and residual list all corrected |
| CORRECTION_LOG | #28 tag | CONFIRMED | Local and origin `v8.0.0-rc4^{}` = b8b20c0 |
| FUNCTION_MATRIX | Status counts | CONFIRMED | Script recount of 114 unique rows: WORKS 99, FIXED 6, CANNOT-TEST-HEADLESS 6, BY-DESIGN-LIMIT 1, PARTIAL 1, BUG 1, UNTESTED 0 = footer |
| FUNCTION_MATRIX | Spine 90 (58 AL + 32 IN) | CONFIRMED | AL01-AL58, IN58-IN89; project.godot 58 autoloads, 29 live input actions |
| FUNCTION_MATRIX | Extra 24 X rows | CONFIRMED | X01-X24 |
| FUNCTION_MATRIX | Header "Current:" line | CONFIRMED | Matches |
| FUNCTION_MATRIX | Grand total 114 | CONFIRMED | 90 + 24 |
| ORDER_PASS | Phase deltas / Residual lists | CONFIRMED | C4 lists match the ledger; C03 in the deferred residuals |
| ORDER_PASS | Header "the candidate is the `v8.0.0-rc1` tag" | PARTIAL | Stale: the C8 loop in the same report runs to rc4 (ORDER_PASS_REPORT.md:3-4) |
| ORDER_PASS | check.sh "42 checks" / "rc4: check.sh full 42 green" | PARTIAL | `5cf3b27` added 2 `ok` checks (check.sh:212 guard demo, :347 guard restore). HEAD --static gives 24 (was 23). A green full run is 24 + reimport + 18 headless gates + guard = **44**, not 42 (ORDER_PASS_REPORT.md:23,42; b8b20c0 message) |
| ORDER_PASS | Visual row: rc4 frames 10/11 PASS 0.15–0.42%, G03 1.28%, 85% edge | CONFIRMED | Gate rerun on HEAD frames: exactly that; G03 hits 85.5% in the outer 15% band, median hue 333 |
| ORDER_PASS | Known-bad frame 9.49%; V02 frame 0.05% | PARTIAL | `docs/stills/evidence/magenta_corruption_suburbs.png` reads **13.19%** on the HEAD gate (13.19–13.28% on every gate version since 5257745), never 9.49% (ORDER_PASS_REPORT.md:32). V02 on the committed rc4 frame is 0.01% hue-only world band / 0.02% full frame, not 0.05% (:58; the note dates from 27ba1d5) |
| ORDER_PASS | Round 1 79/7/3 | CONFIRMED | 0873f38 report totals and row counts |
| ORDER_PASS | Round 2 128/6/0 | CONFIRMED | 5402640 report |
| ORDER_PASS | Round 3 145/14/0 | CONFIRMED | b8b20c0 report: 145/14/0 rows = totals line |
| ORDER_PASS | Tags rc1 27ba1d5, rc2 5724544, rc3 5402640 | CONFIRMED | `git rev-parse` |
| ORDER_PASS | tz_verify rc1 14 / rc2 15 | CONFIRMED | 27ba1d5 / 5724544 runners |
| ORDER_PASS | 28 corrections (14 / 15-21 / 22 / 23-28) | CONFIRMED | CORRECTION_LOG row counts at 27ba1d5=14, 0873f38=21, 5402640=22, HEAD=28 |
| ORDER_PASS | Footstep mutation fails=3 | CONFIRMED | Code unchanged since rc3 |
| ORDER_PASS | No external CLOSURE_VERIFICATION.md | CONFIRMED | Not tracked |
| ORDER_PASS | C9 keystore gitignored | CONFIRMED | .gitignore:85; nothing tracked under .signing/ |
| Gates | i18n_truth_gate | CONFIRMED | 12/12 locales PASS, 0 missing/mixed/overflow, rc 0 |
| Gates | hardcoded_text_gate | CONFIRMED | 0 hits, rc 0 |
| Gates | hardcoded_text_gate --demo | CONFIRMED | demo OK, rc 0 |
| Gates | visual_truth_gate tzverify/*.png | CONFIRMED | 10/11 PASS (0.15–0.42%), G03_sprint_fov FAIL 1.28%. Matches the ORDER_PASS visual row, not the ARENA R0 row (see the R0 row) |
| Gates | user_data_guard.sh --demo | CONFIRMED | demo OK, rc 0 |
| Gates | check.sh --static (TLS_SKIP_REIMPORT=1) | CONFIRMED | "Всё зелёное", 24 checks passed, 0 FAIL, exit 0 |
| Gates | git status after gates | CONFIRMED | Only the known ` M project.godot`; nothing reverted |

CONFIRMED=186 PARTIAL=12 FAKE=0
