class_name Wave2GameBridge
extends Node

## Glue between the supplied Wave 2 modules and the live game.
## Rule: no game rules are reimplemented here. The 3-step state machine lives in
## Wave2DistrictFlow, the two map views live in Wave2ProgressionMap, and live
## locale propagation lives in Wave2LocalizationSync. This node only builds the
## physical world objects and forwards events/state between them.

const FLOW_SCRIPT := preload("res://scripts/overhaul/Wave2DistrictFlow.gd")
const INTERACT_SCRIPT := preload("res://scripts/overhaul/Wave2Interactable.gd")

const DISTRICTS: Array[StringName] = [
	&"suburbs", &"residential", &"park", &"school", &"hospital",
	&"gas_station", &"police", &"warehouses", &"industrial", &"substation", &"power_station",
]
## Street-grid coordinates: the player starts at (-8, -8); parts are spread
## across real blocks at walking distance. No marker is ever registered for them.
const RELAY_OFFSETS: Array[Vector3] = [
	Vector3(-18.0, 0.85, -16.0), Vector3(16.0, 0.85, -12.0),
	Vector3(-2.0, 0.85, 18.0), Vector3(22.0, 0.85, 10.0),
	Vector3(-24.0, 0.85, 6.0), Vector3(4.0, 0.85, -24.0),
]
const FUSEBOX_POS: Vector3 = Vector3(12.0, 1.0, 12.0)
const GATE_POS: Vector3 = Vector3(0.0, 0.0, 30.0)
const GATE_CLEAR_WIDTH_M: float = 6.0
const COL_BRASS := Color(0.7882, 0.6353, 0.2902, 1.0)
const COL_AMBER := Color(0.8314, 0.6627, 0.3059, 1.0)
const COL_LOCKED := Color(0.55, 0.12, 0.09, 1.0)
const TOTAL_DISTRICTS: int = 11
const W2_IRON_ALBEDO := "res://assets/textures/wave2/iron_brass_hardware_albedo.png"
const W2_IRON_ORM := "res://assets/textures/wave2/iron_brass_hardware_orm.png"

var _index: int = 0
var _district_id: StringName = &""
var _root: Node3D = null
var _content: Node3D = null
var _gate_sign: Label3D = null
var _beacon: OmniLight3D = null
var _beacon_mesh: MeshInstance3D = null
var _objective_label: Label = null
var _map: CanvasLayer = null
var _poll: float = 0.0
var _built_for: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_wire")

func _wire() -> void:
	var flow := get_node_or_null("/root/Wave2Flow")
	if flow != null:
		if not flow.state_changed.is_connected(_on_flow_state):
			flow.state_changed.connect(_on_flow_state)
		if not flow.relay_parts_changed.is_connected(_on_parts_changed):
			flow.relay_parts_changed.connect(_on_parts_changed)
		if not flow.fusebox_repaired.is_connected(_on_fusebox_repaired):
			flow.fusebox_repaired.connect(_on_fusebox_repaired)
		if not flow.exit_gate_unlocked.is_connected(_on_gate_unlocked):
			flow.exit_gate_unlocked.connect(_on_gate_unlocked)
		if not flow.district_transition_requested.is_connected(_on_transition):
			flow.district_transition_requested.connect(_on_transition)
		if not flow.game_victory_reached.is_connected(_on_victory):
			flow.game_victory_reached.connect(_on_victory)
		if not flow.safe_zone_toggled.is_connected(_on_safe_zone):
			flow.safe_zone_toggled.connect(_on_safe_zone)
	if not EventBus.district_entered.is_connected(_on_district_entered):
		EventBus.district_entered.connect(_on_district_entered)
	if not EventBus.streetlight_activated.is_connected(_on_streetlights):
		EventBus.streetlight_activated.connect(_on_streetlights)
	var i18n := get_node_or_null("/root/I18nSync")
	if i18n != null and not i18n.locale_changed.is_connected(_on_locale):
		i18n.locale_changed.connect(_on_locale)
	_map = get_parent().get_node_or_null("Wave2ProgressionMap") as CanvasLayer
	if _map != null and not _map.map_opened.is_connected(_on_map_opened):
		_map.map_opened.connect(_on_map_opened)
	_setup_objective_label()
	_refresh_objective()

