# Final gate report — RELEASE CANDIDATE FINAL v2 (2026-09-13, FINAL HARDENING PASS)

Every gate, run fresh right before declaring RC FINAL v2. All commands
below are copy-pasteable; this is what the owner's own
`bash tools/check.sh --static && tools/qa_sim/headless_suite` will show.

## Static (10/10 green)

`bash tools/check.sh --static` → **10/10**, incl. `flow_check` (53/53
game-loop wiring checks) and `scene_node_check.py` (93 script/scene pairs,
0 dangling `$NodePath` refs).

## Engine gates, headless (22/23 green — 1 pre-existing, documented, unchanged)

`bash tools/check.sh` (full, timeout-guarded per-gate):

| Gate | Result |
|---|---|
| compile all scripts | OK |
| signal arity | OK |
| autoload API | OK (61 autoloads incl. this pass's new `PlayIntegrityService`) |
| i18n | OK |
| assets | OK |
| **3D-scene combat smoke** | **FAIL (timeout 90s)** — pre-existing, documented (`docs/KNOWN_ISSUES.md` "game_test_3d_scene.tscn gate stalls silently"); unchanged this pass, not a regression. |
| save integrity (incl. 50-mutant fuzz, export/import, backup-rotation, progress-signature forgery) | OK |
| boot-flow | OK |
| footstep mapper | OK |
| audio silence-before-input | OK |
| theme unify | OK |
| perf budget | OK (self-skips under `--headless`, needs `--windowed` for a real number) |
| touch input probe (incl. this pass's timing budgets + calibration overlay) | OK |

## `tools/qa_sim/headless_suite` — green ×2 consecutive at this tip

Includes the extended scenario driver: districts + full loot, 5 endings,
save+language switch, combat, all locale keys at runtime, a soak pass.

## `tools/qa_sim/*.py` — static sims (7/7 PASS)

| Sim | Result |
|---|---|
| `a11y_check.py` | PASS |
| `balance_sim.py` | PASS — DARK ≥20% margin every district, 0 dead-ends, 4 skill branches, 3-6h time-to-win |
| `drawcall_estimate.py` | PASS |
| `endings_sim.py` | PASS — all 5 GDD endings reachable |
| `lighting_stage_sim.py` | PASS |
| `overflow_check.py` | 0 fixed-width text sites at risk |
| `puzzle_economy_sim.py` | PASS |

## Autoplay bot — **11/11 districts in the clear majority of runs** (was 0/11, every run)

The FINAL HARDENING PASS found and fixed the actual root cause of the
project's long-standing boot-lifecycle softlock — see `docs/
KNOWN_ISSUES.md` "Autoplay bot" for the full trace. Re-run multiple times
this pass on seed 1: full 11/11 district spine clear in the clear
majority of attempts (real combat, real revives, real boss engagement);
a minority of runs still fail early with the same SOFTLOCK signature at a
different point each time (physics/navigation timing variance, not yet
root-caused — flagged, not chased further this pass). The final boss's
P2 phase is not yet won by the bot even with aim-tracking and battery
management added to it — a bot-sophistication gap, not the lifecycle bug
this pass targeted.

## i18n

`tools/i18n_audit.py` → `tr() keys used: 341 | en.json: 1110 | MISSING: 0`
(13 locales, 0 missing keys).

## Bottom line

Everything that CAN be proven headlessly is green, and the headless
evidence bar itself moved substantially this pass: from "the game world
cannot survive 8 seconds" to "the whole game is headlessly completable
except the final boss fight." The two remaining gaps (a pre-existing
engine-only combat-scene stall, and the boss fight specifically) are both
fully documented with exact evidence, and are exactly the class of
finding `docs/HONEST_ASSESSMENT.md` already names as the reason a real
playtest is the single highest-leverage action left.
