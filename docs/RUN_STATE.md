# Run state — orchestrator pass (2026-09-19)

## Done, pushed
- `86228c6` Phase 0: CLAUDE.md economy rules block; no `.mcp.json` in repo (nothing to disable at
  repo scope); `rtk` not installed, not verified, skipped.
- `ff863c3` Phase 1: merged `arena/01a0b08a-igra` (verified real, clean, conflict-free before
  merging — not trusted from the task description). Gates re-verified after a clean `--import`:
  static 12/12, full 25/26 (only the pre-existing 3D-scene stall). 4 OTHER unmerged `arena/*`
  branches checked and deliberately NOT merged — see below, not silently dropped.
- `8704231` Phase 2: `AGENTS.md` (OpenCode zone), `.clinerules/zone.md` (Cline zone),
  `docs/AGENT_ZONES.md` (manifest). Local branches `oc/visual-w10`/`cl/a11y-i18n` created from
  current main, not pushed (both empty so far).
- `bf0f7c9` Phase 3: `docs/TOOLING_DECISIONS.md` — nothing installed (see file for why).

## Arena branches NOT merged — real evidence, not a guess
- `arena/019ffbd0-igra` (77 files, 2953+/1052- vs main, 110 conflict-marker lines in a merge-tree
  dry run) — deep early-history divergence (commits go back to hiding-spot/save-system fixes
  already shipped on main under different hashes). Real conflict, needs human resolution.
- `arena/01a07b1c-igra` (45 files, 1197+/216-, 71 conflict-marker lines) — FPS weapon-layer
  changes that likely conflict with the live weapon code on main.
- `arena/01a09af1-igra` (552 files, 20244+/343-, 6 conflict-marker lines) — its own history is
  just merges of two ALREADY-merged branches, yet diverges massively from current main. Almost
  certainly stale/abandoned, not safe to merge blind.
- `arena/01a0ab24-igra` (3 files, 517+, **direct semantic conflict**) — a more detailed,
  conflicting `docs/GAMEFEEL_SPEC.md`/new `docs/QA_MATRIX.md`/`docs/BALANCE_MATRIX.md` vs the
  version already wired into shipped code this session (`f372a5c`). Flagged in both zone
  contracts for whoever picks up visual/a11y work next.
- `arena/card-unique-rescue` — already explicitly rejected in this repo's own history
  (`docs/RELEASE_ARTIFACTS.md`: fabricated 22/22 cert, byte-identical blobs to main). Not
  re-attempted.

## Integrator stance
No dev work on `main` right now. Waiting on either owner command "MERGE NOW" or both
`docs/RUN_STATE_OC.md`/`docs/RUN_STATE_CL.md` showing done+pushed (neither exists yet — no
OpenCode/Cline session has started work).

## Owner actions
1. `/model opusplan` (Phase 0 ask).
2. Open OpenCode Desktop on this repo, checkout `oc/visual-w10` — it auto-reads `AGENTS.md`.
3. Open Cline Desktop on this repo, checkout `cl/a11y-i18n` — it auto-reads `.clinerules/zone.md`.
4. When both are done: say "MERGE NOW" (or just wait — this tool checks both RUN_STATE files).
