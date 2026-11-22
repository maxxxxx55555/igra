extends "res://scripts/tools/_final_frames_runner.gd"
## Wave 2 showcase runner. Windowed only; it lives under scripts/tools/ so the
## integrity manifest and check.sh do not ship it. It captures the phone HUD,
## the light-revealed city map, all eleven districts, and the overhauled UI,
## and writes MOBILE_TOUCH_AUDIT.txt next to the frames.

const ORDER: Array[StringName] = [
	&"suburbs", &"residential", &"park", &"school", &"hospital", &"gas_station",
	&"police", &"warehouses", &"industrial", &"substation", &"power_station",
]
const TOUCH_BUTTONS: Array[String] = [
	"BtnAttack", "BtnSprint", "BtnStealth", "BtnInteract", "BtnJump", "BtnFlash",
	"BtnStrobe", "BtnWheel", "BtnReload", "BtnMelee", "BtnUV", "BtnDodge",
	"BtnInventory", "BtnWorkbench", "MapButton",  # the shipped node behind the brief's BtnMap
]
const PHONE_209 := Vector2i(1600, 720)
const PHONE_169 := Vector2i(1280, 720)

var _audit: Array[String] = []
var _audit_fails: int = 0
var _lang0: String = "en"
var _size0: int = 1
var _win0: Window
var _size_win0 := Vector2i(1280, 720)
var _mode0: Window.Mode = Window.MODE_WINDOWED
var _calibrated0: Variant = false
var _emulate0: bool = false


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("[wave2] SKIP headless - showcase frames need a real display")
		get_tree().quit(3)
		return
	if OS.get_environment("TLS_FRAMES_OUT") != "":
		out_dir = OS.get_environment("TLS_FRAMES_OUT")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	QualityManager.enabled = false

	_lang0 = LocalizationManager.current_lang
	_size0 = int(SettingsManager.get_setting("text_size", 1))
	_win0 = get_window()
	_size_win0 = _win0.size
	_mode0 = _win0.mode
	_calibrated0 = SettingsManager.get_setting("touch_calibration_done", false)
	_emulate0 = Input.emulate_touch_from_mouse
	LocalizationManager.set_language("ru")
	SettingsManager.set_text_size(1)
	_win0.mode = Window.MODE_WINDOWED
	_win0.size = PHONE_169
	_await_frames(2)

	# The boot scene routes itself into the menu; start_game() from a cold
	# boot leaves GameManager without a player (the release runner does this
	# handoff explicitly, so the showcase must too).
	Routes.goto(Routes.BOOT)
	await get_tree().create_timer(1.2).timeout
	var menu_up := func() -> bool:
		var cs := get_tree().current_scene
		return cs != null and cs.scene_file_path == Routes.MENU
	if not await _wait_until(menu_up, 15.0):
		Routes.goto(Routes.MENU)
		if not await _wait_until(menu_up, 10.0):
			_fail("main menu never came up")
			return
	SaveSystem.mark_onboard_done()
	Routes.start_game()
	if not await _wait_until(func() -> bool:
		return GameManager.is_playing() and get_tree().get_first_node_in_group("player") != null, 20.0):
		_fail("never reached gameplay")
		return
	TutorialSystem.call("_skip_tutorial")
	WeatherSystem.set("process_mode", Node.PROCESS_MODE_DISABLED)
	WeatherSystem.current = WeatherSystem.Weather.CLEAR
	WeatherSystem.call("_emit")
	RandomEvents.set("process_mode", Node.PROCESS_MODE_DISABLED)
	await get_tree().create_timer(1.5).timeout

	# A) phone HUD with real touch controls, lit street then combat.
	await _go_district(&"residential", DistrictData.Stage.FULL)
	await _set_touch(true, PHONE_209)
	_touch_audit("20x9_lit")
	await _capture("mobile_phone_20x9_lit", false)
	await _set_touch(true, PHONE_169)
	await _stage_boss()
	EventBus.player_detected.emit(&"wave2_showcase_combat")
	await get_tree().create_timer(0.3).timeout
	_touch_audit("16x9_combat")
	await _capture("mobile_phone_16x9_combat", false)
	await _set_touch(false, PHONE_169)

	# B) the map: a light-revealed partial city, at desktop and phone aspect.
	for id: StringName in ORDER:
		var stage: int = DistrictData.Stage.DARK
		if id == &"suburbs" or id == &"residential" or id == &"hospital":
			stage = DistrictData.Stage.FULL
		elif id == &"park" or id == &"police":
			stage = DistrictData.Stage.STREETS
		PowerGrid._set_stage_direct(id, stage)
	UIManager.open(&"city_map")
	await get_tree().create_timer(0.8).timeout
	await _capture("map_partial_reveal_ru", false)
	_win0.size = PHONE_209
	await _await_frames(4)
	await _capture("map_mobile_phone_ru", false)
	UIManager.close(&"city_map")
	_win0.size = PHONE_169
	await _await_frames(3)

	# C) one dark contrast frame, then all eleven districts lit at eye level.
	# Substation is captured last on purpose: leaving it dark until then keeps
	# the finale (and the boss flare) out of the power-station still.
	await _go_district(&"suburbs", DistrictData.Stage.DARK)
	await _capture("dist_00_suburbs_dark", false)
	var capture_order: Array[StringName] = ORDER.duplicate()
	capture_order.erase(&"substation")
	capture_order.push_back(&"substation")
	for id: StringName in capture_order:
		await _go_district(id, DistrictData.Stage.FULL)
		var idx: int = ORDER.find(id)
		await _capture("dist_%02d_%s_lit" % [idx + 1, String(id)], false)

	# D) combat vignette and boss arena from the same staged Architect, so
	# both frames actually carry a visible threat; then the overhauled screens.
	await _stage_boss()
	EventBus.player_detected.emit(&"wave2_showcase_combat")
	await get_tree().create_timer(0.3).timeout
	await _capture("combat_01_vignette", false)
	await _capture("boss_01_arena", false)

	UIManager.open(&"skill_tree")
	await get_tree().create_timer(0.8).timeout
	await _capture("ui_02_skill_tree", false)
	UIManager.close(&"skill_tree")
	var screens: Node = get_tree().root.find_child("Screens", true, false)
	if screens != null:
		screens.call("show_screen", "Shop")
		await get_tree().create_timer(0.8).timeout
		await _capture("ui_03_shop", false)
		screens.call("hide_all")
	Routes.goto(Routes.MENU)
	await _wait_until(func() -> bool:
		var cs := get_tree().current_scene
		return cs != null and cs.scene_file_path == Routes.MENU, 15.0)
	await _await_frames(12)
	await _capture("ui_01_main_menu", false)

	_write_audit()
	LocalizationManager.set_language(_lang0)
	SettingsManager.set_text_size(_size0)
	Input.emulate_touch_from_mouse = _emulate0
	SettingsManager.set_setting("touch_calibration_done", _calibrated0)
	_win0.size = _size_win0
	_win0.mode = _mode0
	print("[wave2] DONE audit_fail=%d frames=%d" % [_audit_fails, 21])
	get_tree().quit(0 if _audit_fails == 0 else 1)