func _setup_objective_label() -> void:
	var hud := get_parent().get_node_or_null("HUD") as CanvasLayer
	if hud == null or hud.get_node_or_null("Wave2Objective") != null:
		return
	var holder := Control.new()
	holder.name = "Wave2Objective"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.set_anchors_preset(Control.PRESET_CENTER_TOP)
	holder.offset_left = -280.0
	holder.offset_right = 280.0
	holder.offset_top = 84.0
	holder.offset_bottom = 116.0
	var label := Label.new()
	label.name = "ObjectiveText"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", COL_BRASS)
	holder.add_child(label)
	hud.add_child(holder)
	_objective_label = label

func _on_district_entered(district_id: StringName) -> void:
	_district_id = district_id
	_index = maxi(0, DISTRICTS.find(district_id))
	var flow := get_node_or_null("/root/Wave2Flow")
	if flow != null:
		var completed: Array = flow.call("get_completed_districts")
		flow.call("start_district", _index, completed)
	var wr := get_parent().get_node_or_null("WorldRuntime")
	if wr != null:
		for child in wr.get_children():
			if child is Node3D and String(child.name).to_lower().begins_with("district_"):
				_root = child as Node3D
				break
	if _root == null:
		return
	if _built_for == str(_root.get_instance_id()):
		return
	_built_for = str(_root.get_instance_id())
	call_deferred("_build_content")
	_refresh_objective()

func _build_content() -> void:
	if not is_instance_valid(_root):
		return
	if _root.get_node_or_null("Wave2Content") != null:
		_root.get_node("Wave2Content").queue_free()
	_content = Node3D.new()
	_content.name = "Wave2Content"
	_root.add_child(_content)
	for i in RELAY_OFFSETS.size():
		_make_relay(i)
	_make_fusebox()
	_make_gate()
	_configure_map()
	_on_streetlights(_district_id)

