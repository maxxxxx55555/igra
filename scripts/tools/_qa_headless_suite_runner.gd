extends Node
## GOLD MASTER headless verification driver (owner-approved headless-only
## policy, 2026-09-10). Runs under get_tree().root so it survives the
## Routes scene swaps it triggers. Phases:
##   P0  every autoload the game needs is actually loaded
##   P1  menu -> New Game -> player spawns
##   P1b every input action in project.godot exercised at least once
##       (order-pass R2 PLAY truth-gate spec: entrypoint coverage)
##   P2  all 11 district scenes instantiate AND DistrictLoot.populate()
##       returns >0 (the LOOT_SCRIPT.populate regression guard)
##   P2c BREAK_REPORT B1 regression: all districts restored while the player
##       is elsewhere, then Travel to power_station via the real
##       DistrictManager.transition_to() the player uses - the boss must
##       actually spawn and survive (was: spawned into the district about to
##       be freed, then silently deleted, win never fires)
##   P2d BREAK_REPORT B2 regression: a document pickup spawned the real way
##       (DistrictLoot._spawn_document) must have its id set before add_child
##       so _load_from_catalog() (which only ever runs once, from _ready())
##       actually loads its title/content (was: "Untitled"/empty forever,
##       even though unlock_doc itself still fires correctly on collect -
##       confirmed by A/B testing both claims, not assumed from the report)
##   P2e BREAK_REPORT B3 regression: buy one rank of move_speed, Restart
##       twice via the real Routes.restart_game() - walk_speed must settle
##       at exactly one rank's effect both times, not compound (was:
##       170->187->205.7->226.4..., shared un-scened player_stats.tres
##       resource replayed every unlocked skill from _ready() every restart)
##   P3  save/load round-trip with a language switch in the middle
##   P4  all 5 endings fire and resolve to localized (non-key) strings
##   P5  every one of the 13 locales resolves a curated key set at runtime
##   P6  soak: sustained gameplay, QA_SOAK_SEC seconds (default 120)
## Prints "[qa] DONE fails=N" and quits with N (capped 250). The shell
## wrapper additionally greps the log for engine-level SCRIPT/parse errors.

const DISTRICTS: Array[StringName] = [
	&"suburbs", &"residential", &"park", &"school", &"hospital",
	&"gas_station", &"police", &"warehouses", &"industrial",
	&"substation", &"power_station",
]
const ENDINGS: Array[StringName] = [&"light", &"hope", &"survivor", &"dark", &"truth"]
## One real key per user-facing surface (menu / HUD / journal / settings /
## endings / toast) — must resolve to a non-empty, non-key string in every
## locale. The bulk check below is full key-parity against en.
const I18N_SAMPLE: Array[String] = [
	"menu_play", "HUD_HP", "HUD_NOISE", "JOURNAL_TITLE", "JOURNAL_RELATED",
	"SETTINGS_ACCESSIBILITY", "PHOTO_MODE_ON", "DISTRICT_RESTORED_TOAST",
	"ENDING_LIGHT_TITLE", "ENDING_TRUTH_DESC",
]
const AUTOLOADS: Array[String] = [
	"Routes", "GameManager", "SaveSystem", "EventBus", "InputService",
	"AdService", "WowDirector", "EndingsManager", "DistrictManager",
	"LocalizationManager", "ProgressTracker", "SkillTreeManager",
]
## Toggle-type screens/modes: pressed twice (open, close) so the pair leaves
## GameManager back in PLAYING regardless of what opening them does.
const TOGGLE_ACTIONS: Array[String] = [
	"inventory_toggle", "inventory", "ui_pause", "city_map_toggle",
	"encyclopedia_toggle", "journal_toggle", "skill_tree_toggle", "toggle_map",
]
## Momentary/one-shot actions: a single press+release is the real usage.
const MOMENTARY_ACTIONS: Array[String] = [
	"move_left", "move_right", "move_up", "move_down", "run", "stealth",
	"interact", "flashlight_toggle", "jump", "quick_slot_1", "quick_slot_2",
	"quick_slot_3", "quick_slot_4", "quick_slot_5", "quick_slot_6", "melee",
	"attack", "strobe", "quick_wheel",
]

var _fails: PackedStringArray = []
var _t0: int = 0
var _done: bool = false
var _ending_seen: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_t0 = Time.get_ticks_msec()
	var hard: float = _soak_sec() + 240.0
	get_tree().create_timer(hard).timeout.connect(_on_hard_timeout)
	call_deferred("_run")

func _soak_sec() -> float:
	var e := OS.get_environment("QA_SOAK_SEC")
	return maxf(10.0, float(e.to_float())) if e != "" else 120.0

func _log(m: String) -> void:
	print("[qa] t=%.1fs %s" % [float(Time.get_ticks_msec() - _t0) / 1000.0, m])

func _fail(m: String) -> void:
	_fails.append(m)
	print("[qa] FAIL ", m)

func _wait_until(pred: Callable, timeout_sec: float) -> bool:
	var waited := 0.0
	while waited < timeout_sec:
		if pred.call():
			return true
		await get_tree().create_timer(0.2).timeout
		waited += 0.2
	return pred.call()

func _run() -> void:
	await _p0_autoloads()
	await _p1_new_game()
	await _p1b_input_coverage()
	await _p2_districts()
	await _p2b_combat()
	await _p3_save_load_lang()
	await _p4_endings()
	await _p5_i18n_locales()
	await _p2c_finale_boss_race()
	await _p2d_document_id_race()
	await _p2e_skill_stack_race()
	await _p2f_secret_full_backpack()
	await _p2g_quest_reward_full_backpack()
	await _p2h_kill_pays_wallet()
	await _p2i_district_save_position_race()
	await _p2j_locked_district_travel_blocked()
	await _p2k_streetlight_activated_fires_once()
	await _p2l_import_save_survives_next_autosave()
	await _p2m_autosave_writes_real_save()
	await _p2n_q1_park_heartbeat_probe()
	await _p2o_offline_player_not_net_active()
	await _p2p_fall_recovery_armed_on_spawn()
	_p2q_autoload_behaviour()
	await _p6_soak()
	_finish()

# ── P0 ────────────────────────────────────────────────────────────────
func _p0_autoloads() -> void:
	for n in AUTOLOADS:
		if get_node_or_null("/root/" + n) == null:
			_fail("P0 autoload missing: " + n)
	_log("P0 autoloads: %d checked, %d missing" % [AUTOLOADS.size(), _fails.size()])

