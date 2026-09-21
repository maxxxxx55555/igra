# INTERIM_TZ_COMPLIANCE — lead-dev self-audit (superseded when arena lands or the full TZ phase runs)

**TZ_SOURCE = derived.** No single owner TZ/tech-spec/design-doc exists in this repo (checked:
`docs/TZ.md`, root `TZ.md`, `docs/TECH_SPEC.md`, `docs/GAME_DESIGN.md`, `docs/PROJECT_PLAN.md`,
`docs/SPEC.md`, and a case-insensitive `rg` for "техническое задание"/"ТЗ"/"game design
document"/"specification" across every `.md` — none exist). Per the studio-lead directive's own
fallback rule, the requirement set is the union of `docs/GAMEFEEL_SPEC.md`, `docs/VISUAL_PASS.md`,
`docs/STORE_KIT.md`, `docs/CARD_ART_BRIEF.md`, `docs/STYLE_GUIDE.md`, `docs/QA_MATRIX.md`.

No `arena/*` branch carries a `TZ_COMPLIANCE_AUDIT` either (checked every remote head,
2026-09-22). This interim document covers only `GAMEFEEL_SPEC.md`, read and spot-checked this
pass — the other 5 source documents (~1550 combined lines) are NOT yet read for compliance
purposes; their rows are listed as PENDING, not silently omitted.

| ID | Requirement (verbatim) | Source | Status | Evidence | Verdict |
|---|---|---|---|---|---|
| TZ-01 | "Every effect names the accessibility toggle that disables or reduces it" — `reduce_flash`/`reduce_time_fx`/`reduce_ui_motion` | `GAMEFEEL_SPEC.md:3-6` | The spec's own text says "None of the three toggles below exist yet in SettingsManager" — **this is now stale**: all three are implemented and gate real effects | `scripts/effects/screen_shake.gd:21` (reduce_screen_shake), `scripts/player/player_3d.gd:887` + `scripts/systems/wow_director.gd:52,70,87` + `scripts/world/streetlight_3d.gd:32,55` (reduce_flash), `scripts/systems/wow_director.gd:70,87` (reduce_time_fx), `scripts/systems/uisfx.gd:98` + `scripts/ui/toast_manager.gd:100` (reduce_ui_motion) — plus a dedicated regression probe `scripts/tools/_a11y_probe.gd`, wired into `tools/check.sh` ("accessibility: reduce_flash/time_fx/ui_motion гейтят juice-сайты") | **MET** |
| TZ-02 | Hit-stop cap ≤80ms, screen shake cap ≤4px-equivalent | `GAMEFEEL_SPEC.md:3` | Shake is implemented as a 3D world-unit camera offset, not a 2D pixel offset — the spec itself says this comparison "cannot be done without measuring in-engine" | not measured this pass | **GAP-DEV (needs an in-engine pixel measurement, not a design call)** — pending |
| TZ-03 | 7 new juice events (`item_picked_up`, `xp_gained`, `achievement_unlocked`, `enemy_hp_updated` crit hit-stop, `player_healed`, `boss_defeated`, `district_blackout`/`light_disrupted`) each wired with the correct toggle and cap | `GAMEFEEL_SPEC.md:30-40` | not checked individually this pass | pending — needs one grep+read per `EventBus` signal listed | **PENDING** |
| TZ-04 | `district_blackout`/`light_disrupted` flash gating is a hard requirement, "never skip the gate" (photosensitivity) | `GAMEFEEL_SPEC.md:46` | not checked this pass — highest-priority PENDING row given the explicit safety framing | pending | **PENDING (safety-relevant — prioritize when the full TZ phase runs)** |
| TZ-05..TZ-N | Everything in `VISUAL_PASS.md`, `STORE_KIT.md`, `CARD_ART_BRIEF.md`, `STYLE_GUIDE.md`, `QA_MATRIX.md` | (not yet read for TZ purposes this pass) | not started | — | **PENDING** |

## Honest residual

This is a 1-of-6-documents pass. Do not read "MET: 1" as "TZ compliance is good" — it means one
narrow toggle-wiring requirement was checked and found already done. The real TZ phase (this
directive's own later step) must read all 6 documents in full before any compliance percentage is
reported, per the HONESTY RULE.
