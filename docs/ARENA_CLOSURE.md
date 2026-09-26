# Arena closure

Every P0/P1 item from the four arena reports, mapped to the commit that closed it or to an honest
defer. Commit hashes come from `git log` on `main`.

- **A** = `docs/BREAK_REPORT.md` (break/exploit)
- **B** = `docs/SECURITY_PATCH_SPEC.md` (anti-tamper)
- **C** = `origin/arena/01a0c589-igra`: `RENDERING_DIAGNOSIS.md`, `REDTEAM_CHALLENGE.md`, `I18N_DEFECTS.md`
- **D** = `docs/SLOP_REPORT.md`
- **Design** = `docs/DESIGN_AUDIT_ARENA.md`

## A: BREAK_REPORT (17/17 closed; B7's legacy-achievements half deferred, see B7 row)

| Item | Closed by |
|---|---|
| B1 finale boss spawn/rebuild timing | `5e1093b` |
| B2 document id before add_child | `7034bcd` |
| B3 skill bonuses compounding on restart | `afadb4b` |
| B4 checksum-only / no progress_hmac saves | `92934a7` (+ the signing fix `ac877a5`, see note) |
| B5 NG+ file/UI/reset bypasses | `fe7ef0e` |
| B6 unsigned daily file | `e9686d7` |
| B7 duplicate RewardsManager/RandomEvents autoloads | `bb662b4` (payout half). **Deferred half:** an unsigned legacy `achievements.cfg` is still trusted once and re-signed (`achievements_manager.gd` `_load`). SECURITY_PATCH_SPEC P-02 records this as a UX trade-off, and attack_sim `_check_achievements_legacy_migrates` locks the migration on purpose. Closing it means rejecting legacy files, which is an owner call. |
| B8 kills paid a display signal only | `1cf3aaf` |
| B9 + B14 non-atomic try_add | `36d44be` |
| B10 district-enter save before placement | `cc1e0b3` |
| B11 district lock only on the map button | `d7a0692` |
| B12 streetlight event fired per FULL repair | `c814621` |
| B13 import not refreshing live state; autosave wrote a dead slot | `a36ac8b` |
| B15 fall-recovery net not armed on spawn | `8c99689` |
| B16 offline player treated as networked | `cb73c83` |
| Q1 heartbeat conflated invalid player with bad position | `a0ec4ee` |

Note on B4: the progress signature B4 made mandatory never matched on load (int vs float after
JSON), so every load wiped district power and ProgressTracker. Found and fixed in `ac877a5`; see
`docs/CORRECTION_LOG.md`.

## B: SECURITY_PATCH_SPEC

| Item | Status |
|---|---|
| P-01 legacy checksum bypass (P1) | Closed `92934a7` |
| P-03 NG+ unsigned (P1) | Closed `9b7a46b` |
| P-04 flashlight upgrades unsigned (P1) | Closed `9b7a46b` |
| P-05 daily tamper / clock replay (P1) | Tamper closed `e9686d7`. **Defer (inherent):** wall-clock trust cannot be fixed client-side. |
| P-06 slot swap (P1/P2) | Closed `9b7a46b` |
| P-07 semantic validation (P1/P2) | Closed `9b7a46b` |
| R-01 dormant integrity watchdog (P1) | Closed `2278cf9` |
| R-02 speed/teleport/memory-edit bounds (P1) | **Defer.** IntegrityGuard covers non-finite position and fell-through-floor. A speed watchdog needs per-state speed envelopes, and false positives risk yanking a legitimate player. Offline single-player with no server trust boundary. |
| R-08 wall-clock trust (P1/P2) | **Defer (inherent):** same as P-05. |
| D-01 PCK overlay (P1) | **Defer (inherent):** no client-side self-verification is possible (`docs/SECURITY_THREAT_MODEL.md`). |
| D-02 HMAC key in client (P1) | **Defer (inherent):** documented in the threat model. |
| D-03 bytecode on / no encryption (P1/P2) | **Defer (owner):** PCK encryption needs a key kept outside the repo at export time. `release_export_check.py` forbids committing one. |
| R-03 position/district trust (P2) | Closed `60a289b` |
| R-07 LAN payloads (P2) | Closed `cef6ae6` |
| D-04 debug signing material committed (P2) | Closed `60a289b` |
| C-08 release-export gate | Closed `a453425` |

