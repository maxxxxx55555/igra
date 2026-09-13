# RELEASE_ARTIFACTS.md — index of release-pass evidence

One line per artifact: what it is, where it lives, what it proves. Source of truth for a
claim always stays in the artifact itself — this file only points at it. Started
2026-09-12 (RELEASE CONVERGENCE PASS), updated 2026-09-13 through FINAL CONSOLIDATION.

## MEGA FINAL PASS (2026-09-13) — 3 of 4 branches merged, secrets made reachable, 6 review agents

The pass that took secrets from "exists in content, unreachable in the build" to findable,
wired the retention content, and put both content validators into the standing gate.

| Artifact | Where | What it proves |
|---|---|---|
| Audio mix report | `docs/artifacts/audio-mix/audio_mix_report.md` | ffmpeg-measured bus tree + LUFS/RMS/peak per file; 7 findings, 3 fixed, 3 logged as deliberate non-goals, 1 pass |
| Retention & fun review | `docs/artifacts/retention-fun/retention_fun_review.md` | return-loop score 5/10 with reasons; proof that only 1 of 26 secrets was reachable at game start; top-3 friction, all fixed |
| Content-depth validator | `docs/artifacts/content-depth/audit_content_depth.py` | 26 secrets + world canon; now gate-enforced, 0 ERROR |
| Retention validator | `docs/artifacts/retention/validate_retention.py` | 60 dailies / 6 NG+ modifiers / 28 captions; 270 checks ALL PASS; now gate-enforced |
| Known issues | `docs/KNOWN_ISSUES.md` | the four gaps this pass leaves open, each with reproducible evidence |
| Player-visible Batch 18 | `docs/PLAYER_VISIBLE_CHANGES.md` | what the owner should verify by hand, headed by the secrets fix |

**Branch decisions.** Merged: `arena/01a09a11-igra` (content-depth, `bcd2bc9`),
`arena/01a09a0b-igra` (ui-audio, `8c334ef`), `arena/01a09a4a-igra` (retention, `e75204d`).
**Rejected: `arena/card-unique-rescue`** — it certifies a 22/22 district-card scene match
while its own blob hashes are byte-identical to main. Zero card art changed, and it would
have replaced the real 1024×1536 contact sheet with a single 512×512 card. Full evidence in
`KNOWN_ISSUES.md`; the underlying 4-of-22 duplicate-photo defect remains open.

**Verification.** 6 agents run this pass: 4 pre-merge scope-checks (1 caught the fabricated
card cert), plus audio-mix, retention-fun, edge-case and visual-consistency reviews. Their
findings were fixed or documented, never dismissed — including one regression the reviews
caught in my own work (guarding `audio_manager`'s procedural click silenced screen
navigation outright) and one latent autoload-order crash (UISFX at autoload 68 referencing
EndingsManager at 107).

## FINAL CONSOLIDATION (2026-09-13) — arena/store-sync + arena/art-final merged, badges/cards wired, owner packet

Merged 2 of the 4 branches the task named (`arena/content-depth`, `arena/ui-audio` were
never pushed to origin — skipped, not fabricated). Both merged branches passed an
independent subagent scope-check first (2 subagents, both PASS, no violations). Wired this
pass: achievement badge icons (`scripts/ui/achievement_screen.gd`) and district collection
cards (`scripts/ui/collection_ui.gd`) from `arena/art-final`'s new texture set. 3 more
verification subagents ran post-wiring: i18n (PASS, MISSING:0), store-copy vaporware audit
(PASS, all claims backed incl. the corrected 31-achievement count), asset legibility/crop
check (found one real, non-blocking gap — 4 of 22 district cards share a base photo,
`docs/KNOWN_ISSUES.md`). New `docs/OWNER_RELEASE_PACKET.md`: one consolidated, copy-paste
document for every remaining owner step, including a gh-pages-ready privacy-policy page
already built and pushed to a new `gh-pages` branch this pass. See
`docs/CONTENT_PIPELINE_AUDIT.md` §18 (store-sync) and §19 (art-final scope note).

## AUDIO/VISUAL FINALE merge (2026-09-13) — postfx presets wired live

Merged `arena/01a09712-igra` (`36c3673`) on top of RC FINAL v2: 11-district cinematic
post-fx presets (bloom/vignette/chroma/grain), 4 trailer hero stills, finale ledger +
certificate. Wired this pass: bloom into `world_env_setup.gd`'s `_apply_postfx()` (the live
WorldEnvironment), vignette/grain into `post_process_overlay.gd`'s existing setters, and a
new `set_chroma_amount()` (no shipped consumer before this merge). Audio side needed no new
wiring — all 11 `AMBIENCE_LIT_BY_DISTRICT` rows were already filled. See
`docs/CONTENT_PIPELINE_AUDIT.md` §17, `docs/ASSET_LICENSES.md` "Added 2026-09-13".

## FINAL HARDENING PASS (2026-09-13) — 3 named blockers closed

