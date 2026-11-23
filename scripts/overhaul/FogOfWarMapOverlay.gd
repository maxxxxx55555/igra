class_name FogOfWarMapOverlay
extends CanvasLayer

## Illumination-only Fog-of-War Map:
## - Reveals ONLY streets, multi-story buildings, and district gates illuminated by the player.
## - STRICT INVARIANT: NEVER renders enemies, loot, or scrap markers.

signal map_closed()

const COLOR_PAPER_FOG: Color = Color(0.055, 0.075, 0.095, 0.96)
const COLOR_REVEALED_STREET: Color = Color(0.118, 0.157, 0.196, 1.0)
const COLOR_REVEALED_BUILDING: Color = Color(0.240, 0.285, 0.325, 1.0)
const COLOR_BUILDING_OUTLINE: Color = Color(0.784, 0.608, 0.329, 0.72)
const COLOR_GATE_LOCKED: Color = Color(0.784, 0.294, 0.192, 0.95)
const COLOR_GATE_OPEN: Color = Color(0.910, 0.745, 0.447, 1.0)
const COLOR_PLAYER: Color = Color(0.929, 0.902, 0.839, 1.0)

@export var world_bounds_min: Vector2 = Vector2(-80.0, -80.0)
@export var world_bounds_max: Vector2 = Vector2(80.0, 80.0)
@export var reveal_cell_size_m: float = 4.0

var _panel: PanelContainer
var _canvas: Control
var _title_label: Label
var _legend_label: Label
var _close_btn: Button

var _revealed_cells: Dictionary = {}
var _buildings: Array[Rect2] = []
var _gates: Array[Dictionary] = []
var _player_pos_xz: Vector2 = Vector2.ZERO
var _player_yaw: float = 0.0
var _district_title: String = "РАЙОН I"


func _ready() -> void:
	layer = 35
	visible = false
	_build_ui()


func toggle_map() -> void:
	visible = not visible
	if visible and is_instance_valid(_canvas):
		_canvas.queue_redraw()
	elif not visible:
		map_closed.emit()


func set_district_metadata(district_name: String, bounds_min: Vector2, bounds_max: Vector2) -> void:
	_district_title = district_name
	world_bounds_min = bounds_min
	world_bounds_max = bounds_max
	if is_instance_valid(_title_label):
		_title_label.text = _loc_title()


func register_building_footprint(rect_xz: Rect2) -> void:
	if rect_xz.size.x > 0.5 and rect_xz.size.y > 0.5:
		_buildings.append(rect_xz)


func scan_world_buildings_from_scene(root: Node) -> int:
	_buildings.clear()
	if root == null:
		return 0
	var stack: Array[Node] = [root]
	var min_x: float = 1e6
	var min_z: float = 1e6
	var max_x: float = -1e6
	var max_z: float = -1e6

	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n as MeshInstance3D
			if not mi.visible or mi.mesh == null or _is_excluded_from_map(mi):
				continue
			var aabb: AABB = mi.global_transform * mi.get_aabb()
			if aabb.size.y >= 2.2 and (aabb.size.x >= 1.5 or aabb.size.z >= 1.5):
				var r: Rect2 = Rect2(Vector2(aabb.position.x, aabb.position.z), Vector2(aabb.size.x, aabb.size.z))
				_buildings.append(r)
				min_x = minf(min_x, r.position.x - 16.0)
				min_z = minf(min_z, r.position.y - 16.0)
				max_x = maxf(max_x, r.end.x + 16.0)
				max_z = maxf(max_z, r.end.y + 16.0)

	if not _buildings.is_empty() and max_x > min_x and max_z > min_z:
		world_bounds_min = Vector2(min_x, min_z)
		world_bounds_max = Vector2(max_x, max_z)
	return _buildings.size()


func register_district_gate(gate_id: String, pos_xz: Vector2, target_name: String, is_unlocked: bool) -> void:
	for g in _gates:
		if String(g.get("id", "")) == gate_id:
			g["pos"] = pos_xz
			g["target"] = target_name
			g["unlocked"] = is_unlocked
			if visible and is_instance_valid(_canvas):
				_canvas.queue_redraw()
			return
	_gates.append({
		"id": gate_id,
		"pos": pos_xz,
		"target": target_name,
		"unlocked": is_unlocked,
		"discovered": false,
	})


