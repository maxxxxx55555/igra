# Order-pass report (v8 sign-off candidate)

Covers C4–C7 of the studio-lead directive. Base is `c73cf7c` (C3 close-out); the candidate is the
latest `v8.0.0-rcN` tag (the last row of "C8 verifier loop" names it). Numbers tagged
**RECONFIRM-AT-SIGNOFF** come from engine or windowed runs whose logs are local only (`.qa_logs/`, never
committed) and must be re-run at sign-off; every other number was recomputed statically at `ce782f8` by
the cloud cross-audit (`docs/CLOUD_AUDIT.md`).

## Phase deltas

| Phase | What changed | Key commits |
|---|---|---|
| C4 TZ-CLOSE | Every row in `docs/TZ_COMPLIANCE_AUDIT.md` has a verdict (0 open GAP-DEV). Applied: A02, V02, V05, G02, G03, G06, G07 (noise), G08 (colour/cone), G12b, G15 (capsule), G16, G17, G20, G34 (bunker), C04, C06, E03 (cooldowns), S03, S04, V01; D03 and E05 in C8 rc12 (DR-4, no measured rejection existed). Decided: A03 (DR-5), G24, G09, G10, G13, S01 (IRON RULE bisect), G04, G27, G31–G33, D02. G22 is GAP-OWNER (DR-6) and C03 DEFERRED-STRUCTURAL since C8. | `fa5fee4` … `97c8bf4` |
| R0 (reopened) | Real root cause of the magenta world: district LUTs imported as a 1D gradient. World hue-magenta 13% → ≤0.30% (hue-only metric, full res). | `bafb740` |
| Save | Progress signature never matched on load, so every Continue wiped district power and progress. | `ac877a5` |
| C5 MATRIX | 0 UNTESTED. X22 (test bug), X20 (PAUSED, harness recovery), P2q/P2r regressions, dead inputs removed, suite deterministic. | `0d3d533`, `9fc8665` (P2m) |
| C6 I18N | `i18n_truth_gate` 12/12 translated locales against `en` (all 13 files hold the same 1301 keys), no cap loosened. Keeper voice fixed. New `hardcoded_text_gate` found 2 leaks plus 7 missing tutorial keys. | `43c9ecd`, `21c6563`, `ad051fc` |
| UI | Tutorial hint box drew over the HUD bars (anchors never applied); map button covered the VISIBILITY caption. | `ad051fc` |
| C9 prep | Release keystore generated (gitignored `.signing/`). AAB export blocked: no Godot 4.7 export templates on the machine. | `7af80d2` |

## Battery (this pass)

