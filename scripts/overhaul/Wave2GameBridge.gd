class_name Wave2GameBridge
extends Node

## Glue between the supplied Wave 2 modules and the live game.
## Rule: no game rules are reimplemented here. The 3-step state machine lives in
## Wave2DistrictFlow, the two map views live in Wave2ProgressionMap, and live
## locale propagation lives in Wave2LocalizationSync. This node only builds the
## physical world objects and forwards events/state between them.

const DETAIL := preload("res://scripts/overhaul/ProceduralDetailMeshes.gd")
const POLISH := preload("res://scripts/overhaul/StreamReadyPolishDirector.gd")
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
const GATE_CLEAR_WIDTH_M: float = DETAIL.GATE_CLEAR_WIDTH_M
const COL_BRASS := Color(0.7882, 0.6353, 0.2902, 1.0)
const COL_AMBER := Color(0.8314, 0.6627, 0.3059, 1.0)
const COL_LOCKED := Color(0.55, 0.12, 0.09, 1.0)
const TOTAL_DISTRICTS: int = 11

var _index: int = 0
var _district_id: StringName = &""
var _root: Node3D = null
var _content: Node3D = null
var _gate_sign: Label3D = null
var _polish: CanvasLayer
var _indicator: MeshInstance3D
var _beacon_mesh: MeshInstance3D = null
var _objective_label: Label = null
var _map: CanvasLayer = null
var _poll: float = 0.0
var _lamp_poll := 0.0
var _mapped_lamps := PackedInt64Array()
var _needs_map := false
var _built_for: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_polish = POLISH.new()
	add_child(_polish)
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
	if not EventBus.district_stage_changed.is_connected(_on_light_stage):
		EventBus.district_stage_changed.connect(_on_light_stage)
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
	_on_district_entered(StringName(DistrictManager.current_district))

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
	_root = null
	var wr := get_parent().get_node_or_null("WorldRuntime")
	if wr != null:
		for child in wr.get_children():
			if child is Node3D and String(child.name).to_lower() == "district_" + String(district_id):
				_root = child as Node3D
				break
	if not is_instance_valid(_root):
		return
	if _built_for == str(_root.get_instance_id()):
		return
	_built_for = str(_root.get_instance_id())
	var flow := get_node_or_null("/root/Wave2Flow")
	if flow != null:
		var completed: Array = flow.call("get_completed_districts")
		flow.call("start_district", _index, completed)
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
	var flow := get_node_or_null("/root/Wave2Flow")
	if flow != null and bool(flow.call("is_gate_unlocked")):
		_on_gate_unlocked(_index)
	_needs_map = true
	_configure_map()

