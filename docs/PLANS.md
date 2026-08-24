# Plans — TRUTH WAVE

One 5-line block per task, written before editing. Append-only log, oldest
first.

## P0.1 — Reproduce real boot + New Game flow (diagnostic, no gate yet)
- Files to touch: none (read-only run against the real configured main
  scene, `res://scenes/ui/boot_loading.tscn`).
- Signals: none touched.
- Risks: headless mode may not surface the same render-path errors as
  windowed; cross-check both.
- Verification: `godot --headless --path .` exit code + full stderr grep
  for ERROR/SCRIPT ERROR, captured to a log file (artifact).
- Screenshot angles: none (headless diagnostic only, screenshots come
  after fixes in P0.5).
- Result: exit 0, zero lines of stderr beyond the version banner. Real
  boot (splash→boot_loading→menu) is clean. Artifact: `/tmp/real_boot_headless.log`.

## P0.2/P0.3 — ads-before-input, New-Game reset gaps, Reset Progress button
- Files to touch: `scripts/core/input_service.gd` (player_acted flag),
  `scripts/monetization/ad_service.gd` (gate interstitial on it),
  `scripts/systems/xp_manager.gd` + `scripts/systems/skill_tree_manager.gd`
  (add reset()), `scripts/core/save_system.gd` (call both from
  reset_all(), add wipe_all_saves(), log+quarantine unreadable saves),
  `scripts/ui/settings_screen.gd` (Reset Progress button + confirm),
  `data/i18n/*.json` (LEVEL_UP_NOTICE, Reset Progress, Reset Progress
  Warning keys × 13).
- Signals: new `InputService.player_acted`; existing `EventBus.game_started`
  (consumed, not changed).
- Risks: XpManager/SkillTreeManager reset() clearing state that some
  other system caches a stale copy of — checked `_apply_skill_effect`,
  it mutates the live player node at unlock time, nothing else caches it,
  so clearing the dict is sufficient.
- Verification: compile_gate_scene (bad=0), i18n_check_scene (fails=0),
  save_integrity_check_scene (fails=0, confirms quarantine log lines fire
  on the gate's own corrupt-file test case).
- Screenshot angles: settings Game tab (Reset Progress button + confirm
  dialog) — captured in P0.5's verification pass.
