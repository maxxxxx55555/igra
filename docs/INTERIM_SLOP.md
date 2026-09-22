# INTERIM_SLOP — lead-dev self-audit (superseded when the arena D branch lands)

No `arena/*` branch carries a `SLOP_REPORT` (checked every remote head, 2026-09-22 — see
`docs/RUN_STATE.md`). This is a fast, real self-audit against CLAUDE.md's own "zero shipped"
rule, not a full independent review — treat it as a floor, not a ceiling.

## Found this pass

| id | item | evidence | verdict |
|---|---|---|---|
| SLOP-01 | `scripts/ui/settings_full.gd` — second, unused settings panel | zero `.tscn` references, zero `load()`/instance sites (`docs/RUN_STATE.md`, `docs/FUNCTION_MATRIX.md` X08) | dead code, high confidence — needs the second independent method (R3 CHALLENGE-03) before deletion per the project's own hard rule |
| SLOP-02 | `tools/qa_sim/i18n_truth_gate.py` overflow flags on 8/12 locales | see `docs/RUN_STATE.md` P0 finding | not code slop — a test-calibration gap (static ratio proxy without a real render check), tracked as its own residual, not duplicated here |
| SLOP-03 | zero-consumer shader files (`wet_asphalt.gdshader`, `foliage_sway.gdshader`, `streetlight_flicker.gdshader`, `height_fog_card.gdshader`, `contact_shadow.gdshader`, `menu_parallax.gdshader`, `asphalt.gdshader`, `facade.gdshader`) + their `assets/env/mat_*.tres` wrappers | confirmed by `docs/RENDERING_DIAGNOSIS.md` §c grep census (arena, read this pass) | dead code, but arena's own doc flags these as *possibly planned* (W2-W10 visual pass shaders) — CLAUDE.md's deletion rule requires "not a planned feature" too; do not delete without checking `docs/VISUAL_PASS.md`/W-item status first |
| SLOP-04 | `grep -rn "TODO\|FIXME"` across `scripts/` | not yet run this pass | UNTESTED — pending |
| SLOP-05 | `close_screen` input action (`project.godot [input]`, bound to Escape) | full-repo grep: zero script consumers (`docs/FUNCTION_MATRIX.md` IN84); `ui_pause` is bound to the SAME physical Escape key and IS consumed — `close_screen` reads as a leftover from before pause/close were consolidated into `ui_pause` | dead config, safe removal candidate — not deleted yet this pass (P2 matrix-sweep found it, not yet actioned); `shop_toggle`/`settings` (IN67/IN86) are also dead-mapping but NOT slop-safe to remove outright — they may be unwired *intended* hotkeys, recorded as an owner QUESTION in `docs/RUN_STATE.md` instead |

## Not checked this pass (honest gap)

Magic numbers vs named consts, copy-paste duplication, over-abstraction, and unused `@export`
vars need their own grep/read pass across `scripts/` (200+ files) — not done yet. This document
will be superseded in place (not appended to) once that pass or the real arena D report lands.
