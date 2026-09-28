# Agent zones (owner wave "finish the game to the GDD", 2026-09-27)

The owner asked for a swarm: one agent per area, and one lead that directs and checks all of them.
Source of truth for what to build: `docs/GDD.md` (§25.2 "Нужно доделать", Appendix V milestone
tags `[M0]`-`[M4]`, the section each row cites) and `docs/TZ_COMPLIANCE.md` (DEFERRED rows).
`docs/PRODUCTION_BIBLE.md` holds the visual and audio canon.

Each agent works in its own git worktree and writes only inside its zone. A needed change outside the
zone is a request in the agent's report (exact file, exact patch), not an edit. A zone violation
means stop and report.

## Zones

| Agent | Owns (exclusive write) | Mission |
|---|---|---|
| lead (main session) | `docs/**`, `project.godot`, `tools/check.sh`, `export_presets.cfg`, merges, every Godot run | Assign, integrate, verify (engine gates, bot, frames read by eye), commit, push |
| enemies | `scripts/enemies/**`, `scenes/enemies/**`, `data/monsters/**`, `data/balance/**` | GDD §6: the 11-type roster in districts, §6.2 stats, group behaviour, danger levels, encyclopedia entries, monster-side detection (S02), monster and boss look per §11 |
| player | `scripts/player/**`, `scenes/player/**`, `scripts/weapons/**`, `scripts/gameplay/**`, `scenes/weapons/**` | G25 weapons (2 slots) and C03 auto-aim live in play (GDD §18), G07 crouch capsule and visibility, player-side S02 visibility modifiers |
| hud | `scripts/ui/hud_3d.gd`, `scenes/ui/hud_3d.tscn`, `scripts/ui/toast_manager.gd`, `scripts/ui/quest_tracker_hud.gd`, `scripts/effects/damage_indicator.gd`, minimap scripts under `scripts/ui/` | Appendix V.1 HUD modules 3.3-3.16 |
| menus | `scripts/ui/**` and `scenes/ui/**` except the hud files, `scripts/inventory/**`, `scripts/systems/settings_manager.gd` | Appendix V.2 menus (5.4 settings tabs, 5.5 load, 5.7 delete save, M4 menu backgrounds), V.5 inventory (equipment, rarity, sorting, detail, comparison), M4 quick wheel |
| world | `scripts/world/**` (except `district_atmosphere.gd`), `scripts/pickups/**`, `scripts/economy/**`, `scripts/systems/progress_tracker.gd`, `scripts/systems/achievements_manager.gd`, `scripts/systems/photo_mode.gd`, `data/items/**`, `scenes/districts/**` | G21 blueprints (§9, §20), G26 photos (§24.2), M4 temperature, weapon pickup placement, prop look per §11 |
| audio | `default_bus_layout.tres`, `scripts/systems/audio_manager.gd`, `scripts/systems/music_manager.gd`, `scripts/systems/footstep_system.gd`, `scripts/systems/uisfx.gd`, `scripts/world/district_atmosphere.gd` | A01 bus graph (§13 / PRODUCTION_BIBLE §3), routing every player onto it |
| qa | `scripts/tools/_qa_autoplay_runner.gd`, `tools/qa_sim/**` | Bot boss-phase skill and the X21 spine stall; regression checks for the new features |

Shared, append-only for every agent: `scripts/events/event_bus.gd` (new signals only) and the 13
`data/i18n/*.json` locale files (new keys only, all 13 locales, real translations). The lead merges
their conflicts as a union.

## Running the swarm from ZCode

- **Lead:** a ZCode or OpenCode task in the main checkout (`TLS_Build`, branch `main`), or a Claude
  Code session. Never more than one at once.
- **Zone agent:** its own ZCode or OpenCode task in its own worktree. From `TLS_Build`, run
  `git worktree add ..\TLS_<zone> -b swarm/<zone> origin/main`, open `..\TLS_<zone>` in ZCode, and
  give that task its row from the table above plus the rules below.
- **Integration:** the lead merges `swarm/<zone>` into `main`, runs the engine checks, pushes, then
  removes the worktree (`git worktree remove ..\TLS_<zone>`).

## Rules for every agent

- `AGENTS.md` applies (`CLAUDE.md` imports it): ponytail (reuse before writing, shortest diff), full 13-locale i18n for every
  user-facing string, zero TODO/FIXME/commented-out code/debug prints/BOM, English comments and
  commit messages, keep each file's CRLF line endings, never delete a file unless proven dead and not
  planned.
- **Never launch Godot** (no editor, windowed or headless run): concurrent runs collide on the
  owner's `user://` profile guard and the import cache. The lead runs every engine check. Agents run
  only `TLS_SKIP_REIMPORT=1 bash tools/check.sh --static`, `python tools/flow_check.py` and
  `python tools/scene_node_check.py`.
- REJECTED forever: PICKUP_TOUCH tightening; NavigationAgent3D navigation changes.
- A behaviour or balance change is verified by the lead with the 3-seed bot (IRON RULE).
- Commit in the worktree, small English imperative messages ending with
  the writing agent's own co-author line (Claude agents:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`). Never push.
- Report: commits, files, GDD/TZ rows done, what the lead must run and look at, i18n keys added,
  cross-zone requests as exact patches, risks.

## Earlier lanes

The OpenCode Desktop (`oc/visual-w10`) and Cline Desktop (`cl/a11y-i18n`) lanes of 2026-09-20 stay
inactive and absorbed into `main` (contracts: `docs/AGENTS_OPENCODE_ARCHIVED.md`, `.clinerules/zone.md`; history of this file).
The root `AGENTS.md` is now the shared instructions file for every agent.
