extends "res://scripts/tools/_final_frames_runner.gd"
## rc16 probe (O1 streaming, O3 polish frames), one windowed run per code tree: tools/qa_sim/rc16_probe <label> <hash>.
##   [probe] stream  district transitions of the real WorldRuntime: load time, frame hitches, node / texture / video memory
##   [probe] perf    draw calls, primitives, objects and the frame p95 at D1 and D11
##   [probe] frame   eight staged states -> docs/stills/polish/<state>_<label>_<hash>_<UTC>.png (the AF3 name: the code tree and the capture time)
## The label and the hash come from the user args --tlabel= and --thash=. A saved PNG proves nothing until it is read.

const ORDER: Array[StringName] = [&"suburbs", &"residential", &"park", &"school", &"hospital", &"gas_station", &"police", &"warehouses", &"industrial", &"substation", &"power_station"]
const HITCH_MS: float = 50.0
const FRAME_BUDGET_MS: float = 33.3
const DWELL_SEC: float = 1.5
const PERF_FRAMES: int = 300
const SPRINT_SEC: float = 0.9
const MIB: float = 1048576.0

var _label: String = "after"
var _hash: String = "unknown"
var _recording: bool = false
var _frame_ms: Array[float] = []

func _process(delta: float) -> void:
	if _recording:
		_frame_ms.append(delta * 1000.0)

func _utc() -> String:
	var d := Time.get_datetime_dict_from_system(true)
	return "%04d%02d%02dT%02d%02d%02dZ" % [d["year"], d["month"], d["day"], d["hour"], d["minute"], d["second"]]

func _runtime() -> Node:
	return get_tree().root.find_child("WorldRuntime", true, false)

func _mem() -> String:
	return "nodes=%d objects=%d orphans=%d tex_mib=%.1f vid_mib=%.1f static_mib=%.1f" % [
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / MIB, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / MIB,
		Performance.get_monitor(Performance.MEMORY_STATIC) / MIB]

## One district change as the game does it (district_entered), timed in wall-clock milliseconds, with the frames of the whole window recorded.
func _transition(id: StringName, pass_name: String) -> bool:
	var runtime := _runtime()
	if runtime == null:
		print("[probe] FAIL no WorldRuntime")
		return false
	_frame_ms.clear()
	_recording = true
	var t0 := Time.get_ticks_usec()
	DistrictManager.current_district = String(id)
	EventBus.district_entered.emit(id)
	var waited := 0.0
	while runtime.current_district() != id and waited < 20.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	var load_ms := float(Time.get_ticks_usec() - t0) / 1000.0
	for i in 3:
		await get_tree().process_frame
	var settled_ms := float(Time.get_ticks_usec() - t0) / 1000.0
	await get_tree().create_timer(DWELL_SEC).timeout
	_recording = false
	var hitches := 0
	var worst := 0.0
	var over := 0.0
	for ms in _frame_ms:
		if ms > HITCH_MS:
			hitches += 1
		worst = maxf(worst, ms)
		over += maxf(0.0, ms - FRAME_BUDGET_MS)
	var stats := ""
	if runtime.has_method("get_last_load_stats"):
		stats = " stats=" + JSON.stringify(runtime.get_last_load_stats())
	print("[probe] stream pass=%s district=%s ok=%s load_ms=%.1f settled_ms=%.1f hitches=%d max_frame_ms=%.1f over_budget_ms=%.1f %s%s" % [
		pass_name, String(id), str(runtime.current_district() == id), load_ms, settled_ms, hitches, worst, over, _mem(), stats])
	return runtime.current_district() == id

func _frame_p95(n: int) -> float:
	var vp := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var ms: Array[float] = []
	var gpu := 0.0
	for i in n:
		await get_tree().process_frame
		ms.append(get_process_delta_time() * 1000.0)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
	ms.sort()
	print("[probe] perf_mean gpu_ms=%.2f" % (gpu / n))
	return ms[int(ms.size() * 0.95)]

func _perf(id: StringName) -> void:
	var runtime := _runtime()
	if runtime != null and runtime.current_district() != id:
		await _transition(id, "perf")
	for i in 60:
		await get_tree().process_frame
	var calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var prims := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var objects := int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	var p95 := await _frame_p95(PERF_FRAMES)
	print("[probe] perf district=%s draw_calls=%d primitives=%d objects_in_frame=%d frame_p95_ms=%.2f %s" % [String(id), calls, prims, objects, p95, _mem()])

func _snap(state: String) -> void:
	out_dir = "res://docs/stills/polish/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var file_name := "%s_%s_%s_%s" % [state, _label, _hash, _utc()]
	await _shot(file_name)
	print("[probe] frame state=%s file=%s.png" % [state, file_name])

func _player_node() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D

func _light_on(player: Node3D) -> void:
	if player.has_method("toggle_flashlight") and not bool(player.get("flashlight_enabled")):
		player.toggle_flashlight()

## The nearest street tree (a MultiMesh sphere canopy) within 4 to 14 m: the flashlight shows its shadow there.
func _face_nearest_canopy(player: Node3D) -> bool:
	var best := Vector2.INF
	var best_d := INF
	for c in _canopies():
		var d := c.distance_to(Vector2(player.global_position.x, player.global_position.z))
		if d > 4.0 and d < 14.0 and d < best_d:
			best_d = d
			best = c
	if best == Vector2.INF:
		return false
	_face(player, Vector3(best.x, player.global_position.y, best.y))
	return true

func _nearest_monster(player: Node3D) -> Node3D:
	var monster: Node3D = null
	for m in get_tree().get_nodes_in_group("monsters"):
		var m3 := m as Node3D
		if m3 == null or not m3.is_visible_in_tree() or m3.global_position.y < -5.0:
			continue
		if monster == null or m3.global_position.distance_to(player.global_position) < monster.global_position.distance_to(player.global_position):
			monster = m3
	return monster

