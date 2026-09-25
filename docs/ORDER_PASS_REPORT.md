# Order-pass report (v8 sign-off candidate)

Covers C4–C7 of the studio-lead directive. Base is `c73cf7c` (C3 close-out); the candidate is the
`v8.0.0-rc1` tag. Every number below was produced by a run in this pass; logs are in `.qa_logs/`
(local only).

## Phase deltas

| Phase | What changed | Key commits |
|---|---|---|
| C4 TZ-CLOSE | Every row in `docs/TZ_COMPLIANCE_AUDIT.md` has a verdict (0 open GAP-DEV). Applied: A02, V02, V05, G02, G03, G06, G07 (noise), G08 (colour/cone), G12b, G15 (capsule), G16, G17, G20, G24, G34 (bunker), C03, C04, C06, E03 (cooldowns), S03, S04, V01. Decided with evidence: G09, G10, G13, S01 (IRON RULE bisect), G04, G22, G27, G31–G33, D02, D03, E05. | `fa5fee4` … `97c8bf4` |
| R0 (reopened) | Real root cause of the magenta world: district LUTs imported as a 1D gradient. World magenta 13% → ≤0.30%. | `bafb740` |
| Save | Progress signature never matched on load, so every Continue wiped district power and progress. | `ac877a5` |
| C5 MATRIX | 0 UNTESTED. X22 (test bug), X20 (PAUSED, harness recovery), P2q/P2r regressions, dead inputs removed, suite deterministic. | `0d3d533`, `c00f118` |
| C6 I18N | `i18n_truth_gate` 12/12 non-base (13/13 with en), no cap loosened. Keeper voice fixed. New `hardcoded_text_gate` found 2 leaks plus 7 missing tutorial keys. | `43c9ecd`, `21c6563`, `ad051fc` |
| UI | Tutorial hint box drew over the HUD bars (anchors never applied); map button covered the VISIBILITY caption. | `ad051fc` |
| C9 prep | Release keystore generated (gitignored `.signing/`). AAB export blocked: no Godot 4.7 export templates on the machine. | `7af80d2` |

## Battery (this pass)

| Gate | Result |
|---|---|
| `tools/check.sh` (static + all engine gates, windowed reimport first) | **Всё зелёное, 42 checks**; 2 windowed-only skips |
| Static only (incl. i18n truth, hardcoded text, R0 pin, release export) | all green |
| GOLD MASTER suite | `DONE fails=0`, 3 consecutive runs, 0 SCRIPT ERROR |
| attack_sim / save_integrity / craft_check / a11y_probe / ui_layout | fails=0 each |
| `balance_sim` / `endings_sim` | PASS / all 5 endings reachable |
| TZ-verify (windowed, `scenes/tools/tz_verify_scene.tscn`) | rc1: 14 checks; rc2: 15 checks, `DONE fails=0` |
| Audio truth (windowed) | PASS: Music −19.3 dB, all buses under −1.5 dB |
| Perf (windowed) | D1 **246** draw calls: under the D11 350 cap, **over the D1 200 target** |
| GUI exploration (windowed) | 19 PASS, 0 BUG, all 13 locales |
| Visual truth (frames below) | Hue-magenta ≤0.05% at full res on all 11 frames. Half res: 10/11 PASS; 1 FAIL (`S03_noise_vignette`, 0.66%, saturation-outlier sub-detector on the ember vignette). Known-bad `magenta_corruption_suburbs.png` still FAILs (9.49%). |
| Bot (3 seeds) | Latest shipped trees: 2/3 (batch `c00f118`), 1/3 (capsule `97c8bf4`, all 3 seeds reached the boss) |
| AAB signed-verify | **not run**: no export templates (see Residual) |

## C8 verifier loop

| Round | Tag | Verifier result | Action |
|---|---|---|---|
| 1 | `v8.0.0-rc1` (`27ba1d5`) | CONFIRMED 79 / PARTIAL 7 / FAKE 3 (`docs/CLOSURE_VERIFICATION_INTERNAL.md`) | FAKE: S03 (vignette never drew), G12b (L5 never cleared flicker), A03 (stealth = walk sample; probe could not fail). PARTIAL: G17 backups survived, G24/C03 mislabelled, R0 numbers, #8 hash, matrix breakdown, check count. All fixed in `0873f38`; CORRECTION_LOG 15-21. |

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
- `docs/stills/tzverify/V02_energy_ball.png`: warm ball; a faint dim-red smudge on the pavement below (0.05% hue-magenta).

## Corrections

14 entries in `docs/CORRECTION_LOG.md`, including the false R0 fix, the dead C06 fog write, and two
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
| Deferred structural rows | S02 visibility model, G21 blueprints, G25 weapons in HUD, G26 photos, A01 bus graph, G07 crouch capsule. |
| Security inherent limits | P-05, R-08, D-01, D-02; D-03 needs an owner-held PCK key. |
| User-data folder reset | `app_userdata/The Last Streetlight` was deleted and recreated about 2026-09-25 00:24, cause unknown. Save files were backed up earlier to `%TEMP%\tls_save_backup`; `settings.cfg`/`onboarding.cfg`/`save.tres` were not. |
