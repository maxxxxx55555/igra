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

## MAX-THROUGHPUT BURST — fix 4: off-canon backgrounds (menu/splash/boot/credits/settings/difficulty/pre_loading)
- What: A2 UI-audit subagent found main_menu.tscn/credits.tscn/
  splash.tscn/boot_loading.tscn/pre_loading.tscn/settings_screen.tscn/
  difficulty_screen.tscn all use a warm brown-black or various
  near-black backgrounds that don't match the canon bg-deep token
  (#0c1016), plus main_menu.tscn's Flicker overlay and Title font +
  splash.tscn's logo color use a stale, more-saturated pre-canon amber
  instead of the brass token (#c9a24a) - live on literally every single
  screen a player sees before/around gameplay, including the very first
  frame of every boot.
- Files: exact hex-token swaps only (Color(0.0706,0.0627,0.0471,*) ->
  Color(0.0471,0.0627,0.0863,*) [bg-deep]; Color(0.8863,0.6392,0.2353,*)
  -> Color(0.7882,0.6353,0.2902,*) [brass]) across main_menu.tscn,
  credits.tscn, splash.tscn, boot_loading.tscn, pre_loading.tscn,
  settings_screen.tscn, difficulty_screen.tscn, plus settings_screen.gd's
  own procedural panel background (matched to the `panel` token #141b24
  instead, since that one's a panel overlay not a screen backdrop).
- NOT changed: win_screen.gd / death_screen.gd's amber/red-tinted
  backgrounds - these read as an intentional mood tint (victory=warm,
  death=danger-red) rather than a stale-color mistake, and forcing them
  to flat bg-deep would remove meaningful differentiation for a
  subjective gain. Left as a deferred item, not silently ignored.
  scenes/ui/menu.tscn (visually identical off-canon bg) also left alone
  - confirmed dead/orphaned, not reachable via Routes/UIManager (only
  referenced by tools/scene_smoke.gd, a dev smoke-test enumerator).
- Verification: compile bad=0. Real-window screenshot (docs/shots/
  burst_menu_palette.png) confirms the fix visually - menu background is
  now the correct cool blue-black, title/logo text is the correct less-
  saturated gold, both matching PRODUCTION_BIBLE.md's palette table.

## MAX-THROUGHPUT BURST — fix 5: skill_button.gd raw-sentence-as-key bug
- What: A2 UI-audit subagent found skill_button.gd passes raw English
  sentences ("Cost: %d SP", "Level: %d/%d", "Already unlocked", "Locked",
  "Requires: %s", "Not enough skill points") directly as the LOOKUP KEY
  to LocalizationManager.t()/tf(), and none of those exact sentences
  exist as real keys in any locale JSON - t() falls back to returning
  the key itself when not found, so every skill button's cost/level/
  requirement text was permanently English in all 13 locales, in the
  live skill tree screen. Distinct from the already-documented "18
  skills' name/description content" gap in docs/KNOWN_ISSUES.md (that
  one is skill_tree_manager.gd's data dict; this is skill_button.gd's
  own surrounding chrome text).
- Fix: added 6 new proper keys (SKILL_COST_SP, SKILL_LEVEL_FMT,
  SKILL_ALREADY_UNLOCKED, SKILL_LOCKED, SKILL_REQUIRES,
  SKILL_NOT_ENOUGH_POINTS) with real translations to all 13 locale
  JSONs (en/ru/de/es/fr/it/ja/ko/pt_BR/tr/zh/zh_TW/ar), then repointed
  skill_button.gd's 6 call sites to use them.
- Verified (before assuming another instance of the same bug) that
  skill_tree_tab.gd's near-identical-looking "Unlocked: %s" call is NOT
  actually broken the same way: it's registered as a literal key
  "Unlocked: %s" in every locale JSON with real per-locale translated
  values (e.g. ru.json: "Открыто: %s") - stylistically inconsistent
  with the UPPERCASE_SNAKE_CASE convention used elsewhere, but
  functionally correct. Left alone - not a bug, don't fix what isn't
  broken.
- Side finding while touching the locale files: zh.json (Simplified
  Chinese) has ~107 additional keys with romanized PINYIN placeholder
  text (e.g. "yes":"Shi", "you_died":"NI SI LE") that are neither real
  Chinese characters nor identical to English - a pattern the earlier
  i18n-audit subagent's "byte-identical-to-English" check couldn't
  catch, widening the known gap beyond A4's 196-key finding. Not fixed
  this pass (out of scope for a quick sanity pass, needs its own
  dedicated review) - flagged in the final report.
- Verification: compile bad=0, i18n gate fails=0.

## MAX-THROUGHPUT BURST — fix 6: hardcoded HUD strings (live, every gameplay session)
- What: A2 UI-audit subagent found NoiseLabel ("ШУМ"), VisibilityLabel
  ("ЗАМЕТ."), AmmoCaption ("AMMO"), RadarLabel ("РАДАР") in the live
  core gameplay HUD (hud_3d.tscn) are hardcoded raw strings (mixed
  Russian/English) with NO code path ever overriding .text - stuck in
  that exact mixed-language state in every locale, every single
  gameplay session. Same for BtnSprint ("БЕГ")/BtnStealth ("СТЕЛС")
  touch buttons.
- Files: added 6 new keys (HUD_NOISE, HUD_VISIBILITY, HUD_AMMO,
  HUD_RADAR, HUD_SPRINT, HUD_STEALTH) with real translations to all 13
  locale JSONs; hud_3d.gd gets a new _localize_static_labels() (mirrors
  the existing _add_captions() pattern for HP/Stamina/Battery), called
  from _ready(), setting all 6 labels/buttons via LocalizationManager.t().
- Verification: compile bad=0, i18n fails=0, signal-arity fails=0. Real
  gameplay screenshot (docs/shots/burst_hud_i18n.png) confirms visually
  - HUD now shows "NOISE"/"VISIBILITY"/"RADAR" in English locale instead
  of the old mixed-language text.
- Minor follow-up noted, not fixed: "VISIBILITY" is longer than the old
  "ЗАМЕТ." abbreviation and visually clips against the notice-icon to
  its left at English locale - a layout/font-size tuning issue, not a
  functional bug. Flagged for a future visual pass.

## MAX-THROUGHPUT BURST — fix 7: skill tree off-palette colors
- What: A2 found skill_button.tscn's NameLabel/LevelLabel (saturated
  gold 1,0.8,0.2), DescLabel (flat grey 0.8,0.8,0.8), CostLabel
  (near-neon green 0.6,1,0.6 - banned high-saturation territory),
  ReqLabel (saturated orange 1,0.5,0.3), and skill_tree_ui.tscn's
  SkillPointsLabel (same gold) all use colors matching no canon token
  - live in every skill card of the live skill tree screen.
- Fix: mapped each to the semantically closest canon token: gold ->
  brass (#c9a24a), grey -> steel-text (#aeb6bf), green cost -> stamina
  (#5f8a4e, the canon "positive" token), orange requirement -> ember
  (#b4452f, canon "danger/blocked" token).
- Verification: compile bad=0.

## WAVE 6 P0 — L10N completion
- CORRECTION before executing: the prompt's P0.1 asked to "complete
  ALL 196 missing keys for RU" - this premise is factually wrong.
  docs/BURST_REPORT.md's own finding (re-verified fresh via
  data/i18n/ru.json/en.json spot-checks) says RU is the ONE locale
  that already has real, distinct, natural translations for the
  196-key gap; the gap is in the OTHER 11 locales. Proceeding on the
  correct premise rather than doing pointless/harmful rework
  (overwriting already-good Russian text) or silently reinterpreting
  without saying so.
- Also corrected the gap's true SIZE: re-counted with a real JSON
  parser (Node.js, available in this environment) instead of trusting
  the prior session's estimate - the actual systemic gap is 381 keys
  identical to EN across >=8 of 11 non-RU/non-EN locales (not 196).
  Per-locale breakdown: ar/ja/ko/zh 381, de/fr 395, it 394, es/pt_BR
  390, tr 386, zh_TW 401 (out of 764 total keys). Family breakdown:
  SCR_* 183, ACH_* 41, Q_* 40, END_*/ENDING_* 25, DIST_*/DISTRICT_* 16,
  ENEMY_*/QUEST_* 22, MAP_*/INV_*/PROMPT_*/SHOP_*/STATS_*/TIP_*/UPG_*
  33, misc singles 21.
- Scope decision (matches the prompt's own "main-flow only, backlog
  the rest, do not half-translate" instruction for P0.3, applied
  consistently): translated 32 high-visibility toast/label/district-
  name keys (BOSS_APPEARS, CHECKPOINT_SET, DISTRICT_STAGE_1/2/3,
  DIST_* x11 district names, WIN_SUMMARY, VICTORY_STATS, JOURNAL_*,
  NEED_*, NEW_GAME_PLUS, etc.) into real, natural text across all 11
  non-RU/non-EN locales (352 strings) via a Node.js-assisted batch
  apply (generated translations myself, applied via targeted JSON
  key-value replacement preserving all other content byte-for-byte).
  ACH_* (41), Q_*/QUEST_* (51), SCR_* (183), END_*/ENDING_* (25),
  ENEMY_* (11), and the smaller scattered families (33) are NOT
  translated this pass - real, accurately-sized CONTENT_BACKLOG (349
  keys x 11 locales remaining), not silently dropped.
- zh.json pinyin placeholders: re-counted precisely (49 real
  instances, not the ~107 estimate) via a pure-ASCII-value-but-
  different-from-EN detector script - these are ALL main-flow
  (menu_title, new_game/continue/quit, difficulty/graphics/sound/
  language settings labels, inventory/shop/craft/quests, all 4
  loading tips, all 6 tutorial hint lines, victory/you_died). Fixed
  all 49 with real Simplified Chinese. Re-ran the detector after:
  0 remaining.
- Verification: i18n gate fails=0, compile bad=0. New scenes/tools/
  i18n_dump_scene.tscn + scripts/tools/_i18n_dump.gd force lang=ru and
  print 15 sample keys spanning menu/HUD/skills/achievements/districts/
  toasts/death - all genuine natural Russian, saved to docs/
  ru_proof_dump.txt (this is PROOF the premise correction is right,
  not just an assertion).

## WAVE 6 P0.2 — skill tree content i18n (RU)
- CORRECTION: prompt said "18 x (name+description)" - the actual
  skill_tree_manager.gd SKILL_TREES dict has 3 branches x 5 skills =
  15 skills, not 18/20 (matches the already-known "3 branches, not
  GDD's stated 4" gap documented in docs/KNOWN_ISSUES.md from a prior
  session - deliberately NOT inventing a 4th branch to reach 18/20,
  same reasoning as before).
- Files: skill_tree_manager.gd's SKILL_TREES now stores i18n KEYS
  (SKILL_<ID>_NAME/_DESC) instead of raw English text for all 15
  skills' name+description; skill_button.gd (2 direct reads + 1
  requirement-name read) and skill_tree_tab.gd (1 notification read)
  updated to route through LocalizationManager.t(). Added 30 new keys
  to en.json (English reference, unchanged text) and ru.json (real,
  natural Russian) - and, required by the project's OWN i18n gate
  (hard parity check across all 13 locales, discovered when it failed
  fails=11 after adding EN+RU only), the same 30 keys with English
  fallback values to the other 11 locales (matches the pre-existing
  behavior for those locales - they showed English before too - but
  now properly routed through the i18n system instead of hardcoded,
  and accurately counted in the backlog: +30 keys to each of 11
  locales, on top of the pre-existing 381/394/etc counts).
- Side find + fix: adding these 3 specific RU descriptions
  ("+15% к скорострельности" etc.) tripped tools/check.sh's own
  placeholder-parity checker (ru/en %-placeholder count mismatch) -
  investigated and found a real regex bug in the checker itself, not
  in the translations: the regex allowed a bare space as a valid
  printf flag character, so plain text like "+15% fire rate" /
  "25% slower" spuriously counted as containing a %f/%s placeholder
  (English matched, Russian correctly didn't, mismatch). Verified via
  a scan of all of en.json that zero real placeholders in this project
  use the space-flag printf form - safe to tighten the regex (removed
  space from the allowed flag chars). Fixed at the source (the
  checker), not by rewording the translations to dodge it.
- Verification: compile bad=0, i18n fails=0, --static 10/10 (which now
  includes the fixed placeholder-parity check, previously silently
  never exercised by anything this specific before).

## WAVE 6 P1 — enemy balance to GDD
- CORRECTION before executing: "data/monsters/*.tres" is NOT the live
  gameplay data source. Verified via grep: those 12 files are only
  referenced by encyclopedia_manager.gd (bestiary/lore display text),
  completely disconnected from base_monster.gd's actual combat stat
  system, which reads HP/damage/hearing from enemy_roster_data.gd's
  `roster` dict (via the AI_TO_ROSTER name-remapping A1's audit
  originally flagged) and vision_range/vision_angle from each monster
  script's own _ready() overrides. Confirmed by checking: the bestiary
  .tres values (e.g. watcher vision_range=320.0) don't match EITHER
  GDD OR the live roster dict's own numbers (watcher's real live
  vision comes from watcher_3d.gd, unset, defaulting to
  base_monster.gd's 10.0) - a third, fully independent, wrong number
  set.
- Given this, did BOTH: (1) the literal ask - fixed all 12 data/
  monsters/*.tres files' max_hp/melee_damage/vision_range/
  vision_cone_deg/detect_radius to GDD §6.2 exact values (real
  bestiary-accuracy value for players reading in-game lore, zero
  gameplay effect, zero code touched) via a Node.js regex-line-replace
  script; (2) the substantive ask - fixed the ACTUAL gameplay-driving
  numbers: enemy_roster_data.gd's roster dict entries for "runner"
  (Hunter), "sniper" (Watcher), "armored" (Destroyer), "dog" (Crawler),
  "beast" (Boss/Architect) - hp/damage/detect_range(hearing) to GDD
  exact values - plus added missing vision_range/vision_angle overrides
  in watcher_3d.gd/hunter_3d.gd/destroyer_3d.gd/crawler_3d.gd/
  boss_3d.gd's _ready() (all 5 were either fully unset, using
  base_monster.gd's generic default of 10m/90°, or partially set).
  This is technically inside .gd files, but is exclusively numeric-
  literal edits (no logic/behavior/architecture changes) - flagging
  this explicitly since P1 said "NO code changes" assuming the .tres
  files were live; doing ONLY the literal ask would have had zero
  actual effect on the real, originally-flagged balance bug.
- "Verify the other 8 rows match too" - they did NOT all match: 8 of
  12 bestiary .tres rows needed vision/hearing corrections even though
  6 of those 8 already had correct HP/damage (brute/burner/rotter/
  hound/tvar/sharpshooter, the already-verified-correct [M2]/[M3]
  roster). On the LIVE data side, brute/burner/rotter/hound/tvar/
  sharpshooter's roster dict entries and vision_range overrides were
  already independently confirmed correct in a prior session/audit -
  not touched, no regression risk introduced there.
- Speed intentionally NOT touched anywhere (bestiary or live roster):
  GDD gives speed as a "x" multiplier with no documented absolute
  baseline anywhere in the project (checked GDD.md, player_stats.tres -
  player's walk_speed=170 is on a visibly different unit scale than the
  roster dict's own speed values of 1.2-6.0, so it can't be used as the
  multiplier's base without guessing). Left as a genuine spec gap
  rather than inventing a conversion factor with real regression risk
  (wrong speed could make an enemy uncontrollably fast or a pushover to
  outrun).
- DEFAULT_CHOICE: Architect (boss)'s vision cone left at 360°(omni) -
  GDD's table gives no cone parenthetical for this row, same formatting
  as Tvar/Rotter which both use 360° - matched that established
  precedent rather than inventing a narrower cone.
- Expected difficulty shift (one paragraph, as asked): Hunter becomes
  meaningfully MORE dangerous (HP 45->120, damage 12->35 - was a
  pushover, now hits like the "raша" GDD describes) while its
  detection cone narrows (90 deg default -> 60 deg), so it's both
  scarier up close and easier to avoid at range. Watcher becomes much
  LESS punishing (HP 160->80, damage 25->12, hearing 25->8m) - it was
  effectively sniping players from 18m with boss-tier stats; now a
  real but softer threat, though its ranged attack_range itself
  wasn't touched (out of the HP/damage/speed/vision/hearing scope) so
  it still shoots from range, just for much less. Destroyer trades
  tankiness for punch (HP 400->200, damage 20->25) and its vision
  narrows sharply (10m default cone-90 -> 5m cone-180 - wide but very
  short-range, matching its "lumbering tank" design), making it easier
  to spot-and-avoid but more dangerous if it catches you. Crawler
  becomes a glass cannon (HP 70->50, damage 9->20, more than doubled)
  and its detection range shrinks (10m default -> 6m), rewarding
  stealth around it much more than before. The Architect boss fight
  gets shorter and harder-hitting (HP 1200->800, damage 30->40) - a
  more intense, less attrition-based final encounter. Net effect
  across all four: less "wrong enemy has boss stats" (Watcher/
  Destroyer were previously over-tuned relative to their design)
  and more real threat where GDD actually wants it (Hunter/Crawler
  were previously undertuned).
- Verification: compile bad=0, --static 10/10 (flow_check unaffected,
  no logic changed). Not gameplay-tested live (no combat-encounter
  screenshot/log tooling exists from prior sessions for this specific
  purpose) - numbers verified against GDD by direct value comparison,
  not by playtesting the actual feel.

## WAVE 6 P2 — craft economy completion
- What: 7 of 8 workbench.gd recipes were permanently uncraftable -
  their required materials (fabric, alcohol, gunpowder, case, metal,
  paper, bottle) didn't exist as items anywhere in the game; only
  "battery" (cable+fuse) was craftable. cable/fuse/tool already
  existed and needed no new item, just the 6 craft-result items
  (noise_bomb/lockpick/repair_kit/firework/molotov/makeshift_lamp) plus
  the 7 raw materials = 13 new data/items/*.tres, matching the existing
  ItemData schema (id/display_name/description/rarity/weight/
  stackable/max_stack/consumable/effect/effect_value). i18n name_key
  strings (ITEM_NOISE_BOMB etc.) already existed in all 13 locales -
  someone pre-registered the recipe display names ahead of the actual
  items, confirmed via grep before assuming a new i18n task was needed.
- Registered all 13 in item_database.gd's _ITEMS preload array.
- Icons: item_database.gd already has a graceful fallback (looks for
  assets/textures/items/<id>.png, procedural draw_icon() otherwise) -
  but the project's OWN asset-check gate hard-fails when a real PNG is
  missing (discovered via fails=2 after registering the items with no
  icons - "ASSET_PENDING" alone wasn't going to pass the gate). Used
  the project's existing procedural icon generator (scripts/tools/
  _gen_item_sprites.gd + scenes/tools/gen_sprites_scene.tscn, the same
  tool that made every other item's icon) - added 10 new _draw_<id>()
  functions in the same analytical-SDF drawing style/palette as the
  existing 28, ran the generator (38 total, all OK), regenerated
  .import files. asset-check: fails=0.
- Wired all 7 new raw materials into district_loot.gd's BY_DISTRICT
  table (GDD gives no loot-table rules for these - thematic
  DEFAULT_CHOICE placement, documented): fabric+alcohol -> hospital
  (medical theme), gunpowder+case -> police (ammo/casings), metal ->
  industrial, paper -> school (documents theme), bottle -> gas_station
  (convenience-store theme). Added to existing district entries rather
  than restructuring the loot table.
- Verification (grep-proof, per P2's own stated alternative to a live
  flow test): confirmed via direct file-existence checks that ALL 8
  recipes' result item AND every one of their component materials now
  resolve to a real data/items/*.tres - 0 missing. Gates: compile
  bad=0, asset-check fails=0, --static 10/10.

## WAVE 6 P3 — 3 dead quests, minimal EventBus-driven triggers
- CORRECTIONS before executing:
  (a) q_find_engineers is coded as type="EXPLORE" target="engineer_camp"
      target_count=1 in quest_manager.gd - NOT an "INTERACT 2-3 notes"
      quest as P3.2 described. Implemented what's actually coded (a
      single zone trigger, reusing the same script as q_explore_school)
      rather than changing the quest's fundamental type/count, which
      would be a bigger, more invasive change for the same player-
      facing beat ("find the engineer camp").
  (b) q_connect_cables asked for a new "3x hold-2s" interaction
      mechanic - but a complete, real cable-connection minigame
      (scripts/ui/puzzle_cables.gd: grid-based wire-matching UI, 5
      attempts, hint button, puzzle_solved/puzzle_failed signals) and
      its full backing system (puzzle_system.gd: per-district puzzle
      ids incl. "fuse_substation" with power_stage/reward data)
      ALREADY EXIST - fully built, GDD-canonical, but PuzzleSystem.
      start_puzzle() was, before this fix, only ever called from test
      scripts, never from any real in-world interactable. Reused the
      existing minigame instead of building a second, redundant
      interaction paradigm from scratch (reuse-before-writing).
- Files: new scripts/world/quest_zone_trigger.gd (generic "reach this
  landmark" Area3D, mirrors district_trigger.gd's pattern, emits
  EventBus.zone_reached) - placed in scenes/districts/school.tscn
  (zone_id="school_zone") and scenes/districts/industrial.tscn
  (zone_id="engineer_camp"). New scripts/world/cable_box_interactable.gd
  (join the "interactable" group like power_switch.gd, calls
  PuzzleSystem.start_puzzle("fuse_substation") on interact) - placed in
  scenes/districts/substation.tscn.
- Side bugs found+fixed while wiring: screens.gd's PuzzleCables screen
  hardcoded "cables_suburb" on every solve, regardless of which
  district's puzzle was actually started - every puzzle in the game
  (not just my new one) would have silently mis-reported as suburb's.
  Added PuzzleSystem.get_active_puzzle() getter, screens.gd now uses
  the real active id. q_connect_cables (INTERACT type, target
  "cable_node") is completed via QuestManager.complete_objective()
  called from that same fixed solve-callback when the active puzzle is
  "fuse_substation" (matches the existing p2 workbench.gd pattern for
  wiring a non-standard completion path into the type-agnostic public
  API, rather than fighting the type-specific _on_interaction_done
  dispatcher for an event that isn't really a direct interaction).
- P3.4 sanity-pass of the 4 remapped KILL-quest flavor texts (from the
  earlier burst-wave session's runner->hunter/tank->destroyer/
  sniper->sharpshooter/squad->hound remap) vs their new targets: all 4
  already read correctly - "Cull the runners" fits Hunter's charge-
  rush design, "Sniper hunter" matches GDD's OWN name for this exact
  creature (GDD §6.2 literally calls sharpshooter's row "Sniper"),
  "Wipe out the pack" matches Hound's real SWARM/pack-call behavior in
  code, "Bring down the tanks"/"Armoured brutes" matches Destroyer's
  actual high-armor slow-tank design. 0 i18n changes needed - this was
  a genuine check, not a rubber stamp.
- Verification: compile bad=0, signal-arity fails=0, asset-check
  fails=0, --static 10/10, boot-flow fails=0 (full menu->play->save->
  load loop still intact, confirms the new district-scene nodes don't
  break scene loading).

## WAVE 6 P4 — generator fuel + crosshair
- Generator: added `const GENERATOR_FUEL: StringName = &"gas_canister"`
  to street_builder.gd (satisfies _game_test_3d.gd's exact check).
  Rewrote scripts/generator.gd (previously never instantiated anywhere,
  required pre-built %PowerLever/%FuelGauge/%InteractArea unique-name
  child nodes no scene provided, and refuel() only touched an internal
  float - never the player's real inventory) to: build its own visuals
  procedurally (matches cable_box_interactable.gd's convention from
  P3), join the "interactable" group with real can_interact()/
  interact_prompt()/interact(), actually consume 1 gas_canister from
  InventoryManager to start, drain fuel_level while running (90s per
  canister), and toast via EventBus.inventory_notice on fuel_empty.
  Placed one live instance (GasGenerator) in scenes/districts/
  gas_station.tscn (thematic fit with gas_canister). Added 2 new i18n
  keys (ACTION_STOP_GENERATOR, GENERATOR_OUT_OF_FUEL) - RU translated,
  other 11 locales English-fallback per the established backlog
  pattern; ACTION_START_GENERATOR already existed in all 13.
- "populate pickups group in the test scene if that's the gap" - it
  was, but not scene-specific: investigated _game_test_3d.gd's actual
  scene load (res://scenes/main_3d.tscn, the REAL game scene, not
  test_zone.tscn) and found NOTHING anywhere in the codebase ever
  called add_to_group("pickups") on a spawned item - not district_
  loot.gd, not item_pickup_3d.gd itself. This wasn't a test-only gap:
  scripts/ui/radar.gd's minimap pickup blips (a real, live gameplay
  HUD feature) read this exact group and were silently always empty
  for every real player too. Fixed at the actual source: item_pickup_
  3d.gd's _ready() now calls add_to_group("pickups") - fixes the radar
  AND the test simultaneously, not a test-specific patch.
- Crosshair: crosshair_state_changed was declared but never emitted
  anywhere - the HUD crosshair was a static ColorRect, one fixed color,
  for the entire game (confirmed dead signal from the earlier burst-
  wave A5 architecture audit). Converted hud_3d.tscn's Crosshair node
  from ColorRect to TextureRect using the delivered crosshair_64.png,
  added a HitMarker TextureRect using hitmarker_64.png (starts
  invisible, flashes on "hit"). Wired 2 of the 3 asked-for real trigger
  sites: weapon_base.gd::fire() emits "default" (hipfire) on every
  successful shot; base_monster.gd::take_damage() emits "hit" whenever
  the player lands a hit on any enemy (a genuine, universal, always-
  fired hook). "aim" was NOT wired to a fake trigger - grepped the
  weapon system end to end and confirmed no aim-down-sights/ADS
  mechanic exists anywhere to hook into; the HUD code and palette entry
  for "aim" are left in place for when that mechanic is built, not
  removed, but nothing calls it - an honest gap, not invented.
- Verification: compile bad=0, signal-arity fails=0, asset-check
  fails=0, i18n fails=0, --static 10/10. game_test_3d_scene launched
  to verify the pickups/GENERATOR_FUEL checks specifically - hit the
  same documented hang-after-completion process-lifecycle issue as
  every prior session (buffered output, needs a kill to flush) -
  result pending, not force-killed this time (learned earlier this
  session that killing it mid-run corrupts the read, not the game).