## C: rendering, redteam, i18n (arena 01a0c589)

| Item | Status |
|---|---|
| R0 magenta 3D world on real GPU (P0) | **Closed `bafb740`, the real root cause.** The 11 LUTs were imported as Texture2D (1D gradient). Measured on a windowed A/B with textures actually loaded: world hue-magenta 13% → 0.01–0.30% (hue-only, full res, frames without the noise vignette). The gate's combined detector (hue OR saturation outlier) reads 0.14–0.46% on the rc12 half-res tzverify frames without the noise vignette, and 0.79% (`G03_sprint_fov`) / 1.02% (`S03_noise_vignette`) on the two running frames, where the canon ember vignette blends into blue at the edges (TZ_DECISIONS S03; CORRECTION_LOG #15). The earlier `24116c4` "fix" is corrected in CORRECTION_LOG #1. |
| RENDERING_DIAGNOSIS (b) Lossless test set | Done as part of `bafb740`: Lossless and S3TC were both A/B'd and ruled out. |
| RENDERING_DIAGNOSIS (d) SSR/SSAO elimination void | The diagnosis's premise is superseded by the LUT root cause. The effects stay tier-driven from `visual_quality.tres`. |
| TG-SEE / TG-HEAR / TG-PLAY hardened gates (P1) | Closed `5257745`, `4c6ca10`. The R0 lock now pins the proven cause (`bafb740`). |
| CHALLENGE-01 phase-7 harness (P1) | Closed `fe3007a` |
| CHALLENGE-02 residential nudge (P1) | Partial `c783544`. Residual: the spine-stall softlock type stays open (FUNCTION_MATRIX X21) and appears at different districts run to run. |
| CHALLENGE-03 settings_full dead code | Closed `0f9685a` |
| MISSED-00..05 (LocalLeaderboard, quick_wheel, hum pool, RandomEvents, PlayIntegrity) | Matrix rows now WORKS/smoke via GOLD MASTER P1b/P2q (`0d3d533`) |
| I18N_DEFECTS native-quality pass | Applied as a value-level merge `43c9ecd`; truth gate 12/12 `21c6563` |

## D: SLOP_REPORT (15/15 + §2 closed)

| Items | Closed by |
|---|---|
| 1, 6 | `855a278` |
| 2 | `1fcf157` |
| 3 | `bbdaa8e` |
| 4, 5, 7, 9, 10, 11, 14, 15 | `d06fe48` |
| 8 | `53353d5` |
| 12 | `2948e23` |
| 13 | `363add0` |
| §2 BLACK_FAIL_PCT 85 → 40 | `7bbc0ca` |
| §3 symptom masks | Reviewed. Tracked honestly in KNOWN_ISSUES; the park "inf" case was re-diagnosed (`0d3d533`). |

## Design audit (P1–P8)

| Item | Closed by |
|---|---|
| P1 stealth investment repair | `2a88503` |
| P2 stealth skills | `c2dbeb4`, `4e7560e` |
| P3 NG+ activation clarity | `4e7560e` |
| P4 pause procedural audio | `f9bbfd7` |
| P5 battery capacity composition | `24ceb68` |
| P6 coin reporting / P7 duration scoping | `8f48faf` (docs + simulator per the audit's own "retain" acceptance criteria) |
| P8 boss P1 telegraph | `ee273ee`, `24ceb68` |

## Open defers

- **Inherent client-side limits:** P-05, R-08, D-01, D-02.
- **Owner-held:** D-03 (PCK encryption key); B7's legacy-achievements half (reject unsigned legacy `achievements.cfg`, a P-02 UX call).
- **Scoped:** R-02 (speed watchdog) and the CHALLENGE-02 spine stall (X21).

No P0 is deferred.
