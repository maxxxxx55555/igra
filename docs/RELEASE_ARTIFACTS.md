# RELEASE_ARTIFACTS.md — index of release-pass evidence

One line per artifact: what it is, where it lives, what it proves. Source of truth for a
claim always stays in the artifact itself — this file only points at it. Started
2026-09-12 (RELEASE CONVERGENCE PASS).

## Arena delivery ledgers + certificates (kept on disk, consolidated into canon docs)

| Artifact | Path | Proves | Consolidated into |
|---|---|---|---|
| Visual ledger | `docs/LEDGER_VISUAL.md` | 11 LUTs + 8 screenshots + 4 trailer re-grades, attempt log | `docs/ASSET_LICENSES.md` (2026-09-12 section) |
| Audio ledger | `docs/LEDGER_AUDIO.md` | 8 lit beds + 3 wow cues, attempt log incl. failed CC0/music-gen search | `docs/ASSET_LICENSES.md` (2026-09-12 section) |
| Visual certificate | `docs/CERT_VISUAL.md` | 0 defects — dims/purity/palette/LUT-monotonicity/letterbox, all measured | `docs/CONTENT_PIPELINE_AUDIT.md` §14 |
| Audio certificate | `docs/CERT_AUDIO.md` | 0 defects — header/granule/loudness/contract-pass, all measured | `docs/CONTENT_PIPELINE_AUDIT.md` §15 |
| Store certificate | `docs/CERT_STORE.md` | 0 open defects — 13/13 locale parity, char limits, master-hash unchanged | `docs/CONTENT_PIPELINE_AUDIT.md` §16 |

## QA / gate reports

| Artifact | Path | Proves |
|---|---|---|
| Static gate suite | `tools/check.sh --static` (run output, not persisted to disk) | 10/10 checks green, re-run after every merge/edit this pass |
| Flow check | `tools/flow_check.py` (53 checks) | full game-loop wiring intact |
| i18n audit | `tools/i18n_audit.py` | `MISSING: 0` across 13 locales |
| Headless suite | `tools/qa_sim/headless_suite` | scripted P0-P6 scenario + all `scenes/tools/*_scene.tscn` gates, run ×2 consecutive |
| Touch probe | `scenes/tools/touch_probe_scene.tscn` / `scripts/tools/_touch_probe.gd` | 23/23 assertions incl. 200-event input fuzz + 30-value settings fuzz |
| Autoplay bot | `tools/qa_sim/autoplay_bot` | winnability evidence — see `docs/KNOWN_ISSUES.md` "Autoplay bot" section for current score |
| Balance sim | `tools/qa_sim/balance_sim.py` | economy/time-to-win modeling, DARK/PARTIAL margins |

## docs/artifacts/ (this pass's new reports)

| Artifact | Path | Proves |
|---|---|---|
| Final gate report | `docs/artifacts/final_gate_report.md` | consolidated green/red state of every gate at RC tag time |
| Security / anti-tamper report | `docs/artifacts/security_report.md` | save HMAC signing, corrupt-recovery behavior, dev-tool exclusion, zero debug prints |
| APK size report | `docs/artifacts/apk_size_report.md` | **done** — 738 texture files, 41.2 MiB, 100% Lossless measured; scoped pilot + honest APK-vs-VRAM impact estimate; not applied (needs a windowed banding check, see report §4) |
| Owner-only items | `docs/artifacts/known_owner_only_items.md` | exhaustive list of what only the owner can finish, and why |

## Canon docs this pass touches (not new artifacts, but the record of truth)

`docs/HONEST_ASSESSMENT.md` (5.5/10 baseline + delta), `docs/VISUAL_AUDIO_SPEC.md` (wiring
contract), `docs/KNOWN_ISSUES.md` (every open gap), `PLAN.md` (milestone stamps),
`docs/PLAYER_VISIBLE_CHANGES.md` (player-facing changelog), `RELEASE_CHECKLIST.md` (owner
click-by-click), `docs/HANDOFF.md` (owner TODO).