# ── P1 ────────────────────────────────────────────────────────────────
func _p1_new_game() -> void:
	await get_tree().create_timer(1.0).timeout
	var cs := get_tree().current_scene
	if cs == null or cs.name != "MainMenu":
		Routes.goto(Routes.MENU)
	var menu_ok := await _wait_until(func() -> bool:
		var s := get_tree().current_scene
		return s != null and s.name == "MainMenu", 12.0)
	if not menu_ok:
		_fail("P1 menu not reachable in 12s")
		return
	Routes.start_game()
	var playing := await _wait_until(func() -> bool: return GameManager.is_playing(), 10.0)
	if not playing:
		_fail("P1 New Game did not reach PLAYING in 10s")
		return
	var player_ok := await _wait_until(func() -> bool:
		return get_tree().get_first_node_in_group("player") != null, 10.0)
	if not player_ok:
		_fail("P1 player did not spawn in 10s")
		return
	_log("P1 New Game OK, player spawned")

# ── P1b ───────────────────────────────────────────────────────────────
## Input.action_press()/action_release() only update polling state (Input.
## is_action_pressed) — they do NOT reach _input/_unhandled_input (Godot's
## own documented behavior). InputService's own stealth/interact/quick_slot
## handling is event-driven (_unhandled_input), so a real InputEventAction
## via parse_input_event is required to actually exercise those paths;
## action_press() would silently no-op them while still "passing" a
## no-crash check. Caught via the quick_slot_requested signal assertion.
func _synth_tap(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await get_tree().process_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame

func _p1b_input_coverage() -> void:
	if not GameManager.is_playing():
		_fail("P1b started outside PLAYING (state=%d)" % GameManager.current_state)
		return
	var qs_seen: Dictionary = {}
	var qs_conn := func(i: int) -> void: qs_seen[i] = true
	InputService.quick_slot_requested.connect(qs_conn)
	var checked := 0
	for a in MOMENTARY_ACTIONS:
		if not InputMap.has_action(a):
			_fail("P1b action '%s' missing from InputMap" % a)
			continue
		await _synth_tap(a)
		checked += 1
		if not GameManager.is_playing():
			_fail("P1b action '%s' left PLAYING (state=%d)" % [a, GameManager.current_state])
			InputService.quick_slot_requested.disconnect(qs_conn)
			return
		if not is_instance_valid(get_tree().get_first_node_in_group("player")):
			_fail("P1b action '%s' invalidated the player" % a)
			InputService.quick_slot_requested.disconnect(qs_conn)
			return
	InputService.quick_slot_requested.disconnect(qs_conn)
	for i in range(6):
		if not qs_seen.get(i, false):
			_fail("P1b quick_slot_%d did not emit quick_slot_requested(%d)" % [i + 1, i])
	# Toggle actions: open (press+release), close (press+release again).
	for a in TOGGLE_ACTIONS:
		if not InputMap.has_action(a):
			_fail("P1b action '%s' missing from InputMap" % a)
			continue
		await _synth_tap(a)
		await _synth_tap(a)
		checked += 1
		if not GameManager.is_playing():
			_fail("P1b toggle '%s' did not return to PLAYING after open+close (state=%d)" % [a, GameManager.current_state])
			return
		if not is_instance_valid(get_tree().get_first_node_in_group("player")):
			_fail("P1b toggle '%s' invalidated the player" % a)
			return
	# photo_mode/photo_capture: on, capture, off — same open/close discipline.
	for a in ["photo_mode", "photo_capture", "photo_mode"]:
		await _synth_tap(a)
	checked += 2
	if not GameManager.is_playing():
		_fail("P1b photo_mode/photo_capture pair did not return to PLAYING (state=%d)" % GameManager.current_state)
		return
	_log("P1b input coverage: %d/%d actions exercised, 0 crash" % [
		checked, MOMENTARY_ACTIONS.size() + TOGGLE_ACTIONS.size() + 2])

# ── P2 ────────────────────────────────────────────────────────────────
func _p2_districts() -> void:
	var holder := Node3D.new()
	holder.name = "QADistrictHolder"
	add_child(holder)
	for id in DISTRICTS:
		var scene_path := "res://scenes/districts/%s.tscn" % String(id)
		if not ResourceLoader.exists(scene_path):
			_fail("P2 %s: scene missing %s" % [id, scene_path])
			continue
		var packed := load(scene_path) as PackedScene
		var inst := packed.instantiate() if packed != null else null
		if inst == null:
			_fail("P2 %s: instantiate() returned null" % id)
			continue
		holder.add_child(inst)
		await get_tree().process_frame
		await get_tree().process_frame
		if not is_instance_valid(inst):
			_fail("P2 %s: scene freed itself during _ready" % id)
			continue
		var placed: int = DistrictLoot.populate(inst, id)
		if placed <= 0:
			_fail("P2 %s: DistrictLoot.populate returned %d (loot regression)" % [id, placed])
		inst.queue_free()
		await get_tree().process_frame
	holder.queue_free()
	_log("P2 districts: %d checked" % DISTRICTS.size())

# ── P2b ───────────────────────────────────────────────────────────────
## Combat smoke in isolation (game_test_3d_scene's phase1 covers this too
## but stalls intermittently under --headless — see docs/KNOWN_ISSUES.md).
func _p2b_combat() -> void:
	var holder := Node3D.new()
	holder.name = "QACombatHolder"
	add_child(holder)
	var inst := (load("res://scenes/districts/suburbs.tscn") as PackedScene).instantiate()
	holder.add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	var monsters := get_tree().get_nodes_in_group("monsters")
	if monsters.is_empty():
		_fail("P2b no monsters in group after building suburbs")
		holder.queue_free()
		return
	var m: Node = monsters[0]
	var hp0: float = float(m.get("hp")) if m.get("hp") != null else -1.0
	if not m.has_method("take_damage"):
		_fail("P2b monster has no take_damage()")
		holder.queue_free()
		return
	m.take_damage(25.0)
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(m):
		_log("P2b combat: hp %.1f -> monster died (lethal damage) — OK" % hp0)
	else:
		var hp1: float = float(m.get("hp")) if m.get("hp") != null else hp0
		if hp1 >= hp0:
			_fail("P2b take_damage did not reduce hp: %.1f -> %.1f" % [hp0, hp1])
		else:
			_log("P2b combat: hp %.1f -> %.1f — OK" % [hp0, hp1])
	holder.queue_free()
	await get_tree().process_frame

## BREAK_REPORT B8 regression: a kill must pay the REAL wallet
## (CoinWallet), not just fire a display-only signal nothing else reads.
func _p2h_kill_pays_wallet() -> void:
	var holder := Node3D.new()
	holder.name = "QAKillHolder"
	add_child(holder)
	var inst := (load("res://scenes/districts/suburbs.tscn") as PackedScene).instantiate()
	holder.add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	var monsters := get_tree().get_nodes_in_group("monsters")
	if monsters.is_empty():
		_fail("P2h no monsters in group after building suburbs")
		holder.queue_free()
		return
	var m: Node = monsters[0]
	var before: int = CoinWallet.get_coins()
	m.take_damage(99999.0)
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(m):
		_fail("P2h monster survived 99999 damage - can't test the kill payout")
	elif CoinWallet.get_coins() <= before:
		_fail("P2h kill did not pay CoinWallet: %d -> %d" % [before, CoinWallet.get_coins()])
	else:
		_log("P2h kill pays wallet: %d -> %d - OK" % [before, CoinWallet.get_coins()])
	holder.queue_free()
	await get_tree().process_frame

## Reads player_pos out of the live save file (bypassing SaveSystem.load_all(),
## which would mutate live autoload state other phases still need). Returns
## Vector3.INF if the file/JSON/field isn't there.
func _p2i_read_saved_player_pos() -> Vector3:
	var f := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.READ)
	if f == null:
		return Vector3.INF
	var outer := JSON.new()
	if outer.parse(f.get_as_text()) != OK:
		return Vector3.INF
	var inner := JSON.new()
	if inner.parse(String((outer.data as Dictionary).get("data_json", ""))) != OK:
		return Vector3.INF
	var saved_pos: Array = (inner.data as Dictionary).get("player_pos", [])
	if saved_pos.size() < 3:
		return Vector3.INF
	return Vector3(saved_pos[0], saved_pos[1], saved_pos[2])

