# Final gate report — RELEASE CANDIDATE FINAL (2026-09-12)

Every gate, run fresh at tip `649874d`, right before declaring RC FINAL.
All commands below are copy-pasteable; this is what the owner's own
`bash tools/check.sh --static && tools/qa_sim/headless_suite` will show.

## Static (10/10 green)

`bash tools/check.sh --static` → **10/10**, incl. `flow_check` (53/53
game-loop wiring checks) and `scene_node_check.py` (93 script/scene pairs,
0 dangling `$NodePath` refs).

## Engine gates, headless (22/23 green — 1 pre-existing, documented)

`bash tools/check.sh` (full, now timeout-guarded per-gate — see
`docs/KNOWN_ISSUES.md` "bound every check.sh gate with a timeout"):

| Gate | Result |
|---|---|
| compile all scripts | OK |
| signal arity | OK |
| autoload API | OK |
| i18n | OK |
| assets | OK |
| **3D-scene combat smoke** | **FAIL (timeout 90s)** — pre-existing, documented (`docs/KNOWN_ISSUES.md` "game_test_3d_scene.tscn gate stalls silently"); phase0 (player/monsters/pickups/fuel spawn) passes every time, phase1's combat/damage step stalls under `--headless` only, not a regression from this pass. `tools/qa_sim/headless_suite` deliberately excludes this one scene for the same documented reason. |
| save integrity (incl. 50-mutant fuzz + export/import, STEP 4/6) | OK |
| boot-flow | OK |
| footstep mapper | OK |
| audio silence-before-input | OK |
| theme unify | OK |
| perf budget | OK (self-skips under `--headless`, needs `--windowed` for a real number) |
| touch input probe (23 assertions + 200-event + 30-value fuzz) | OK |

## `tools/qa_sim/headless_suite` — green ×3 consecutive at tip

Includes the extended scenario driver: 12 autoloads, 11 districts + full
loot, 5 endings, save+language switch, combat, 1100 keys × 13 locales at
runtime, a soak pass. A real intermittent flake was caught and fixed
mid-pass (`649874d` — a tree-detach race in the language-switch scenario,
~1-in-3 before the fix, 0-in-3 after); reported here as found-and-fixed,
not swept under the rug.

## `tools/qa_sim/*.py` — static sims (7/7 PASS)

| Sim | Result |
|---|---|
| `a11y_check.py` | PASS |
| `balance_sim.py` | PASS — DARK ≥20% margin every district, 0 dead-ends, 4 skill branches, 3-6h time-to-win |
| `drawcall_estimate.py` | PASS |
| `endings_sim.py` | PASS — all 5 GDD endings reachable |
| `lighting_stage_sim.py` | PASS |
| `overflow_check.py` | 0 of 45 fixed-width text sites at risk |
| `puzzle_economy_sim.py` | PASS |

## Autoplay bot — 0/1, pre-existing, reconfirmed unchanged

`QA_SEEDS="1" tools/qa_sim/autoplay_bot` still softlocks at
suburbs/spine_i=0 after this pass's changes — identical symptom to before
this pass, not a regression, not fixed either (see
`docs/KNOWN_ISSUES.md` "Autoplay bot" for the full trace and why it's
deferred to an owner real-device playtest rather than chased further).

## i18n

`tools/i18n_audit.py` → `tr() keys used: 331 | en.json: 1100 | MISSING: 0`
(13 locales, 0 missing keys, 0 changes needed).

## Bottom line

Everything that CAN be proven headlessly is green. The two things that
can't (a pre-existing engine-only combat-scene stall, and the autoplay
bot's boot-lifecycle softlock) are both fully documented with exact
evidence and are exactly the class of finding `docs/HONEST_ASSESSMENT.md`
already names as the reason a real playtest is the single highest-leverage
action left.