func _metal_material(tint: Color, glow: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.metallic = 0.55
	mat.roughness = 0.6
	if ResourceLoader.exists(W2_IRON_ALBEDO):
		mat.albedo_texture = load(W2_IRON_ALBEDO)
		mat.roughness_texture = load(W2_IRON_ORM)
	mat.emission_enabled = glow > 0.0
	mat.emission = tint
	mat.emission_energy_multiplier = glow
	return mat

func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	parent.add_child(mi)
	return mi

func _make_relay(i: int) -> void:
	var at: Vector3 = RELAY_OFFSETS[i]
	var holder := Node3D.new()
	holder.name = "RelayPart_%02d" % (i + 1)
	holder.position = at
	_content.add_child(holder)
	_box(holder, "GlintMesh", Vector3(0.34, 0.34, 0.10), Vector3.ZERO,
		_metal_material(COL_AMBER, 1.8))
	var adapter: Node = INTERACT_SCRIPT.new()
	adapter.name = "Interact"
	adapter.set("kind", &"relay")
	adapter.set("part_id", "d%d_relay_%02d" % [_index, i])
	adapter.set("district_index", _index)
	holder.add_child(adapter)
	holder.add_to_group(&"interactable")

func _make_fusebox() -> void:
	var holder := Node3D.new()
	holder.name = "DistrictFusebox"
	holder.position = FUSEBOX_POS
	_content.add_child(holder)
	_box(holder, "Cabinet", Vector3(0.9, 1.3, 0.45), Vector3.ZERO,
		_metal_material(Color(0.16, 0.20, 0.23), 0.08))
	_box(holder, "BrassTrim", Vector3(0.72, 0.12, 0.07), Vector3(0.0, 0.42, 0.26),
		_metal_material(COL_BRASS, 0.35))
	var adapter: Node = INTERACT_SCRIPT.new()
	adapter.name = "Interact"
	adapter.set("kind", &"fusebox")
	adapter.set("district_index", _index)
	holder.add_child(adapter)
	holder.add_to_group(&"interactable")

func _make_gate() -> void:
	var holder := Node3D.new()
	holder.name = "Wave2ExitGate"
	holder.position = GATE_POS
	_content.add_child(holder)
	var iron := _metal_material(Color(0.13, 0.16, 0.18), 0.05)
	var pillar_x: float = GATE_CLEAR_WIDTH_M * 0.5 + 0.55
	for side in [-1.0, 1.0]:
		var px: float = side * pillar_x
		_box(holder, "Pillar%s" % ("L" if side < 0.0 else "R"),
			Vector3(1.1, 4.4, 1.1), Vector3(px, 2.2, 0.0), iron)
		var body := StaticBody3D.new()
		body.name = "PillarCollider%s" % ("L" if side < 0.0 else "R")
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = Vector3(px, 2.2, 0.0)
		holder.add_child(body)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.1, 4.4, 1.1)
		shape.shape = box
		body.add_child(shape)
	_box(holder, "Lintel", Vector3(pillar_x * 2.0 + 1.1, 0.55, 1.0),
		Vector3(0.0, 4.45, 0.0), iron)
	_beacon_mesh = _box(holder, "BeaconGlass", Vector3(0.42, 0.42, 0.42),
		Vector3(0.0, 4.95, 0.0), _metal_material(COL_LOCKED, 2.2))
	_beacon = OmniLight3D.new()
	_beacon.name = "BeaconLight"
	_beacon.light_color = COL_LOCKED
	_beacon.light_energy = 0.7
	_beacon.shadow_enabled = false
	_beacon.position = Vector3(0.0, 4.95, 0.0)
	_beacon.distance_fade_begin = 24.0
	_beacon.distance_fade_length = 10.0
	holder.add_child(_beacon)
	_gate_sign = Label3D.new()
	_gate_sign.name = "GateSign"
	_gate_sign.position = Vector3(0.0, 3.55, -0.62)
	_gate_sign.font_size = 96
	_gate_sign.modulate = COL_BRASS
	_gate_sign.no_depth_test = false
	holder.add_child(_gate_sign)
	_refresh_gate_sign()
	var adapter: Node = INTERACT_SCRIPT.new()
	adapter.name = "Interact"
	adapter.set("kind", &"gate")
	adapter.set("district_index", _index)
	holder.add_child(adapter)
	holder.add_to_group(&"interactable")
	var area := Area3D.new()
	area.name = "GateZone"
	area.collision_mask = 1
	area.position = Vector3(0.0, 1.3, 0.0)
	holder.add_child(area)
	var area_shape := CollisionShape3D.new()
	var area_box := BoxShape3D.new()
	area_box.size = Vector3(GATE_CLEAR_WIDTH_M, 2.6, 1.4)
	area_shape.shape = area_box
	area.add_child(area_shape)
	area.body_entered.connect(_on_gate_body)

