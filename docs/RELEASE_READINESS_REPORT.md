# Release readiness report v7.3.2 — 2026-09-21 (softlock CLOSED + audio loudness + arena debug merge)

Supersedes v7.3.1 below (kept as history, same date). Unlike v7.3.1, this pass closed real
DEV-REMAINING work — two items move, honestly scored.

## Verification (this pass)

| Item | Result | Evidence |
|---|---|---|
| Static gates | **12/12 PASS** | `bash tools/check.sh --static`, re-run |
| i18n | **13/13 locales, MISSING: 0** | re-run, no new strings this pass |
| Store listing | **13/13 GREEN** | re-run |
| Quarantine audit | **PASS** | re-run |
| `balance_sim.py` | **PASS** | re-run |
| `autoplay_bot` | **3/3 WINS, zero FAIL/SOFTLOCK lines** | fresh run verifying the nudge-duration fix (`b7213ac`) — up from the 2/3 boss-fix baseline, a real improvement, not a reused number |
| Engine gates (full) | **26/27, reused from the v7.3 tag** | not re-run: this pass's only code changes were to `scripts/tools/_qa_autoplay_runner.gd` (QA-only tool, exercised live and error-free across 6 real bot runs this pass) and a temporary diagnostic in `item_pickup_3d.gd` that was fully reverted before commit — no shipped scene/resource/gameplay-script change the 26/27 suite would see differently |
| Arena merge | **1 ref merged** (`arena/01a0c324-igra`, docs-only, `68d6ce4`) | directly enabled the softlock fix; the other 5 refs are unchanged from v7.3.1's audit |

## Weighted readiness: **70%** (up from v7.3.1's 69%)

| Category | Weight | Score | Change | Why |
|---|---|---|---|---|
| Engineering gates | 30 | 98% | +2 | the 26/27 static/engine count is unchanged, but this pass adds a genuinely stronger correctness signal: the autoplay bot went from a 2/3 baseline with a known, real softlock to 3/3 with zero failures anywhere, on a QA-tool fix verified the same way the boss-phase fix was |
| Security | 10 | 100% | — | unchanged |
| Size/perf | 15 | 62% | — | unchanged |
| Visual/juice | 10 | 47% | — | unchanged |
| Content/i18n | 10 | 100% | — | unchanged |
| Store/marketing | 10 | 65% | — | unchanged |
| Owner-only steps | 15 | 0% | — | unchanged — structurally still 0 until the owner actually does one of the steps; `docs/OWNER_HANDOFF.md` (new) lowers the *effort* to act, not this score |

`30×0.98 + 10×1.00 + 15×0.62 + 10×0.47 + 10×1.00 + 10×0.65 + 15×0.00 = 69.9` → **70%**

This report's categories still have no slot for "audio quality" (same structural gap as
"economy" in v7.3.1) — the loudness fix is real and is reflected in `docs/IDEAL_GAP_REPORT.md`
instead, which has an Audio category; not force-fit into a score bucket here that doesn't
semantically cover it.

## OWNER-ONLY — see `docs/OWNER_HANDOFF.md` (new, single consolidated document)

| Item | Effort | Change this pass |
|---|---|---|
| Music generation (19 tracks) | ~2-4h | prompts now also inline in the handoff doc, not just `docs/MUSIC_RECIPE.md` |
| Windowed stills (`docs/stills/`, 8 shots) | ~2 min | **corrected**: the 5 `assets/store/screenshot_0X.png` files are already shipped (confirmed on disk this pass) — only this 8-shot before/after set is actually blocked, not "8 store shots" as prior reports implied |
| Android keystore + signed AAB, Play Console | ~1-2h | flagged a real inconsistency between two existing docs' keystore commands (different filename/alias each) — owner must pick one, not run both |
| `gh auth login` | ~2 min | unchanged, still not done |

## DEV-REMAINING — down to 2 items (was 4 in v7.3.1)