func reveal_illumination(player_pos_3d: Vector3, forward_dir_3d: Vector3, flashlight_on: bool, light_range_m: float = 16.0) -> void:
	_player_pos_xz = Vector2(player_pos_3d.x, player_pos_3d.z)
	var fwd_2d: Vector2 = Vector2(forward_dir_3d.x, forward_dir_3d.z)
	if fwd_2d.length_squared() > 0.0001:
		fwd_2d = fwd_2d.normalized()
		_player_yaw = fwd_2d.angle()

	_mark_disk_revealed(_player_pos_xz, 3.5)
	if flashlight_on and light_range_m > 0.5:
		var steps: int = maxi(2, int(ceilf(light_range_m / maxf(1.5, reveal_cell_size_m * 0.7))))
		for s in range(1, steps + 1):
			var dist: float = (float(s) / float(steps)) * light_range_m
			var sample_center: Vector2 = _player_pos_xz + fwd_2d * dist
			var cone_r: float = clampf(dist * 0.36, 2.2, 7.5)
			_mark_disk_revealed(sample_center, cone_r)

	for g in _gates:
		if _is_point_revealed(g["pos"] as Vector2):
			g["discovered"] = true

	if visible and is_instance_valid(_canvas):
		_canvas.queue_redraw()


func _mark_disk_revealed(center_xz: Vector2, radius_m: float) -> void:
	var cs: float = maxf(1.0, reveal_cell_size_m)
	var min_cx: int = int(floorf((center_xz.x - radius_m) / cs))
	var max_cx: int = int(floorf((center_xz.x + radius_m) / cs))
	var min_cz: int = int(floorf((center_xz.y - radius_m) / cs))
	var max_cz: int = int(floorf((center_xz.y + radius_m) / cs))
	var r2: float = radius_m * radius_m
	for cx in range(min_cx, max_cx + 1):
		for cz in range(min_cz, max_cz + 1):
			var cell_center: Vector2 = Vector2((float(cx) + 0.5) * cs, (float(cz) + 0.5) * cs)
			if cell_center.distance_squared_to(center_xz) <= r2:
				_revealed_cells[Vector2i(cx, cz)] = true


func _is_point_revealed(p_xz: Vector2) -> bool:
	var cs: float = maxf(1.0, reveal_cell_size_m)
	return _revealed_cells.has(Vector2i(int(floorf(p_xz.x / cs)), int(floorf(p_xz.y / cs))))