## BREAK_REPORT B10 regression: the district-enter autosave used to be a
## listener connected directly to EventBus.district_entered, the same signal
## DistrictManager.transition_to() emits SYNCHRONOUSLY before it even
## returns - so that listener wrote the PRE-teleport position to disk before
## load_district() had a chance to run at all. A later, physics-driven
## re-fire of the same signal (once the placed player overlaps the new
## district's own trigger volume) then silently re-saves the correct
## position within the same headless frame this test's earlier
## frame-count/position-poll versions used, self-healing the bug before any
## practical wait could observe it - so this checks the file the instant
## transition_to() returns, with no await at all, which is also the
## faithful repro of the report's own "quit right after crossing" scenario.
func _p2i_district_save_position_race() -> void:
	if not GameManager.is_playing():
		_fail("P2i started outside PLAYING (state=%d)" % GameManager.current_state)
		return
	var player := get_tree().get_first_node_in_group("player")
	var dm := get_node_or_null("/root/DistrictManager")
	if player == null or dm == null:
		_fail("P2i no player/DistrictManager to test against")
		return
	var target: StringName = &"park" if String(dm.current_district) != "park" else &"suburbs"
	var marker := Vector3(500.0, 1.0, 500.0)
	player.global_position = marker
	dm.transition_to(String(target))
	var immediate_saved := _p2i_read_saved_player_pos()
	if immediate_saved != Vector3.INF and immediate_saved.distance_to(marker) < 1.0:
		_fail("P2i district-enter autosave wrote the pre-teleport marker position %s to disk (stale save)" % immediate_saved)
		return
	# Let the transition fully settle, then also confirm the save eventually
	# reflects where the player actually ended up.
	var frames_waited := 0
	const MAX_FRAMES := 120
	while player.global_position.distance_to(marker) < 1.0 and frames_waited < MAX_FRAMES:
		await get_tree().process_frame
		frames_waited += 1
	if player.global_position.distance_to(marker) < 1.0:
		_fail("P2i player never actually moved off the test marker position within %d frames" % MAX_FRAMES)
		return
	if String(dm.current_district) != String(target):
		_fail("P2i district did not reach '%s'" % target)
		return
	var final_pos: Vector3 = player.global_position
	var saved := _p2i_read_saved_player_pos()
	if saved == Vector3.INF:
		_fail("P2i save file missing/invalid after a district-entered autosave")
		return
	if saved.distance_to(final_pos) > 1.0:
		_fail("P2i saved position %s does not match actual post-transition position %s (stale save)" % [saved, final_pos])
		return
	_log("P2i district save position race: no stale marker write, saved position matches post-transition spawn - OK")

## BREAK_REPORT B11 regression: DistrictManager.transition_to() used to
## enforce the district-lock rule nowhere - only the city map's Travel
## button checked PowerGrid.is_unlocked() before calling transition_to(),
## so any other caller (the QA bot's own fallback path, this test) could
## walk straight into a district whose prerequisite district was never
## repaired. De-levels a district's real prerequisite back to DARK
## (runs after P2c has already advanced everything to FULL, so this is
## the only way left to get a genuinely locked target), confirms
## is_unlocked() agrees, then calls the real transition_to() and checks
## current_district did not move.
func _p2j_locked_district_travel_blocked() -> void:
	var pg := get_node_or_null("/root/PowerGrid")
	var dm := get_node_or_null("/root/DistrictManager")
	if pg == null or dm == null:
		_fail("P2j PowerGrid/DistrictManager autoload missing")
		return
	var target: StringName = &"school" if String(dm.current_district) != "school" else &"hospital"
	var parent_id: StringName = pg.get_district(target).powered_by[0]
	var parent_stage_before: int = pg.get_stage(parent_id)
	pg.get_district(parent_id).stage = DistrictData.Stage.DARK
	if pg.is_unlocked(target):
		_fail("P2j test setup failed: '%s' still unlocked after de-leveling its prerequisite '%s'" % [target, parent_id])
		pg.get_district(parent_id).stage = parent_stage_before as DistrictData.Stage
		return
	var before: String = String(dm.current_district)
	dm.transition_to(String(target))
	var after: String = String(dm.current_district)
	pg.get_district(parent_id).stage = parent_stage_before as DistrictData.Stage
	if after != before:
		_fail("P2j transition_to() entered locked district '%s' (prerequisite '%s' was DARK)" % [target, parent_id])
		return
	_log("P2j locked district travel blocked: transition_to() correctly refused - OK")