| Item | Effort | Change this pass |
|---|---|---|
| Full W2-W10 visual pass | large, multi-session | none |
| Economy: repeat-profile coin shortfall | medium, design call | unchanged, decision card now in `docs/OWNER_HANDOFF.md` too |

**Closed this pass**: residential spine-softlock (was unscoped DEV, now fixed and verified
3/3) and the shipped-track half of audio loudness normalization (was "~2-3h, needs ears" —
the ears-needing part turns out to have been measurable with `ffmpeg loudnorm`, done; what's
left is 100% new-track generation, which is owner work, not dev work).

---

# Release readiness report v7.3.1 — 2026-09-21 (arena backlog audit + softlock re-investigation)

Supersedes v7.3 below (kept as history, same date). **No score movement this pass** — every
weighted category below is unchanged from v7.3, honestly, because this pass's work (Phase M0
arena-backlog re-audit, a second softlock hypothesis tried and rejected, an economy
funding-path options doc) closed zero DEV-REMAINING items. Recording that plainly rather than
inventing a bump: process/analysis depth isn't the same as a shipped fix, and this report's
weighting doesn't have a category for "audited harder."

## Verification (this pass — reused where explicitly justified, re-run otherwise)

| Item | Result | Evidence |
|---|---|---|
| Static gates | **12/12 PASS** | `bash tools/check.sh --static`, re-run this pass |
| i18n | **13/13 locales, MISSING: 0** | `python tools/i18n_audit.py`, re-run — no new strings this pass, confirms no regression |
| Quarantine audit | **PASS** | `python tools/quarantine_audit.py --check`, re-run |
| `balance_sim.py` | **PASS** | re-run; independently reproduces the same 1,300-coin repeat-profile gap `docs/ECONOMY_OPTIONS.md` cites |
| Engine gates (full) | **26/27, reused from the v7.3 tag** | not re-run: this pass's only gameplay-code edit (a `NavigationAgent3D` experiment in the QA bot) was fully reverted (`git checkout --`, never committed) — zero net code delta since the v7.3 measurement, so the result provably still holds |
| `autoplay_bot`, boss-resolved | **2/3, reused from `acddc80`** | same reasoning as above — no gameplay code changed since that commit |
| Arena merge backlog | **0/5 mergeable, re-confirmed with `git merge-tree --write-tree`** | `docs/RUN_STATE.md` has the per-ref conflict evidence; not a rubber-stamp of the 2026-09-20 finding, independently re-derived |

## Weighted readiness: **69%** (unchanged from v7.3 — see note above)

| Category | Weight | Score | Change from v7.3 | Why |
|---|---|---|---|---|
| Engineering gates | 30 | 96% | — | reused, justified above |
| Security | 10 | 100% | — | unchanged |
| Size/perf | 15 | 62% | — | unchanged |
| Visual/juice | 10 | 47% | — | unchanged, still the lowest dev-scored category |
| Content/i18n | 10 | 100% | — | unchanged |
| Store/marketing | 10 | 65% | — | unchanged |
| Owner-only steps | 15 | 0% | — | unchanged |

`30×0.96 + 10×1.00 + 15×0.62 + 10×0.47 + 10×1.00 + 10×0.65 + 15×0.00 = 69.15` → **69%**

This report has no weighted slot for "economy" or "process/QA depth" — the coin-shortfall gap
and the arena-backlog audit both live in `docs/IDEAL_GAP_REPORT.md`'s separate per-category
scoring, unaffected here on purpose (same rubric v7.3 used).

## OWNER-ONLY — unchanged from v7.3

See v7.3's table below; nothing about owner-side effort changed this pass.

## DEV-REMAINING — unchanged from v7.3, deeper evidence on two of four