func _await_frames(n: int) -> void:
	for i: int in n:
		await get_tree().process_frame


func _go_district(id: StringName, stage: int) -> void:
	PowerGrid._set_stage_direct(id, stage)
	DistrictManager.current_district = String(id)
	EventBus.district_entered.emit(id)
	var runtime := get_tree().root.find_child("WorldRuntime", true, false)
	var waited := 0.0
	while runtime != null and runtime.current_district() != id and waited < 15.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	await get_tree().create_timer(0.8).timeout
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null:
		_face_lamps(player)
		player.set("_pitch", deg_to_rad(-10.0))
	await _await_frames(3)


func _set_touch(on: bool, size: Vector2i) -> void:
	SettingsManager.set_setting("touch_calibration_done", on)
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", on)
	Input.emulate_touch_from_mouse = on
	_win0.mode = Window.MODE_WINDOWED
	_win0.size = size
	await _swap_hud(get_tree().current_scene)
	await get_tree().create_timer(0.7).timeout


func _stage_combat() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var monster: Node3D = null
	for m in get_tree().get_nodes_in_group("monsters"):
		var m3 := m as Node3D
		if m3 == null or not m3.is_visible_in_tree() or m3.global_position.y < -5.0:
			continue
		if monster == null or m3.global_position.distance_to(player.global_position) < monster.global_position.distance_to(player.global_position):
			monster = m3
	if monster == null:
		# District streaming parks the pooled enemies; stage one explicitly so
		# the combat evidence actually shows a threat and the new vignette.
		var scene := load("res://scenes/enemies/watcher_3d.tscn") as PackedScene
		if scene != null:
			monster = scene.instantiate() as Node3D
			monster.name = "Wave2CombatEnemy"
			get_tree().current_scene.add_child(monster)
			monster.global_position = player.global_position + Vector3(0.0, 0.0, -6.0)
	if monster == null:
		return
	var away := player.global_position - monster.global_position
	away.y = 0.0
	away = away.normalized() * 6.0 if away.length() > 0.1 else Vector3(0.0, 0.0, 6.0)
	player.global_position = monster.global_position + away + Vector3(0.0, 0.5, 0.0)
	monster.set_physics_process(false)
	_face(player, monster.global_position)
	if player.has_method("heal"):
		player.heal(1000.0)
	await get_tree().create_timer(0.5).timeout
	_aim(player, monster.global_position + Vector3(0.0, 1.2, 0.0))
	await _await_frames(3)


