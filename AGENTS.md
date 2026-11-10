<!-- LOCALE TRUTH (2026-11-10): the shipped build supports exactly 2 locales (en, ru); the owner cut the other 11 on 2026-11-10. Body mentions of other (pre-cut) locale counts are historical records, not the current build. -->

# AGENTS.md — OpenCode Desktop zone contract

> **Branch policy (verified 2026-11-10):** work on `main` only. `origin` has exactly two
> branches — `main` and `gh-pages` (`git ls-remote --heads origin` confirms this). The historical
> historical `oc/*` and `arena/*` branches **do not exist on origin** and must not be
> created, checked out, or referenced. The shipped spec on `main` is authoritative.

## Zone (touch nothing outside this list)
`scripts/world_env_setup.gd`, `shaders/**`, `assets/shaders/**`, visual `.tres` (materials,
environments, `visual_quality.tres`), VFX scenes (`scenes/vfx/**`), `docs/stills/**`,
`docs/store_screens/**`, and physical deletion of `assets/_orphaned/`, `assets/audio/_pre_norm/`,
and `res://_QUARANTINE/` entries — **only** ones marked `AUTO-DELETABLE` in
`docs/QUARANTINE_AUDIT.md` (10 as of the last audit run: 6 fonts, 4 `_QUARANTINE/scenes/effects/*.tscn`
— re-run `python3 tools/quarantine_audit.py --check` before trusting the count, don't trust this
number stale). **Never** touch an entry marked `UNCERTAIN` — that's owner-eyes, not yours to judge.

**Already delivered by an arena session, merged into `main` — do not redo:**
- `docs/STORE_KIT.md` §Full listings (2-locale ledger) and `store/screens_spec/shotlist.json`
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
2. **The `docs/GAMEFEEL_SPEC.md` conflict is MOOT (verified 2026-11-10).** The unmerged variant
   on the historical arena branch no longer exists anywhere: `git ls-remote origin` shows no such branch,
   and `git log --all -- docs/GAMEFEEL_SPEC.md` returns only the `main`-side history. There is now a
   single authoritative `docs/GAMEFEEL_SPEC.md` on `main`. `main`'s juice code
   (`wow_director.gd`, `toast_manager.gd`, `uisfx.gd`) is built against that shipped spec. Wire new
   juice/accessibility effects directly to `main`'s spec; no cross-branch reconciliation is needed.

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