## BREAK_REPORT B12 regression: PowerGrid.advance_district() used to fire
## streetlight_activated whenever new_stage >= STREETS, not just when the
## district actually CROSSED into STREETS - so repairing STREETS -> FULL
## fired it a second time. AchievementManager's own unlock is idempotent so
## it hid the bug there, but DailyChallengeManager's light_streets counter
## just increments per event and double-counted. Runs after P2c/P2j have
## already pushed every district to FULL, so this de-levels one district to
## PARTIAL, replays the report's exact repro (advance to STREETS, then to
## FULL) while counting real signal emissions, then restores the district's
## stage.
func _p2k_streetlight_activated_fires_once() -> void:
	var pg := get_node_or_null("/root/PowerGrid")
	if pg == null:
		_fail("P2k PowerGrid autoload missing")
		return
	var target: StringName = &"school"
	var d = pg.get_district(target)
	if d == null:
		_fail("P2k district '%s' not found" % target)
		return
	var stage_before: int = d.stage
	d.stage = DistrictData.Stage.PARTIAL
	# Boxed in an Array: GDScript lambdas capture plain locals by value, so a
	# bare int would never see the mutation happen inside the closure.
	var fire_count := [0]
	var counter := func(_id) -> void: fire_count[0] += 1
	EventBus.streetlight_activated.connect(counter)
	pg.advance_district(target, DistrictData.Stage.STREETS)
	pg.advance_district(target, DistrictData.Stage.FULL)
	EventBus.streetlight_activated.disconnect(counter)
	d.stage = stage_before as DistrictData.Stage
	if fire_count[0] != 1:
		_fail("P2k streetlight_activated fired %d times for one district's PARTIAL->STREETS->FULL repair (expected exactly 1, at the STREETS crossing)" % fire_count[0])
		return
	_log("P2k streetlight_activated fires exactly once per district - OK")

## BREAK_REPORT B13a regression: import_save_from_file() used to only
## overwrite the file on disk - the live session's in-memory state never
## refreshed, so the very next event-driven _save() (district-enter,
## secret, puzzle, purchase) immediately clobbered the import with the
## stale pre-import state. Exports the current state, mutates the live
## wallet, saves (simulating ongoing play with that mutation already on
## disk), imports (should restore the pre-mutation state on disk AND live),
## then replays the report's "Travel, or pick up a secret" step (another
## real _save()) and checks the file still holds the pre-mutation balance.
func _p2l_import_save_survives_next_autosave() -> void:
	var wallet := get_node_or_null("/root/CoinWallet")
	if wallet == null:
		_fail("P2l CoinWallet autoload missing")
		return
	var original: int = wallet.get_coins()
	# export_save_to_file() copies whatever is CURRENTLY on SAVE_PATH - an
	# earlier phase's save may be stale relative to the live wallet right
	# now, so force a fresh write first or the exported snapshot won't
	# actually match `original`.
	SaveSystem.save_all()
	if not SaveSystem.export_save_to_file():
		_fail("P2l export_save_to_file failed")
		return
	wallet.add(777)
	SaveSystem.save_all()
	if not SaveSystem.import_save_from_file():
		_fail("P2l import_save_from_file failed")
		wallet.from_dict({"coins": original})
		SaveSystem.save_all()
		return
	SaveSystem.save_all()
	var saved_coins := _p2l_read_saved_coins()
	# Restore live state to what the (correct) import should leave it at,
	# regardless of outcome, so later phases aren't affected by this test.
	wallet.from_dict({"coins": original})
	SaveSystem.save_all()
	if saved_coins != original:
		_fail("P2l import was clobbered by the next autosave: file has %d coins, expected the imported %d" % [saved_coins, original])
		return
	_log("P2l import survives the next event-driven autosave - OK")

func _p2l_read_saved_coins() -> int:
	var f := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.READ)
	if f == null:
		return -1
	var outer := JSON.new()
	if outer.parse(f.get_as_text()) != OK:
		return -1
	var inner := JSON.new()
	if inner.parse(String((outer.data as Dictionary).get("data_json", ""))) != OK:
		return -1
	var wallet_dict: Dictionary = (inner.data as Dictionary).get("wallet", {})
	return int(wallet_dict.get("coins", -1))

## BREAK_REPORT B13b regression: the periodic autosave used to write
## save_slot(4), a slot nothing reachable in the shipping game (the
## multi-slot picker UI was archived) ever reads - Continue only reads
## SAVE_PATH via load_all(). Forces one autosave tick and confirms
## SAVE_PATH's own mtime actually advances (the fix routes the timer
## through _save(), which writes SAVE_PATH; the bug wrote a different file
## entirely and never touched this one).
func _p2m_autosave_writes_real_save() -> void:
	if not FileAccess.file_exists(SaveSystem.SAVE_PATH):
		_fail("P2m no save file present to check")
		return
	var before := FileAccess.get_modified_time(SaveSystem.SAVE_PATH)
	# Real filesystem mtimes are 1-second granularity on some platforms;
	# without this the write can land in the same second and look like a
	# no-op even when it genuinely wrote.
	await get_tree().create_timer(1.1).timeout
	SaveSystem._process(999.0)
	var after := FileAccess.get_modified_time(SaveSystem.SAVE_PATH)
	if after <= before:
		_fail("P2m periodic autosave tick did not write SAVE_PATH (mtime unchanged: %d)" % before)
		return
	_log("P2m periodic autosave writes the real save Continue reads - OK")

