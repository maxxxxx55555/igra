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

## P0.4 — permanent boot_check_scene.tscn gate
- Files to touch: `scripts/tools/_boot_check.gd` (new, tiny bootstrap),
  `scripts/tools/_boot_check_runner.gd` (new, actual driver — has to live
  under get_tree().root, not the swappable current_scene, same pattern as
  `_smoke_fps_flow.gd`/`_smoke_fps_runner.gd`, or Routes.goto() frees it
  mid-check), `scenes/tools/boot_check_scene.tscn` (new), `tools/check.sh`
  (wire into the engine-gate section, after save-integrity).
- Signals: none new; reads GameManager.is_playing(), watches for a live
  "player" group node, checks for a stray AdPopupInterstitial node.
- Risks: 60s real sustain makes this gate slow (~90s total) — acceptable,
  it only runs in the non-`--static` path. Hard 150s timeout so a real
  hang fails loudly instead of hanging the whole session (this project's
  history has exactly that failure mode from unrelated causes).
- Verification: compile_gate_scene (bad=0), then run the gate directly
  and read its own exit code + phase log.
- Screenshot angles: none (logic-only gate).
- Result: found and fixed a real bug in the gate itself — `_boot_check.gd`
  called `get_tree().root.add_child()` directly from `_ready()` instead
  of deferring it, which fails outright ("Parent node is busy setting up
  children") during the engine's own scene-setup window. Fixed to match
  `_smoke_fps_flow.gd`'s `call_deferred("_start")` pattern. Second real
  finding: the menu-reachable check used a single 0.5s wait instead of
  polling — too short for a real scene swap in this environment, changed
  to `_wait_until(..., 8.0)`. Verification in progress.

## P1 — real bug sweep: dead-code audit for tr() misuse, streetlight duplication
- Files to touch (i18n): `scripts/ui/skill_button.gd`,
  `scripts/ui/skill_tree_tab.gd`, `scripts/ui/skill_tree_ui.gd` (Godot's
  native tr() called on raw English sentences — no Translation entry
  exists for a non-key string, so it always fell through to English
  regardless of locale). `scripts/ui/lobby_menu.gd` and
  `scripts/ui/save_slot_entry.gd` have the identical bug but are
  confirmed unreachable (not in UIManager's screen dict, no call site
  anywhere) — left unfixed per this project's established policy on
  dead code, documented in docs/KNOWN_ISSUES.md instead.
- Files to touch (streetlights): `scripts/world/street_props.gd`
  (instantiate the real `streetlight_3d.tscn` instead of building flat
  emissive decals), `project.godot` (`[world] legacy_streetlights=false`),
  `docs/KNOWN_ISSUES.md` (new).
- Signals: none new; consumes the existing `EventBus.district_stage_changed`
  hookup already inside `streetlight_3d.gd` (previously unwired, not
  because it was broken — nothing ever instantiated the scene).
- Risks: `streetlight_spawner.gd`, initially flagged as "duplicate", is
  actually dead code (only placed in `main_3d.tscn`'s root, whose
  `street_builder_path` default never resolves there) — verified via
  grep across all 11 district `.tscn` files before touching anything, so
  no legacy-flag treatment was needed for it.
- Verification: compile_gate_scene (bad=0); visual confirmation via
  shot_tool scenario screenshot pending in P0.5's pass.
- Screenshot angles: night-street district shot, ideally two districts at
  different power stages to show the lit-vs-dark contrast now actually
  working.

## P1 (cont.) — real bug found via boot_check_scene.tscn itself
- What: the new gate's sustain phase reproducibly caught GameManager
  getting force-kicked from PLAYING to MENU ~10-20s into a fresh game,
  every run. Traced to `scripts/systems/integrity_guard.gd`'s `_watchdog()`
  (runs every 1s while playing): the instant `get_tree().get_first_node_in_group("player")`
  returns null for even a single 1s tick, it force-calls
  `GameManager._change_state(GameState.MENU)` directly — no grace period,
  no check for whether the player is just mid-death/mid-transition. A
  brief, single-tick gap (node being freed/reparented during a normal
  death or scene-internal transition) reads identically to "player
  crashed forever" and silently boots the session back to the main menu.
  Not a hypothetical — reproduced on every boot_check run before the fix.
- Fix: `scripts/systems/integrity_guard.gd` — require
  `MISSING_PLAYER_GRACE_TICKS=3` consecutive missing-player ticks before
  acting, and re-check `GameManager.is_playing()` at that point too (a
  legitimate state change during the grace window, e.g. death, isn't a
  watchdog failure).
- Risk: raising the grace period means a genuinely-vanished player stays
  undetected for up to ~3s longer — acceptable, this is a safety net for
  a rare failure mode, not a per-frame check.
- Verification: boot_check_scene.tscn re-run, watching whether the
  spontaneous MENU-kick stops recurring.
- Result: debounce alone did NOT fix it — added temporary stack-trace
  instrumentation to `_change_state()` and `Routes.goto()` (removed after
  diagnosis) and found the REAL cause: `_boot_check_runner.gd`'s own
  first action was `Routes.goto(Routes.MENU)`, fired so early (mid
  autoload init) that it raced `_bootstrap.gd`'s own current-scene check
  — which independently redirected to `splash.tscn`. The resulting
  orphaned splash instance's tween (fade 1s + hold 2s) wasn't freed
  cleanly and fired its queued `Routes.goto(BOOT)` callback a SECOND
  time much later, mid-gameplay, restarting boot_loading -> main_menu on
  top of an active game — and main_menu.gd's own defensive
  `if not GameManager.is_menu(): return_to_menu()` then forced the state
  change my gate caught. Exact same bug class `shot_tool.gd` hit last
  session (documented in `docs/VISUAL_AUDIT.md`) — same fix: don't call
  `Routes.goto()` from a script that starts this early, just poll for
  the menu to appear on its own. IntegrityGuard's debounce fix is kept
  regardless — a real, independently-worthwhile robustness improvement,
  just not the cause of this specific bug.

## RESCUE WAVE P0 — real windowed launch, not headless
- Files to touch: unknown yet — first reproduce with real `--windowed`
  Godot process, capture stdout/stderr to docs/runtime_log.txt, read it.
- Signals: none pre-known; whatever the parse/null/preload errors say.
- Risks: window may not close itself in a non-interactive shell; may
  need to force-kill the process after timeout and grep whatever got
  flushed.
- Verification: process exits (or is killed cleanly), log file is
  non-empty, no leftover godot*.exe processes afterward (tasklist check,
  per docs/HANDOFF.md's known process-lifecycle gotcha).
- Screenshot angles: main menu (fresh boot), first ~10-20s of gameplay
  after New Game, via shot_tool.gd flags if the window stays up long
  enough, else via the OS-level screenshot mechanism.

## RESCUE WAVE P0 — ROOT CAUSE FOUND: EndingScreen auto-fires
- What: real windowed launch works fine (menu renders correctly,
  screenshot proof). Clicking Play -> gameplay starts but is IMMEDIATELY
  covered by a full-screen "All districts powered!" (msg_win) overlay
  with [ESC]/[TAP] hint, fading in over 1.2s. This is the actual
  "user can't get into the game" blocker.
- Root cause: `scenes/main_3d.tscn` has a permanent `EndingScreen`
  CanvasLayer child (`scripts/ui/ending_screen.gd`) whose `_ready()`
  unconditionally calls `_build()`, and `kind` exports default to
  `"win"`. Nothing anywhere calls `show_ending()` (grepped, zero call
  sites) — it's dead API wired to a live, always-on node. So every
  single load of the gameplay scene self-paints a fake win screen.
  Confirmed NOT the canonical win screen: `GameManager.trigger_win()`
  -> `EventBus.game_won` -> `UIManager` opens `&"win"` -> maps to
  `scripts/ui/win_screen.gd` (uses EndingsManager's real 5-ending
  system, GDD-correct). `ending_screen.gd` and a third orphaned
  `scripts/ui/victory_screen.gd` are both unwired duplicates;
  `ending_screen.gd` is uniquely harmful because it's physically
  embedded in main_3d.tscn's node tree, not because anything triggers
  it.
- Files to touch: `scripts/ui/ending_screen.gd` only — stop `_ready()`
  from calling `_build()`; `show_ending()` already lazily builds
  (`if _bg == null: _build()`), so making it dormant by default costs
  nothing and doesn't delete the file/feature per CLAUDE.md's hard
  rule.
- Risk: none identified — no other code references this node by path,
  confirmed via grep.
- Verification: relaunch real window, Play, confirm gameplay is visible
  with no overlay; screenshot.