func _stage_states() -> void:
	var player := _player_node()
	if player == null:
		print("[probe] frame FAIL no player")
		return
	# 1 and 2: the spawn street, dark with the flashlight on, then restored
	await _transition(&"suburbs", "frames")
	player.heal(1000.0)
	_light_on(player)
	_face_lamps(player)
	await get_tree().create_timer(0.4).timeout
	await _snap("01_dark_street")
	PowerGrid.advance_district(&"suburbs", DistrictData.Stage.FULL)
	await get_tree().create_timer(1.5).timeout
	_face_lamps(player)
	await get_tree().create_timer(0.3).timeout
	await _snap("02_lit_street")
	# 3 and 4 and 5: a dark district, the flashlight on a tree, a hit, a hit taken
	await _transition(&"residential", "frames")
	player = _player_node()
	player.heal(1000.0)
	_light_on(player)
	if not _face_nearest_canopy(player):
		_face_lamps(player)
	await get_tree().create_timer(0.5).timeout
	await _snap("03_flashlight_shadow")
	var monster := _nearest_monster(player)
	if monster == null:
		print("[probe] frame state=04_combat_hit SKIPPED no monster in the district")
		print("[probe] frame state=05_damage_taken SKIPPED no monster in the district")
	else:
		var away := player.global_position - monster.global_position
		away.y = 0.0
		away = away.normalized() * 3.0 if away.length() > 0.1 else Vector3(0.0, 0.0, 3.0)
		player.global_position = monster.global_position + away + Vector3(0.0, 0.5, 0.0)
		_face(player, monster.global_position)
		await get_tree().create_timer(0.6).timeout
		monster.take_damage(8.0, player.global_position, EnemyRosterData.DamageType.BLUNT)
		await get_tree().create_timer(0.15).timeout
		await _snap("04_combat_hit")
		await get_tree().create_timer(1.0).timeout
		player.set("_damage_grace_timer", 0.0)
		player.set("_iframes", 0.0)
		player.take_damage(10.0, monster.global_position)
		await get_tree().create_timer(0.06).timeout
		await _snap("05_damage_taken")
	# 6: a sprint at the Ultra tier (the motion blur tier), then the default tier again
	var tier: int = int(SettingsManager.get_setting("graphics_tier", 2))
	SettingsManager.set_graphics_tier(3)
	player.heal(1000.0)
	player.set("stamina", 100.0)
	InputService.set_joy_active(true)
	InputService.set_joy_move_dir(Vector2(0.0, -1.0))
	InputService.set_joy_run_held(true)
	await get_tree().create_timer(SPRINT_SEC).timeout
	await _snap("06_sprint_ultra")
	InputService.set_joy_run_held(false)
	InputService.set_joy_move_dir(Vector2.ZERO)
	InputService.set_joy_active(false)
	SettingsManager.set_graphics_tier(tier)
	# 7: a street with its manhole steam (industrial), looking along the nearest steam vent or the lamps
	await _transition(&"industrial", "frames")
	player = _player_node()
	player.heal(1000.0)
	_light_on(player)
	var vents := get_tree().get_nodes_in_group("steam_vent")
	if vents.is_empty():
		_face_lamps(player)
	else:
		_face(player, (vents[0] as Node3D).global_position)
	await get_tree().create_timer(1.5).timeout
	await _snap("07_steam_street")
	# 8: the inventory screen with a hovered button (hover scale) and the quick slot row
	UIManager.open(&"inventory")
	await get_tree().create_timer(0.6).timeout
	var buttons := get_tree().root.find_children("*", "Button", true, false)
	for b in buttons:
		var button := b as Button
		if button != null and button.is_visible_in_tree() and not button.disabled:
			button.mouse_entered.emit()
			break
	await get_tree().create_timer(0.3).timeout
	await _snap("08_inventory_ui")
	UIManager.close(&"inventory")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("[probe] SKIP headless - frames need a real display")
		get_tree().quit(3)
		return
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("--tlabel="):
			_label = s.substr(9)
		elif s.begins_with("--thash="):
			_hash = s.substr(8)
	var ads := get_node_or_null("/root/AdService")
	if ads:
		ads.enabled = false
	var menu_up := func() -> bool:
		var cs := get_tree().current_scene
		return cs != null and cs.scene_file_path == Routes.MENU
	if not await _wait_until(menu_up, 15.0):
		Routes.goto(Routes.MENU)
		if not await _wait_until(menu_up, 10.0):
			_fail("main menu never came up")
			return
	await get_tree().create_timer(1.0).timeout
	SaveSystem.mark_onboard_done()
	Routes.start_game()
	var playing := func() -> bool: return GameManager.is_playing() and get_tree().get_first_node_in_group("player") != null
	if not await _wait_until(playing, 20.0):
		_fail("never reached gameplay")
		return
	await get_tree().create_timer(3.0).timeout
	print("[probe] start label=%s hash=%s tier=%d display=%s %s" % [_label, _hash, int(SettingsManager.get_setting("graphics_tier", 2)), DisplayServer.get_name(), _mem()])
	await _perf(&"suburbs")
	for i in range(1, ORDER.size()):
		await _transition(ORDER[i], "cold")
	for i in range(ORDER.size() - 2, -1, -1):
		await _transition(ORDER[i], "warm")
	await _perf(&"suburbs")
	await _perf(&"power_station")
	await _stage_states()
	print("[probe] DONE label=%s hash=%s" % [_label, _hash])
	get_tree().quit(0)