| Blocker | Result | Evidence |
|---|---|---|
| 1. Autoplay bot boot-lifecycle | **Root cause found and fixed** (not deferred) — `scenes/main_3d.tscn`'s Splash child unconditionally redirected to boot after ~3s, a real bug hitting real players; plus a fall-recovery gap and a dead item-effect listener, both fixed. 0/11→11/11 districts in the clear majority of runs. Boss P2 phase remains a bot-sophistication gap, not this blocker. | `docs/KNOWN_ISSUES.md` "Autoplay bot", commits `84cd280`/`85af9f9`/`8f5925e` |
| 2. Texture compression | **Executed and measured** — 74 files VRAM-compressed, individually PSNR-verified ≥40dB; real ~4x VRAM reduction, small on-disk increase (honest, not the naive expectation) | `docs/artifacts/texture_compression_audit.md`, commit `a2c4074` |
| 3. Touch feel | **Timing proven in simulation** — 4 new budget assertions, caught and fixed a real animation-rate bug; touch tuning presets + one-time calibration added; real-device feel honestly stays unprovable headlessly | `docs/KNOWN_ISSUES.md` "Touch feel", commit `a3e34b1` |
| STEP 4 anti-tamper | Save versioning hook, 3-generation backup rotation, independent progress signature (closes a real downgrade gap), Play Integrity stub | `docs/artifacts/security_report.md` §7, commit `8d9140e` |

## Arena delivery ledgers + certificates (kept on disk, consolidated into canon docs)

| Artifact | Path | Proves | Consolidated into |
|---|---|---|---|
| Visual ledger | `docs/LEDGER_VISUAL.md` | 11 LUTs + 8 screenshots + 4 trailer re-grades, attempt log | `docs/ASSET_LICENSES.md` (2026-09-12 section) |
| Audio ledger | `docs/LEDGER_AUDIO.md` | 8 lit beds + 3 wow cues, attempt log incl. failed CC0/music-gen search | `docs/ASSET_LICENSES.md` (2026-09-12 section) |
| Visual certificate | `docs/CERT_VISUAL.md` | 0 defects — dims/purity/palette/LUT-monotonicity/letterbox, all measured | `docs/CONTENT_PIPELINE_AUDIT.md` §14 |
| Audio certificate | `docs/CERT_AUDIO.md` | 0 defects — header/granule/loudness/contract-pass, all measured | `docs/CONTENT_PIPELINE_AUDIT.md` §15 |
| Store certificate | `docs/CERT_STORE.md` | 0 open defects — 13/13 locale parity, char limits, master-hash unchanged | `docs/CONTENT_PIPELINE_AUDIT.md` §16 |
| Finale ledger | `docs/LEDGER_FINALE.md` | postfx presets + trailer heroes, full attempt log incl. license rows for the docs owner | `docs/ASSET_LICENSES.md` (2026-09-13 section) |
| Finale certificate | `docs/CERT_FINALE.md` | 0 defects — presets schema/clamps, full-strength sim, trailer dims/purity, scope hygiene | `docs/CONTENT_PIPELINE_AUDIT.md` §17 |

## QA / gate reports

| Artifact | Path | Proves |
|---|---|---|
| Static gate suite | `tools/check.sh --static` (run output, not persisted to disk) | 10/10 checks green, re-run after every merge/edit this pass |
| Flow check | `tools/flow_check.py` (53 checks) | full game-loop wiring intact |
| i18n audit | `tools/i18n_audit.py` | `MISSING: 0` across 13 locales |
| Headless suite | `tools/qa_sim/headless_suite` | scripted P0-P6 scenario + all `scenes/tools/*_scene.tscn` gates, run ×2 consecutive |
| Touch probe | `scenes/tools/touch_probe_scene.tscn` / `scripts/tools/_touch_probe.gd` | all green incl. 200-event input fuzz, 30-value settings fuzz, timing budgets, and the touch-calibration overlay (2026-09-13) |
| Autoplay bot | `tools/qa_sim/autoplay_bot` | **11/11 districts in the clear majority of runs** (was 0/11, every run — see `docs/KNOWN_ISSUES.md` "Autoplay bot" for the fix and the remaining boss-fight gap) |
| Balance sim | `tools/qa_sim/balance_sim.py` | economy/time-to-win modeling, DARK/PARTIAL margins |

## docs/artifacts/ (this pass's new reports — all delivered)

| Artifact | Path | Proves |
|---|---|---|
| Final gate report | `docs/artifacts/final_gate_report.md` | 22/23 engine gates green (1 pre-existing documented stall), headless_suite ×3, 7/7 qa_sim, i18n MISSING:0 |
| Security / anti-tamper report | `docs/artifacts/security_report.md` | HMAC-SHA256 save signing, 50-mutant corruption fuzz (0 crashes), stat clamps, dev-tool export exclusion, 0 shipped debug prints found |
| APK size report | `docs/artifacts/apk_size_report.md` | updated 2026-09-13 with the real measured before/after (was an estimate) |
| Texture compression audit | `docs/artifacts/texture_compression_audit.md` | full PSNR method + per-category results for the 74 compressed files (new 2026-09-13) |
| Owner-only items | `docs/artifacts/known_owner_only_items.md` | exactly 4 items, zero technical, as of 2026-09-13 |
| PSNR verification tool | `tools/texture_psnr_check.gd` | reusable headless PSNR checker — decodes a reimported texture, diffs against the original PNG pixel-for-pixel |

## Canon docs this pass touches (not new artifacts, but the record of truth)

`docs/HONEST_ASSESSMENT.md` (5.5/10 baseline + delta), `docs/VISUAL_AUDIO_SPEC.md` (wiring
contract), `docs/KNOWN_ISSUES.md` (every open gap), `PLAN.md` (milestone stamps),
`docs/PLAYER_VISIBLE_CHANGES.md` (player-facing changelog), `RELEASE_CHECKLIST.md` (owner
click-by-click), `docs/HANDOFF.md` (owner TODO).