| Gate | Result |
|---|---|
| `tools/check.sh` (static + all engine gates, windowed reimport first) | rc1-rc3 and the rc4 game code before `5cf3b27`: **Всё зелёное, 42 checks**; with the user-data guard (rc4 tag onward): **44** (measured at rc5); **45** at rc12 (QaLaunchGuard copy check), **46** at rc13 (QaLaunchGuard lifecycle on the real profile); 2 windowed-only skips. Full runs RECONFIRM-AT-SIGNOFF; the count itself holds at `ce782f8` (24 static + reimport + 19 engine + lifecycle + guard restore) |
| Static only (incl. i18n truth, hardcoded text, R0 pin, release export) | **24/24** green, recomputed at `ce782f8` and on every `cloud/audit-ce782f8` commit |
| GOLD MASTER suite | `DONE fails=0`, 3 consecutive runs, 0 SCRIPT ERROR; RECONFIRM-AT-SIGNOFF |
| attack_sim / save_integrity / craft_check / a11y_probe / ui_layout | fails=0 each; RECONFIRM-AT-SIGNOFF (attack_sim gains `_check_daily_clock_rollback_rejected` on `cloud/audit-ce782f8`) |
| `balance_sim` / `endings_sim` | PASS (districts 11 x 200..1200 = 7700 coins; battery budget 12.8 min vs need 12.6) / all 5 endings reachable; recomputed at `ce782f8` |
| TZ-verify (windowed, `scenes/tools/tz_verify_scene.tscn`) | rc1: 14 checks; rc2: 15; rc5: 17; rc12: 19 (D03 per stage added, profile restore moved to QaLaunchGuard); rc13: 19 (`ce782f8` message); `DONE fails=0` each; RECONFIRM-AT-SIGNOFF |
| Audio truth (windowed) | PASS: Music −19.3 dB (C7) and −20.3 dB (rc11, guarded), all buses under −1.5 dB; RECONFIRM-AT-SIGNOFF |
| Perf (windowed) | D1 **246** draw calls (C7), **253** (rc11 run via `tools/qa_sim/guarded_windowed`): under the D11 350 cap, **over the D1 200 target**; RECONFIRM-AT-SIGNOFF. Static estimate (`drawcall_estimate.py`, recomputed): ~38 mesh/2D draw calls and 18 active real-time lights in D1, see `docs/PERF_PASS.md` |
| Visual truth (frames below) | Recomputed at `ce782f8`, same figures: rc12 tzverify frames (14, incl. D03 x3), half res: 12/14 PASS (0.14–0.46%); the two running frames FAIL: `G03_sprint_fov` 0.79% (0.51% hue-band hits, 98% of them in the outer 15% edge band, plus 0.29% saturation outliers) and `S03_noise_vignette` 1.02% (all hue-band, 88% in the edge band) = canon ember vignette over blue (TZ_DECISIONS S03). The R0 regression lock is the LUT import pin in `check.sh` (PASS); the visual gate's `r0_after_*` run only checks the gate against committed frames. Known-bad `magenta_corruption_suburbs.png` still FAILs (13.19%). |
| Bot (3 seeds) | C7: 2/3 (batch `c00f118`), 1/3 (capsule `97c8bf4`). C8: rc2 1/3, rc3 1/3, rc4 1 WIN (seeds 2-3 of that run were killed by the environment), rc12 **2/3** (s2 spine stall at power_station, known X21 type); stalls of known types only; RECONFIRM-AT-SIGNOFF |
| AAB signed-verify | **not run**: no export templates (see Residual) |

## C8 verifier loop

