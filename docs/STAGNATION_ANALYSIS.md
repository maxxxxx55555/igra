# Stagnation analysis: the C8 verifier loop

Built from the 12 committed versions of `docs/CLOSURE_VERIFICATION_INTERNAL.md`, one per round
(`git log -- docs/CLOSURE_VERIFICATION_INTERNAL.md`). Each round's verifier file is committed with
that round's fix commit. Findings are the PARTIAL and FAKE rows. **Fix kind** says what that round's
fix commit changed: game (shipped code or config), tool (QA gates, probes, guards) or doc.

## 1. Timeline

| Round | Audited tag | Verdict C / P / F | Fix commit | Findings by fix kind (game / tool / doc) |
|---|---|---|---|---|
| 1 | rc1 `27ba1d5` (09-25 05:09) | 79 / 7 / 3 | `0873f38` 09:10 | 4 / 0 / 6 |
| 2 | rc2 `5724544` (09:11) | 128 / 6 / 0 | `5402640` 09:38 | 1 / 0 / 5 |
| 3 | rc3 `5402640` | 145 / 14 / 0 | `b8b20c0` 10:39 | 5 / 0 / 9 |
| 4 | rc4 `b8b20c0` | 186 / 12 / 0 | `3ee3568` 14:00 | 0 / 3 / 9 |
| 5 | rc5 `3ee3568` | 132 / 4 / 0 | `4061f1b` 14:26 | 0 / 1 / 3 |
| 6 | rc6 `4061f1b` | 94 / 10 / 0 | `8c0e01c` 14:53 | 0 / 4 / 6 |
| 7 | rc7 `8c0e01c` | 105 / 3 / 0 | `9936ab3` 15:12 | 0 / 1 / 2 |
| 8 | rc8 `9936ab3` | 106 / 3 / 0 | `94af752` 19:25 | 0 / 0 / 3 |
| 9 | rc9 `94af752` | 114 / 4 / 0 | `c46d8a3` 19:42 | 0 / 0 / 4 |
| 10 | rc10 `c46d8a3` | 121 / 3 / 0 | `1430516` 09-26 01:54 | 1 / 1 / 1 |
| 11 | rc11 `1430516` | 121 / 15 / 0 | `b8abb2e` 06:51 | 2 / 4 / 9 |
| 12 | rc12 `b8abb2e` | 132 / 11 / 0 | `ce782f8` 13:51 | 0 / 4 / 7 |
| **Σ** | 12 rounds in 28.7 h | 95 findings (92 P, 3 F) | | **13 / 18 / 64** |

The three FAKEs were real game defects: S03 vignette, G12b flicker and A03 footsteps, all in round 1.
From round 4 on:
- 3 of 65 findings changed game code: V05-mobile (r10), D03 and E05 (r11). All three are GDD
  relabels (DR-3 without a measurement became DR-4), not bugs.
- **No game-code defect has been found since round 3.**
- PARTIAL per round runs 12, 4, 10, 3, 3, 4, 3, 15, 11. It never reached 0.

## 2. Loop topics (PARTIAL/FAKE in ≥ 2 consecutive rounds)

95 findings, 93 unique `source | item` ids, 24 topics. These 9 topics repeat across consecutive
rounds:

| Topic | Rows | Rounds | Longest run | Kind |
|---|---|---|---|---|
| Report drift (ORDER_PASS rows, counts, candidate line) | 17 | 2, 3, 4, 5, 6, 8, 12 | 5 (r2–r6) | doc |
| Profile guard (user_data_guard → in-process snapshot → refusals → wrapper → QaLaunchGuard) | 16 | 4, 5, 6, 7, 10, 11, 12 | 4 (r4–r7) | tool (owner-data safety) |
| DR labels + V05-mobile | 12 | 3, 9, 10, 11, 12 | 4 (r9–r12) | doc → 3 game value changes |
| Flashlight upgrades (G12b, respawn, Stability, drain) | 6 | 1, 2, 3, 4 | 4 (r1–r4) | game |
| C06 tier fog at load | 6 | 2, 3, 4, 12 | 3 (r2–r4) | game, then tool |
| FUNCTION_MATRIX legend and rows | 6 | 1, 2, 9, 10, 11 | 3 (r9–r11) | doc |
| S03 evidence wording | 5 | 1, 5, 6, 7, 11 | 3 (r5–r7) | game (r1), then doc |
| TZ citations and counts | 6 | 1, 4, 8, 9, 12 | 2 (r8–r9) | doc |
| ARENA B7 defer + open-defers list | 2 | 6, 7 | 2 | doc |

Exact-id repeats in consecutive rounds:
- `MATRIX / Status legend` (r9→r10)
- `Fix / 5cf3b27 guard around QA runs` (r10→r11)
- r12 re-finding r11's DR-1 label at `ORDER_PASS_REPORT.md:49`

Only the flashlight topic converged, in round 4. It is the only loop topic whose fixes changed game code
and nothing else.

## 3. Root causes

1. **The verifier audits the previous round's fix, and since round 4 each fix added new QA
   tooling.** The guard grew in six layers: `5cf3b27` shell guard, then in-process snapshot, per-runner
   refusals, the `guarded_windowed` wrapper, the `QaLaunchGuard` autoload, and finally manifest, pid,
   crash abort and lifecycle gate. Each layer was new surface for the next round, and 16 guard
   findings in 7 rounds followed. The guard protects real owner data, so the work was legitimate. It
   was just routed through the game sign-off loop.