## BREAK_REPORT Q1 probe: the autoplay bot's own heartbeat log used to
## collapse "player node invalid/freed", "player not in tree yet" and "the
## player's actual transform is broken" into one indistinguishable
## ppos=(inf,inf,inf) fallback. This travels to park (matching the report's
## own repro district) via the real DistrictManager.transition_to() and
## checks is_instance_valid/is_inside_tree/is_finite immediately on the
## first tick after the district id flips - the exact split the report
## asked for, run through the reliable GOLD MASTER path instead of the
## autoplay bot's spine AI (which can hit its own separate, already-known
## residential softlock long before ever reaching park).
func _p2n_q1_park_heartbeat_probe() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var dm := get_node_or_null("/root/DistrictManager")
	if player == null or dm == null:
		_fail("P2n no player/DistrictManager to probe with")
		return
	# Report names "park" specifically as the repro district - go via
	# suburbs first if already there, so this always actually crosses INTO
	# park rather than toggling away from it.
	if String(dm.current_district) == "park":
		dm.transition_to("suburbs")
		var away_frames := 0
		while String(dm.current_district) != "suburbs" and away_frames < 120:
			await get_tree().process_frame
			away_frames += 1
	var target: StringName = &"park"
	dm.transition_to(String(target))
	var frames_waited := 0
	const MAX_FRAMES := 120
	while String(dm.current_district) != String(target) and frames_waited < MAX_FRAMES:
		await get_tree().process_frame
		frames_waited += 1
	var p_valid := is_instance_valid(player)
	var p_in_tree := p_valid and player.is_inside_tree()
	var pos: Vector3 = (player as Node3D).global_position if p_in_tree else Vector3.INF
	var p_finite := p_in_tree and is_finite(pos.x) and is_finite(pos.y) and is_finite(pos.z)
	_log("P2n Q1 answer: after travel to '%s', first-tick player state: valid=%s in_tree=%s finite=%s pos=%s" % [target, p_valid, p_in_tree, p_finite, pos])
	if not p_valid or not p_in_tree:
		_fail("P2n Q1: player node invalid/detached right after travel to '%s' (valid=%s in_tree=%s) - this is 'who freed the player', not a transform bug" % [target, p_valid, p_in_tree])
		return
	if not p_finite:
		_fail("P2n Q1: player transform is genuinely non-finite after travel to '%s': %s - a REAL NaN/INF bug, distinct from B15's floor race" % [target, pos])
		return
	_log("P2n Q1 answered: player is valid, in-tree and finite after travel to park - the report's ppos=(inf,inf,inf) heartbeat entries are the _player_ok()==false fallback sentinel, not evidence of a broken transform")

## BREAK_REPORT B16 regression: player_3d.gd's _net_active used to be
## `multiplayer.multiplayer_peer != null`, true even in single-player
## because Godot's default OfflineMultiplayerPeer is never actually null -
## inventory_manager.gd and base_monster.gd already exclude it
## specifically, this copied the check before those were fixed. Confirms
## the real player node in this single-player headless session doesn't
## consider itself networked.
func _p2o_offline_player_not_net_active() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		_fail("P2o no player to check")
		return
	if multiplayer.multiplayer_peer == null:
		_fail("P2o test invalid: multiplayer_peer is actually null here, can't tell OfflineMultiplayerPeer exclusion apart from a plain null check")
		return
	if not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		_fail("P2o test invalid: multiplayer_peer is not OfflineMultiplayerPeer in this headless session (got %s) - assumption behind this test doesn't hold" % multiplayer.multiplayer_peer.get_class())
		return
	if bool(player.get("_net_active")):
		_fail("P2o single-player session with only the default OfflineMultiplayerPeer set _net_active=true - RPCs would fire on yourself every physics frame")
		return
	_log("P2o offline player correctly does not treat OfflineMultiplayerPeer as a live network - OK")

## BREAK_REPORT B15 regression: fall recovery in player_3d.gd used to only
## arm _last_grounded_pos once is_on_floor() had actually been true at
## least once this run - zero safety net for the very first frame(s) after
## any teleport, including a district transition landing before
## street_builder.gd's deferred road-collision build has run, if a hitch
## dropped the player through the not-yet-solid floor. WorldRuntime now
## calls player.mark_spawn_as_grounded() right after positioning the
## player, arming the net with the intended spawn immediately.
##
## Two checks: (1) a direct unit check that mark_spawn_as_grounded()
## actually sets state, isolated from real physics/transition timing;
## (2) resets to the exact "never grounded" sentinel the bug depends on,
## then confirms a real district transition arms it via the earliest
## observable check (same technique as B10/P2i - no extra frames of
## margin, since natural is_on_floor() grounding could otherwise mask the
## same gap this exists to catch).
func _p2p_fall_recovery_armed_on_spawn() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var dm := get_node_or_null("/root/DistrictManager")
	if player == null or dm == null:
		_fail("P2p no player/DistrictManager to test against")
		return
	if not player.has_method("mark_spawn_as_grounded"):
		_fail("P2p player_3d.gd has no mark_spawn_as_grounded() method")
		return
	# (1) direct unit check
	player.set("_last_grounded_pos", Vector3.ZERO)
	player.mark_spawn_as_grounded(Vector3(11.0, 22.0, 33.0))
	if Vector3(player.get("_last_grounded_pos")) != Vector3(11.0, 22.0, 33.0):
		_fail("P2p mark_spawn_as_grounded() did not set _last_grounded_pos")
		return
	# (2) real transition, earliest-frame check
	player.set("_last_grounded_pos", Vector3.ZERO)
	player.set("_airborne_sec", 0.0)
	var target: StringName = &"park" if String(dm.current_district) != "park" else &"suburbs"
	dm.transition_to(String(target))
	var frames_waited := 0
	const MAX_FRAMES := 120
	while String(dm.current_district) != String(target) and frames_waited < MAX_FRAMES:
		await get_tree().process_frame
		frames_waited += 1
	if Vector3(player.get("_last_grounded_pos")) == Vector3.ZERO:
		_fail("P2p _last_grounded_pos still ZERO immediately after a district transition - the spawn had no fall-recovery net armed")
		return
	_log("P2p fall recovery armed on spawn (mark_spawn_as_grounded wired into WorldRuntime._place_player) - OK")