| Round | Tag | Verifier result | Action |
|---|---|---|---|
| 1 | `v8.0.0-rc1` (`27ba1d5`) | CONFIRMED 79 / PARTIAL 7 / FAKE 3 (`docs/CLOSURE_VERIFICATION_INTERNAL.md`) | FAKE: S03 (vignette never drew), G12b (L5 never cleared flicker), A03 (stealth = walk sample; probe could not fail). PARTIAL: G17 backups survived, G24/C03 mislabelled, R0 numbers, #8 hash, matrix breakdown, check count. All fixed in `0873f38`; CORRECTION_LOG 15-21. |
| 2 | `v8.0.0-rc2` (`5724544`) | CONFIRMED 128 / PARTIAL 6 / FAKE 0 | G12b fix only held until respawn: flashlight upgrades were applied at purchase only, and the formulas used base 1.0 / 8 m instead of the scene's 24 / 16 m (buying Brightness dimmed the light). Fixed in the rc3 commit with suite P2r (mutation-tested: fails with the reapply removed). Doc partials: P01/P02 decision rows, stale C06 row, matrix AL range, correction count. CORRECTION_LOG 22. rc3: check.sh full 42 green, suite `DONE fails=0`, bot 1/3 (boss-phase + X21 spine stalls, both known types). |
| 3 | `v8.0.0-rc3` (`5402640`) | CONFIRMED 145 / PARTIAL 14 / FAKE 0 | Flashlight upgrades leaked across New Game/hardcore/slots (now per-run save data, cleared by `reset_all`); Stability L1-L4 did nothing (now -10..-50% drain, GDD §3.3); `fog_setup.gd` overrode tier fog on every load; monster hit flash left monsters pure white. Ledger: A04 reason, A01 Hum bus, S04 hiding spots, legend, stale report lists. CORRECTION_LOG 23-28. rc4 game code: check.sh full 42 green (run before the guard commit `5cf3b27`; the rc4 tag includes it, and the same check.sh counts 44 at rc5), suite `fails=0`, tz_verify `fails=0`, each new check mutation-tested. Bot: seed 1 X21 spine stall (known), seed 2 **WIN** 11/11; seed 3 unmeasured, since Godot runs under `timeout` were killed with exit 127 from 10:11 (committed HEAD killed the same way in an A/B, so environmental; seed 2 won when run without the wrapper). |
| 4 | `v8.0.0-rc4` (`b8b20c0`) | CONFIRMED 186 / PARTIAL 12 / FAKE 0 | No game-code defects. The user-data guard could delete the whole profile if its snapshot was lost; restore now refuses in that case. tz_verify and direct suite runs bypassed the shell guard; both now take an in-process snapshot first. P2r measures the Stability drain through `_update_battery` instead of reading a field. Figures and wording fixed; CORRECTION_LOG 29-31. rc5: check.sh full **44 green** (24 static + reimport + 18 engine + guard restore); direct suite `fails=0` and tz_verify 17 checks `fails=0`, each leaving all 11 profile files sha256-identical; drain and lost-snapshot mutations caught. Tools and docs only, so no IRON RULE bot. |
| 5 | `v8.0.0-rc5` (`3ee3568`) | CONFIRMED 132 / PARTIAL 4 / FAKE 0 | No game-code defects. A failed snapshot did not stop the run (shell `cp` unchecked; null in-process snapshot ignored). Every runner now aborts before starting the game, and `udg_snapshot` verifies each copy and a failed `mktemp`. rc4 check count and S03 reason corrected; CORRECTION_LOG 32-33. rc6: check.sh full **44 green**; direct suite `fails=0` and tz_verify `fails=0` left all 11 profile files sha256-identical; guard `--demo` covers the snapshot-failure and lost-snapshot cases. Tools and docs only. |
| 6 | `v8.0.0-rc6` (`4061f1b`) | CONFIRMED 94 / PARTIAL 10 / FAKE 0 | No game-code defects. Fixes: a failed restore now fails the run (`udg_restore || exit 97` in every EXIT trap); a failed copy drops its partial snapshot; the demo covers the failed-copy path (mutation-tested) and keeps its temp inside its own dir; `tools/qa_sim/tz_verify` runs the probe under the guard. Docs: ARENA B7's deferred half, S03 edge share 70-98%, R0 lock wording, candidate line, correction ranges; CORRECTION_LOG 34. rc7: check.sh full **44 green**; tz_verify through the wrapper 17 checks `fails=0`, all 11 profile files sha256-identical. Tools and docs only. |
| 7 | `v8.0.0-rc7` (`8c0e01c`) | CONFIRMED 105 / PARTIAL 3 / FAKE 0 | No game-code defects. tz_verify now refuses a direct launch (only the guarded wrapper may run it); wrapper made executable; B7 deferral listed in the open defers and residuals; S03 hue wording; CORRECTION_LOG 35. rc8: a direct launch exits 2 with nothing touched; wrapper run 17 checks `fails=0`, all 11 profile files sha256-identical; static 24 green. The engine battery was first skipped on a wrong premise: the compile gate loads every `.gd`, so it does see these files (CORRECTION_LOG 36). Re-run on the rc8 code: check.sh full **44 green**. |
| 8 | `v8.0.0-rc8` (`9936ab3`) | CONFIRMED 106 / PARTIAL 3 / FAKE 0 | No code defects. Fixed the skipped-battery claim (re-run: 44 green), the G18/G19 GDD line range (168-181) and the missing R-02 residual row; CORRECTION_LOG 36. rc9: docs only on top of the rc8 code measured above. |
| 9 | `v8.0.0-rc9` (`94af752`) | CONFIRMED 114 / PARTIAL 4 / FAKE 0 | No code defects. V05 split into MET (desktop 2048) / DECIDED (mobile 1024, new V05-mobile row); G28/D04 no longer cites a precedence rule the GDD does not have; I02 key count 1301; FUNCTION_MATRIX legend defines FIXED and PARTIAL. CORRECTION_LOG 37. rc10: docs only. Nothing outside `docs/` has changed since the 44-green run on `9936ab3`. |
| 10 | `v8.0.0-rc10` (`c46d8a3`) | CONFIRMED 121 / PARTIAL 3 / FAKE 0 | The windowed perf and audio probes start a New Game but had no save guard on their documented direct launch; both runners now refuse to start unguarded, and `tools/qa_sim/guarded_windowed` runs any windowed probe under the guard (`tz_verify` delegates to it). V05-mobile had no measurement behind DR-3: the mobile 1024 override is removed (GDD 2048, DR-4). The six FIXED matrix rows name their commits. CORRECTION_LOG 38. rc11: direct launches exit 2 with the profile untouched; guarded perf (D1 253 draw calls, D11 cap OK), audio (Music -20.3 dB, PASS) and tz_verify (`fails=0`, V05 desktop+mobile 2048) each restored all 11 profile files byte-identical; check.sh full **44 green**. Mobile-only render setting, no gameplay change: no IRON RULE bot. |
| 11 | `v8.0.0-rc11` (`1430516`) | CONFIRMED 121 / PARTIAL 15 / FAKE 0 | Root fix for QA launches on the owner's profile (round 12 added autopilot coverage, a verified manifest, an airtight abort and a lifecycle gate): the first autoload `QaLaunchGuard` snapshots on any `scenes/tools/*` or `--shot` launch not wrapped by the shell guard, restores at exit, and keeps a crash copy the next unguarded launch restores (replaces the per-runner refusals and `_user_data_snapshot.gd`). DR-4 applied where DR-3 had no measurement: D03 stage lighting now GDD (0.03/0.12, 0.11/0.25, 0.16/0.40) and E05 district reward 200 + 100 per district. Labels: S03 note, V05-mobile DR-4, A03 DR-5, G22 DR-6; G34 audio logs counted; S02 text; X12 verified (suite P2r); X24 text; headless_suite treats exit 3 as skip; P2m retries a MENU window; tz_verify no longer reads a stale log. CORRECTION_LOG 39. rc12: `qa_guard_check` OK; direct unguarded suite x3 and a killed run recovered, profile sha256-identical each time; tz_verify 19 checks `fails=0`; X12 / E05 / drain / flash mutations caught; check.sh full **45 green**; IRON RULE bot **2/3 WIN** (s2 X21-type spine stall at power_station), coins earned 8718-8975 on the wins. |
| 12 | `v8.0.0-rc12` (`b8abb2e`) | CONFIRMED 132 / PARTIAL 11 / FAKE 0 | QaLaunchGuard hardened: sha256 manifest written last and pid ownership (a partial, empty or damaged copy is never restored), airtight `OS.crash` abort, verified copies, every `tools/` scene or script counts as a QA launch (autopilot included), and the shell guard refuses while a copy is pending. New check.sh lifecycle check on the real profile. Fog-at-load check loads on High (Ultra profiles masked it). D03 cite GDD.md:108-111. Report rows fixed (C4 lists, battery, visual breakdown, DR-4 label). CORRECTION_LOG 40. rc13: guard copy check 13/13, lifecycle check OK and mutation-caught, damaged-copy abort rc 132 with no probe written, check.sh full **46 green**. QA tooling and docs: the rewritten QaLaunchGuard autoload ships but acts only on QA launches, so no IRON RULE bot. |

