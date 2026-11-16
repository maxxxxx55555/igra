extends "res://scripts/tools/_monster_frames_runner.gd"

var _failures: int = 0
var _out: String = "res://.qa_logs/b10_verify/"

func _check(ok: bool, what: String) -> void:
	print("[b10v] %s %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failures += 1

func _frame(state: String) -> void:
	await RenderingServer.frame_post_draw
	var path := _out + state + ".png"
	var image := get_tree().root.get_texture().get_image()
	_where(state)
	_check(image.save_png(ProjectSettings.globalize_path(path)) == OK, "saved " + path)

func _xz(box: AABB) -> Rect2:
	return Rect2(Vector2(box.position.x, box.position.z), Vector2(box.size.x, box.size.z))

func _check_placement(piece: Node3D) -> void:
	var occupied := AABB()
	var first := true
	for mesh: MeshInstance3D in piece.find_children("*", "MeshInstance3D", true, false):
		var box := mesh.global_transform * mesh.get_aabb()
		occupied = box if first else occupied.merge(box)
		first = false
	var footprint := _xz(occupied)
	var collisions: Array[String] = []
	for batch: MultiMeshInstance3D in get_tree().current_scene.find_children("*", "MultiMeshInstance3D", true, false):
		if not batch.name.begins_with("B9") and not batch.name.begins_with("Urban_") and batch.name not in ["Crates", "Barrels", "Bins"]:
			continue
		var mm := batch.multimesh
		if mm == null:
			continue
		for i in mm.instance_count:
			var box := batch.global_transform * mm.get_instance_transform(i) * mm.mesh.get_aabb()
			if footprint.intersects(_xz(box)):
				collisions.append("%s[%d]" % [batch.name, i])
	_check(collisions.is_empty(), "%s clear of solid dressing: %s" % [piece.name, str(collisions)])

func _pose(at: Vector3, target: Vector3) -> void:
	var player := _player_node()
	player.global_position = at
	await get_tree().create_timer(0.4).timeout
	_aim(player, target)
	await get_tree().create_timer(0.4).timeout

func _click(control: Control) -> void:
	var point := control.get_global_rect().get_center() * Vector2(get_window().size) / get_viewport().get_visible_rect().size
	print("[b10v] click %s at %s window=%s viewport=%s mouse=%s" % [control.name, point, get_window().size, get_viewport().get_visible_rect().size, Input.mouse_mode])
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame

func _inventory_frames() -> void:
	for stack: Array in [[&"battery", 2], [&"medkit", 1], [&"serum", 1], [&"fuse", 2], [&"circuit", 2], [&"cable", 3], [&"scrap", 6], [&"alcohol", 1]]:
		InventoryManager.try_add(stack[0], stack[1])
	for lang in ["en", "ru"]:
		LocalizationManager.set_language(lang)
		UIManager.open(&"inventory")
		var ui := UIManager._get_screen(&"inventory")
		_check(ui != null, lang + " inventory opened")
		if ui == null:
			return
		ui.call("_on_filter", 0)
		var pack_scroll := (ui.get("_grid") as Control).get_parent() as ScrollContainer
		pack_scroll.scroll_vertical = 0
		await get_tree().create_timer(0.5).timeout
		await _frame("inventory_" + lang)
		var actions: Control = ui.get("_actions")
		var detail: Control = ui.get("_detail")
		var quick: Control = ui.get("_quick_title")
		_check(actions.get_global_rect().end.y < quick.get_global_rect().position.y, lang + " inventory actions clear of quick slots")
		_check(detail.get_global_rect().end.y <= actions.get_global_rect().position.y, lang + " item details clear of actions")
		var equipment: Control = ui.get("_equip_rows")
		_check(equipment.get_global_rect().end.y < quick.get_global_rect().position.y, lang + " equipment contained above footer")
		_check((equipment.get_parent() as Control).get_global_rect().encloses(equipment.get_global_rect()), lang + " all five equipment rows initially visible")
		var vitals: Label = ui.get("_vitals")
		var text_height := vitals.get_theme_font("font").get_height(vitals.get_theme_font_size("font_size")) * vitals.get_line_count()
		_check(text_height <= vitals.size.y, lang + " vitals text stays inside footer")
		var footer_end := ((ui.get("_stage") as Control).get_global_transform() * Vector2(0.0, 672.0)).y
		_check(vitals.get_global_rect().end.y <= footer_end, lang + " vitals control stays inside footer")
		var grid: Control = ui.get("_grid")
		_check(grid.size.y <= (grid.get_parent() as Control).size.y, lang + " all twelve pack cells initially visible")
		var filters: Array = ui.get("_filter_buttons")
		var sorts: Array = ui.get("_sort_buttons")
		_check((filters[0] as Control).get_global_rect().end.y <= (sorts[0] as Control).get_global_rect().position.y, lang + " filter and sort hitboxes separated")
		_check((sorts[0] as Control).get_global_rect().end.y <= grid.get_global_rect().position.y, lang + " sort clear of item grid")
		await _click(filters[4])
		_check(ui.get("_filter") == 3, lang + " mouse click selects Epic filter")
		await _click(filters[0])
		_check(ui.get("_filter") == -1, lang + " mouse click returns to All filter")
		var kept_pack := InventoryManager.to_dict()
		var player := _player_node()
		var kept_battery: float = player.battery
		player.battery = 40.0
		var batteries := InventoryManager.count_of(&"battery")
		await _click(actions.get_child(0).get_child(0) as Control)
		_check(InventoryManager.count_of(&"battery") == batteries - 1 and player.battery > 40.0, lang + " Use click recharges player and consumes one battery")
		player.battery = kept_battery
		InventoryManager.from_dict(kept_pack)
		InventoryManager.from_dict({})
		ui.call("_on_filter", 4)
		await get_tree().create_timer(0.3).timeout
		_check(grid.get_child_count() == 0, lang + " filtered empty contains no item cells")
		_check(actions.get_child_count() == 0, lang + " filtered empty contains no actions")
		_check((ui.get("_note") as Label).text == LocalizationManager.t("INV_FILTER_EMPTY"), lang + " filtered empty explains the state")
		await _frame("inventory_filtered_empty_" + lang)
		UIManager.close(&"inventory")
		InventoryManager.from_dict(kept_pack)
	LocalizationManager.set_language("en")

func _prop_checks() -> void:
	var props: Node3D = load("res://scripts/world/b10_setpieces.gd").new()
	add_child(props)
	var tint := Color(0.32, 0.27, 0.20)
	var material: StandardMaterial3D = props.call("_mat", "plywood", tint, 0.88)
	_check(is_equal_approx(material.albedo_color.r * 0.38, tint.r), "textured wood keeps its intended mean tint")
	props.call("_keeper_shed", Vector3.ZERO)
	var radio := props.find_child("ShortwaveRadio", true, false) as Node3D
	var first := true
	var bounds := AABB()
	if radio != null:
		var meshes := radio.find_children("*", "MeshInstance3D", true, false)
		if radio is MeshInstance3D:
			meshes.append(radio)
		for mesh: MeshInstance3D in meshes:
			var box := mesh.global_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
	_check(not first and bounds.size.x >= 0.4 and bounds.size.y >= 0.24, "shortwave radio has a readable tabletop scale")
	var tuner := props.find_child("TuningGlass", true, false) as Node3D
	var lamp := props.find_child("WorkLampLight", true, false) as Node3D
	_check(tuner != null and lamp != null and (lamp.global_position - tuner.global_position).dot(radio.global_basis.z) > 0.05, "work lamp illuminates the radio face")
	props.queue_free()
	print("[b10v] PROP_DONE failures=%d" % _failures)
	get_tree().quit(0 if _failures == 0 else 1)

func _store_shots() -> void:
	get_window().size = Vector2i(1920, 1080)
	SettingsManager.set_setting("trailer_mode", true)
	for spec: Array in [
		[&"residential", "Playground", Vector3(0.8, 1.0, 6.5), Vector3(0.4, 0.2, 2.8), "shot03_stealth_horror_1920x1080_en"],
		[&"park", "KeeperShed", Vector3(1.13, 1.0, 1.65), Vector3(0.0, 1.05, -0.6), "shot04_keeper_lore_1920x1080_en"],
		[&"industrial", "WorkshopB", Vector3(0.0, 1.0, 4.6), Vector3(0.0, 1.3, 0.0), "shot06_mystery_inside_1920x1080_en"],
	]:
		await _transition(spec[0], "store")
		_freeze_monsters()
		var player := _player_node()
		player.heal(1000.0)
		player.set("_crouch_toggled", true)
		_flashlight(player, spec[0] == &"residential")
		var piece := get_tree().current_scene.find_child(spec[1], true, false) as Node3D
		_check(piece != null, "store subject " + spec[1])
		if piece == null:
			continue
		_check_placement(piece)
		_check(PowerGrid.get_stage(spec[0]) == DistrictData.Stage.DARK, "store district remains DARK")
		await _pose(piece.global_position + spec[2], piece.global_position + spec[3])
		await get_tree().create_timer(60.0 if spec[0] == &"residential" else 3.0).timeout
		await _frame(spec[4])
		player.set("_crouch_toggled", false)
	print("[b10v] STORE_DONE failures=%d" % _failures)
	get_tree().quit(0 if _failures == 0 else 1)

func _run() -> void:
	if OS.get_environment("TLS_B10_PROP_ONLY") == "1":
		_prop_checks()
		return
	if not await _enter_game():
		return
	if OS.has_environment("TLS_B10_OUT"):
		_out = OS.get_environment("TLS_B10_OUT").trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	if OS.get_environment("TLS_STORE_SHOTS") == "1":
		await _store_shots()
		return
	get_window().size = Vector2i(1600, 900)
	LocalizationManager.set_language("en")
	SettingsManager.set_text_size(1)
	SettingsManager.set_setting("trailer_mode", false)
	TutorialSystem.call("_skip_tutorial")
	_freeze_monsters()
	_raise(&"suburbs", DistrictData.Stage.FULL)
	await get_tree().create_timer(1.5).timeout
	var player := _player_node()
	var wm := player.get_node("WeaponManager") as WeaponManager
	wm.unlock(&"pistol")
	_check(wm.equip(&"pistol"), "pistol equipped through gameplay manager")
	ProgressTracker.add_ammo(60)
	await get_tree().create_timer(3.0).timeout
	var weapon := wm.get_current_weapon()
	var hand := weapon.get_node_or_null("FirstPersonHands") as MeshInstance3D
	if OS.get_environment("TLS_B10_LIGHT_ONLY") == "1":
		var body := weapon.get_node_or_null("WeaponModel/Body") as GeometryInstance3D
		var key := weapon.get_node_or_null("ViewmodelLight") as OmniLight3D
		var model := weapon.get_node("WeaponModel") as Node3D
		_check(hand != null and hand.position.is_equal_approx(model.position), "hands share the weapon grip frame")
		_check(body != null and (body.layers & player.flashlight.light_cull_mask) == 0, "flashlight does not bleach viewmodel steel")
		_check(key != null and key.light_cull_mask == 2 and key.light_energy > 0.0 and key.light_energy <= 1.0, "restrained viewmodel light cannot illuminate world layer")
		_check(hand != null and (hand.layers & player.flashlight.light_cull_mask) == 0, "flashlight excludes close-range hands")
		_check(hand != null and hand.visibility_range_end_margin < hand.visibility_range_end, "hand LOD margin cannot swallow near range")
		get_tree().quit(0 if _failures == 0 else 1)
		return
	_check(hand != null and hand.is_visible_in_tree(), "visible authored hands on pistol")
	_check(hand != null and (hand.layers & player.flashlight.light_cull_mask) == 0, "flashlight excludes close-range hands")
	await _pose(Vector3(-5.4, 1.0, -18.5), Vector3(-9.4, 3.0, -32.0))
	await _frame("street_hud")
	_flashlight(player, false)
	await get_tree().create_timer(1.5).timeout
	await _frame("hands_no_flash")
	_flashlight(player, true)
	await _inventory_frames()
	if OS.get_environment("TLS_B10_INVENTORY_ONLY") == "1":
		print("[b10v] DONE failures=%d" % _failures)
		get_tree().quit(0 if _failures == 0 else 1)
		return
	wm.fire()
	await get_tree().process_frame
	await _frame("hands_fire")
	await get_tree().create_timer(0.5).timeout
	wm.reload()
	await get_tree().create_timer(0.3).timeout
	await _frame("hands_reload")
	await get_tree().create_timer(2.0).timeout
	for id: StringName in [&"rifle", &"shotgun"]:
		wm.unlock(id)
		_check(wm.equip(id), String(id) + " equipped")
		await get_tree().create_timer(0.5).timeout
		await _frame("hands_" + String(id))
	wm.holster()
	SettingsManager.set_setting("trailer_mode", true)
	for spec: Array in [[&"residential", "Playground", Vector3(5.5, 1.0, 6.5), Vector3(0.6, 1.1, 0.8), "shot03"], [&"park", "KeeperShed", Vector3(2.6, 1.0, 3.8), Vector3(0.0, 1.0, -0.4), "shot04"], [&"industrial", "WorkshopB", Vector3(4.2, 1.0, 4.8), Vector3(0.0, 1.4, 0.4), "shot06"]]:
		await _transition(spec[0], "b10")
		_freeze_monsters()
		if spec[0] == &"residential":
			_raise(spec[0], DistrictData.Stage.FULL)
		var piece := get_tree().current_scene.find_child(spec[1], true, false) as Node3D
		_check(piece != null, "spawned " + spec[1])
		if piece == null:
			continue
		_check_placement(piece)
		player = _player_node()
		player.heal(1000.0)
		_flashlight(player, spec[0] == &"residential")
		await _pose(piece.global_position + spec[2], piece.global_position + spec[3])
		await get_tree().create_timer(3.0).timeout
		await _frame(spec[4])
	await _transition(&"suburbs", "b10")
	_freeze_monsters()
	player = _player_node()
	_flashlight(player, true)
	await _pose(Vector3(8.0, 1.0, 2.0), Vector3(8.0, 1.4, -3.0))
	for id in ["rotter", "brute", "crawler"]:
		var monster := _stand(id, Vector3(8.0, 0.08, -3.0), PI)
		await get_tree().create_timer(0.5).timeout
		await _frame("creature_" + id)
		monster.queue_free()
		await get_tree().process_frame
	print("[b10v] DONE failures=%d" % _failures)
	get_tree().quit(0 if _failures == 0 else 1)
