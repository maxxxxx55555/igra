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

## RESCUE WAVE P1 — footstep mapper (surface x speed, ox alpha's 18 files)
- Files: scripts/systems/footstep_system.gd (add SPEED_SAMPLES lookup +
  grass/gravel/tile MATERIALS entries + detection keywords), new
  scripts/tools/_footstep_check.gd + scenes/tools/footstep_check_scene.tscn
  (permanent gate), tools/check.sh (wire it in).
- Signals: none new.
- Risk: only 3 player movement states reach play_step (WALK/STEALTH/RUN;
  CROUCH/IDLE are silent) but delivered files have 3 speed tiers
  (walk/jog/sprint) — no "jog" state exists. DEFAULT_CHOICE: WALK+STEALTH
  both use "walk" tier, RUN uses "sprint" tier, "jog" files stay unused
  rather than inventing a jog mechanic. Documented inline in code comment.
- Verification: extended footstep_system.gd's existing demo() self-check
  to assert every SPEED_SAMPLES entry actually resolves to a loaded,
  non-null AudioStream (not just that the dict key exists); new gate
  scene runs demo() headless and prints each surface/speed -> file
  resolution. Result: `[footstep-check] DONE fails=0`, all 12
  surface/speed combos print OK.
- Screenshot angles: none (audio-only, no visual surface).

## RESCUE WAVE P0.5 — real gameplay screenshot tool
- What: existing scripts/tools/shot_tool.gd's blind 8s-wait scenario
  path raced the splash/boot bootstrap and produced menu screenshots
  instead of gameplay (confirmed twice: docs/shots/rescue_street_verify{,2}.png).
  Manual GUI-automation clicking (PostMessage/SendInput on the real
  window) proved unreliable in this sandbox after the very first click
  (see below) - not a reliable verification method here.