func _stage_boss() -> void:
	for id: StringName in ORDER:
		PowerGrid._set_stage_direct(id, DistrictData.Stage.FULL)
	DistrictManager.current_district = "power_station"
	EventBus.district_entered.emit(&"power_station")
	await _wait_until(func() -> bool: return is_instance_valid(FinaleDirector._boss), 8.0)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var boss: Node3D = FinaleDirector._boss
	if boss == null or not is_instance_valid(boss):
		var scene := load("res://scenes/enemies/boss_architect_3d.tscn") as PackedScene
		if scene != null:
			boss = scene.instantiate() as Node3D
			boss.name = "Wave2BossArena"
			get_tree().current_scene.add_child(boss)
	if player == null or boss == null:
		return
	for m in get_tree().get_nodes_in_group("monsters"):
		if m != boss and m is Node3D:
			m.queue_free()
	if player.has_method("heal"):
		player.heal(1000.0)
	var back := player.global_position - boss.global_position
	back.y = 0.0
	back = back.normalized() if back.length() > 0.1 else Vector3.FORWARD
	player.global_position = boss.global_position + back * 5.0 + Vector3(0.0, 0.5, 0.0)
	_face(player, boss.global_position)
	await get_tree().create_timer(1.0).timeout
	_aim(player, boss.global_position + Vector3(0.0, 1.6, 0.0))
	await _await_frames(3)


func _touch_audit(tag: String) -> void:
	var hud := get_tree().root.find_child("HUD", true, false)
	var vp := get_viewport().get_visible_rect()
	var rects: Dictionary = {}
	var rows: Array[String] = []
	_audit.append("## %s viewport=%dx%d" % [tag, int(vp.size.x), int(vp.size.y)])
	for nm: String in TOUCH_BUTTONS:
		var btn: Button = hud.find_child(nm, true, false) as Button if hud != null else null
		var display: String = "BtnMap" if nm == "MapButton" else nm
		if btn == null or not btn.is_visible_in_tree():
			_audit.append("%s|node=%s|MISSING_OR_HIDDEN" % [display, nm])
			_audit_fails += 1
			continue
		var r := btn.get_global_rect()
		rects[nm] = r
		var ok_size: bool = r.size.x >= 48.0 and r.size.y >= 48.0
		var inside: bool = vp.encloses(r)
		if not ok_size or not inside:
			_audit_fails += 1
		var line := "%s|node=%s|visible=true|x=%d|y=%d|%dx%d|size=%s|inside=%s" % [display, nm, int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y), str(ok_size), str(inside)]
		rows.append(line)
		_audit.append(line)
	var overlaps: int = 0
	for i: int in rects.size():
		var a: String = rects.keys()[i]
		for j: int in range(i + 1, rects.size()):
			var b: String = rects.keys()[j]
			if (rects[a] as Rect2).intersects(rects[b] as Rect2):
				overlaps += 1
				_audit.append("OVERLAP %s %s" % [a, b])
	_audit_fails += overlaps
	_audit.append("visible_buttons=%d overlaps=%d result=%s" % [rows.size(), overlaps, "PASS" if overlaps == 0 else "FAIL"])
	print("[wave2] MOBILE_TOUCH_AUDIT %s buttons=%d overlaps=%d" % [tag, rows.size(), overlaps])


func _write_audit() -> void:
	if not _audit.is_empty():
		_audit.insert(0, "MOBILE_TOUCH_AUDIT: %s" % ("PASS" if _audit_fails == 0 else "FAIL"))
	var f := FileAccess.open(ProjectSettings.globalize_path(out_dir + "MOBILE_TOUCH_AUDIT.txt"), FileAccess.WRITE)
	if f != null:
		for line: String in _audit:
			f.store_line(line)
		f.close()
	print("[wave2] MOBILE_TOUCH_AUDIT: %s (fails=%d)" % ["PASS" if _audit_fails == 0 else "FAIL", _audit_fails])
