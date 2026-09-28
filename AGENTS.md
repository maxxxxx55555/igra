# The Last Streetlight: agent instructions

One source of truth for every coding agent. ZCode loads this file at the start of each task;
Claude Code loads it through `CLAUDE.md` (`@AGENTS.md`). Edit this file, never a copy.

Godot 4.7 stealth-narrative game: GDScript, GL Compatibility renderer, 13 locales. You are the sole
dev. The owner only pulls, runs one command and pastes the report. Decide design questions
yourself and justify them in docs.

## Start here
- Current wave and NEXT-ROW: the top of `docs/RUN_STATE.md`. Since 2026-09-27 the wave is "finish
  the game to the GDD with an agent swarm". Who writes where, and how to run the lead and zone
  agents from ZCode, is in `docs/AGENT_ZONES.md`.
- Owner decisions still open: `docs/MERGE_PLAN.md` §7. Release path: `docs/RELEASE_RUNBOOK.md`.
  Verifier-loop exit rule: `docs/STAGNATION_ANALYSIS.md` §5.

## Default mode: ponytail
Read `.claude/skills/ponytail/SKILL.md` and apply it to every change. Shortest working diff, reuse
before writing, delete over add, no unrequested abstractions. Never lazy about: understanding the
flow first, validation at trust boundaries, i18n, and one runnable check per non-trivial change.

## Skills
The current skills live in `.claude/skills/<name>/SKILL.md` (ponytail\*, speckit-\*). When the owner
names one, read that file and follow it. `.opencode/skills/` is the older OpenCode set; its gate
list is out of date, so use it only when asked.

## Spec-kit
Installed (`.specify/`, `.claude/skills/speckit-*`); the owner asked to always use it. For any new
feature-sized wave of work, run speckit-specify → speckit-plan → speckit-tasks → speckit-implement
instead of freeform planning. Small fixes and bug chases don't need the full flow.

## Read first, every wave
`docs/PRODUCTION_BIBLE.md`: pillars, visual/audio canon, asset budgets, gameplay-canon pointers,
store positioning, launch checklist. Read it before starting any new wave of work. It exists so
canon doesn't have to be re-derived from screenshots or memory each time.

## Hard rules
- Never clone repos into the project tree; never touch `.git/` hooks.
- Never delete a file unless it is proven dead *and* not a planned feature (lesson: `hiding_spot.gd`).
- Zero shipped: TODO, FIXME, commented-out code, debug prints, BOM.
- Autoloads via `/root`; `PROCESS_MODE_ALWAYS` on anything that runs while paused.
- Full i18n, 13 locales, every user-facing string, through `LocalizationManager.t()`/`tf()` with
  the key in all 13 `data/i18n/*.json`.
- Code style: TAB indentation, UTF-8 without BOM, static typing, signals through `EventBus`.
- Never commit secrets, `*.log`, `.qa_logs/`, `.signing/`, `.tls_bak/`, `godot_extracted/` or build
  output. Check `git status` before every commit.
- Small English imperative commits. The lead pushes every 2-3; zone agents never push.

## Validation gates: run after every change
On Windows, run the shell scripts with Git Bash (`"C:\Program Files\Git\bin\bash.exe"`), not WSL's
`bash`. The scripts find a working Python themselves.
```bash
bash tools/check.sh --static
python tools/flow_check.py          # python3 on Linux/macOS
python tools/scene_node_check.py
```
Full battery with the engine gates:
`GODOT="C:/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe" bash tools/check.sh`

Godot: `C:\Users\Maxsim\Desktop\TLS_Build\godot_extracted\Godot_v4.7-stable_win64_console.exe --path .`
QA scenes run on the owner's real profile. Start windowed probes only through
`tools/qa_sim/guarded_windowed <scene>`; `QaLaunchGuard` covers the rest.
Headless scene smoke: `tools/scene_smoke.gd`.

## Reference repos (read-only, `..\refs\`)
`godot-docs` (grep on any API doubt) · `godot-demo-projects` · `escoria` (quest patterns) ·
`godot-open-rpg` (architecture) · `ink` (narrative)

## Already done: do not redo
Launch, RPC-on-self, StyleBoxFlat scenes, NoiseLabel tscn, FadeTransition pause freeze, death
signal, hiding_spot restore, medkit/battery, monster vision vs visibility, doors/keys API, HUD badge
refresh + bar overlap, blackout, save-slot district parity, autosave order, ScreenShake, finale
reachability, tutorial CanvasLayer, emissive windows guard, double photo-mode, save/load round-trip.
AppLovin MAX ad SDK is integrated in `..\refs\` and wired behind `AdService` (a real SDK key is
still needed; see `docs/store/HUMAN_CHECKLIST.md`). A permanent boot-flow gate exists
(`scenes/tools/boot_check_scene.tscn`, wired into `tools/check.sh`).

## Corrected (TRUTH WAVE): claimed done, actually wasn't
`reset_all()`/"XP reset" was listed as done, but `SaveSystem.reset_all()` never actually called
`XpManager.reset()` or `SkillTreeManager.reset()`. A fresh New Game kept the previous playthrough's
level, XP and skill points on the same save profile. Fixed; see `docs/KNOWN_ISSUES.md` and
`docs/PLANS.md` for the full trace. Lesson: an "already done" claim should point at a real test or
gate, not just a past commit message.

## Economy rules (context budget)
- Read with targeted `rg`/`sed -n`; never cat a whole file over ~300 lines.
- Never re-read a file already held this turn.
- Command output: redirect, then `grep`/`tail` down to ≤30-40 relevant lines. Never paste a full log.
- One-line phase reports on multi-step work (`PHASE N DONE: <hash> <gate-summary>`).
- Reuse an earlier gate result only when the diff provably cannot affect it, and state the reason
  in one clause.
- `rtk` is not installed on this machine (checked 2026-09-19, `command not found`), and there's no
  verified official package by that name, so this repo runs without it. If it's ever added, prefix
  verbose commands with it instead of the above.

## Multi-agent zones
`docs/AGENT_ZONES.md` lists which agent may write where. Zone agents commit in their own worktree
and never push or launch Godot; the lead merges, runs every engine check and pushes. Only one lead
runs at a time, in ZCode, OpenCode, or Claude Code, never more than one. A zone violation (editing outside your row)
means stop and report, not push through.

## Not built yet
Nothing currently known. The last item here, the perf-guard draw-call gate, turned out more built
than claimed (2026-09-22 P2 matrix sweep): `tools/qa_sim/drawcall_estimate.py` gives a real,
assertion-backed structural estimate and is wired into `tools/check.sh --static`, and a live
windowed gate (`scenes/tools/perf_check_scene.tscn`) already existed. Neither has re-measured the
true <200 GDD draw-call target on a real GPU recently; that needs a `--windowed` run, not a new
tool. Check current state before assuming something doesn't exist rather than trusting this list.
