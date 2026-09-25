# Order-pass report (v8 sign-off candidate)

Covers C4–C7 of the studio-lead directive. Base is `c73cf7c` (C3 close-out); the candidate is the
latest `v8.0.0-rcN` tag (the last row of "C8 verifier loop" names it). Every number below was produced by a run in this pass; logs are in `.qa_logs/`
(local only).

## Phase deltas

| Phase | What changed | Key commits |
|---|---|---|
| C4 TZ-CLOSE | Every row in `docs/TZ_COMPLIANCE_AUDIT.md` has a verdict (0 open GAP-DEV). Applied: A02, V02, V05, G02, G03, G06, G07 (noise), G08 (colour/cone), G12b, G15 (capsule), G16, G17, G20, G34 (bunker), C04, C06, E03 (cooldowns), S03, S04, V01. Decided with evidence: A03, G24, G09, G10, G13, S01 (IRON RULE bisect), G04, G22, G27, G31–G33, D02, D03, E05. C03 moved to DEFERRED-STRUCTURAL in C8. | `fa5fee4` … `97c8bf4` |
| R0 (reopened) | Real root cause of the magenta world: district LUTs imported as a 1D gradient. World hue-magenta 13% → ≤0.30% (hue-only metric, full res). | `bafb740` |
| Save | Progress signature never matched on load, so every Continue wiped district power and progress. | `ac877a5` |
| C5 MATRIX | 0 UNTESTED. X22 (test bug), X20 (PAUSED, harness recovery), P2q/P2r regressions, dead inputs removed, suite deterministic. | `0d3d533`, `9fc8665` (P2m) |
| C6 I18N | `i18n_truth_gate` 12/12 non-base (13/13 with en), no cap loosened. Keeper voice fixed. New `hardcoded_text_gate` found 2 leaks plus 7 missing tutorial keys. | `43c9ecd`, `21c6563`, `ad051fc` |
| UI | Tutorial hint box drew over the HUD bars (anchors never applied); map button covered the VISIBILITY caption. | `ad051fc` |
| C9 prep | Release keystore generated (gitignored `.signing/`). AAB export blocked: no Godot 4.7 export templates on the machine. | `7af80d2` |

## Battery (this pass)

| Gate | Result |
|---|---|
| `tools/check.sh` (static + all engine gates, windowed reimport first) | rc1-rc3 and the rc4 game code before `5cf3b27`: **Всё зелёное, 42 checks**; with the user-data guard (rc4 tag onward): **44** (measured at rc5); 2 windowed-only skips |
| Static only (incl. i18n truth, hardcoded text, R0 pin, release export) | all green |
| GOLD MASTER suite | `DONE fails=0`, 3 consecutive runs, 0 SCRIPT ERROR |
| attack_sim / save_integrity / craft_check / a11y_probe / ui_layout | fails=0 each |
| `balance_sim` / `endings_sim` | PASS / all 5 endings reachable |
| TZ-verify (windowed, `scenes/tools/tz_verify_scene.tscn`) | rc1: 14 checks; rc2: 15 checks, `DONE fails=0` |
| Audio truth (windowed) | PASS: Music −19.3 dB, all buses under −1.5 dB |
| Perf (windowed) | D1 **246** draw calls: under the D11 350 cap, **over the D1 200 target** |
| GUI exploration (windowed) | 19 PASS, 0 BUG, all 13 locales |
| Visual truth (frames below) | rc4 tzverify frames, half res: 10/11 PASS (0.15–0.42%); `G03_sprint_fov` FAIL 1.28%, 85% of hits in the outer 15% edge band = canon ember vignette over blue (TZ_DECISIONS S03). The R0 regression lock is the LUT import pin in `check.sh` (PASS); the visual gate's `r0_after_*` run only checks the gate against committed frames. Known-bad `magenta_corruption_suburbs.png` still FAILs (13.19%). |
| Bot (3 seeds) | Latest shipped trees: 2/3 (batch `c00f118`), 1/3 (capsule `97c8bf4`, all 3 seeds reached the boss) |
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
| 7 | `v8.0.0-rc7` (`8c0e01c`) | CONFIRMED 105 / PARTIAL 3 / FAKE 0 | No game-code defects. tz_verify now refuses a direct launch (only the guarded wrapper may run it); wrapper made executable; B7 deferral listed in the open defers and residuals; S03 hue wording; CORRECTION_LOG 35. rc8: a direct launch exits 2 with nothing touched; wrapper run 17 checks `fails=0`, all 11 profile files sha256-identical; static 24 green. The engine battery (44 at rc7) is not re-run, because the diff touches only tz_verify files and docs, which no check.sh engine gate loads. |

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
- `docs/stills/tzverify/TUT_hint_layout.png`: tutorial box laid out correctly.
- `docs/stills/tzverify/V02_energy_ball.png`: warm ball; a faint dim-red smudge on the pavement below (rc4 frame: hue-only 0.01%, gate 0.42%).

## Corrections

35 entries in `docs/CORRECTION_LOG.md` (14 at rc1, 15-21 from C8 round 1, 22 from round 2, 23-28 from round 3, 29-31 from round 4, 32-33 from round 5, 34 from round 6, 35 from round 7), including the false R0 fix, the dead C06 fog write, and two
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
| X21 bot spine stall | Open (bot harness). Game side verified reachable; the bot wins 1–2/3 per run. |
| X20 | Harness recovery proven; the keypress trigger is inferred. |
| D1 draw calls 246 > 200 | Needs batching work (DEFERRED-STRUCTURAL). |
| Deferred structural rows | S02 visibility model, S04 hiding-spot placement, G21 blueprints, G25 weapons in HUD, C03 auto-aim (needs G25), G26 photos, A01 bus graph, G07 crouch capsule, P01 draw calls. |
| Security inherent limits | P-05, R-08, D-01, D-02; D-03 needs an owner-held PCK key; B7 legacy unsigned `achievements.cfg` still trusted once (owner decides whether to reject legacy files, P-02). |
| User-data folder reset | `app_userdata/The Last Streetlight` was deleted and recreated about 2026-09-25 00:24, cause unknown. Save files were backed up earlier to `%TEMP%\tls_save_backup`; `settings.cfg`/`onboarding.cfg`/`save.tres` were not. |