2. **The report is hand-maintained and cumulative.** Each round appended counts, tags and figures to
   ORDER_PASS_REPORT, TZ_COMPLIANCE, CORRECTION_LOG and FUNCTION_MATRIX, and every append made an
   older row stale. That produced 17 report-drift rows and 6 citation rows. A cloud re-run shows the
   drift only ever affects documentation, never a measured value.
3. **Label rules were re-read more strictly each round.** DR-3 needs a measured rejection, but the
   ledger assigned it without one; later rounds reclassified these as DR-1, then DR-4 (12 rows). The
   rule text never changed; its application tightened. G08's NEEDS-EYES label was the last live
   instance and is fixed on `cloud/audit-ce782f8`.
4. **The exit rule could never be met.** "Loop until FAKE=0 PARTIAL=0" (`RUN_STATE.md:5`) counts any
   wording slip as PARTIAL, and each round re-verified the whole ledger (94–186 CONFIRMED items).
   Across 100+ re-checked claims, at least one stale detail per round is close to certain. There was
   no cap, no severity split and no scope freeze.

## 4. What a player actually got from C8

| Commit (round) | Player-visible change | Evidence |
|---|---|---|
| `0873f38` (r1) | The ember vignette tints and pulses with noise (S03) | `docs/stills/tzverify/S03_noise_vignette.png` |
| `0873f38` (r1) | Low-battery flicker stops at Stability L5 (G12b) | `docs/stills/tzverify/G12b_low_battery.png` |
| `0873f38` (r1) | Concrete, wood and metal footsteps use separate walk/jog/sprint files; other surfaces vary pitch by speed (A03) | footstep probe (audio) |
| `0873f38` (r1) | Hardcore death also removes `.bak2`/`.bak3` (G17) | `docs/stills/tzverify/G17_hardcore_death.png` |
| `5402640` (r2) | Flashlight upgrades survive respawn and Continue; Brightness no longer dims the light | suite P2r |
| `b8b20c0` (r3) | Upgrades reset with New Game, hardcore and slot changes. Stability L1–L4 cut drain by 10–50%. The tier fog applies at load (C06). Monsters no longer stay white after a hit (V02) | `docs/stills/tzverify/C06_tier_low.png`, `C06_tier_ultra.png`; suite P2b |
| `1430516` (r10) | Phones draw the moon shadow at 2048 like desktop (V05) | mobile only, no frame |
| `b8abb2e` (r11) | District stages use the GDD lighting: darker DARK, brighter FULL (D03) | `docs/stills/tzverify/D03_stage_dark.png`, `D03_stage_streets.png`, `D03_stage_full.png` |
| `b8abb2e` (r11) | District rewards follow the 200 → 1200 coin curve (E05) | suite P2q; bot wins earned 8718–8975 coins |
| `c2e9b86` (cloud) | A claimed daily stays claimed through clock changes, and play-minute credit is capped per frame | attack_sim `_check_daily_clock_rollback_rejected` |

Rounds 4–9 and 12 shipped nothing a player can see. Every tzverify frame was re-captured in
`0873f38`, `b8b20c0` and `b8abb2e`; the D03 frames exist only from `b8abb2e`.

## 5. Anti-loop fix

**Cap.** One more verifier round (round 13, on the merge of `cloud/audit-ce782f8`), then C8 ends.
A round 14 runs only if round 13 finds a FAKE or a PARTIAL-G/S (below).

**Severity split.** Every finding carries one class:
- **PARTIAL-G:** shipped game code, config, assets or a GDD verdict is wrong.
- **PARTIAL-S:** player or owner data can be lost, or a security claim is false.
- **PARTIAL-D:** doc or report wording, a stale figure, or QA-tool internals that cannot harm data.

The exit rule is FAKE = 0, PARTIAL-G = 0 and PARTIAL-S = 0. PARTIAL-D items are fixed in one batch
commit and never start a new round.

**Loop-signature rule.** A finding is a *loop signature* when its topic (same file, same ledger row
family, or same report table) was PARTIAL in the previous round.
1. A loop signature must be fixed by removing the surface, not by rewording it: delete the claim,
   generate the number from a script, or tag it RECONFIRM-AT-SIGNOFF. Rewording the same sentence is
   not a fix.
2. Two consecutive rounds whose findings are all loop signatures or PARTIAL-D stop the loop. Batch
   the D items and sign off.

**No new tooling in a sign-off round.** A fix commit may add a QA mechanism only to close a
PARTIAL-S. Anything else goes to a tooling lane with its own gate (the guard now has
`qa_guard_e2e`), audited once, outside C8.

**Frozen scope for the final round:**
- In scope: game code and shipped autoloads changed since the last round, every GDD verdict (once),
  player and owner data safety, and security claims.
- Out of scope: report prose, cross-document number consistency (numbers are recomputed or tagged
  RECONFIRM-AT-SIGNOFF), and QA-tool internals beyond "can it touch the profile".

**Record per round in RUN_STATE:** PARTIAL-G / S / D counts and the number of loop signatures.

Applied to this history:
- Round 4 found 0 PARTIAL-G. Its guard findings were PARTIAL-S, which belong to the tooling lane.
- Rounds 5–8 found only tool and doc items, so the loop would have stopped after round 5.
- The label-driven V05, D03 and E05 items (r9–r11) fall inside the frozen scope ("every GDD
  verdict, once"), so the single final round would still have caught them.