- Files: new scripts/tools/_gameplay_shot.gd (bootstrap, mirrors
  _boot_check.gd exactly) + scripts/tools/_gameplay_shot_runner.gd (the
  real logic, spawned under get_tree().root so Routes.goto() scene
  swaps don't free it mid-coroutine) + scenes/tools/gameplay_shot_scene.tscn.
- Verification: `godot --path . --windowed res://scenes/tools/gameplay_shot_scene.tscn`
  -> `SHOT_OK: .../docs/shots/gameplay_shot.png 1920x1055`. Screenshot
  (saved as docs/shots/rescue_gameplay_after_p0_fix.png) shows real
  gameplay - HUD (health/stamina/battery, ШУМ/ЗАМЕТ, radar, ammo), NO
  win-overlay bug - proves the ending_screen.gd fix holds in a real
  windowed run, not just the headless boot gate.
- Side finding: the spawn view is almost entirely black/grain with no
  visible environment - feeds directly into P2 (night sky, lighting).

## RESCUE WAVE P2.1 — night sky panorama -> WorldEnvironment
- Files: scenes/environment/world_env.tscn (background_mode 1->2, add
  PanoramaSkyMaterial+Sky using assets/textures/sky/night_sky_panorama_
  2048x1024.png), scripts/world/district_grading.gd (was force-setting
  background_mode=BG_COLOR every district entry/stage change, silently
  overwriting the sky - now only does that on LOW graphics tier as a
  perf fallback per Production Bible's checklist item; SKY mode
  otherwise).
- DEFAULT_CHOICE: moon_glow_256.png NOT wired as a permanent fixture.
  docs/ASSET_HANDOFF.md's own delivery note says "design says no
  permanent moon" - it's for a future moon EVENT, not default sky.
  Wiring it always-on would invent a visual the design doc explicitly
  says isn't canon.
- Verification: compile+asset-check gates green. New scripts/tools/
  _gameplay_shot.gd + _gameplay_shot_runner.gd (bootstrap-under-root
  pattern, same as _boot_check.gd) drive real New Game headlessly and
  capture the live viewport - avoids the GUI-automation unreliability
  hit earlier this session (manual PostMessage/SendInput clicks on the
  real window worked exactly once out of ~10 attempts, not reproducible
  on demand - documented as a sandbox limitation, not a game bug).
  docs/shots/rescue_p2_sky2.png: real street geometry now visible
  (trees, streetlight pole, sidewalk - the pre-fix shot was flat black
  with zero geometry visible). Sky region is a textured navy gradient,
  not solid flat color, though individual stars read faint under fog +
  DARK-stage tonemap - left as-is: GDD's pillar 1 wants DARK stage
  near-pitch-black, so a barely-visible starfield there is closer to
  canon than a bright one, not a bug to chase further.

## RESCUE WAVE P2.2 — district ambience beds -> MusicManager
- Files: scripts/systems/music_manager.gd (AMBIENCE_DARK_BY_DISTRICT +
  AMBIENCE_LIT_BY_DISTRICT consts, _ambience_path_for()/_refresh_
  district_ambience() replacing the old AMBIENT_BY_DISTRICT lookup in
  _on_district_entered, new _on_district_stage_changed handler so power
  restoration is audible immediately, not just on next district visit),
  scripts/tools/_asset_check.gd (2 assertions hardcoded the old shared
  generic filenames — updated to the new per-district bed names, same
  intent).
- DEFAULT_CHOICE: only suburbs/hospital/power_station got a _lit.ogg
  from ox alpha; the other 8 districts keep playing their _dark bed even
  once restored rather than inventing a _lit file that wasn't delivered.
- Verification: asset-check gate (which already had music-layer tests)
  green after updating the 2 stale assertions; compile gate green;
  --static suite 10/10, flow_check 53/53.

## RESCUE WAVE P3 — perf guard (draw calls)
- Files: new scripts/tools/_perf_check.gd + _perf_check_runner.gd (same
  bootstrap-under-root pattern) + scenes/tools/perf_check_scene.tscn.
  Prints draw_calls/primitives/objects_in_frame once real gameplay is
  reached, does not hard-fail (no per-district budget wired to know
  which of the GDD's two budgets applies at the spawn point) - matches
  Production Bible's own "printed/verified, not yet an automated gate"
  scoping. Not wired into tools/check.sh (would add ~15-20s per run for
  a diagnostic-only check that always exits 0 - no real gate value).
- Result: 370 draw calls in suburbs (spawn district), over both the D1
  (<200) and D11 (<350) budgets. Root cause identified (streetlight_3d.
  tscn has no MultiMesh batching, 2 MeshInstance3D per pole x pole pairs
  at every street interval) but NOT fixed this session - would need to
  preserve each pole's individual power-stage reactivity (fixed last
  session, real regression risk if rushed). Documented in docs/
  KNOWN_ISSUES.md and docs/PRODUCTION_BIBLE.md's checklist.

## RESCUE WAVE P2.5 — boss stings, WAV>1MB -> OGG + wired to encounters
- Files: converted assets/audio/sfx/{architect,tvar}_sting.wav (1.3MB/
  1.0MB, over the 1MB budget per docs/PRODUCTION_BIBLE.md) to .ogg via
  ffmpeg libvorbis q6 (78KB/69KB) - originals kept, not deleted (matches
  the _pre_norm/ backup convention, avoids the "never delete" hard rule
  on files that might still be a reference/planned asset). Generated
  .import files (godot --headless --import).
  Added base_monster.gd::_play_intro_sting() (positional one-shot via
  AudioManager.play_sound_3d - separate from play_cue()'s repeatable
  attack/hit/death/step convention, which hardcodes a .wav path and
  isn't meant for a single per-encounter stinger).
  boss_3d.gd (Architect, final boss): sting plays at the same "first
  real player contact" moment that already triggers enter_boss() music.
  tvar_3d.gd (mini-boss): new _sting_played guard + EventBus.player_
  detected listener (id-checked against monster_id, since that signal
  is a global per-monster broadcast), plays once on first detection.
- Verification: compile/signal-arity/asset-check gates green, --static
  10/10. Not screenshotted (audio-only); not manually heard this session
  (would need a live combat encounter, out of reach of the headless/
  scripted verification tools built this session).

## MAX-THROUGHPUT BURST — fix 1: 6 silent enemy types (no combat audio)
- What: asset-audit subagent found brute/burner/rotter/hound/tvar/
  sharpshooter (all 6 new-roster enemies) never call _set_cues() at all
  -> play_cue() no-ops on _cues.has(cue)==false for every cue including
  "attack" -> these enemies were fully playable but 100% silent in
  combat. 24 delivered mon_*.wav files (ASSET_HANDOFF.md T1) sat unused.
- Files: brute_3d.gd, burner_3d.gd, rotter_3d.gd, hound_3d.gd, tvar_3d.gd,
  sharpshooter_3d.gd — added _set_cues({attack/hit/death/step}) matching
  ASSET_HANDOFF.md's own snippet and existing db suggestions.
- DEFAULT_CHOICE: sharpshooter_3d.gd's monster_id is "sharpshooter" but
  the delivered files are named mon_sniper_*.wav (GDD calls this enemy
  "Sniper") — wired to the files that exist rather than renaming
  anything (edits-only scope, no renames).
- Note for the report, not a fix: grepped base_monster.gd — only
  "attack"/"chase"/"investigate" cues are ever centrally triggered
  (base_monster.gd:643-647); "hit"/"death"/"step" are never called for
  ANY enemy, old or new roster alike. This isn't a regression I'm
  introducing — it's the pre-existing behavior for every other enemy
  type too (crawler/destroyer/hunter/shadow/watcher). Wiring real
  hit/death/step trigger call sites site-wide would be a much larger
  change than "wire the missing _set_cues() call" and is out of this
  session's edits-only scope — left as dict entries for forward
  compatibility, not claiming they're audible yet.
- Verification: compile gate bad=0, asset-check fails=0.

## MAX-THROUGHPUT BURST — fix 2: monster_spotted dead signal (5 subscribers)
- What: arch-audit subagent found EventBus.monster_spotted (5 live
  subscribers: audio_atmosphere.gd, encyclopedia_manager.gd,
  audio_manager.gd, onboarding.gd, hud_3d.gd) is never emitted anywhere
  - codebase migrated to EventBus.player_detected (same signature:
  monster_id: StringName) but 5 subscriber files were never repointed.
  Concrete effect: encyclopedia never auto-unlocks on sighting, HUD
  spotted-indicator never fires, shadow tutorial hint never triggers,
  spotted-growl SFX never plays.
- Fix: repointed all 5 .connect() calls from monster_spotted to
  player_detected (the live, actually-emitted signal with an identical
  signature) - a rename-fix, not a new emit site.
- Also investigated A5's [INIT_ORDER] claim (GameManager._ready()
  connecting to AdService.reward_granted, AdService being autoload #52
  vs GameManager #19) — did NOT reproduce: grepped every runtime log
  captured this session (multiple full real-window boots) for
  AdService/connect-on-null errors, zero hits; a fresh direct headless
  boot also produced zero related errors. GDScript raises hard on
  null.method() calls, so a silent no-op isn't possible here - the
  connection must be succeeding. Not fixing a bug that doesn't
  reproduce; noting as investigated-and-dismissed in the final report.
- Verification: compile bad=0, signal-arity fails=0.

## MAX-THROUGHPUT BURST — fix 3: achievement threshold bug + quest bugs + economy
- What: A1 code-audit subagent found: (a) achievements_manager.gd's
  _check_unlock() had a dead "Simplified check / pass" branch - any int
  condition >=1 unlocked immediately, so "kill 50 shadows"/"10 photos"/
  "10 secrets" all unlocked on the FIRST occurrence instead of at the
  real threshold; ach_01 "first_light" was passed a StringName that
  matched neither branch, so it could never unlock at all. (b) 4 of 5
  KILL quests targeted flavor/roster names ("runner"/"tank"/"sniper"/
  "squad") that don't exist as real monster_id substrings - permanently
  stuck at 0/N. (c) Both district REPAIR quests fired on ANY district
  reaching FULL (dead `or stage >= 2` bypass, plus fictional "district_1"/
  "district_2" targets that never matched real ids either way) -
  completed simultaneously on the first district restored. (d)
  q_craft_items only advanced via crafting_manager.gd, which is never
  autoloaded/instantiated - the live crafting path (workbench.gd) never
  called QuestManager at all. (e) flashlight stability/battery upgrade
  branches used a different cost table than GDD §3.3 documents (20650
  total to max vs GDD's 19250, a 1400-coin/7% deviation).
- Files: achievements_manager.gd (_check_unlock fixed to compare real
  progress against threshold for int conditions; ach_01 -> true, same
  trigger as ach_02 since both fire from the same stage>=3 handler with
  nothing else differentiating them), quest_manager.gd (KILL targets
  fixed via AI_TO_ROSTER's naming: runner->hunter, tank->destroyer
  (no roster "tank" exists, "armored"/destroyer is the closest heavy
  unit), sniper->sharpshooter (the real GDD "Sniper" character),
  squad->hound (DEFAULT_CHOICE - swarm/pack flavor, no "squad" roster
  entry exists); REPAIR targets suburbs/residential (real 1st/2nd
  district ids per power_grid.gd's _DISTRICTS order); dropped the
  `or stage >= 2` bypass), workbench.gd (_do_craft() now calls
  QuestManager.complete_objective(&"q_craft_items", &"", _craft_qty)),
  flashlight_upgrade_manager.gd (stability/battery cost tables matched
  to the GDD-documented shared table).
- DEFAULT_CHOICE (flagged for human review, these are content/design
  judgment calls, not pure code fixes): the runner/tank/sniper/squad ->
  hunter/destroyer/sharpshooter/hound mappings, and ach_01 unlocking on
  the same trigger as ach_02. Reasonably grounded in the existing
  AI_TO_ROSTER naming scheme, not arbitrary, but a human should sanity-
  check quest flavor text still reads correctly against the enemy it
  now actually targets.
- NOT fixed (out of edits-only scope, noted for the report): q_find_
  engineers/q_explore_school (EXPLORE zone_id triggers that don't exist
  anywhere - would need new zone-detection code, a new system, not a
  wire-up), q_connect_cables (same, INTERACT trigger doesn't exist),
  workbench 7/8 recipes uncraftable (needs new item .tres resources -
  content creation, not wiring), enemy stat AI_TO_ROSTER mismatches
  (watcher/hunter/destroyer/crawler stats vs GDD - a real balance
  change affecting core combat difficulty across the whole game,
  deliberately deferred as too large/risky for this pass).
- Verification: compile bad=0, --static 10/10 (flow_check 53/53,
  includes the existing craft-flow self-check).