func _build_ui() -> void:
	var bg_dim: ColorRect = ColorRect.new()
	bg_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_dim.color = Color(0.02, 0.03, 0.04, 0.80)
	add_child(bg_dim)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", AdaptiveScreenFrame._chamfer_box(COLOR_PAPER_FOG, AdaptiveScreenFrame.COLOR_BRASS, 2, 16, 14))
	margin.add_child(_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	var header: HBoxContainer = HBoxContainer.new()
	vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = _loc_title()
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_color_override("font_color", AdaptiveScreenFrame.COLOR_BRASS_ACTIVE)
	_title_label.add_theme_font_size_override("font_size", 24)
	header.add_child(_title_label)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(64.0, 48.0)
	_close_btn.add_theme_stylebox_override("normal", AdaptiveScreenFrame._chamfer_box(AdaptiveScreenFrame.COLOR_BG, AdaptiveScreenFrame.COLOR_BRASS, 2, 8, 6))
	_close_btn.add_theme_color_override("font_color", AdaptiveScreenFrame.COLOR_TEXT)
	_close_btn.pressed.connect(toggle_map)
	header.add_child(_close_btn)

	_canvas = Control.new()
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.draw.connect(_on_draw_map)
	vbox.add_child(_canvas)

	_legend_label = Label.new()
	_legend_label.add_theme_color_override("font_color", AdaptiveScreenFrame.COLOR_TEXT_MUTED)
	_legend_label.add_theme_font_size_override("font_size", 16)
	_legend_label.text = _loc_legend()
	vbox.add_child(_legend_label)


func _on_draw_map() -> void:
	var sz: Vector2 = _canvas.get_rect().size
	if sz.x <= 8.0 or sz.y <= 8.0:
		return
	_canvas.draw_rect(Rect2(Vector2.ZERO, sz), COLOR_PAPER_FOG, true)

	var world_span: Vector2 = world_bounds_max - world_bounds_min
	if world_span.x <= 1.0 or world_span.y <= 1.0:
		return
	var scale_f: float = minf((sz.x - 32.0) / world_span.x, (sz.y - 32.0) / world_span.y)
	var offset: Vector2 = (sz - world_span * scale_f) * 0.5
	var cs: float = maxf(1.0, reveal_cell_size_m)

	for cell_key in _revealed_cells.keys():
		var ck: Vector2i = cell_key
		var p0: Vector2 = (Vector2(float(ck.x) * cs, float(ck.y) * cs) - world_bounds_min) * scale_f + offset
		_canvas.draw_rect(Rect2(p0, Vector2(cs * scale_f + 1.0, cs * scale_f + 1.0)), COLOR_REVEALED_STREET, true)

	for b in _buildings:
		var lit: bool = _is_point_revealed(b.get_center()) or _is_point_revealed(b.position) or _is_point_revealed(b.end) or _is_point_revealed(Vector2(b.position.x, b.end.y)) or _is_point_revealed(Vector2(b.end.x, b.position.y))
		if not lit:
			continue
		var draw_r: Rect2 = Rect2((b.position - world_bounds_min) * scale_f + offset, b.size * scale_f)
		_canvas.draw_rect(draw_r, COLOR_REVEALED_BUILDING, true)
		_canvas.draw_rect(draw_r, COLOR_BUILDING_OUTLINE, false, 1.5)

	for g in _gates:
		if not bool(g.get("discovered", false)):
			continue
		var g_pos: Vector2 = ((g["pos"] as Vector2) - world_bounds_min) * scale_f + offset
		var g_col: Color = COLOR_GATE_OPEN if bool(g.get("unlocked", false)) else COLOR_GATE_LOCKED
		_canvas.draw_rect(Rect2(g_pos - Vector2(7.0, 7.0), Vector2(14.0, 14.0)), g_col, true)
		_canvas.draw_rect(Rect2(g_pos - Vector2(9.0, 9.0), Vector2(18.0, 18.0)), COLOR_PLAYER, false, 1.5)

	var pl_screen: Vector2 = (_player_pos_xz - world_bounds_min) * scale_f + offset
	var dir_v: Vector2 = Vector2(cos(_player_yaw), sin(_player_yaw))
	var perp_v: Vector2 = Vector2(-dir_v.y, dir_v.x)
	_canvas.draw_colored_polygon(PackedVector2Array([
		pl_screen + dir_v * 11.0,
		pl_screen - dir_v * 7.0 + perp_v * 6.0,
		pl_screen - dir_v * 7.0 - perp_v * 6.0,
	]), COLOR_PLAYER)


func _is_excluded_from_map(node: Node) -> bool:
	var p: Node = node
	while p != null:
		if p is CharacterBody3D or p is RigidBody3D or p is Skeleton3D:
			return true
		var ln: String = p.name.to_lower()
		if ln.contains("enemy") or ln.contains("mob") or ln.contains("stalker") or ln.contains("pickup") or ln.contains("scrap") or ln.contains("item"):
			return true
		p = p.get_parent()
	return false


func _loc_title() -> String:
	if TranslationServer.get_locale().to_lower().begins_with("ru"):
		return "КАРТА ОСВЕЩЕНИЯ — %s" % _district_title
	return "ILLUMINATION MAP — %s" % _district_title


func _loc_legend() -> String:
	if TranslationServer.get_locale().to_lower().begins_with("ru"):
		return "Открываются только освещённые дома и проходы в районы. Враги и предметы не отображаются."
	return "Reveals illuminated buildings and district gates only. Enemies and items stay hidden."