# ── P2q ───────────────────────────────────────────────────────────────
## FUNCTION_MATRIX C5: one real behavioural assertion per state-bearing
## autoload that had none (pool lifecycle, serialisation round-trips,
## API contract values). State touched here is snapshotted and restored.
func _p2q_autoload_behaviour() -> void:
	var ps := PackedScene.new()
	ps.pack(Node3D.new())
	ObjectPool.register(&"qa_pool", ps, 2)
	var inst = ObjectPool.get_instance(&"qa_pool")
	if inst == null or ObjectPool.active_count(&"qa_pool") != 1:
		_fail("P2q ObjectPool.get_instance did not hand out exactly one active instance")
	else:
		ObjectPool.return_instance(&"qa_pool", inst)
		if ObjectPool.active_count(&"qa_pool") != 0 or ObjectPool.free_count(&"qa_pool") < 1:
			_fail("P2q ObjectPool.return_instance did not release the instance")
	var enc_before: Dictionary = Encyclopedia.to_dict()
	var ids: Array = Encyclopedia.all_ids()
	if ids.is_empty():
		_fail("P2q Encyclopedia.all_ids() is empty")
	else:
		Encyclopedia.unlock(ids[0])
		if not Encyclopedia.is_unlocked(ids[0]):
			_fail("P2q Encyclopedia.unlock() did not stick")
		var snap: Dictionary = Encyclopedia.to_dict()
		Encyclopedia.from_dict({})
		Encyclopedia.from_dict(snap)
		if Encyclopedia.to_dict() != snap:
			_fail("P2q Encyclopedia to_dict/from_dict round-trip changed the data")
	Encyclopedia.from_dict(enc_before)
	var q_before: Dictionary = QuestManager.serialize()
	QuestManager.from_dict(q_before)
	if QuestManager.serialize() != q_before:
		_fail("P2q QuestManager serialize/from_dict round-trip changed the data")
	var sp: int = SkillTreeManager.get_skill_points()
	SkillTreeManager.add_skill_points(1)
	if SkillTreeManager.get_skill_points() != sp + 1:
		_fail("P2q SkillTreeManager.add_skill_points(1) did not add exactly 1")
	SkillTreeManager.add_skill_points(-1)
	var xp_snap = XpManager.save_data()
	XpManager.reset()
	if XpManager.get_level() != 1:
		_fail("P2q XpManager.reset() did not return to level 1")
	XpManager.add_xp(1000000)
	if XpManager.get_level() <= 1:
		_fail("P2q XpManager.add_xp(1000000) did not level up")
	XpManager.load_data(xp_snap)
	if FlashlightUpgradeManager.get_max_level() != 5 or FlashlightUpgradeManager.get_cost("brightness", 1) != 100:
		_fail("P2q FlashlightUpgradeManager max level / L1 cost differ from GDD.md:90-95 (5 / 100)")
	if DistrictManager.get_district_count() != 11 or String(DistrictManager.get_district_id(0)) != "suburbs":
		_fail("P2q DistrictManager district list is not the 11-district GDD order")
	var prog_before: Dictionary = ProgressTracker.to_dict()
	var docs_before: int = ProgressTracker.count_docs()
	ProgressTracker.unlock_doc("qa_probe_doc")
	if not ProgressTracker.is_doc_unlocked("qa_probe_doc") or ProgressTracker.count_docs() != docs_before + 1:
		_fail("P2q ProgressTracker.unlock_doc did not register exactly one new doc")
	ProgressTracker.from_dict(prog_before)
	if AchievementManager.get_all().is_empty():
		_fail("P2q AchievementManager.get_all() is empty")
	if NewGamePlus.get_current_ng_plus() < 0 or NewGamePlus.get_modifiers().is_empty():
		_fail("P2q NewGamePlus current level / modifier list invalid")
	for w in [WeatherSystem.fog_strength(), WeatherSystem.rain_strength()]:
		if float(w) < 0.0 or float(w) > 1.0:
			_fail("P2q WeatherSystem strength outside 0..1")
	if not (DailyChallengeManager.get_today() is Dictionary) or DailyChallengeManager.get_today().is_empty():
		_fail("P2q DailyChallengeManager.get_today() is empty")
	if PlayIntegrityService.is_available():
		_fail("P2q PlayIntegrityService reports available under headless desktop")
	if float(NoisePropagation.get_noise_at(Vector2(1e6, 1e6))) != 0.0:
		_fail("P2q NoisePropagation.get_noise_at() far from every source is not 0")
	_log("P2q autoload behavioural asserts run - OK")

# ── P3 ────────────────────────────────────────────────────────────────
func _p3_save_load_lang() -> void:
	SaveSystem.save_all()
	if not SaveSystem.has_save():
		_fail("P3 save_all() produced no save")
		return
	LocalizationManager.set_language("ja")
	var l1 := SaveSystem.load_all()
	LocalizationManager.set_language("ar")
	var l2 := SaveSystem.load_all()
	LocalizationManager.set_language("en")
	if not l1 or not l2:
		_fail("P3 load_all() failed after save (mid-load lang switch): ja=%s ar=%s" % [l1, l2])
	_log("P3 save/load round-trip with language switch OK")

# ── P4 ────────────────────────────────────────────────────────────────
func _p4_endings() -> void:
	EndingsManager.ending_reached.connect(func(id: StringName) -> void:
		_ending_seen[id] = true)
	for e in ENDINGS:
		_ending_seen.erase(e)
		EndingsManager.force_ending(e)
		await get_tree().process_frame
		if not _ending_seen.get(e, false):
			_fail("P4 ending '%s' did not emit ending_reached" % e)
		var data: Dictionary = EndingsManager.get_ending_data(e)
		var title := String(data.get("title", ""))
		var desc := String(data.get("description", ""))
		if title == "" or title == "ENDING_%s_TITLE" % String(e).to_upper():
			_fail("P4 ending '%s' title unresolved: '%s'" % [e, title])
		if desc == "" or desc == "ENDING_%s_DESC" % String(e).to_upper():
			_fail("P4 ending '%s' desc unresolved: '%s'" % [e, desc])
	_log("P4 endings: %d checked" % ENDINGS.size())

# ── P5 ────────────────────────────────────────────────────────────────
func _p5_i18n_locales() -> void:
	var missing := 0
	# Baseline: every key en actually ships.
	LocalizationManager.set_language("en")
	var en_keys: Array = LocalizationManager._strings.keys()
	for loc in LocalizationManager.SUPPORTED:
		LocalizationManager.set_language(loc)
		# 5a: full key parity against en — no locale file may be short.
		var loc_strings: Dictionary = LocalizationManager._strings
		var gaps := 0
		for k in en_keys:
			if not loc_strings.has(k) or String(loc_strings[k]) == "":
				gaps += 1
		if gaps > 0:
			_fail("P5 %s: %d/%d keys MISSING or empty vs en" % [loc, gaps, en_keys.size()])
			missing += gaps
		# 5b: the curated per-surface sample must resolve to real text.
		for k in I18N_SAMPLE:
			if LocalizationManager.t(k) in ["", k]:
				_fail("P5 %s: surface key '%s' unresolved at runtime" % [loc, k])
				missing += 1
	LocalizationManager.set_language("en")
	_log("P5 i18n: %d locales x (%d en keys + %d surface keys), %d MISSING" % [
		LocalizationManager.SUPPORTED.size(), en_keys.size(), I18N_SAMPLE.size(), missing])