func _on_gate_body(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	var flow := get_node_or_null("/root/Wave2Flow")
	if flow != null and bool(flow.call("is_gate_unlocked")):
		flow.call("try_enter_exit_gate")

func _refresh_gate_sign() -> void:
	if _gate_sign == null:
		return
	var i18n := get_node_or_null("/root/I18nSync")
	var next_idx: int = mini(_index + 2, 11)
	var next_name: String = ""
	if i18n != null:
		next_name = String(i18n.call("t", "DISTRICT_NAME_%02d" % next_idx))
	if next_name.is_empty():
		next_name = "DISTRICT %02d" % next_idx
	_gate_sign.text = next_name

func _on_flow_state(_state: StringName, _idx: int) -> void:
	_refresh_objective()

func _on_parts_changed(_have: int, _need: int) -> void:
	_refresh_objective()

func _on_fusebox_repaired(_idx: int) -> void:
	var pg := get_node_or_null("/root/PowerGrid")
	if pg != null and pg.has_method("advance_district") and int(pg.call("get_stage", _district_id)) < 3:
		pg.call("advance_district", _district_id, 3)
	_refresh_objective()
	if _map != null:
		_map.call("set_progression_state", _index, _completed_indices(), 3, true)

func _on_gate_unlocked(_idx: int) -> void:
	if _beacon != null:
		_beacon.light_color = COL_AMBER
		_beacon.light_energy = 1.8
	if _beacon_mesh != null:
		_beacon_mesh.material_override = _metal_material(COL_AMBER, 3.0)
	_refresh_gate_sign()

func _on_transition(next_index: int) -> void:
	if next_index < 0 or next_index >= DISTRICTS.size():
		return
	var next_id: StringName = DISTRICTS[next_index]
	var dm := get_node_or_null("/root/DistrictManager")
	if dm != null:
		dm.set("current_district", String(next_id))
	EventBus.district_entered.emit(next_id)
	SaveSystem.autosave()

func _on_victory() -> void:
	EventBus.game_won.emit()
	SaveSystem.autosave()

func _on_streetlights(_id: StringName) -> void:
	if _map == null or not is_instance_valid(_root):
		return
	if _root.has_node("Wave2ExitGate"):
		_map.call("register_lit_streetlight", GATE_POS, 8.0)
	_map.call("register_lit_streetlight", Vector3(-8.0, 0.0, -8.0), 9.0)

func _configure_map() -> void:
	if _map == null or not is_instance_valid(_root):
		return
	var rects: Array[Rect2] = []
	var skyline: Node = _root.get_node_or_null("Skyline")
	if skyline != null and skyline.has_method("get_footprints"):
		var raw: Variant = skyline.call("get_footprints")
		if raw is Array:
			for r in raw:
				if r is Rect2:
					rects.append(r)
	_map.call("configure_district", _index, Vector2(-60.0, -60.0), Vector2(60.0, 60.0),
		rects, Vector2(GATE_POS.x, GATE_POS.z), true)
	_map.call("set_progression_state", _index, _completed_indices(), 1, false)

func _completed_indices() -> Array:
	var flow := get_node_or_null("/root/Wave2Flow")
	if flow == null:
		return []
	return flow.call("get_completed_districts")

func _refresh_objective() -> void:
	if _objective_label == null or not is_instance_valid(_objective_label):
		_objective_label = null
		_setup_objective_label()
	if _objective_label == null:
		return
	var flow := get_node_or_null("/root/Wave2Flow")
	var i18n := get_node_or_null("/root/I18nSync")
	if flow == null or i18n == null:
		return
	var info: Dictionary = flow.call("get_objective_key_and_args")
	var args: Dictionary = info.get("args", {})
	_objective_label.text = String(i18n.call("t", String(info.get("key", "OBJ_STEP1_PARTS")), args))

func _on_locale(_lang: String) -> void:
	_refresh_objective()
	_refresh_gate_sign()

func _on_safe_zone(is_inside: bool) -> void:
	var music := get_node_or_null("/root/MusicManager")
	if music == null or is_inside == false:
		return
	if music.has_method("is_in_combat") and bool(music.call("is_in_combat")):
		return
	if music.has_method("set_mood"):
		music.call("set_mood", MusicDirector.Mood.AMBIENT)

func _on_map_opened() -> void:
	var ui := get_node_or_null("/root/UIManager")
	if ui != null and ui.has_method("close"):
		ui.call("close", &"city_map")

func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	_tick_safe_zone(delta, player)
	if _map == null:
		return
	_poll -= delta
	if _poll > 0.0:
		return
	_poll = 0.12
	var flash: SpotLight3D = player.get_node_or_null("ModelPivot/FlashlightPivot/Flashlight") as SpotLight3D
	var on: bool = bool(player.get("flashlight_enabled")) and flash != null and flash.visible
	_map.call("update_player_illumination", player.global_position, player.rotation.y, on, 12.0, 3.2)

func _tick_safe_zone(delta: float, player: Node3D) -> void:
	var flow := get_node_or_null("/root/Wave2Flow")
	if flow == null:
		return
	var light_grid := get_node_or_null("/root/LightGrid")
	var lit: bool = false
	if light_grid != null and light_grid.has_method("is_lit"):
		lit = bool(light_grid.call("is_lit", player.global_position, 0.3))
	var gd := get_node_or_null("/root/GameplayDirector")
	var battery: float = float(gd.get("battery")) if gd != null else 100.0
	var warmth: float = float(gd.get("warmth")) if gd != null else 100.0
	var res: Dictionary = flow.call("tick_offline_safe_zone", delta, lit, battery, warmth)
	if gd == null:
		return
	gd.set("battery", clampf(float(res.get("battery_pct", battery)), 0.0, 100.0))
	gd.set("warmth", clampf(float(res.get("warmth_pct", warmth)), 0.0, 100.0))
