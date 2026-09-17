# Release readiness report v7 — 2026-09-17 (premium spec pack, security reuse, size cut, juice+accessibility)

Supersedes v6 below (kept as history; see `docs/RELEASE_ARTIFACTS.md` for the full evidence
chain). Commissioned as a 6-phase autonomous push assuming no prior work existed for security
signing or headless screenshot capture — both checked against the repo first and found already
built: security was reused and re-verified rather than duplicated; headless capture was already
proven impossible by a prior session and wasn't rebuilt to fail the same way twice. Full trace in
`docs/RUN_STATE.md` and `docs/RELEASE_ARTIFACTS.md`'s new top entry.

**Correction to this pass's own earlier claim**: the P4 commit (`f372a5c`) said "static 12/12" —
re-verified twice since (once mid-pass, once for this report) and the real, reproducible number is
**11/12**. `flow_check`'s own Master-bus sub-check (`tools/flow_check.py`: `buses =
read("default_bus_layout.tres")`, checks for a literal `name = &"Master"` string) fails on any
valid Godot bus layout — the implicit index-0 Master bus is never explicitly named in the file
format, confirmed by grepping the file directly. Zero diff on that file this entire session, so
this is a pre-existing check bug, not a regression — but the earlier "12/12" line was wrong and
this report doesn't repeat it uncorrected.

## Verification (real runs, this session)

| Item | Result | Evidence |
|---|---|---|
| Static gates | **11/12 PASS** | `bash tools/check.sh --static` → "Провалено: 1, пройдено: 11". The 1 fail is `flow_check`'s Master-bus check, explained above |
| Engine gates (full) | **24/26 PASS** | `bash tools/check.sh` → "Провалено: 2, пройдено: 24". Fails: `flow_check` (same as above) and `прогон 3D-сцены (таймаут 90s)` — the long-documented pre-existing stall (`docs/KNOWN_ISSUES.md` "game_test_3d_scene.tscn gate stalls"), unchanged this session |
| Compile gate | **bad=0** | `compile_gate_scene.tscn` — every script compiles, incl. all P4-edited files |
| Save signing + tamper probe | **fails=0** | `save_integrity_check_scene.tscn` — round-trip, `.bak` recovery, corrupt-rejected, backup rotation, forged-signature rejected, 50-mutant fuzz, export/import. System already existed; reused, not rebuilt (`docs/SECURITY_THREAT_MODEL.md`) |
| Payload cut | **27.7% real, measured** | `godot --headless --export-pack "Windows Desktop"`: 281,710,668 → 203,681,544 bytes, commit `11cbb4e`. Export-filter exclusion, no files deleted, fully revertible |
| Stills (8 before + 8 after) | **0 — owner-run, not fabricated** | `tools/qa_sim/capture_stills.gd`'s own header proves headless capture is impossible (no compositor); exact windowed command in `docs/KNOWN_ISSUES.md` |
| Store shots (8) | **0 — owner-run, not fabricated** | same tool, same blocker |
| Hero key art | **Skipped, honest note** | no image-generation tool available in this session |

**Carried forward unchanged from v6** (nothing in their scope was touched this session):

| # | Item | Result |
|---|---|---|
| Autoplay bot wins ≥1 of 3 seeds | **PASS — 6/10** |
| Bot restores 11/11 districts on all seeds | **Still FAIL** — two reverted fix attempts on record, see `docs/KNOWN_ISSUES.md` |
| Textures ≥30% payload cut (VRAM compression axis) | **Still PARTIAL** — different axis from this session's 27.7% export-filter cut; texture claim itself stands unverified past the 74-file pilot |
| Edge-case fixes, file:line | **11 total, unchanged** |

## Weighted readiness: **62%**

Simple weighted average, not a precise formula — each category scored against what's actually
verified, not aspirational:

| Category | Weight | Score | Why |
|---|---|---|---|
| Engineering gates | 30 | 92% | 24/26, both fails pre-existing and named |
| Security | 10 | 100% | signed saves + tamper probe, real, gated, green |
| Size/perf | 15 | 55% | E1 (export filters) done and measured; E2-E4 narrowing partial; E5 (physical delete) owner-blocked; E7 (audio) skipped on purpose |
| Visual/juice | 10 | 35% | accessibility toggles + juice hooks wired and gated; the full W2-W10 visual pass (`docs/VISUAL_PASS.md`) was not attempted this session, only the juice/accessibility subset |
| Content/i18n | 10 | 100% | 13/13 locale parity maintained including this session's 3 new keys |
| Store/marketing | 10 | 30% | docs complete and grounded in real GDD copy; 0/8 shots captured, key art skipped, listing translated to EN only (12 locales pending) |
| Owner-only steps | 15 | 0% | structurally outside what a session can do — 0% here means "not yet done by the owner," not "broken" |

`30×0.92 + 10×1.00 + 15×0.55 + 10×0.35 + 10×1.00 + 10×0.30 + 15×0.00 = 62.35` → **62%**

## Gaps

### OWNER-ONLY (a session cannot do these — account, GUI, signing key, or eyes-on-render)

| Item | Effort | Evidence / exact step |
|---|---|---|
| Android keystore + signed AAB | ~30min, needs SDK install | `docs/store/HUMAN_CHECKLIST.md` §"Play Store / release" has the exact `keytool` command; `docs/artifacts/known_owner_only_items.md` item 1 has the full trace (Android SDK not installed on this machine either) |
| Play Console: app creation, IARC, listing upload, screenshot/AAB upload | ~1-2h, needs Google account | `docs/artifacts/known_owner_only_items.md` item 2, `docs/OWNER_RELEASE_PACKET.md` §b |
| Privacy policy: hosted URL + real contact email | ~15min | Skeleton in `docs/STORE_KIT.md` this session; a gh-pages draft already exists per `docs/artifacts/known_owner_only_items.md` item 3 — needs the contact-email placeholder replaced and Pages enabled |
| Physical deletion of `assets/_orphaned/` + `assets/audio/_pre_norm/` | 1 command | `git rm -r assets/_orphaned assets/audio/_pre_norm` — already excluded from the shipped build via export filters (`11cbb4e`), this just frees repo checkout space |
| Windowed stills (8 before + 8 after) | ~10min | `docs/KNOWN_ISSUES.md` has the exact `--windowed` command |
| Windowed store screenshots (8) | ~10min | same tool, same command, `docs/STORE_KIT.md`'s shot list |
| One real device/eyes-on playtest | ~30min | `docs/artifacts/known_owner_only_items.md` item 4 — 12-line script with expected visual per line, covers boss fight, texture banding, draw-call budget, touch feel |

### DEV-REMAINING (a future session can do these)

| Item | Effort | Evidence |
|---|---|---|
| SIZE_BUDGET E2-E4: per-file narrowing of the ~720 remaining size candidates against dynamic-loader ID schemes | ~2-3h | `docs/SIZE_BUDGET.md` — methodology and 5 spot-checks done, full per-file pass not |
| Audio bitrate tightening (E7) | ~1-2h, needs care | `docs/KNOWN_ISSUES.md` — needs confirming whether Godot 4.7's WAV importer exposes a kbps control before touching anything |
| Full W2-W10 visual pass per `docs/VISUAL_PASS.md` | large, multi-session | not attempted this session — only the juice/accessibility subset of P4 was done |
| Store listing translation to 12 non-English locales | ~1h/locale or MT+review | `docs/STORE_KIT.md` — EN copy exists and traces to GDD, others not started |
| `flow_check.py`'s Master-bus check fix | ~5min | `tools/flow_check.py` line ~139 — checks for a string Godot's bus-layout format never writes for the implicit index-0 bus; either fix the check or special-case bus 0 |
| `res://_QUARANTINE/` directory — not yet folded into the size-budget pass | unknown until investigated | seen in `compile_gate_scene.tscn` gate output this session, `docs/KNOWN_ISSUES.md` |

## Standing gates

`bash tools/check.sh` — 12 static + 14 engine (26 total). `bash tools/qa_sim/headless_suite`.
`python tools/i18n_audit.py`/the static i18n check — 13×1268 keys (1265 + this session's 3),
MISSING: 0. All re-verified this session after clearing the same recurring `.godot` import-cache
staleness `docs/RELEASE_READINESS_REPORT.md` v6 first documented — a real, repeatable process
gotcha (`godot --headless --path . --import` before trusting a gate result), not a code bug.
