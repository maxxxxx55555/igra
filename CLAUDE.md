# The Last Streetlight

Godot 4 stealth-narrative game. You are the sole dev; owner only pulls, runs one command, pastes the report. Decide design questions yourself and justify in docs.

## Default mode: ponytail
Apply `.claude/skills/ponytail` to every change. Shortest working diff, reuse before writing, delete over add, no unrequested abstractions. Never lazy about: understanding the flow first, validation at trust boundaries, i18n, one runnable check per non-trivial change.

## Hard rules
- Never clone repos into the project tree; never touch `.git/` hooks.
- Never delete a file unless proven dead *and* not a planned feature (lesson: `hiding_spot.gd`).
- Zero shipped: TODO, FIXME, commented-out code, debug prints, BOM.
- Autoloads via `/root`; `PROCESS_MODE_ALWAYS` on anything that runs while paused.
- Full i18n, 13 locales, every user-facing string.
- Small English imperative commits; push every 2-3.

## Validation gates — run after every change
```bash
bash tools/check.sh --static
python3 tools/flow_check.py
python3 tools/scene_node_check.py
```
Godot: `C:\Users\Maxsim\Desktop\TLS_Build\godot_extracted\Godot_v4.7-stable_win64_console.exe --path .`
Headless scene smoke: `tools/scene_smoke.gd`.

## Reference repos (read-only, `..\refs\`)
`godot-docs` (grep on any API doubt) · `godot-demo-projects` · `escoria` (quest patterns) · `godot-open-rpg` (architecture) · `ink` (narrative)

## Already done — do not redo
Launch, RPC-on-self, StyleBoxFlat scenes, NoiseLabel tscn, FadeTransition pause freeze, death signal, hiding_spot restore, medkit/battery, monster vision vs visibility, doors/keys API, HUD badge refresh + bar overlap, blackout, reset_all, save-slot district parity, autosave order, ScreenShake, finale reachability, tutorial CanvasLayer, emissive windows guard, double photo-mode, save/load round-trip, XP reset.

## Not built yet
`tools/autopilot/`, `docs/HANDOFF.md`, `docs/KNOWN_ISSUES.md`, and any ad SDK in `..\refs\` do not exist. Build before referencing.