# ── P2c ───────────────────────────────────────────────────────────────
## BREAK_REPORT B1 regression. Order respects the real powered_by DAG
## (data/districts/*.tres): suburbs has no prereq; residential/park need
## suburbs; hospital/school need residential; police/gas_station need park;
## warehouses needs hospital; industrial needs warehouses AND police;
## substation needs industrial; power_station needs substation.
const FULL_RESTORE_ORDER: Array[StringName] = [
	&"suburbs", &"residential", &"park", &"hospital", &"school",
	&"police", &"gas_station", &"warehouses", &"industrial",
	&"substation", &"power_station",
]
func _p2c_finale_boss_race() -> void:
	if not GameManager.is_playing():
		_fail("P2c started outside PLAYING (state=%d)" % GameManager.current_state)
		return
	var pg := get_node_or_null("/root/PowerGrid")
	var dm := get_node_or_null("/root/DistrictManager")
	if pg == null or dm == null:
		_fail("P2c PowerGrid/DistrictManager autoload missing")
		return
	if String(dm.current_district) == "power_station":
		_fail("P2c player already in power_station - can't test the Travel race")
		return
	for id in FULL_RESTORE_ORDER:
		pg.advance_district(id, 3)
	if not pg.all_restored():
		_fail("P2c all_restored() false after advancing every district to 3")
		return
	# The real Travel entry point (city_map.gd's button calls the same API).
	dm.transition_to("power_station")
	var boss_ok := await _wait_until(func() -> bool:
		var b := get_tree().get_first_node_in_group("boss")
		return b != null and is_instance_valid(b) and not b.is_queued_for_deletion(), 5.0)
	if not boss_ok:
		_fail("P2c boss did not spawn (or was freed) within 5s of Travel to power_station")
		return
	var boss := get_tree().get_first_node_in_group("boss")
	var boss_parent := boss.get_parent()
	if boss_parent == null or (boss_parent as Node).scene_file_path != "res://scenes/districts/power_station.tscn":
		_fail("P2c boss parent is not the power_station district root (path=%s)" % (
			String(boss_parent.scene_file_path) if boss_parent else "null"))
		return
	_log("P2c finale boss race: boss spawned and alive in power_station after Travel - OK")

# ── P2d ───────────────────────────────────────────────────────────────
## BREAK_REPORT B2 regression: spawn a document the real way (the static
## helper the district-populate flow actually calls, not ProgressTracker
## directly) and confirm the id survived _ready() and a real collect.
func _p2d_document_id_race() -> void:
	var holder := Node3D.new()
	holder.name = "QADocHolder"
	add_child(holder)
	const DOC_ID := "doc_blackout_news"
	if ProgressTracker.is_doc_unlocked(DOC_ID):
		_log("P2d skipped: '%s' already unlocked from an earlier phase" % DOC_ID)
		holder.queue_free()
		return
	var before := ProgressTracker.count_docs()
	var ok: bool = DistrictLoot._spawn_document(holder, DOC_ID, Vector3.ZERO)
	if not ok:
		_fail("P2d _spawn_document returned false")
		holder.queue_free()
		return
	await get_tree().process_frame
	var pickup := holder.get_child(0) if holder.get_child_count() > 0 else null
	if pickup == null or not is_instance_valid(pickup):
		_fail("P2d document pickup node missing after spawn")
		holder.queue_free()
		return
	# The property itself is correct regardless of ordering (set() always
	# updates it) - what actually distinguishes "ready saw it in time" is
	# _load_from_catalog(), which only ever runs once, from _ready(), and
	# bails immediately if document_id was still "" at that moment. If it
	# bailed, title/content stay at their empty defaults forever - no later
	# fix to the id property re-triggers it.
	var got_title: String = String(pickup.get("document_title"))
	var got_content: String = String(pickup.get("document_content"))
	if got_title == "Untitled" or got_content == "":
		_fail("P2d _ready() missed the id: title='%s' content='%s' (catalog never loaded)" % [got_title, got_content])
		holder.queue_free()
		return
	pickup.call("_collect")
	await get_tree().process_frame
	if not ProgressTracker.is_doc_unlocked(DOC_ID):
		_fail("P2d collecting the pickup did not unlock_doc('%s')" % DOC_ID)
	if ProgressTracker.count_docs() != before + 1:
		_fail("P2d count_docs() did not increment: %d -> %d" % [before, ProgressTracker.count_docs()])
	holder.queue_free()
	_log("P2d document id race: real _spawn_document -> _ready sees id -> collect unlocks it - OK")

# ── P2e ───────────────────────────────────────────────────────────────
## BREAK_REPORT B3 regression: real Restart, not a synthetic reset. Buys
## one rank of a real, no-prerequisite, cost-1 skill and reloads the game
## scene through Routes.restart_game() (the same path Pause -> Restart
## uses) twice, checking the actual player node each time.
func _p2e_skill_stack_race() -> void:
	if not GameManager.is_playing():
		_fail("P2e started outside PLAYING (state=%d)" % GameManager.current_state)
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or player.get("stats") == null:
		_fail("P2e no player/stats to test against")
		return
	var base_speed: float = float(player.stats.walk_speed)
	var expected: float = base_speed * 1.1
	SkillTreeManager.add_skill_points(1)
	if not SkillTreeManager.unlock_skill(&"move_speed"):
		_fail("P2e unlock_skill(move_speed) failed (unexpected prereq/cost gate)")
		return
	var after_buy: float = float(player.stats.walk_speed)
	if not is_equal_approx(after_buy, expected):
		_fail("P2e after buying rank 1: walk_speed=%.2f, expected %.2f" % [after_buy, expected])
		return
	for restart_n in range(1, 3):
		Routes.restart_game()
		var back := await _wait_until(func() -> bool:
			return GameManager.is_playing() and get_tree().get_first_node_in_group("player") != null, 10.0)
		if not back:
			_fail("P2e restart %d: game/player did not come back in 10s" % restart_n)
			return
		player = get_tree().get_first_node_in_group("player")
		var speed: float = float(player.stats.walk_speed)
		if not is_equal_approx(speed, expected):
			_fail("P2e after restart %d: walk_speed=%.2f, expected %.2f (stacking if higher)" % [
				restart_n, speed, expected])
			return
	_log("P2e skill stack race: one rank of move_speed survives 2 real restarts at %.1f, no compounding - OK" % expected)

