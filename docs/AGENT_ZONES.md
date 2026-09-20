# Agent zones

Multi-agent write access to this repo, each agent scoped to a non-overlapping zone. **A zone
violation — editing outside your own row's zone — is a stop-and-report, not a push-through.**

| Agent | Branch | Zone | State file |
|---|---|---|---|
| OpenCode Desktop — **INACTIVE** (2026-09-20: `oc/visual-w10` tip is `86228c6`, identical to `cl/a11y-i18n` and to `main` at branch-creation time — zero commits since creation, never started; scope absorbed below) | `oc/visual-w10` | ~~`scripts/world_env_setup.gd`, `shaders/**`, `assets/shaders/**`, visual `.tres`, VFX scenes, `docs/stills/**`, `docs/store_screens/**`, AUTO-DELETABLE-only deletion of `assets/_orphaned`/`assets/audio/_pre_norm`/`res://_QUARANTINE` per `docs/QUARANTINE_AUDIT.md`~~ | `docs/RUN_STATE_OC.md` (never created) |
| Cline Desktop — **INACTIVE** (same evidence as above) | `cl/a11y-i18n` | ~~`data/i18n/*.json`, `scripts/ui/*` accessibility code, `scripts/tools/_a11y_probe.gd`, `docs/ACCESSIBILITY.md`~~ | `docs/RUN_STATE_CL.md` (never created) |
| Claude Code (this tool) | `main` (integrator + both absorbed zones) | Everything, including OpenCode's and Cline's former zones above (now unstruck) — verify-before-write remains the standing rule, own-zone-only no longer applies while both lanes are inactive | `docs/RUN_STATE.md` |

Full contracts: [AGENTS.md](../AGENTS.md) (OpenCode, auto-read), [.clinerules/zone.md](../.clinerules/zone.md)
(Cline, auto-read).

## Why these zones don't overlap
Checked file-by-file against the current `main` tree before writing this table — no path in one
zone is a path either other zone touches. The one shared concern (both OpenCode's visual work and
Cline's accessibility work read `docs/GAMEFEEL_SPEC.md`) is read-only for both; neither zone owns
that file, and both contracts flag the same real, unresolved conflict against unmerged branch
`arena/01a0ab24-igra`'s more detailed version — see either contract for the trace.

## Merge order (integrator only, on "MERGE NOW")
`cl/a11y-i18n` first (smaller, more contained diff), then `oc/visual-w10`. Both `--no-ff`, gates
green after each, ancestry proven (`git merge-base --is-ancestor <branch-tip> main`). Moot while
both lanes stay inactive/empty — nothing to merge from them.

## Reactivation
If the owner opens OpenCode Desktop or Cline Desktop on their branch after this pass, their zone
row reverts to active for whatever they touch from that point — this doc doesn't retroactively
own work they do later. Re-strike this entry and restore the owned-zone table above.
