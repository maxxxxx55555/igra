# INTERIM_BREAK — lead-dev self-audit (superseded when the arena A branch lands)

No `arena/*` branch carries a `BREAK_REPORT` (checked every remote head, 2026-09-22 — see
`docs/RUN_STATE.md`). This lists breaks/exploits already known to this session and its
predecessors, cross-referenced against `docs/FUNCTION_MATRIX.md` and `docs/SECURITY_PATCH_SPEC.md`
(the arena B doc, read in full this pass) rather than a fresh independent red-team pass — a real
arena BREAK_REPORT would find things this list does not.

## Reproducible, already tracked (not duplicated in depth — see linked source)

| id | break | status | source |
|---|---|---|---|
| BRK-01 | park-travel via City Map "Travel" → `player.global_position = (inf,inf,inf)` softlock | open, standing bug | `docs/KNOWN_ISSUES.md`, `docs/FUNCTION_MATRIX.md` X20 |
| BRK-02 | residential softlock, nudge-related, recurs after the 1.2s→0.25s fix | open, flaky, mechanism unconfirmed | `docs/FUNCTION_MATRIX.md` X21; `docs/REDTEAM_CHALLENGE.md` CHALLENGE-02 (arena, read this pass) names a concrete hypothesis: bot stop distance 1.4-1.5m vs 1.0m true contact radius — not yet tested |
| BRK-03 | `_game_test_3d.gd` phase-7 harness: null boss `get()` errors, gate reports FAIL every full run | open | `docs/FUNCTION_MATRIX.md` X19; `docs/REDTEAM_CHALLENGE.md` CHALLENGE-01 (arena) — confirms the 90s→170s timeout bump was opacity, not a fix |
| BRK-04 | save/economy/NG+/flashlight/daily file-tamper exploits (8 findings, P-01..P-08) | open, not yet implemented | full detail in `docs/SECURITY_PATCH_SPEC.md` (arena B) — this is the real, thorough break-and-fix document for the save/security surface; do not re-derive it here |

## Not checked this pass (honest gap)

No UI-exploit pass (double-submit, race conditions on rapid input, save-scumming beyond what
security spec already covers), no economy-balance exploit pass (infinite currency loops outside
the file-tamper vectors above), no client-side physics/collision exploit pass. A real arena A
BREAK_REPORT would cover these; this interim list does not claim to.