## Fills every real inventory slot with a non-matching item so try_add()
## has zero capacity for anything else, regardless of the tested item's
## own stacking rules. Shared by P2f/P2g; restores empty slots after.
func _fill_backpack_full() -> void:
	for i in InventoryManager.slots.size():
		InventoryManager.slots[i] = {"item_id": &"scrap", "count": 999}
	InventoryManager.call("_recompute_weight")

func _empty_backpack() -> void:
	for i in InventoryManager.slots.size():
		InventoryManager.slots[i] = null
	InventoryManager.call("_recompute_weight")

# ── P2f ───────────────────────────────────────────────────────────────
## BREAK_REPORT B9 regression: a secret interacted with on a full backpack
## must stay in the world, not be silently consumed. Instantiates the real
## secret scene with properties set before add_child (also verifies the
## district_loot.gd spawn-order fix alongside it, real reuse not a stub).
func _p2f_secret_full_backpack() -> void:
	if not GameManager.is_playing():
		_fail("P2f started outside PLAYING (state=%d)" % GameManager.current_state)
		return
	_fill_backpack_full()
	var holder := Node3D.new()
	holder.name = "QASecretHolder"
	add_child(holder)
	var secret := (load("res://scenes/props/secret.tscn") as PackedScene).instantiate()
	const TEST_ID := "qa_test_secret"
	secret.set("secret_id", StringName(TEST_ID))
	secret.set("item_id", &"battery")
	secret.set("amount", 1)
	secret.set("home_district", &"")
	secret.set("min_stage", 0)
	holder.add_child(secret)
	secret.call("interact", null)
	if not (is_instance_valid(secret) and not secret.get("_taken")):
		_fail("P2f secret was consumed even though the backpack was full")
	if ProgressTracker.is_secret_found(TEST_ID):
		_fail("P2f ProgressTracker recorded a secret that couldn't be collected")
	_empty_backpack()
	if is_instance_valid(secret):
		secret.queue_free()
	holder.queue_free()
	_log("P2f secret full-backpack: secret preserved, not recorded as found - OK")

# ── P2g ───────────────────────────────────────────────────────────────
## BREAK_REPORT B14 regression: a quest whose item reward can't fit must
## stay open (done=false), not complete short with the item lost. Builds
## a minimal synthetic quest dict matching what _complete() actually reads
## (isolates the fixed logic from needing real quest content data).
func _p2g_quest_reward_full_backpack() -> void:
	if not GameManager.is_playing():
		_fail("P2g started outside PLAYING (state=%d)" % GameManager.current_state)
		return
	_fill_backpack_full()
	var before_coins: int = CoinWallet.get_coins()
	var q: Dictionary = {
		"id": "qa_test_quest", "done": false, "reward_coins": 50,
		"reward_items": [["battery", 1]],
	}
	QuestManager.call("_complete", q)
	if bool(q.get("done", false)):
		_fail("P2g quest completed even though its item reward couldn't fit")
	if CoinWallet.get_coins() != before_coins:
		_fail("P2g coin reward was paid even though the quest didn't complete (%d -> %d)" % [
			before_coins, CoinWallet.get_coins()])
	_empty_backpack()
	QuestManager.call("_complete", q)
	if not (bool(q.get("done", false)) and CoinWallet.get_coins() == before_coins + 50):
		_fail("P2g same quest failed to complete once there was room (done=%s coins=%d)" % [
			q.get("done", false), CoinWallet.get_coins()])
	CoinWallet.from_dict({"coins": before_coins})
	_log("P2g quest reward full-backpack: stays open when full, completes once there's room - OK")

# ── P6 ────────────────────────────────────────────────────────────────
func _p6_soak() -> void:
	var target := _soak_sec()
	if not GameManager.is_playing():
		Routes.start_game()
		await _wait_until(func() -> bool: return GameManager.is_playing(), 10.0)
	_log("P6 soak: %ds sustained gameplay target" % int(target))
	var elapsed := 0.0
	while elapsed < target:
		var step: float = minf(10.0, target - elapsed)
		await get_tree().create_timer(step).timeout
		elapsed += step
		if GameManager.is_dead():
			_log("P6 player died at t=%.0fs (legit outcome) — ending soak" % elapsed)
			break
		if GameManager.current_state == GameManager.GameState.MENU:
			# PLAYING->MENU without a death: the pre-existing test-runner
			# race (a gate scene boots past boot_loading.tscn, so the
			# splash/bootstrap fallback and natural load fight over the
			# first scene swap). Real players always boot via
			# boot_loading.tscn and never hit it. Same stance as the
			# PERMANENT gate _boot_check_runner.gd — log and stop the soak,
			# do NOT fail. Documented in docs/KNOWN_ISSUES.md.
			_log("P6 PLAYING->MENU at t=%.0fs — known test-runner artifact, not a game bug — ending soak" % elapsed)
			break
		if not GameManager.is_playing():
			_fail("P6 left PLAYING into state %d (not DEAD/MENU) at t=%.0fs" % [GameManager.current_state, elapsed])
			return
		if not is_instance_valid(get_tree().get_first_node_in_group("player")):
			_fail("P6 player vanished from tree at t=%.0fs" % elapsed)
			return
		_log("P6 heartbeat %.0f/%.0fs — playing, player alive, no freed-instance/state errors" % [elapsed, target])
	_log("P6 soak: %.0fs sustained, clean" % elapsed)

# ── done ──────────────────────────────────────────────────────────────
func _on_hard_timeout() -> void:
	if _done:
		return
	_fail("hard timeout — something hung")
	_finish()

func _finish() -> void:
	if _done:
		return
	_done = true
	for f in _fails:
		print("[qa] FAIL ", f)
	print("[qa] DONE fails=", _fails.size())
	get_tree().quit(mini(_fails.size(), 250))