func _signal_material(tint: Color, glow: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = glow
	return mat

func _holder(kind: StringName, title: String, at: Vector3, part_id := "") -> Node3D:
	var holder: Node3D = INTERACT_SCRIPT.new()
	holder.name = title
	holder.set("kind", kind)
	holder.set("part_id", part_id)
	holder.set("district_index", _index)
	holder.position = at
	_content.add_child(holder)
	holder.add_to_group(&"interactable")
	return holder

func _make_relay(i: int) -> void:
	var part_id := "d%d_relay_%02d" % [_index, i]
	var flow := get_node_or_null("/root/Wave2Flow")
	if flow != null and bool(flow.call("has_relay_part", part_id)):
		return
	var holder := _holder(&"relay", "RelayPart_%02d" % (i+1), RELAY_OFFSETS[i], part_id)
	var coil := DETAIL.place(holder, &"relay", "RelayCoil", Vector3.ZERO)
	coil.visibility_range_end = 20.0
	var glint := DETAIL.place(holder, &"lens", "GlintMesh", Vector3(0,0.19,0),Vector3(0.27,0.34,0.27))
	glint.material_override = _signal_material(COL_AMBER,0.4)
	glint.visibility_range_end = 8.0

func _make_fusebox() -> void:
	var holder := _holder(&"fusebox", "DistrictFusebox", FUSEBOX_POS)
	DETAIL.place(holder, &"cabinet", "Cabinet", Vector3.ZERO)
	_indicator = DETAIL.place(holder,&"lens","Indicator",Vector3(0.23,0.34,0.28),Vector3(0.34,0.45,0.34))
	_indicator.rotation.x = PI * 0.5
	_indicator.material_override = _signal_material(COL_LOCKED,0.55)

func _make_gate() -> void:
	var holder := _holder(&"gate", "Wave2ExitGate", GATE_POS)
	var pillar_x: float = GATE_CLEAR_WIDTH_M * 0.5 + 0.55
	for side in [-1.0, 1.0]:
		var px: float = side * pillar_x
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
	DETAIL.place(holder, &"gate", "GateFrame", Vector3.ZERO)
	_beacon_mesh = DETAIL.place(holder, &"lens", "BeaconGlass", Vector3(0,5.1,0), Vector3(1.5,3,1.5))
	_beacon_mesh.material_override = _signal_material(COL_LOCKED,0.8)
	_gate_sign = Label3D.new()
	_gate_sign.name = "GateSign"
	_gate_sign.position = Vector3(0.0, 3.96, -0.56)
	_gate_sign.rotation.y = PI
	_gate_sign.pixel_size = 0.0023
	_gate_sign.font_size = 96
	_gate_sign.modulate = COL_BRASS
	_gate_sign.no_depth_test = false
	holder.add_child(_gate_sign)
	_refresh_gate_sign()
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
	if not is_instance_valid(_gate_sign):
		return
	var name_key := "DISTRICT_NAME_%02d" % mini(_index + 2, 11)
	_gate_sign.text = LocalizationManager.t(name_key)

func _on_flow_state(_state: StringName, _idx: int) -> void:
	_refresh_objective()
	if is_instance_valid(_map):
		_map.call("set_progression_state", _index, _completed_indices(), Wave2Flow.get_step_number(), Wave2Flow.is_gate_unlocked())

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
	var amber := _signal_material(COL_AMBER,1.0)
	if is_instance_valid(_indicator):
		_indicator.material_override = amber
	if is_instance_valid(_beacon_mesh):
		_beacon_mesh.material_override = amber
	_refresh_gate_sign()

func _on_transition(next_index: int) -> void:
	if next_index < 0 or next_index >= DISTRICTS.size():
		return
	_polish.call("transition", next_index, _enter_next_district.bind(next_index))

func _enter_next_district(next_index: int) -> void:
	var next_id: StringName = DISTRICTS[next_index]
	var dm := get_node_or_null("/root/DistrictManager")
	if dm != null:
		dm.set("current_district", String(next_id))
	# WorldRuntime saves after the player actually arrives at the new spawn.
	EventBus.district_entered.emit(next_id)

func _on_victory() -> void:
	SaveSystem.autosave()
	GameManager.trigger_win()

func _on_light_stage(id: StringName, _stage: int) -> void:
	if id == _district_id:
		call_deferred("_on_streetlights", id)

func _on_streetlights(_id: StringName) -> void:
	if _map == null or not is_instance_valid(_root):
		return
	var ids := PackedInt64Array()
	var lit: Array[SpotLight3D] = []
	for lamp in get_tree().get_nodes_in_group("streetlights"):
		if _root.is_ancestor_of(lamp):
			var spot := lamp.get_node_or_null("SpotLight") as SpotLight3D
			if is_instance_valid(spot) and spot.is_visible_in_tree() and spot.light_energy > 0.0:
				ids.append(spot.get_instance_id())
				lit.append(spot)
	if ids == _mapped_lamps:
		return
	_mapped_lamps = ids
	_map.call("clear_lit_streetlights")
	for spot in lit:
		var radius := tan(deg_to_rad(spot.spot_angle)) * (spot.global_position.y - _root.global_position.y)
		_map.call("register_lit_streetlight", spot.global_position, maxf(0.0,radius))

func _configure_map() -> void:
	if _map == null or not is_instance_valid(_root):
		return
	var rects: Array[Rect2] = []
	var skyline: Node = _root.find_child("Skyline", true, false)
	if skyline == null:
		return
	_needs_map = false
	_mapped_lamps.clear()
	if skyline.has_method("get_footprints"):
		var raw: Variant = skyline.call("get_footprints")
		if raw is Array:
			for r in raw:
				if r is Rect2:
					rects.append(r)
	_map.call("configure_district", _index, Vector2(-60.0, -60.0), Vector2(60.0, 60.0),
		rects, Vector2(GATE_POS.x, GATE_POS.z), true)
	var flow := get_node_or_null("/root/Wave2Flow")
	if flow != null:
		_map.call("set_progression_state", _index, _completed_indices(), flow.call("get_step_number"), flow.call("is_gate_unlocked"))

	_on_streetlights(_district_id)

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
	_lamp_poll -= delta
	if _lamp_poll <= 0.0:
		_lamp_poll = 0.5
		_on_streetlights(_district_id)
	_poll -= delta
	if _poll > 0.0:
		return
	_poll = 0.12
	if _needs_map:
		_configure_map()
	var flash: SpotLight3D = player.get_node_or_null("ModelPivot/FlashlightPivot/Flashlight") as SpotLight3D
	var on: bool = bool(player.get("flashlight_enabled")) and flash != null and flash.visible
	if on:
		_map.call("update_player_illumination",flash.global_position,flash.global_rotation.y,true,flash.spot_range,flash.spot_angle)

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
