# Round 6, HEAD 4061f1b, tag v8.0.0-rc6

Static verification only. Code and data were read at HEAD, history came from `git show`, and the
python and bash gates were run locally. The Godot binary was not run. Runtime-only numbers (bot,
suite, tz_verify output, draw calls, the full check.sh count) are accepted when the code does not
contradict them. Local and origin tags rc1-rc6 resolve to 27ba1d5 / 5724544 / 5402640 / b8b20c0 /
3ee3568 / 4061f1b. "n/m lines" means n of the m non-trivial code lines the commit added are still
present at HEAD. The misses were checked by hand and are refactors or later corrections.

| Source | Item | Verdict | Evidence |
|---|---|---|---|
| ARENA A | B1 finale boss timing `5e1093b` | CONFIRMED | Exists, ancestor of HEAD, 39/39 lines |
| ARENA A | B2 document id `7034bcd` | CONFIRMED | 33/33 |
| ARENA A | B3 skill bonuses `afadb4b` | CONFIRMED | 44/44 |
| ARENA A | B4 progress_hmac `92934a7` (+`ac877a5`) | CONFIRMED | 49/49 and 4/4. save_system.gd:222 rejects a missing progress_hmac |
| ARENA A | B5 NG+ bypasses `fe7ef0e` | CONFIRMED | 68/70. The 2 misses are an attack_sim refactor. wipe_all_saves resets NG+ (save_system.gd:586-592) |
| ARENA A | B6 daily signing `e9686d7` | CONFIRMED | 33/33 |
| ARENA A | B7 "duplicate RewardsManager/RandomEvents autoloads" `bb662b4`, counted in "17/17 closed" | PARTIAL | The autoload dup and the short-id grant are fixed (21/21). The report's own B7 repro is an unsigned `achievements.cfg` being trusted. That still loads and gets re-signed at HEAD (achievements_manager.gd:205-210). bb662b4's message says this half was deliberately left open (P-02 is P2). ARENA_CLOSURE.md:20 marks B7 closed with no defer note, and the section header claims "17/17 closed" |
| ARENA A | B8 kills pay wallet `1cf3aaf` | CONFIRMED | 28/28 |
| ARENA A | B9+B14 atomic try_add `36d44be` | CONFIRMED | 88/88 |
| ARENA A | B10 district-enter save `cc1e0b3` | CONFIRMED | 47/47 |
| ARENA A | B11 district lock `d7a0692` | CONFIRMED | 22/22 |
| ARENA A | B12 streetlight event once `c814621` | CONFIRMED | 23/23 |
| ARENA A | B13 import/autosave `a36ac8b` | CONFIRMED | 50/50 |
| ARENA A | B15 fall-recovery net `8c99689` | CONFIRMED | 34/36. The P2p check was strengthened to a sentinel wait (suite:680-693). player_3d.gd:375-381 arms it on spawn |
| ARENA A | B16 offline player `cb73c83` | CONFIRMED | 14/14 |
| ARENA A | Q1 heartbeat `a0ec4ee` | CONFIRMED | 35/35 |
| ARENA B | P-01 checksum bypass `92934a7` | CONFIRMED | save_system.gd:190-222 |
| ARENA B | P-03 / P-04 / P-06 / P-07 `9b7a46b` | CONFIRMED | 131/131. The flashlight cfg is signed and clamped (flashlight_upgrade_manager.gd:132-167) |
| ARENA B | P-05 tamper `e9686d7` + clock defer | CONFIRMED | Tamper fix present. Wall-clock trust is an honest inherent defer |
| ARENA B | R-01 watchdog `2278cf9` | CONFIRMED | 12/12. IntegrityGuard autoload is at project.godot:113 |
| ARENA B | R-02 defer | CONFIRMED | The reason holds: integrity_guard.gd:83 covers non-finite position and y<=-50 only |
| ARENA B | R-08, D-01, D-02 inherent defers | CONFIRMED | Client-side limits, as the threat model says |
| ARENA B | D-03 owner defer | CONFIRMED | release_export_check passes, and no key is committed |
| ARENA B | R-03 / D-04 `60a289b` | CONFIRMED | 41/41. release_export_check is green |
| ARENA B | R-07 LAN `cef6ae6` | CONFIRMED | 26/26 |
| ARENA B | C-08 export gate `a453425` | CONFIRMED | 59/59. Wired at check.sh:255 |
| ARENA C | R0 `bafb740` + numbers | CONFIRMED | 112/112. All 11 LUT imports are `3d_texture` (static pin OK). Gate on the rc4 frames: 0.15-0.42%, G03 1.28%, as stated |
| ARENA C | RENDERING_DIAGNOSIS (b), (d) | CONFIRMED | Covered by bafb740. The tier-driven effects read visual_quality.tres |
| ARENA C | TG gates `5257745`, `4c6ca10` | CONFIRMED | 118/119 (the miss is PIL HSV, SLOP 13) and 7/7. LUT pin at check.sh:198 |
| ARENA C | CHALLENGE-01 `fe3007a` | CONFIRMED | 20/22. The misses are a reworded phase-8 check (X22) |
| ARENA C | CHALLENGE-02 partial `c783544` | CONFIRMED | 10/10. The residual is honestly X21 |
| ARENA C | CHALLENGE-03 `0f9685a` | CONFIRMED | settings_full.gd is absent at HEAD |
| ARENA C | MISSED-00..05 | CONFIRMED | Matrix rows AL35/AL50/AL55/AL57/IN89 are WORKS |
| ARENA C | I18N `43c9ecd` / `21c6563` | CONFIRMED | 159/159 and 217/218. The truth gate reads 12/12 now |
| ARENA D | SLOP items 1-15 and §2, §3 (9 rows) | CONFIRMED | Every item 1-15 is mapped. 855a278 5/5, 1fcf157 3/3, bbdaa8e 11/11, d06fe48 16/16, 53353d5 13/13, 363add0 3/3, 7bbc0ca 1/1. BTN_ONE_MORE_RUN has 0 references |
| ARENA Design | P1-P8 (7 rows) | CONFIRMED | 2a88503 2/2, c2dbeb4 80/86 (the misses are i18n value edits), 4e7560e 336/342, f9bbfd7 12/12, 24ceb68 35/37 (the formula now uses a named const, player_3d.gd:1186), 8f48faf 34/34, ee273ee 3/3 |
| ARENA | Open defers / "No P0 is deferred" | CONFIRMED | The only P0 (R0) is closed |
| TZ legend | Every verdict in the legend | CONFIRMED | All 48 rows use legend verdicts |
| TZ sources | tz_verify "17 checks at rc5" | CONFIRMED | 18 `_check` sites, one of them an exclusive else-branch (:245), so 17. The count at HEAD is unchanged since rc5. rc1 14, rc2 15, rc4 16 by the same count |
| TZ sources | footstep probe exits 1 | CONFIRMED | footstep_system.gd:190-204 counts duplicates and missing samples. _footstep_check.gd:15 |
| TZ | A02 fade 2.0 | CONFIRMED | music_manager.gd:118, used at :209/:262. Checked at tz_verify:103 |
| TZ | A03 DECIDED | CONFIRMED | SPEED_FILE walk/jog/sprint (footstep_system.gd:47). Pitch 0.9/1.0/1.12 (:49). Files exist |
| TZ | A04 MET-STATIC | CONFIRMED | ambience 46.0 - wav_src 29.9 = 16.1. 16.1 + sfx 6.3 + one_shots 1.1 = 23.5 MB. Music 37.2 MB. wav_src is in exclude_filter |
| TZ | A01 DEFERRED | CONFIRMED | Buses Master/Music/SFX/Voice/Ambient/UI/Hum (default_bus_layout.tres) |
| TZ | V02 MET | CONFIRMED | Brass `_HIT_FLASH_COLOR` and restore (base_monster.gd). P2b asserts the restore (suite:299-310). The colour is static only |
| TZ | V05 MET | CONFIRMED | project.godot:296 is 2048. tz_verify:106 |
| TZ | V01 MET-STATIC | CONFIRMED | day_night.gd has no environment writer |
| TZ | D03, G01, G04, G09, G10, G13, G22, G27, G31-33, D02, S01, E05 DECIDED (12 rows) | CONFIRMED | Each has a TZ_DECISIONS row. The cited code matches: interactor.gd:24 REACH 3.2, drain 100/450, battery.tres 35, fps_mode=true, combo comment player_3d.gd:75-77, balance_sim ledger 2200+1300+3100 |
| TZ | V03, G28/D04, N01/I02/T01 GAP-OWNER (3 rows) | CONFIRMED | Honest reasons. I02's "1291 keys" was true when written (4bb5772); en.json has 1301 now, which is still "grown past it" |
| TZ | G02 / G03 / G06 MET | CONFIRMED | SPRINT_BOB_AMP 0.1 and SPRINT_FOV_BONUS 5 (camera_follow_3d.gd:22-24). run 272 = 170 x 1.6 (player_stats.tres). The checks are non-vacuous (G03 threshold >3) |
| TZ | G07 split verdict | CONFIRMED | CROUCH_SPEED_MULT 0.4 (:563) and CROUCH_NOISE_MULT 0.3 (:542). Visibility and capsule deferred with reasons |
| TZ | G08 MET / NEEDS-EYES | CONFIRMED | c9a24a, 45°, energy 24, range 16 (player_3d.tscn:179-184) |
| TZ | G12b MET | CONFIRMED | Threshold 20 (flashlight_stats.tres:11). Cleared at max level (player_3d.gd:1140,1164). Drain cut per level (:760). P2r asserts respawn, 0.5 cut and reset (suite:797-869) |
| TZ | G15 MET-STATIC / DECIDED | CONFIRMED | Capsule height 1.6 (player_3d.tscn:9). Attack box 1.4x0.8x3.4 (player_3d.gd:311) |
| TZ | G16 MET | CONFIRMED | P2r uses the exact death_screen.gd:52-54 button path |
| TZ | G17 MET | CONFIRMED | _remove_with_backups covers all 4 files. wipe_all_saves calls reset_all, which clears the flashlight. tz_verify:249-259 seeds and checks |
| TZ | G18 / G19 MET-STATIC | CONFIRMED | All 10 table types + Shadow (shadow_3d.gd:13,16) + boss 800/40 match GDD.md:169-180 |
| TZ | G20 MET-STATIC | CONFIRMED | boss_3d.gd:48-50 0.70/0.30. BEAM_DAMAGE 40 |
| TZ | G21, G25, G26, S02, S04-hide, C03, P01 DEFERRED (7 rows) | CONFIRMED | No weapon_manager in any scene. No take_photo caller. hiding_spot not placed. No visibility reader in enemies |
| TZ | G24 DECIDED | CONFIRMED | P2q asserts both sides (suite:771-782) |
| TZ | G34 MET / DECIDED | CONFIRMED | P2q bunker assert (:784-787). endings_sim green |
| TZ | S03 MET | CONFIRMED | Edge-warmth check is non-vacuous (tz_verify:139) |
| TZ | S04 MET-STATIC | CONFIRMED | SEARCH_TIME 10 / RADIUS 5 (base_monster.gd:45-46). P2q :768 |
| TZ | E03/T02 split | CONFIRMED | Cooldowns 3600 (ad_service.gd:27,31). skip_bonus_coins :111 |
| TZ | C04 MET | CONFIRMED | ru "Слепые псы", en "Blind Dogs", key in all 13 locales. tz_verify:208 |
| TZ | C06 MET | CONFIRMED | fog_setup.gd no longer writes density. Tier presets 0.012/0.013/0.014/0.015. The load check would pass pre-fix only on an Ultra profile |
| TZ | P02 NEEDS-MEASUREMENT | CONFIRMED | Honest reason |
| TZ | Footer "Open GAP-DEV rows: 0" | CONFIRMED | All 54 audit GAP-DEV/GAP-OWNER IDs appear in the ledger (script) |
| TZ_DECISIONS | S03 reason: "85-98% of those pixels sit in the outer 15% edge band ... rc2 and rc4 G03/S03 frames" | PARTIAL | Measured edge share of hue-band hits: rc4 G03 86%, rc2 G03 87%, rc2 S03 98%, but rc4 S03 70% (75% on a min-edge-distance metric). The stated range excludes one of the four cited frames (TZ_DECISIONS.md:50) |
| TZ_DECISIONS | All other non-MET reasons | CONFIRMED | Each non-MET ledger row has a matching, code-consistent reason |
| Fix | `0873f38` S03 / G12b / A03 / G17 | CONFIRMED | All at HEAD. Each new check fails on 5724544^: the G12b L5 spread was >0 at bonus 0.5, edge warmth did not rise, stealth=walk duplicates the key, and .bak2/.bak3 survived the delete |
| Fix | `5402640` upgrades across respawn | CONFIRMED | _ready reapplies from the scene base (player_3d.gd). P2r fails on 5724544 (no reapply) |
| Fix | `b8b20c0` per-run upgrades, drain, fog, hit flash | CONFIRMED | Save/load/slot/reset paths all carry the "flashlight" key (save_system.gd:293,335,367,490,543). Checks fail on 5cf3b27 (no to_dict/reset). Note: a pre-rc4 save without the key inherits the live levels (:335,:543). This is a deliberate migration default |
| Fix | `5cf3b27` guard wiring: headless_suite / autoplay_bot exit status | PARTIAL | A failed `udg_restore` runs only inside the EXIT trap, and bash keeps the script's own exit code. headless_suite exits `$FAILS` (:94) and autoplay_bot exits 0 on 3/3 wins even when the profile was not restored (trap at headless_suite:27, autoplay_bot:23). Reproduced: a trap that returns 1 after `exit 0` still gives rc=0. check.sh is fine because it counts an explicit restore (check.sh:347) |
| Fix | `3ee3568` in-process snapshot for direct runs | PARTIAL | The snapshot is memory-only. The suite restores on its hard timeout (suite:1170-1180). tz_verify has no hard timeout or other abort handler (_tz_verify_runner.gd:68-264), so a script error or window close mid-run loses the snapshot after start_game/G17 have already rewritten the profile. The lost-snapshot demo does fail on 5cf3b27, and the drain check is real |
| Fix | `4061f1b` abort on failed snapshot + "--demo covers the snapshot-failure case" (ORDER_PASS_REPORT.md:44) | PARTIAL | The aborts are present in all five runners (check.sh:273, bots :22/:26, tz_verify:78-81, suite:115-119). But --demo only exercises the mktemp branch (user_data_guard.sh:96). Mutating the per-file `cp && cmp \|\| return 1` check at :41 to a no-op still prints `demo OK`, so the exact round-5 hole (unchecked cp) has no regression check |
| Guard | user_data_guard.sh: set -u, spaces, restore safety | CONFIRMED | Every path is quoted and all expansions are guarded under `set -u`. Restore refuses on a missing or incomplete snapshot and removes only files that were not in the list. Callers cd to the repo root before `udg_dir` reads project.godot |
| Guard | user_data_guard.sh failure-path cleanup | PARTIAL | A failed per-file copy returns at :43 and leaves `$UDG_SNAP` (partial copies of the owner's saves) in TEMP. `_udg_demo` still has the unchecked `mktemp` pattern that 4061f1b fixed in udg_snapshot (:80): with a bad TMPDIR, `d=""` and the demo writes `/tls_savegame.save` and `/saves/` at the filesystem root |
| CORRECTION_LOG | Header "Oldest first" | CONFIRMED | git blame: rows were appended in commit order 648cfd2 → 27ba1d5 → 0873f38 → 5402640 → b8b20c0 → 3ee3568 → 4061f1b |
| CORRECTION_LOG | #1-#7 | CONFIRMED | bafb740 LUT fix, 37581d7 imports, 2547fff fog, 0d3d533 X22/X20. The pre-0d3d533 matrix recounts to 61 WORKS / 40 UNTESTED |
| CORRECTION_LOG | #8 | CONFIRMED | `_ensure_playing` first appears in 9fc8665 (`git log -S`) |
| CORRECTION_LOG | #9-#14 | CONFIRMED | d06fe48 body item "6." is the btn_d StyleBox (SLOP 7). ad051fc says "all PASS". ae410b9 says "C06 ultra tier 0.66%", but on the rc1 frames 0.66% is S03 |
| CORRECTION_LOG | #15 | CONFIRMED | Re-measured: rc1 frames 0.17-0.66% with S03 FAIL. rc2 frames 0.17-0.46% with G03 1.01% |
| CORRECTION_LOG | #16-#20 | CONFIRMED | Matches the 0873f38 diffs |
| CORRECTION_LOG | #21 | CONFIRMED | 90 spine (58 AL + 32 IN) + 24 X. tz_verify 14 at rc1 and 15 at rc2 |
| CORRECTION_LOG | #22-#27 | CONFIRMED | Matches the 5402640 / b8b20c0 diffs. Music layers are in music/ |
| CORRECTION_LOG | #28 | CONFIRMED | origin rc4 now peels to b8b20c0. The earlier push cannot be checked but is not contradicted |
| CORRECTION_LOG | #29-#32 | CONFIRMED | The P2r drain measurement, restore refusal, in-process snapshot and abort paths are all present. V02 hue-only 0.01% and known-bad 13.19% re-measured |
| CORRECTION_LOG | #33 "Both corrected" | PARTIAL | The rc4 count is corrected (44). The S03 reason still gives an edge-share range that the rc4 S03 frame (70%) falls outside (TZ_DECISIONS.md:50) |
| MATRIX | Status recount by script | CONFIRMED | 114 rows: WORKS 99, FIXED 6, CTH 6, BDL 1, PARTIAL 1, BUG 1, UNTESTED 0, which equals the footer (FUNCTION_MATRIX.md:153) |
| MATRIX | Spine/extra header and totals | CONFIRMED | AL01-58, IN58-89 (32), X01-24, no duplicates. project.godot has 58 autoloads and 29 live input actions, and 3 IN rows are FIXED |
| ORDER_PASS | Candidate tag line | PARTIAL | ORDER_PASS_REPORT.md:4 says "rc5 at the last update", but HEAD is tagged rc6 and the same file's :44 reports rc6 results |
| ORDER_PASS | check.sh counts (42 rc1-rc3, 44 from rc4 tag, 24 static) | CONFIRMED | check.sh is identical from 27ba1d5 to 5402640: 23 static + reimport + 18 (20 run_gates, 2 windowed skips) = 42. The guard adds 2 = 44. The static run now gives 24 |
| ORDER_PASS | Verifier rounds 1-5 figures | CONFIRMED | 79/7/3, 128/6/0, 145/14/0, 186/12/0, 132/4/0 each match that round's CLOSURE_VERIFICATION_INTERNAL |
| ORDER_PASS | Correction ranges | PARTIAL | :42 says round 3 gave "CORRECTION_LOG 23-27", but :64 and b8b20c0's message say 23-28 (row 28 was added in b8b20c0) |
| ORDER_PASS | Correction count 33 | CONFIRMED | 33 rows. The per-round split in :64 matches git blame |
| ORDER_PASS | Visual row (:32) | PARTIAL | The numbers match (10/11 PASS 0.15-0.42%, G03 1.28%, known-bad 13.19%, G03 edge 85-87%). But it still calls the r0_after gate the "Blocking R0 lock", which TZ_DECISIONS.md:50 and CORRECTION_LOG #33 say cannot catch an R0 regression. check.sh:190 still labels it "R0 regression lock" |
| ORDER_PASS | rc2 evidence (:46-50) and frames section | CONFIRMED | rc2 0.17-0.46%, G03 1.01%, edge 87%. V02 rc4 hue-only 0.01%, gate 0.42% |
| ORDER_PASS | tz_verify counts (:28, :43) | CONFIRMED | 14 / 15 / 17 by the `_check` count |
| Gate | `i18n_truth_gate.py` | CONFIRMED | 12/12 locales PASS, rc 0 |
| Gate | `hardcoded_text_gate.py` and `--demo` | CONFIRMED | 0 hits, rc 0. demo OK |
| Gate | `visual_truth_gate.py` tzverify + known-bad | CONFIRMED | 10/11 PASS 0.15-0.42%. G03 FAIL 1.28%. magenta_corruption 13.19% FAIL. rc 1 as expected. Matches ARENA R0 and ORDER_PASS |
| Gate | `user_data_guard.sh --demo` | CONFIRMED | demo OK, rc 0, no tls_udg dirs left in TEMP |
| Gate | `TLS_SKIP_REIMPORT=1 check.sh --static` | CONFIRMED | "Всё зелёное", 24 passed, 0 FAIL. `git status`: only the pre-existing ` M project.godot` |

CONFIRMED=94 PARTIAL=10 FAKE=0