| Item | Effort | Change this pass |
|---|---|---|
| Full W2-W10 visual pass | large, multi-session | none |
| Spine-phase softlock, `residential` | unscoped | 2 hypotheses now rejected (was 1), 1 lead ruled out before coding — `docs/KNOWN_ISSUES.md` |
| Economy: repeat-profile coin shortfall | medium, design call | 3 scored options now exist — `docs/ECONOMY_OPTIONS.md` — still awaiting an owner pick |
| Audio loudness normalization + new-track mixing | ~2-3h, needs ears | none |

---

# Release readiness report v7.3 — 2026-09-21 (real-engine sign-off)

Supersedes v7.2 below (kept as history). Full detail in `docs/IDEAL_GAP_REPORT.md` (v7.3
update, same date) and `docs/VISUAL_REMAINING.md`/`docs/MUSIC_RECIPE.md` (new this pass).

**What's different about this pass:** it ran on a machine with a real Godot 4.7 binary, not
a headless-only sandbox. Every prior v7.x report's "environmental, proven via git-stash A/B
test" gate failures were real but unfixable without hardware — this pass had the hardware,
so TOP-10 #4 (from v7.2) actually got closed instead of re-confirmed-and-carried-forward.
The fix was exactly what `docs/RELEASE_READINESS_REPORT.md` v6 already documented (`godot
--headless --path . --import` before trusting a gate result) — no session since v6 had a
real machine to run it on until now.

## Verification (real runs, this pass)

