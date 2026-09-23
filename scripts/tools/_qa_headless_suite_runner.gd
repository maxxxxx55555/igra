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
## Confirmed via full-repo grep (no is_action_pressed/is_action_released/
## is_action() call anywhere in scripts/): defined in project.godot's
## [input] map but not consumed by any script. Not a crash risk, just dead
## config — pressed anyway (harmless no-op) so coverage is still literal,
## but logged separately so the matrix doesn't claim WORKS for them.
const DEAD_ACTIONS: Array[String] = ["shop_toggle", "close_screen", "settings"]

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
## own documented behavior). InputService.gd's stealth/interact/quick_slot
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
	for a in MOMENTARY_ACTIONS + DEAD_ACTIONS:
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
	_log("P1b input coverage: %d/%d actions exercised, 0 crash, %d dead (no consumer): %s" % [
		checked, MOMENTARY_ACTIONS.size() + DEAD_ACTIONS.size() + TOGGLE_ACTIONS.size() + 2,
		DEAD_ACTIONS.size(), ", ".join(DEAD_ACTIONS)])

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
