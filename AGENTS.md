AGENTS.md — rules for AI agents (Jules / Copilot / Claude / OpenCode)
Repo: THE LAST STREETLIGHT (Godot 4.7, GDScript, GL Compatibility).
Single source of truth: docs/GDD.md (v4 canon). On conflict — GDD wins.

== OPENCODE ENVIRONMENT ==
Godot headless: C:\Users\Maxsim\Desktop\TLS_Build\godot_extracted\Godot_v4.7-stable_win64_console.exe
Autonomous mode: permissions granted (edit/bash/webfetch/task).
After each block: git commit + append progress to progress.md.
Target: 0 ERROR in: godot --headless --editor --quit --path .
Style: YAGNI (Ponytail): minimal code; decision ladder before new abstractions.

== LOCAL REFERENCES (read on demand, do not copy into repo) ==
C:\Users\Maxsim\Desktop\free-for-dev — free services/APIs catalog (AI section)
C:\Users\Maxsim\Desktop\ecc — advanced skills: council, argus, code-tour
C:\Users\Maxsim\Desktop\godot-demo-projects — official Godot examples (FPS, 3D, shaders)
C:\Users\Maxsim\Desktop\awesome-godot — curated list of Godot assets/tools
Project skills: .opencode/skills/ (yagni, self-commit, godot-gates, surgical-edit, council, art-pipeline)

== SKILLS USAGE ==
- yagni: cut scope; reuse existing autoloads before writing new code.
- self-commit: one logical block = one commit + progress.md update.
- godot-gates: run the 4 gate scenes after code changes.
- surgical-edit: point fixes only, never full rewrites.
- council: ambiguous decision -> 3 options, critique each, pick one, log reason.
- art-pipeline: external art prompts go to docs/*_PROMPTS.md; code never blocks on missing art.

Before editing
Read the relevant GDD section first.
WIRE existing autoloads/systems (PowerGrid, EventBus, base_monster, player_fps...).
No parallel duplicate systems. Surgical edits, never full rewrites.

Mandatory gates after changes (headless; some scenes never quit — use timeout+kill)
godot --headless --path . res://scenes/tools/compile_gate_scene.tscn
godot --headless --path . res://scenes/tools/signal_arity_check_scene.tscn
godot --headless --path . res://scenes/tools/i18n_check_scene.tscn
godot --headless --path . res://scenes/tools/asset_check_scene.tscn
All must exit 0. Report gate results in the PR description.

Code style
TAB indentation, UTF-8 without BOM, strict typing, signals via EventBus.
No hardcoded UI strings — tr() with keys from data/i18n (13 locales).

Never commit
.tls_bak/, .log, p3_dump.txt, en_keys.txt, audio_refs.txt, missing_audio.txt,
debug scaffolding (scripts/tools/*.gd, scenes/tools/where*_scene.tscn etc.).
NEVER commit secrets/tokens/keys in any file.

PR rules
One task = one branch = one PR. List changed files + gate results.
Do not mix docs and code changes in one PR.

== ALWAYS ==
Apply .opencode/skills/ on EVERY task; state which skills you use before starting.