Cloud cross-audit of rc13 (`docs/CLOUD_AUDIT.md`): CONFIRMED 95 / PARTIAL 4 / FAKE 0 and 3 honesty findings,
all fixed on `cloud/audit-ce782f8` (`a6f4fdb` guard, `c2e9b86` daily clock, docs); CORRECTION_LOG 41-43.

rc2 evidence: tz_verify 15 checks `DONE fails=0`; footstep probe `fails=0` and mutation-tested
(`fails=3`, rc 1, with stealth mapped onto walk's file); `tools/check.sh` full **42 green**; bot 1/3 won, 11/11
districts FULL on all three seeds, both stalls in the boss phase (same type as the rc1 baseline).
Visual gate on the rc2 tzverify frames (half res): 10/11 PASS (0.17–0.46%); `G03_sprint_fov` FAIL 1.01%,
87% of the hits in the outer 15% edge band = canon ember vignette over blue (TZ_DECISIONS S03).
No external `docs/CLOSURE_VERIFICATION.md` exists.

## Frames (read by eye this pass)

- `docs/stills/tzverify/baseline.png`: night street, brass-lit pool, tutorial hint bottom-centre.
- `docs/stills/tzverify/C04_arachnophobia_label.png`: "Blind Dogs" spotted label (en locale this run; the ru run showed "Слепые псы").
- `docs/stills/tzverify/C06_tier_ultra.png`: Ultra tier, fog 0.015.
- `docs/stills/tzverify/G12b_low_battery.png`: 10% battery.
- `docs/stills/tzverify/TUT_hint_layout.png`: tutorial box laid out correctly
- `docs/stills/tzverify/D03_stage_dark.png` / `D03_stage_full.png`: GDD stage lighting (rc12); DARK shows silhouettes, road edges and the tree, FULL a moonlit street.
- `docs/stills/tzverify/V02_energy_ball.png`: warm ball; a faint dim-red smudge on the pavement below (rc12 frame: hue-only 0.01%, gate 0.37%).

## Corrections

43 entries in `docs/CORRECTION_LOG.md` (14 at rc1, 15-21 from C8 round 1, 22 from round 2, 23-28 from round 3, 29-31 from round 4, 32-33 from round 5, 34 from round 6, 35 from round 7, 36 from round 8, 37 from round 9, 38 from round 10, 39 from round 11, 40 from round 12, 41-43 from the cloud cross-audit), including the false R0 fix, the dead C06 fog write, and two
wrong claims in this pass's own commit messages.

## Residual (honest)

| Item | Owner action / status |
|---|---|
| Signed AAB/APK export | Install the Godot 4.7 export templates and the Android build template (a ~1 GB download from godotengine.org; not downloaded without your OK), then run the steps in `docs/RELEASE_ARTIFACTS.md`. |
| Play Console upload | Owner (credentials). |
| Music | Excluded by owner. |
| `gh` auth | Optional. Git push works without it. |
| Bebas Neue Bold (V03) | Owner supplies the font file. |
| GDD text amendments (G28/D04, N01, I02) | Owner edits `GDD.md` or accepts the recorded defaults. |
| G22 save-slot picker (DR-6) | Owner re-enables the archived 3+1 slot UI or amends GDD G22 (PLAN.md §В Этап 1 recorded "archive"). |
| A03 per-speed footsteps (DR-5) | Owner supplies walk/jog/sprint recordings for asphalt, puddle and glass; the code already maps the other three surfaces. |
| X21 bot spine stall | Open (bot harness). Game side verified reachable; the bot wins 1–2/3 per run. |
| X20 | Harness recovery proven; the keypress trigger is inferred. |
| D1 draw calls 246-253 > 200 | Needs batching work (DEFERRED-STRUCTURAL). |
| Deferred structural rows | S02 visibility model, S04 hiding-spot placement, G21 blueprints, G25 weapons in HUD, C03 auto-aim (needs G25), G26 photos, A01 bus graph, G07 crouch capsule, P01 draw calls. |
| R-02 speed/teleport watchdog | Deferred (ARENA_CLOSURE R-02): IntegrityGuard covers non-finite position and falling through the floor; a speed watchdog needs per-state bounds. |
| Security inherent limits | P-05 and R-08 (a clock set forward across launches; R-08's same-session half is closed in `c2e9b86`), D-01, D-02; D-03 needs an owner-held PCK key; B7 legacy unsigned `achievements.cfg` still trusted once (owner decides whether to reject legacy files, P-02). |
| User-data folder reset | `app_userdata/The Last Streetlight` was deleted and recreated about 2026-09-25 00:24, cause unknown. Save files were backed up earlier to `%TEMP%\tls_save_backup`; `settings.cfg`/`onboarding.cfg`/`save.tres` were not. |
| P02 particles < 500, RAM/VRAM | NEEDS-MEASUREMENT (TZ P02): windowed or on-device profile; the same run prices V05's 2048 moon shadow on a phone. |
| G08 flashlight range 8 m / energy 2.0 | NEEDS-MEASUREMENT (TZ_DECISIONS G08): guarded windowed G08 frame and a 3-seed IRON RULE bot at the GDD values, then DR-4 or DR-3. |
| GUI exploration | Not run this pass (last run 2026-09-22, before the C6 locale edits): re-run `gui_explore_scene` for the 13-locale settings sweep. |
| `cloud/audit-ce782f8` code | `a6f4fdb` (guard) and `c2e9b86` (daily clock) are gate-covered but not engine-run: check.sh full (new lifecycle case) and attack_sim after the merge. |
