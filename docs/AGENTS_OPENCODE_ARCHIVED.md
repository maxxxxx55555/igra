# AGENTS.md — OpenCode Desktop zone contract

Branch: `oc/visual-w10` (create from `main` if missing; never push an empty branch).

## Zone (touch nothing outside this list)
`scripts/world_env_setup.gd`, `shaders/**`, `assets/shaders/**`, visual `.tres` (materials,
environments, `visual_quality.tres`), VFX scenes (`scenes/vfx/**`), `docs/stills/**`,
`docs/store_screens/**`, and physical deletion of `assets/_orphaned/`, `assets/audio/_pre_norm/`,
and `res://_QUARANTINE/` entries — **only** ones marked `AUTO-DELETABLE` in
`docs/QUARANTINE_AUDIT.md` (10 as of the last audit run: 6 fonts, 4 `_QUARANTINE/scenes/effects/*.tscn`
— re-run `python3 tools/quarantine_audit.py --check` before trusting the count, don't trust this
number stale). **Never** touch an entry marked `UNCERTAIN` — that's owner-eyes, not yours to judge.

**Already delivered by an arena session, merged into `main` — do not redo:**
- `docs/STORE_KIT.md` §Full listings (13/13 locale ledger) and `store/screens_spec/shotlist.json`
  (the 8-shot capture spec, machine-readable) — both real, both merged (`ff863c3`).
- `docs/QUARANTINE_AUDIT.md` + `tools/quarantine_audit.py` — the deletion manifest itself.
- `docs/SURFACES_UI_NARROWING.md` — `assets/textures/{surfaces,ui}/` per-file audit.

## Real known blocker — read before wiring anything visual
Only **W1** (graphics-tier preset) of `docs/VISUAL_PASS.md`'s W1-W11 wiring spec is actually
connected in the shipped code as of `main`'s current tip. W2-W10's materials/shaders exist on
disk, zero consumers. Two real findings from investigating this, not guesses:
1. The "live" ground-material code path is genuinely ambiguous — `district_grading.gd` looks like
   the place to wire wet-asphalt/foliage-sway (W5) but its own file comment says it's dead code
   today (`world_environment_path`/`district_root_path` exports never set by its instantiator).
   The real ground rendering may be scene-file authored (up to 11 district `.tscn` files), not
   script-driven — verify which before writing code, don't assume the script path.
2. **A conflicting `docs/GAMEFEEL_SPEC.md` exists on unmerged branch `arena/01a0ab24-igra`** — more
   detailed than the version on `main` (specific numeric caps: hit-stop budgets, shake-px
   measurement method, `reduce_time_fx`/`reduce_flash`/`reduce_ui_motion` toggle semantics tied to
   specific QA rows in a companion `docs/QA_MATRIX.md`). `main`'s current juice code
   (`wow_director.gd`, `toast_manager.gd`, `uisfx.gd`) was built against the shipped version, not
   that one. Before wiring more juice/accessibility effects: read both versions, reconcile by hand
   (this is a real content decision, not a mechanical merge — `git merge-tree` shows a genuine
   conflict on this file), and note which spec you followed in your commit.

## Scope order
Windowed BEFORE stills capture → `docs/VISUAL_PASS.md` §8 W2-W10 (mobile-tier fallbacks; every
effect gated by `reduce_flash`/`reduce_time_fx`/`reduce_ui_motion`, reconciled against the GAMEFEEL_SPEC
conflict above first) → AFTER stills + luminance/saturation deltas → `_QUARANTINE` AUTO-DELETABLE
deletes per the manifest → backlog (VISUAL_PASS polish, particle/LOD tuning, W8 menu parallax using
`assets/textures/loading/*_loading.png` — confirmed real planned art, not dead, see
`docs/SIZE_BUDGET.md`'s correction history for why that matters here specifically).

## Rules
- Push after every commit; prove it: `git ls-remote origin <ref>` must equal `git rev-parse <ref>`.
  One retry with an explicit refspec; two failures in a row is a hard stop.
- Rewrite `docs/RUN_STATE_OC.md` after each phase, ≤40 lines: what's done, hashes, what's next.
- Never touch `main` directly, never touch Cline's zone (`data/i18n/*.json`, `scripts/ui/*`
  accessibility, `scripts/tools/_a11y_probe.gd`, `docs/ACCESSIBILITY.md`) — a zone violation is a
  stop-and-report, not a push-through.
- Economy rules apply (see `CLAUDE.md`): targeted reads, output caps, one-line phase reports.
- Hard stop: same gate failing twice on the identical error; any deletion outside the AUTO-DELETABLE
  manifest; push failing twice.

See `docs/AGENT_ZONES.md` for the full agent/branch/zone table.
