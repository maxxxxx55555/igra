# Round 3, HEAD 5402640, tag v8.0.0-rc3

Static verification only: code/data read at HEAD, history via `git show`, python gates run locally.
The Godot binary was not run. Runtime-only numbers (bot, suite, tz_verify output, draw calls) are
accepted when the code does not contradict them.

| Source | Item | Verdict | Evidence |
|---|---|---|---|
| ARENA A | B1 finale boss timing `5e1093b` | CONFIRMED | Commit is an ancestor of HEAD; 36/36 added code lines still present |
| ARENA A | B2 document id `7034bcd` | CONFIRMED | Ancestor; 26/26 lines present |
| ARENA A | B3 skill compounding `afadb4b` | CONFIRMED | Ancestor; 41/41 lines present; `resource_local_to_scene` in player_stats.tres:4 |
| ARENA A | B4 checksum-only saves `92934a7` (+`ac877a5`) | CONFIRMED | Both ancestors; 42/42 and 4/4 lines present |
| ARENA A | B5 NG+ bypasses `fe7ef0e` | CONFIRMED | Ancestor; 50/53 lines present (the others were later rewording); wipe_all_saves still removes ng_plus_data.json (save_system.gd:577-584) |
| ARENA A | B6 daily signing `e9686d7` | CONFIRMED | Ancestor; 27/27 lines present |
| ARENA A | B7 duplicate autoloads `bb662b4` | CONFIRMED | project.godot:109-110 declare RewardsManager/RandomEvents once each |
| ARENA A | B8 kills pay wallet `1cf3aaf` | CONFIRMED | Ancestor; 25/25 lines present |
| ARENA A | B9+B14 atomic try_add `36d44be` | CONFIRMED | Ancestor; 72/72 lines present |
| ARENA A | B10 `cc1e0b3` | CONFIRMED | Ancestor; 41/41 lines present |
| ARENA A | B11 `d7a0692` | CONFIRMED | Ancestor; 20/20 lines present |
| ARENA A | B12 `c814621` | CONFIRMED | Ancestor; 21/21 lines present |
| ARENA A | B13 `a36ac8b` | CONFIRMED | Ancestor; 40/40 lines present |
| ARENA A | B15 `8c99689` | CONFIRMED | Ancestor; 29/31 lines present (2 reworded later) |
| ARENA A | B16 `cb73c83` | CONFIRMED | player_3d.gd:231-232 excludes OfflineMultiplayerPeer |
| ARENA A | Q1 `a0ec4ee` | CONFIRMED | Ancestor; 32/32 lines present |
| ARENA B | P-01 `92934a7` | CONFIRMED | As B4 |
| ARENA B | P-03 / P-04 / P-06 / P-07 `9b7a46b` | CONFIRMED | Ancestor; 112/112 lines present; flashlight_upgrade_manager.gd:143-166 signed envelope + clamp |
| ARENA B | P-05 tamper closed, clock defer | CONFIRMED | `e9686d7` present; wall-clock trust is inherently client-side, honest defer |
| ARENA B | R-01 `2278cf9` | CONFIRMED | project.godot:113 IntegrityGuard autoload |
| ARENA B | R-02 defer | CONFIRMED | integrity_guard.gd:83 checks non-finite position and y <= -50 only, as the reason says |
| ARENA B | R-08 / D-01 / D-02 defers (inherent) | CONFIRMED | Honest: client-held key and wall clock |
| ARENA B | D-03 defer (owner) | CONFIRMED | release_export_check PASS in check.sh; .signing/ gitignored (.gitignore:85) |
| ARENA B | R-03 + D-04 `60a289b` | CONFIRMED | Ancestor; 36/36 lines present |
| ARENA B | R-07 `cef6ae6` | CONFIRMED | Ancestor; 26/26 lines present |
| ARENA B | C-08 `a453425` | CONFIRMED | Ancestor; release_export_check OK in check.sh --static |
| ARENA C | R0 `bafb740` | CONFIRMED | All 11 `assets/textures/luts/*.import` are `importer="3d_texture"` / CompressedTexture3D; check.sh pin OK. Gate on HEAD frames: 0.17-0.46% on 10 frames, G03 1.01% FAIL, exactly as the row says |
| ARENA C | RENDERING (b) lossless | CONFIRMED | Folded into `bafb740` (runtime A/B, not contradicted) |
| ARENA C | RENDERING (d) SSR/SSAO | CONFIRMED | visual_quality.tres:9-12 drive ssao/ssr per tier |
| ARENA C | TG gates `5257745`, `4c6ca10` | CONFIRMED | Ancestors; 104/105 and 5/5 lines present |
| ARENA C | CHALLENGE-01 `fe3007a` | CONFIRMED | Ancestor; 17/19 lines present |
| ARENA C | CHALLENGE-02 partial `c783544` | CONFIRMED | Honest partial, residual tracked as X21 BUG |
| ARENA C | CHALLENGE-03 `0f9685a` | CONFIRMED | scripts/ui/settings_full.gd absent |
| ARENA C | MISSED-00..05 | CONFIRMED | FUNCTION_MATRIX AL35/AL50/AL55 WORKS (smoke), AL57 P2q (suite:742), IN89 P1b |
| ARENA C | I18N `43c9ecd` / `21c6563` | CONFIRMED | i18n_truth_gate 12/12 PASS now |
| ARENA D | SLOP 1, 6 `855a278` | CONFIRMED | Subject names items 1/6; lines present |
| ARENA D | SLOP 2 `1fcf157` | CONFIRMED | Present |
| ARENA D | SLOP 3 `bbdaa8e` | CONFIRMED | 11/11 lines present |
| ARENA D | SLOP 4,5,7,9,10,11,14,15 `d06fe48` | CONFIRMED | 15/15 lines present |
| ARENA D | SLOP 8 `53353d5` | CONFIRMED | 13/13 present |
| ARENA D | SLOP 12 `2948e23` | CONFIRMED | BTN_ONE_MORE_RUN absent from data/scripts/scenes |
| ARENA D | SLOP 13 `363add0` | CONFIRMED | visual_truth_gate.py:80-84 uses PIL HSV |
| ARENA D | SLOP §2 `7bbc0ca` | CONFIRMED | visual_truth_gate.py:50 BLACK_FAIL_PCT = 40.0 |
| ARENA D | SLOP §3 reviewed | CONFIRMED | Consistent with X20 row and CORRECTION_LOG #6 |
| ARENA Design | P1 `2a88503` | CONFIRMED | 2/2 lines present |
| ARENA Design | P2 `c2dbeb4`, `4e7560e` | CONFIRMED | 68/74 and 305/311 lines present |
| ARENA Design | P3 `4e7560e` | CONFIRMED | As above |
| ARENA Design | P4 `f9bbfd7` | CONFIRMED | 9/9 present |
| ARENA Design | P5 `24ceb68` | CONFIRMED | player_3d.gd:1185-1189 recomputes battery_max from both sources |
| ARENA Design | P6/P7 `8f48faf` | CONFIRMED | balance_sim [7] prints the coin ledger |
| ARENA Design | P8 `ee273ee`, `24ceb68` | CONFIRMED | Present |
| ARENA | Open defers summary / "No P0 deferred" | CONFIRMED | Matches the table rows |
| TZ | Evidence: tz_verify 15 checks | CONFIRMED | _tz_verify_runner.gd has 15 distinct runtime checks (27ba1d5 had 14) |
| TZ | Evidence: footstep probe exits 1 | CONFIRMED | _footstep_check.gd:13-15; footstep_system.gd:188-203 |
| TZ | Evidence: suite fails=0 | CONFIRMED | Runtime, not contradicted |
| TZ | A02 crossfade 2.0 s | CONFIRMED | music_manager.gd:118, used at :209,262-263 |
| TZ | A03 DECIDED DR-A03 | CONFIRMED | footstep_system.gd:32,47-49; walk/jog/sprint files exist for 6 surfaces; asphalt/puddle/glass single step_*.wav |
| TZ | A04 audio caps MET-STATIC | PARTIAL | Verdict holds but the evidence is wrong: ambience/ is not "the music layers" (TZ_COMPLIANCE.md:30, TZ_DECISIONS.md:12). It holds 3 layer .ogg plus 15.6 MB of district/weather ambience; the 30 MB of layer sources sit in ambience/wav_src, which export_presets.cfg:3 excludes. Caps hold because of that exclusion |
| TZ | A01 DEFERRED-STRUCTURAL | PARTIAL | Honest deferral, but TZ_DECISIONS.md:45 lists buses "Master, Music, SFX, Voice, Ambient, UI"; default_bus_layout.tres:54 also has a Hum bus |
| TZ | V02 no neon / #fff MET | PARTIAL | Energy ball is fine, but base_monster.gd:670-672 sets every monster to pure white albedo+emission on hit. The restore at :676 duplicates the white material, so the monster stays #fff after its first hit |
| TZ | V05 shadow 2048 | CONFIRMED | project.godot:296 |
| TZ | V01 no day | CONFIRMED | day_night.gd is a 31-line clock with no Environment writes |
| TZ | D03 DECIDED | CONFIRMED | TZ_DECISIONS D03/V01 row |
| TZ | V03 GAP-OWNER | CONFIRMED | TZ_DECISIONS V03 row |
| TZ | G01 DECIDED | CONFIRMED | main_3d.tscn:61 fps_mode = true |
| TZ | G02 headbob 0.1 | CONFIRMED | camera_follow_3d.gd:22,84 |
| TZ | G03 FOV +5 | CONFIRMED | camera_follow_3d.gd:24 |
| TZ | G04 DECIDED 3.2 m | CONFIRMED | interactor.gd:24 REACH 3.2 |
| TZ | G06 sprint x1.6 | CONFIRMED | player_stats.tres:6-7 170/272 |
| TZ | G07 crouch | CONFIRMED | player_3d.gd:87-88,542,563; deferred halves have TZ_DECISIONS rows |
| TZ | G08 colour/cone MET, range/energy NEEDS-EYES | CONFIRMED | player_3d.tscn:179-184; honest TZ_DECISIONS G08 row |
| TZ | G09 DECIDED | CONFIRMED | player_3d.gd:96 100/450 |
| TZ | G10 DECIDED | CONFIRMED | data/items/battery.tres:14 effect_value 35 |
| TZ | G12b flicker <20%, cleared by L5 | CONFIRMED | flashlight_stats.tres threshold 20; player_3d.gd:1138-1139 gated on `_flashlight_stability_maxed`, set at :1165 and now reapplied in `_ready` (:245-247), so respawn/Continue keep it |
| TZ | G13 DECIDED | CONFIRMED | player_3d.gd:78-82 14/21/35 |
| TZ | G15 capsule 1.6 | CONFIRMED | player_3d.tscn:8-9 |
| TZ | G16 respawn | CONFIRMED | death_screen.gd:52-54 -> game_manager.gd:113-136; P2r drives the same pair |
| TZ | G17 hardcore wipes save | PARTIAL | save_system.gd:548-554 now removes main + .bak/.bak2/.bak3 (tz_verify:244-258). But wipe_all_saves (save_system.gd:569-584) leaves user://flashlight_upgrades.cfg, and since 5402640 player_3d.gd:245-247 re-applies it. Every bought upgrade survives a Hardcore death while coins are reset |
| TZ | G18/G19 roster | CONFIRMED | enemy_roster_data.gd alias rows match GDD.md:170-181; shadow_3d.gd:13,16 30/15 |
| TZ | G20 boss 70/30, beams 40 | CONFIRMED | boss_3d.gd:9,48,50 |
| TZ | G21 DEFERRED | CONFIRMED | TZ_DECISIONS G21 row |
| TZ | G22 DECIDED | CONFIRMED | KNOWN_ISSUES.md:1239 archived slot UI |
| TZ | G24 DECIDED | CONFIRMED | district_manager.gd:32-42; suite:750-762 asserts both sides |
| TZ | G25 DEFERRED | CONFIRMED | weapon scenes only referenced by tools |
| TZ | G26 DEFERRED | CONFIRMED | take_photo has no caller |
| TZ | G27 DECIDED | CONFIRMED | player_3d.gd:413 JOY_ZONE_RATIO 0.35 |
| TZ | G28/D04 GAP-OWNER | CONFIRMED | TZ_DECISIONS row |
| TZ | G31-33 DECIDED | CONFIRMED | TZ_DECISIONS row |
| TZ | G34 MET / "DR-5" | PARTIAL | Bunker check is real (progress_tracker.gd:128-130; suite:763-767). "DR-5" (TZ_COMPLIANCE.md:61) is not a verdict in the legend |
| TZ | S01 DECIDED | CONFIRMED | player_3d.gd:538-543 has no hit/dodge noise |
| TZ | S02 DEFERRED | CONFIRMED | base_monster.gd never reads player visibility |
| TZ | S03 ember pulse MET | CONFIRMED | post_process_overlay.gd:141 keeps COLOR.rgb; hud_3d.gd:639-647 lerps bg-deep->ember on the 0-1 noise scale |
| TZ | S04 search MET-STATIC | PARTIAL | 10 s / 5 m is real (base_monster.gd:45-46; suite:748). The ledger row (TZ_COMPLIANCE.md:65) drops the rest of the audit requirement (TZ_COMPLIANCE_AUDIT.md:93): no bushes or dark-corner hiding spots (hiding_spot.gd:4-14). No verdict or decision covers that half |
| TZ | D02 DECIDED | CONFIRMED | TZ_DECISIONS row |
| TZ | E03/T02 MET-STATIC + BY-DESIGN-ABSENT | PARTIAL | ad_service.gd:27,31,111-115 real. "BY-DESIGN-ABSENT" (TZ_COMPLIANCE.md:67) is not a verdict in the legend |
| TZ | E05 DECIDED | CONFIRMED | balance_sim prints 2200 + 1300 + 3100 |
| TZ | C03 DEFERRED | CONFIRMED | No gameplay weapon instance; melee sphere 2.7 m at player_3d.gd:326 |
| TZ | C04 MET | CONFIRMED | localization_manager.gd:161-171; ru.json:276; frame shows "Blind Dogs" (en run) |
| TZ | C06 tier fog + particles MET | PARTIAL | Tier fog applies only after a tier change. On every main_3d load, WorldEnvSetup (main_3d.tscn:87) applies the tier (world_env_setup.gd:85), then its sibling FogSetup (main_3d.tscn:90) overwrites it with fog_setup.gd:16 `fog_density = 0.015`. Every tier boots at 0.015. tz_verify:141-150 measures only after set_graphics_tier, so it cannot see this |
| TZ | P01 DEFERRED | CONFIRMED | TZ_DECISIONS P01 row |
| TZ | P02 NEEDS-MEASUREMENT | CONFIRMED | In legend; TZ_DECISIONS row |
| TZ | N01 / I02 / T01 GAP-OWNER | CONFIRMED | TZ_DECISIONS rows |
| TZ | Every non-MET row has a decision; 0 GAP-DEV | CONFIRMED | Every audit GAP-DEV id is in the ledger; each non-MET id has a TZ_DECISIONS row |
| Fix 0873f38 | S03 vignette fix | CONFIRMED | Shader + hud change as above; no other RGB writer |
| Fix 0873f38 | S03 check non-vacuous | CONFIRMED | tz_verify:136 needs r>0.4 and edge warmth +0.03; 27ba1d5:116 was `alpha > 0`. On 27ba1d5 code the shader dropped RGB, so the warmth delta fails |
| Fix 0873f38 | G12b keyed on max level | CONFIRMED | player_3d.gd:1165 |
| Fix 0873f38 | G12b L5 check non-vacuous | CONFIRMED | tz_verify:168-177; the 27ba1d5 bonus>=1.0 gate never clears at L5 (0.5) |
| Fix 0873f38 | A03 walk/jog/sprint + pitch | CONFIRMED | footstep_system.gd:47-49,138-146 |
| Fix 0873f38 | A03 probe can fail | CONFIRMED | 27ba1d5 probe printed fails=0 and quit 0 unconditionally; now duplicate or missing -> fails, exit 1 |
| Fix 0873f38 | G17 backups removed | CONFIRMED | save_system.gd:545-554, 569-570 cover SAVE_PATH and every slot |
| Fix 0873f38 | G17 check non-vacuous | CONFIRMED | tz_verify seeds .bak-.bak3; the 27ba1d5 wipe left .bak2/.bak3 |
| Fix 5402640 | Upgrades reapplied on respawn/Continue | CONFIRMED | player_3d.gd:245-247 each new player; autoload loads cfg at boot (flashlight_upgrade_manager.gd:57-58); purchase path unchanged (:98,123-128) |
| Fix 5402640 | Scale from scene base 24 / 16 m | CONFIRMED | player_3d.gd:239-240,1159,1195 |
| Fix 5402640 | P2r check non-vacuous | CONFIRMED | suite:827-834. Without the reapply `maxed` is false; with a 1.0 base the energy is 1.2 vs 28.8 wanted |
| Fix 5402640 | Complete for all paths (New Game / Reset / Hardcore / slots) | PARTIAL | flashlight_upgrade_manager.gd has no reset. reset_all (save_system.gd:345-386) and wipe_all_saves (:569-584) never touch it, and the cfg is global, not per slot. Now that player_3d.gd:245-247 applies it on every spawn, New Game, Reset Progress, Hardcore death and another slot all start with the previous run's upgrades while coins are zeroed. This is the same class as TRUTH WAVE P0.2. It was masked before 5402640 |
| Fix 5402640 | Stability upgrade effective | PARTIAL | Only L5 does anything. player_3d.gd:1161-1163 writes `softness` to `cone.material_override`, but the cone material is set with set_surface_override_material (:166), so that override is null, and flashlight_cone.gdshader:17-21 has no `softness` uniform. L1-L4 are no-ops on every path, and GDD §3.3 says Stability cuts drain by 10-50% |
| CORRECTION_LOG | #1 R0 `bafb740` | CONFIRMED | LUT imports are Texture3D; commit is the import change |
| CORRECTION_LOG | #2 `37581d7` | CONFIRMED | 528 .import files committed |
| CORRECTION_LOG | #3 C06 fog `2547fff` | PARTIAL | `2547fff` did rebuild the tier fog on visual_quality.tres, but "single source" is false: fog_setup.gd:16 overwrites it on every load (see C06) |
| CORRECTION_LOG | #4 V05 | CONFIRMED | Stays 2048 |
| CORRECTION_LOG | #5 X22 `0d3d533` | CONFIRMED | Matrix X22 FIXED test bug |
| CORRECTION_LOG | #6 X20 `0d3d533` | CONFIRMED | X20 PARTIAL |
| CORRECTION_LOG | #7 footer 58/43 -> 61/40 | CONFIRMED | 0d3d533^ matrix has 40 UNTESTED rows |
| CORRECTION_LOG | #8 `ac877a5`, `9fc8665` | CONFIRMED | `_ensure_playing` added in 9fc8665; c00f118 is docs only |
| CORRECTION_LOG | #9 A04 `4bb5772` | PARTIAL | Same wrong premise as TZ A04: ambience/ also holds 15.6 MB of real ambience; caps hold because wav_src is export-excluded |
| CORRECTION_LOG | #10 `d06fe48` "item 6" | CONFIRMED | Body numbers the theme_provider fix "6."; SLOP_REPORT.md:134 is item 7 |
| CORRECTION_LOG | #11 `ad051fc` / `ae410b9` | CONFIRMED | ad051fc body says "all PASS"; ae410b9 corrects |
| CORRECTION_LOG | #12 `ae410b9` | CONFIRMED | Gate on ae410b9 frames: S03 0.66% FAIL, C06 ultra 0.31% PASS |
| CORRECTION_LOG | #13 P01 | CONFIRMED | Matches TZ P01 / TZ_DECISIONS |
| CORRECTION_LOG | #14 S01 `c00f118` | CONFIRMED | c00f118 adds the S01 DR-3 row |
| CORRECTION_LOG | #15 magenta numbers | CONFIRMED | rc1 frames 0.17-0.66% (S03 FAIL); HEAD frames 0.17-0.46%, G03 1.01% |
| CORRECTION_LOG | #16 S03 | CONFIRMED | 27ba1d5: shader BG_DEEP, /10.4, `maxf(0.55, pulse*0.5)` keeps alpha at 0.55, check `alpha > 0` |
| CORRECTION_LOG | #17 G12b | CONFIRMED | Diff `_flashlight_stability_bonus < 1.0` -> level == max |
| CORRECTION_LOG | #18 A03 | CONFIRMED | 27ba1d5 footstep_system.gd:33-39 walk/run only; probe unconditional |
| CORRECTION_LOG | #19 G17 | CONFIRMED | 27ba1d5 delete_slot removed only .bak |
| CORRECTION_LOG | #20 G24 / C03 | CONFIRMED | Ledger now DECIDED / DEFERRED-STRUCTURAL |
| CORRECTION_LOG | #21 | CONFIRMED | 9fc8665; 58 AL + 32 IN + 24 X; 14 / 15 checks |
| CORRECTION_LOG | #22 | CONFIRMED | 5402640 diff matches (reapply in `_ready`, scene base) |
| FUNCTION_MATRIX | Status counts | CONFIRMED | Script recount of 114 unique rows: WORKS 99, FIXED 6, CANNOT-TEST-HEADLESS 6, BY-DESIGN-LIMIT 1, PARTIAL 1, BUG 1, UNTESTED 0 = footer |
| FUNCTION_MATRIX | Spine 90 (58 AL + 32 IN) | CONFIRMED | AL01-AL58, IN58-IN89; project.godot has 58 live autoloads, 29 live inputs |
| FUNCTION_MATRIX | Extra 24 X rows | CONFIRMED | X01-X24 |
| FUNCTION_MATRIX | Header "Current:" line (AL01-AL58) | CONFIRMED | Matches |
| FUNCTION_MATRIX | Grand total 114 | CONFIRMED | 90 + 24 |
| ORDER_PASS | Phase deltas / Residual lists | PARTIAL | The C4 row (ORDER_PASS_REPORT.md:11) still lists G24 and C03 as "Applied", but they are DECIDED / DEFERRED-STRUCTURAL since rc2. A03 is not under "Decided". The Residual deferred list (:77) omits C03. C5 (:14) cites docs-only `c00f118` as a key commit |
| ORDER_PASS | Battery "Visual truth" row | PARTIAL | ORDER_PASS_REPORT.md:32 still gives rc1 numbers: 1 FAIL = S03 0.66%. On the committed frames S03 is 0.46% PASS and G03 1.01% is the FAIL, as its own C8 section and ARENA R0 say. :12 "≤0.30%" has no hue-only qualifier (CORRECTION_LOG #15) |
| ORDER_PASS | tz_verify rc1 14 / rc2 15 | CONFIRMED | Check count in 27ba1d5 vs HEAD runner |
| ORDER_PASS | Round 1 79/7/3 | CONFIRMED | 0873f38 report totals line |
| ORDER_PASS | Round 2 128/6/0 | CONFIRMED | 5402640 report: 128 / 6 / 0 rows |
| ORDER_PASS | rc2 visual numbers (10/11, 0.17-0.46, G03 1.01, 87% edge) | CONFIRMED | Gate rerun; G03 hits 87.3% in the outer 15% left/right band, median hue 332 |
| ORDER_PASS | Footstep mutation fails=3 | CONFIRMED | Stealth->jog duplicates on concrete/wood/metal = 3 |
| ORDER_PASS | 22 corrections | CONFIRMED | CORRECTION_LOG has 22 rows |
| ORDER_PASS | No external CLOSURE_VERIFICATION.md | CONFIRMED | Not tracked |
| ORDER_PASS | C9 keystore gitignored | CONFIRMED | .gitignore:85, nothing tracked |
| Gates | i18n_truth_gate | CONFIRMED | 12/12 locales PASS, 0 missing/mixed/overflow |
| Gates | hardcoded_text_gate | CONFIRMED | 0 hits |
| Gates | hardcoded_text_gate --demo | CONFIRMED | demo OK |
| Gates | visual_truth_gate tzverify/*.png | CONFIRMED | 10/11 PASS (0.17-0.46%), G03_sprint_fov FAIL 1.01%; matches ORDER_PASS C8 and ARENA R0 |
| Gates | check.sh --static (TLS_SKIP_REIMPORT=1) | CONFIRMED | "Всё зелёное", 23 checks OK, 0 FAIL, exit 0 |
| Gates | git status after gates | CONFIRMED | Only the known ` M project.godot` (line endings, empty content diff); nothing reverted |

CONFIRMED=145 PARTIAL=14 FAKE=0
