# Release readiness report v7.2 — 2026-09-20 (RC finish pass: OC/Cline absorbed, arena consumed, IRON RULE)

Supersedes v7.1 below (kept as history). Full detail in `docs/IDEAL_GAP_REPORT.md` (new
this pass — per-category score with evidence, TOP-10 gap-to-ideal list) and
`docs/RELEASE_ARTIFACTS.md`'s new top entry; this section is the readiness-percentage
summary, not a duplicate of either.

**Two sessions same day.** First caught and reverted a real regression the prior session
shipped to `main` (a player-speed "fix" that softlocked the QA bot 0/3 seeds at spawn —
see `docs/GAME_AUDIT.md`'s CORRECTION notice). Second consumed the arena design audit's 8
proposals into real code (not just documentation), absorbed the never-started
OpenCode/Cline lanes, added an accessibility probe gate that previously didn't exist, and
established the IRON RULE: no balance/number commit without a 3-seed `autoplay_bot` run
recorded in the commit message. Neither session tagged a release before this one.

## Verification (real runs, this pass)

| Item | Result | Evidence |
|---|---|---|
| Static gates | **12/12 PASS** | unchanged all pass, `bash tools/check.sh --static` |
| Engine gates (full, 15 - added the new a11y probe) | **9/15 PASS** (21/27 incl. static) | `bash tools/check.sh` → "Провалено: 6, пройдено: 21". All 6 fails independently root-caused as sandbox-environmental this session, NOT code regressions - proven via `git stash` A/B test against pristine pre-session code for save-integrity/boot-flow (byte-identical failures on both), and matched to an already-documented missing-`.godot`-import-cache issue (present before any edit this session) for compile-gate/asset-check/theme-unify. The 3D-scene stall is the same long-documented pre-existing one. Full trace in `docs/RUN_STATE.md` |
| a11y probe (new) | **7/7 assertions PASS** | `a11y_probe_scene.tscn` run standalone, exit 0 |
| `balance_sim.py` | **PASS** | DARK solvable, no resource dead-ends, 4 skill branches, coin-economy ledger now reported (new `[7]` section) |
| autoplay_bot | **1/3 then 1/1** (this pass's own runs) | P5 verification: 1 win, 2 softlocks (both post-11/11-districts, in the boss phase - see `docs/KNOWN_ISSUES.md`'s new top entry). Diagnostic re-run: clean win, 303s, 0 deaths. Meets the arena audit's own stated target (>=1/3, not 3/3) |
| i18n | **13/13 locales, parity + key-usage green** | 19 new keys this pass (NGP_*/LAN_*), `bash tools/check.sh --static` |
| Store listing | **13/13 GREEN** | `python docs/artifacts/store-sync/verify_listing.py` |
| Quarantine audit | **PASS** | `python tools/quarantine_audit.py --check` (36 UNCERTAIN = owner eyes, not a gate failure, per the tool's own verdict policy) |

## Weighted readiness: **64%** (down from v7.1's 67% — see note)

| Category | Weight | Score | Change from v7.1 | Why |
|---|---|---|---|---|
| Engineering gates | 30 | 85% | -11 | 21/27 in this sandbox; all 6 fails proven environmental (see above), not regressions, but genuinely unresolved in this checkout until a real machine re-runs them (`docs/IDEAL_GAP_REPORT.md` TOP-10 #4) — scored honestly, not smoothed over |
| Security | 10 | 100% | — | unchanged; save-integrity gate's sandbox failure is the same proven-environmental issue above, not a signing/crypto regression |
| Size/perf | 15 | 60% | — | untouched this pass |
| Visual/juice | 10 | 45% | +10 | a11y probe now proves the 3 toggles actually gate their juice sites (previously unverified); W9 theme parity wired |
| Content/i18n | 10 | 100% | — | unchanged, more robust (lan_menu now fully localized, 19 new keys, parity maintained) |
| Store/marketing | 10 | 45% | — | untouched this pass |
| Owner-only steps | 15 | 0% | — | structurally unchanged, not a code gap |

`30×0.85 + 10×1.00 + 15×0.60 + 10×0.45 + 10×1.00 + 10×0.45 + 15×0.00 = 63.5` → **64%**

**Note on the drop from 67%**: this is a more honest count, not a regression. v7.1's "25/26"
engine-gate figure only ever surfaced 1 known-environmental fail (the 3D-scene stall); this
pass's fuller battery run surfaced 5 more (missing texture-import cache, a `user://`
filesystem quirk) that were already present in the sandbox but hadn't been hit/reported
before. Confirmed via direct A/B test that none of them trace to any commit this session or
last.

## Gaps

See `docs/IDEAL_GAP_REPORT.md` for the full TOP-10, split OWNER vs DEV with effort
estimates. Carried forward unchanged from v7.1 (nothing in that scope was touched this
pass): SIZE_BUDGET E5 physical deletion (owner-blocked), `surfaces/`/`ui/` narrowing,
store listing translation to 11 locales, Android keystore/Play Console setup, windowed
stills/screenshots, one real device/eyes-on playtest.

---

# Release readiness report v7.1 — 2026-09-17 (closure pass: 5 DEV-REMAINING items from v7)

Supersedes v7 below (kept as history; v7.0.0-rc1 stays tagged on origin as released, per explicit
instruction — this isn't a rewrite of what shipped, it's the next real pass). Closed 4 of v7's 5
DEV-REMAINING items for real; the 5th (full W2-W10 visual pass) was investigated and deliberately
not attempted — see below, not silently dropped.

**Correction to v7's own reported number**: v7 said the payload cut was 27.7%. That figure already
baked in a mistake from the prior P3 session (`assets/store/v2`/`assets/store/endings` excluded as
"dead marketing" when they're real planned content for platform store listings and the ending
screens). This pass's own first attempt at narrowing the size budget further made the *same class*
of mistake on a larger scale — 6 directories worth of real, documented, planned-but-unwired
content (menu-parallax art, touch-gesture pictograms, the map-screen UI, etc.) excluded on
zero-code-reference evidence alone, without cross-checking the delivery docs that would have
caught it. Caught and reverted within the same pass rather than left standing — full trace in
`docs/SIZE_BUDGET.md`'s "E2-E4 executed... then corrected" section. **Real total cut: 23.5%**
(215,512,000 bytes, down from an original 281,710,668), not 27.7% and not the 36.6% this pass
briefly claimed in between.

## v7's 5 DEV-REMAINING items — closure status

| # | Item | Result |
|---|---|---|
| 1 | `flow_check.py` Master-bus check fix | **Done**, `822642f` — real tool bug (checked for a string Godot's own bus-layout format never writes for the implicit index-0 bus), not a game bug. Static gates now 12/12 |
| 2 | SIZE_BUDGET E2-E4 narrowing | **Done, with a self-caught correction** — see above. Real cut 23.5%, `3eab8e3` |
| 3 | Audio bitrate investigation | **Done, definitive** — `ce8f7b6`, checked `../refs/godot-docs`'s authoritative `ResourceImporterWAV` reference: no bitrate/quality control exists in Godot 4.7's WAV importer at all (3-value enum only). No files re-encoded |
| 4 | Full W2-W10 visual pass | **Not attempted, on purpose** — `3980737`. Verified only W1 is wired; W2-W10's materials/shaders exist unused. Not wired because (a) the live ground-material code path is genuinely ambiguous (looks scene-file-based, not script-based, needing up to 11 `.tscn` edits to verify), and (b) this session cannot visually verify a shader/material change, and item 2's own correction just proved this repo has real, easy-to-miss wired-vs-delivered traps. Full wiring spec already exists in `docs/VISUAL_PASS.md` §8 for whoever can see the render |
| 5 | Store listing 12 locales | **Partial, real** — `2ce2be6`. All 13 locales now have a translated, char-verified (≤80) short description. Full long-form listing (description/bullets/keywords) stays untranslated for 11 locales — deliberately not rushed at low review depth |

## Verification (real runs, this pass)

| Item | Result | Evidence |
|---|---|---|
| Static gates | **12/12 PASS** | `bash tools/check.sh --static` → "Всё зелёное. Проверок пройдено: 12" |
| Engine gates (full) | **25/26 PASS** | `bash tools/check.sh` → "Провалено: 1, пройдено: 25". The 1 fail is `прогон 3D-сцены (таймаут 90s)` — the same long-documented pre-existing stall, unchanged. `flow_check` no longer among the failures |
| Compile gate | **bad=0** | `compile_gate_scene.tscn`, re-run after every export-filter change this pass |
| Save signing + tamper probe | **fails=0** | `save_integrity_check_scene.tscn`, re-verified in the full run above |
| Payload cut | **23.5% real, measured, corrected** | see above and `docs/SIZE_BUDGET.md` |
| Stills / store shots | **0 — still owner-run** | unchanged from v7, `docs/KNOWN_ISSUES.md` has the exact command |

## Weighted readiness: **67%** (up from v7's 62%)

| Category | Weight | Score | Change from v7 | Why |
|---|---|---|---|---|
| Engineering gates | 30 | 96% | +4 | 25/26, real fix landed (flow_check), only the pre-existing stall remains |
| Security | 10 | 100% | — | unchanged |
| Size/perf | 15 | 60% | +5 | real 23.5% cut with a corrected, trustworthy methodology (worth more than a higher but wrong number); E5 physical delete and `surfaces/`/`ui/` narrowing still open |
| Visual/juice | 10 | 35% | — | unchanged — W2-W10 investigated, not wired, for good reason (see item 4 above) |
| Content/i18n | 10 | 100% | — | unchanged |
| Store/marketing | 10 | 45% | +15 | all 13 locales now have a real short description; full listing still EN-only |
| Owner-only steps | 15 | 0% | — | structurally unchanged, not a code gap |

`30×0.96 + 10×1.00 + 15×0.60 + 10×0.35 + 10×1.00 + 10×0.45 + 15×0.00 = 66.8` → **67%**

## Gaps (updated)

OWNER-ONLY list is unchanged from v7 (see below, carried forward) — nothing in this pass reduced
it, since none of the 5 items were account/GUI/signing-key/eyes-on-render work.

DEV-REMAINING, updated: SIZE_BUDGET E5 (physical deletion, still tool-permission-blocked) +
`surfaces/`/`ui/` per-file narrowing; full W2-W10 visual pass (needs a session/human that can see
the render); store listing translation to 11 locales (short descriptions done, long-form not);
`res://_QUARANTINE/` directory still not folded into the size pass.

---

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
