# AGENTS.md — rules for AI agents (Jules / Copilot / Claude / OpenCode)

Repo: THE LAST STREETLIGHT (Godot 4.7, GDScript, GL Compatibility).
Single source of truth: docs/GDD.md (v4 canon). On conflict — GDD wins.

## Before editing
- Read the relevant GDD section first.
- WIRE existing autoloads/systems (PowerGrid, EventBus, base_monster, player_fps...).
- No parallel duplicate systems. Surgical edits, never full rewrites.

## Mandatory gates after changes (headless; some scenes never quit — use timeout+kill)
godot --headless --path . res://scenes/tools/compile_gate_scene.tscn
godot --headless --path . res://scenes/tools/signal_arity_check_scene.tscn
godot --headless --path . res://scenes/tools/i18n_check_scene.tscn
godot --headless --path . res://scenes/tools/asset_check_scene.tscn
All must exit 0. Report gate results in the PR description.

## Code style
- TAB indentation, UTF-8 without BOM, strict typing, signals via EventBus.
- No hardcoded UI strings — tr() with keys from data/i18n (13 locales).

## Never commit
- .tls_bak/, *.log, p3_dump.txt, en_keys.txt, audio_refs*.txt, missing_audio.txt,
  debug scaffolding (scripts/tools/_*.gd, scenes/tools/where_*_scene.tscn etc.).
- NEVER commit secrets/tokens/keys in any file.

## PR rules
- One task = one branch = one PR. List changed files + gate results.
- Do not mix docs and code changes in one PR.