| Item | Result | Evidence |
|---|---|---|
| Static gates | **12/12 PASS** | `bash tools/check.sh --static` |
| Engine gates (full) | **26/27 PASS** (up from v7.2's 21/27) | `bash tools/check.sh` → "Провалено: 1, пройдено: 26". The 1 remaining fail is `прогон 3D-сцены (таймаут 90s)` — the same long-documented pre-existing stall named in v7, v7.1 and v7.2 (`docs/KNOWN_ISSUES.md`), unchanged by this pass's import fix. Compile-gate, asset-check, boot-flow, theme-unify and save-integrity — all 5 of v7.2's other "environmental" failures — are now confirmed environmental AND fixed, not just A/B-tested as probably-environmental |
| Full asset import | **530/530 imported, 0 errors** | `godot --headless --import --path .` — this alone flipped compile-gate and asset-check from FAIL to PASS; both prior failures were 100% import-cache staleness, not code or content bugs (traced to specific missing `.ctex` cache entries, confirmed by direct re-run after import) |
| `autoplay_bot` (pre-fix baseline) | **1/3** | seed2 WIN, seed1 + seed3 both softlocked in the boss phase with the identical Y-dip signature — `.qa_logs/autoplay_seed{1,3}.log` this pass |
| `autoplay_bot` (post-fix) | **2/3, boss resolved both wins** | seed1 WIN, seed3 WIN; seed2 hit a new, unrelated spine-phase softlock in `residential` (logged as a new open item, not the boss bug) — `.qa_logs/autoplay_seed{1,2,3}.log` this pass, IRON RULE record in commit `acddc80` |
| `balance_sim.py` | **PASS** | stealth branch now 4 skills/13 SP (was 2/7) reflecting this pass's `low_profile`/`quiet_pace` addition, matches `docs/DESIGN_AUDIT_ARENA.md`'s derived arithmetic exactly |
| i18n | **13/13 locales, MISSING: 0** | `python tools/i18n_audit.py`; 2 new skill keys × 13 locales this pass |
| Quarantine audit | **PASS** | `python tools/quarantine_audit.py --check`; separately, real `--export-pack` measured the fold-in at −575,616 bytes (−0.27%) |
| a11y | **PASS, 7/7** | `python tools/qa_sim/a11y_check.py` (static) — no `_sec_probe` file exists in this repo under that name; the closest equivalent static safety check, `tools/qa_sim/overflow_check.py` (text-overflow risk scan), also ran clean of new findings |
| Store listing | **CORRECTION: already 13/13 complete, not an open item** | `python tools/gen_store_listing_locales.py --check` → GREEN this pass. `store/listing.md` was read directly and confirmed to contain genuine, complete, non-placeholder title/tagline/short+full description/8 bullets/ASO tags for all 13 locales (landed `82a7e87`, 2026-09-10-13, "FINAL SYNC" note in the file itself). v7, v7.1, v7.2 and this report's own first draft all carried forward "translation to 11 locales" as a DEV-REMAINING/OWNER-ONLY gap without re-checking — even though v7.2's own Verification table already said "13/13 GREEN" a section above its stale gap list. Corrected here rather than repeated a 4th time; see the Store/marketing score and OWNER-ONLY table below |

## Weighted readiness: **69%** (up from v7.2's 64%; 2 points of this pass's gain is the store-listing correction, not new work)

| Category | Weight | Score | Change from v7.2 | Why |
|---|---|---|---|---|
| Engineering gates | 30 | 96% | +11 | 26/27 real, on real hardware — not an A/B-tested guess. The single remaining fail is the long-documented pre-existing 3D-scene stall, unchanged across 4 reports now |
| Security | 10 | 100% | — | unchanged |
| Size/perf | 15 | 62% | +2 | quarantine fold-in measured this pass (`docs/IDEAL_GAP_REPORT.md`) |
| Visual/juice | 10 | 47% | +2 | one more W-item wired (W10 streetlight energy_mult); still the lowest-scoring dev category |
| Content/i18n | 10 | 100% | — | unchanged |
| Store/marketing | 10 | 65% | +20 | listing text (title/tagline/short+full description/bullets/tags, 13/13 locales) was already complete and is now correctly counted — see the correction above. Remaining gap is purely visual: 0/8 screenshots, key art, both owner-only (headless capture still impossible) |
| Owner-only steps | 15 | 0% | — | structurally unchanged; music generation now has a ready recipe (`docs/MUSIC_RECIPE.md`) which lowers the owner's effort but not this score (still 0 tracks actually generated) |

`30×0.96 + 10×1.00 + 15×0.62 + 10×0.47 + 10×1.00 + 10×0.65 + 15×0.00 = 69.15` → **69%**

## OWNER-ONLY (unchanged structurally, one item's effort just dropped)

| Item | Effort | Evidence |
|---|---|---|
| Windowed stills + store screenshots | ~10 min | `docs/KNOWN_ISSUES.md` has the exact command; headless capture confirmed still impossible (no compositor) even with a real Godot binary now available |
| Android keystore + signed AAB, Play Console setup | ~1-2h | `docs/store/HUMAN_CHECKLIST.md` |
| `gh auth login` | ~2 min | checked this pass: still not authenticated |
| **Music generation (19 tracks)** | **~2-4h, effort lowered this pass** | `docs/MUSIC_RECIPE.md` (new) — every Suno prompt is ready to paste in order; the owner's remaining work is generation + the DAW trim/loudnorm/export pass, not prompt-writing |

## DEV-REMAINING

| Item | Effort | Evidence |
|---|---|---|
| Full W2-W10 visual pass | large, multi-session, needs eyes-on-render | `docs/VISUAL_REMAINING.md` (new this pass) — itemized, including one real doc/code conflict found and flagged rather than guessed at |
| New spine-phase softlock, `residential` district | unscoped | found by this pass's own verification run, `docs/IDEAL_GAP_REPORT.md` "New open item"; needs the same diagnostic treatment the boss-phase bug just got |
| Economy: repeat-profile coin shortfall | medium, design call | `shop.gd` deletion closed the dead-code half of this, not the funding gap itself |
| Audio loudness normalization + new-track mixing | ~2-3h, needs ears | `docs/AUDIO_MIX_AUDIT.md` §a; this pass did the auto-fixable subset only (loop-flag fix + dead-file cleanup) |

---

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
| Content/i18n | 10 | 100% | — | unchanged |
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
