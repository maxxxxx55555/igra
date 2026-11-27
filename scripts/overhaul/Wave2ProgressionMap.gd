class_name Wave2ProgressionMap
extends CanvasLayer

## Dual-layer Map & Progression System for Last Streetlight.
## 1) Always-visible clickable Progression Minimap (top-right safe area): an
##    enlarged architectural crop around the player, lit-area fog only.
## 2) Full Overview Map with [District] and [Full City 11-District] tabs.
## Fog is an L8 Image painted with the theme's soft radial brush and sampled
## with linear filtering; only light reveals ground. The overlay never
## registers or draws threat markers or loot markers of any kind.

signal map_opened
signal map_closed
signal district_inspected(district_index: int)

const COL_BG_DEEP: Color = Color(0.0235, 0.0588, 0.0745, 0.96)
const COL_BRASS: Color = Color(0.7882, 0.6353, 0.2902, 1.0)
const COL_AMBER: Color = Color(0.8314, 0.6627, 0.3059, 1.0)
const COL_TEXT_MAIN: Color = Color(0.902, 0.871, 0.784, 1.0)
const COL_TEXT_MUTED: Color = Color(0.569, 0.620, 0.643, 1.0)
const COL_GRID: Color = Color(0.333, 0.451, 0.510, 0.13)
const COL_RIVER: Color = Color(0.031, 0.071, 0.086, 1.0)
const COL_HIGHWAY: Color = Color(0.110, 0.150, 0.175, 1.0)
const COL_QUARTER: Color = Color(0.045, 0.072, 0.088, 1.0)
const COL_ROUTE_DARK: Color = Color(0.24, 0.30, 0.34, 0.80)
const TOTAL_DISTRICTS: int = 11
const FOG_GRID_RES: int = 192
const FOG_BRUSH_PX: float = 1.4
const MINI_HALF_SPAN_M: float = 24.0
const STREET_STEP_M: float = 16.0

var _world_min: Vector2 = Vector2(-60.0, -60.0)
var _world_max: Vector2 = Vector2(60.0, 60.0)
var _fog_cells: PackedByteArray = PackedByteArray()
var _fog_image: Image = null
var _fog_tex: ImageTexture = null
var _fog_dirty: bool = true
var _fog_view_min: Vector2 = Vector2.ZERO
var _fog_view_span: Vector2 = Vector2.ONE
var _buildings: Array[Rect2] = []
var _lit_lamps: Array[Vector2] = []
var _player_pos: Vector2 = Vector2.ZERO
var _player_yaw: float = 0.0
var _exit_gate_pos: Vector2 = Vector2.ZERO
var _exit_gate_exists: bool = false
var _exit_gate_unlocked: bool = false

var _current_district_idx: int = 0
var _completed_districts: Dictionary = {}
var _current_step: int = 1
var _selected_district_idx: int = 0
var _active_tab: int = 1  # 0 = District, 1 = Full City
var _is_full_open: bool = false

# Honest runtime report values, readable through get() by verification probes.
var map_building_footprints: int = 0
var map_player_arrow_drawn: bool = false
var map_tab_legend_distinct: bool = false
var map_threat_or_loot_markers: int = 0

# UI nodes
var _mini_btn: Button = null
var _mini_canvas: Control = null
var _mini_fog: Control = null
var _mini_marks: Control = null
var _mini_title: Label = null
var _mini_hint: Label = null
var _overlay_root: Control = null
var _title_lbl: Label = null
var _tab_district_btn: Button = null
var _tab_city_btn: Button = null
var _close_btn: Button = null
var _full_canvas: Control = null
var _full_fog: Control = null
var _full_marks: Control = null
var _legend_lbl: Label = null
var _info_lbl: Label = null
var _district_buttons: Array[Button] = []

const CITY_NODE_UV: Array[Vector2] = [
	Vector2(0.08, 0.72), Vector2(0.17, 0.50), Vector2(0.26, 0.68),
	Vector2(0.35, 0.40), Vector2(0.44, 0.62), Vector2(0.53, 0.34),
	Vector2(0.62, 0.58), Vector2(0.70, 0.30), Vector2(0.78, 0.54),
	Vector2(0.86, 0.36), Vector2(0.93, 0.52),
]


func _ready() -> void:
	layer = 35
	_init_fog()
	_build_ui()
	EventBus.hud_visibility_changed.connect(_sync_minimap_visibility)
	EventBus.game_state_changed.connect(func(_state: int) -> void: _sync_minimap_visibility())
	_sync_minimap_visibility()
	_layout_safe_area()
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_layout_safe_area):
		get_viewport().size_changed.connect(_layout_safe_area)
	refresh_localization()


func _sync_minimap_visibility(_visible: bool = true) -> void:
	if is_instance_valid(_mini_btn):
		_mini_btn.visible = GameManager.is_playing() and not UIManager.is_hud_blocked() and not _is_full_open


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		refresh_localization()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_map") or (event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo and (event as InputEventKey).keycode == KEY_M):
		toggle_full_map()
		get_viewport().set_input_as_handled()
	elif _is_full_open and event.is_action_pressed("ui_cancel"):
		close_full_map()
		get_viewport().set_input_as_handled()


func _init_fog() -> void:
	_fog_cells.resize(FOG_GRID_RES * FOG_GRID_RES)
	_fog_cells.fill(0)
	if _fog_image == null:
		_fog_image = Image.create(FOG_GRID_RES, FOG_GRID_RES, false, Image.FORMAT_L8)
	_fog_image.fill(Color(0.06, 0.06, 0.06, 1.0))
	_fog_dirty = true


func configure_district(district_index: int, world_min_xz: Vector2, world_max_xz: Vector2, building_rects: Array[Rect2], gate_xz: Vector2, has_gate: bool) -> void:
	_current_district_idx = clampi(district_index, 0, TOTAL_DISTRICTS - 1)
	_selected_district_idx = _current_district_idx
	_world_min = world_min_xz
	_world_max = Vector2(maxf(world_min_xz.x + 8.0, world_max_xz.x), maxf(world_min_xz.y + 8.0, world_max_xz.y))
	_buildings = building_rects.duplicate()
	map_building_footprints = _buildings.size()
	_lit_lamps.clear()
	_exit_gate_pos = gate_xz
	_exit_gate_exists = has_gate
	_exit_gate_unlocked = false
	_fog_cells.fill(0)
	_init_fog()
	refresh_localization()
	_redraw_all()


func set_progression_state(district_index: int, completed_indices: Array, step_index: int, gate_unlocked: bool) -> void:
	_current_district_idx = clampi(district_index, 0, TOTAL_DISTRICTS - 1)
	_completed_districts.clear()
	for idx in completed_indices:
		_completed_districts[int(idx)] = true
	_current_step = clampi(step_index, 1, 3)
	_exit_gate_unlocked = gate_unlocked
	refresh_localization()
	_redraw_all()


func update_player_illumination(player_world_pos: Vector3, player_yaw_rad: float, flashlight_on: bool, flashlight_range_m: float = 12.0, half_angle_degrees: float = 26.0) -> void:
	_player_pos = Vector2(player_world_pos.x, player_world_pos.z)
	_player_yaw = player_yaw_rad
	if not flashlight_on or flashlight_range_m <= 0.0:
		return
	var origin := Vector2(player_world_pos.x, player_world_pos.z)
	var forward := Vector2(-sin(player_yaw_rad), -cos(player_yaw_rad))
	reveal_circle(origin, flashlight_range_m, forward, cos(deg_to_rad(half_angle_degrees)))
	_redraw_all()


func clear_lit_streetlights() -> void:
	_lit_lamps.clear()
	_redraw_all()


func register_lit_streetlight(lamp_world_pos: Vector3, light_radius_m: float = 9.0) -> void:
	var pt: Vector2 = Vector2(lamp_world_pos.x, lamp_world_pos.z)
	for existing in _lit_lamps:
		if existing.distance_squared_to(pt) < 1.0:
			return
	_lit_lamps.append(pt)
	reveal_circle(pt, light_radius_m)
	_redraw_all()


func reveal_circle(center_xz: Vector2, radius_m: float, forward := Vector2.ZERO, min_dot := -1.0) -> void:
	var span: Vector2 = _world_max - _world_min
	if span.x <= 0.1 or span.y <= 0.1 or _fog_image == null:
		return
	var r2: float = radius_m * radius_m
	var gx_min: int = clampi(int(floorf(((center_xz.x - radius_m - _world_min.x) / span.x) * float(FOG_GRID_RES))), 0, FOG_GRID_RES - 1)
	var gx_max: int = clampi(int(ceilf(((center_xz.x + radius_m - _world_min.x) / span.x) * float(FOG_GRID_RES))), 0, FOG_GRID_RES - 1)
	var gz_min: int = clampi(int(floorf(((center_xz.y - radius_m - _world_min.y) / span.y) * float(FOG_GRID_RES))), 0, FOG_GRID_RES - 1)
	var gz_max: int = clampi(int(ceilf(((center_xz.y + radius_m - _world_min.y) / span.y) * float(FOG_GRID_RES))), 0, FOG_GRID_RES - 1)

	# Compare light rays with the same static footprints used to draw the outlines.
	var blockers: Array[AABB] = []
	var bounds := Rect2(center_xz - Vector2.ONE * radius_m, Vector2.ONE * 2.0 * radius_m)
	for footprint: Rect2 in _buildings:
		if footprint.intersects(bounds):
			blockers.append(AABB(Vector3(footprint.position.x, -1.0, footprint.position.y), Vector3(footprint.size.x, 2.0, footprint.size.y)))
	var origin := Vector3(center_xz.x, 0.0, center_xz.y)
	var half_cell: float = span.length() / (2.0 * float(FOG_GRID_RES))
	var painted: bool = false

	for gz in range(gz_min, gz_max + 1):
		var wz: float = _world_min.y + ((float(gz) + 0.5) / float(FOG_GRID_RES)) * span.y
		var row_off: int = gz * FOG_GRID_RES
		for gx in range(gx_min, gx_max + 1):
			var wx: float = _world_min.x + ((float(gx) + 0.5) / float(FOG_GRID_RES)) * span.x
			var dx: float = wx - center_xz.x
			var dz: float = wz - center_xz.y
			if _fog_cells[row_off + gx] != 0 or dx * dx + dz * dz > r2:
				continue
			if forward != Vector2.ZERO and Vector2(dx, dz).normalized().dot(forward) < min_dot:
				continue
			var endpoint := Vector3(wx, 0.0, wz).move_toward(origin, half_cell)
			var blocked: bool = false
			for box: AABB in blockers:
				if box.intersects_segment(origin, endpoint) != null:
					blocked = true
					break
			if blocked:
				continue
			_fog_cells[row_off + gx] = 1
			UnslopVisualTheme.paint_soft_fog_circle(_fog_image, gx, gz, FOG_BRUSH_PX)
			painted = true
	if painted:
		_fog_dirty = true


func toggle_full_map() -> void:
	if _is_full_open:
		close_full_map()
	else:
		open_full_map(1)


func open_full_map(default_tab: int = 1) -> void:
	if not GameManager.is_playing() or UIManager.is_hud_blocked():
		return
	_is_full_open = true
	_active_tab = clampi(default_tab, 0, 1)
	if _overlay_root != null:
		_overlay_root.visible = true
	_update_tab_visuals()
	refresh_localization()
	_sync_minimap_visibility()
	_redraw_all()
	map_opened.emit()


func close_full_map() -> void:
	_is_full_open = false
	if _overlay_root != null:
		_overlay_root.visible = false
	_sync_minimap_visibility()
	map_closed.emit()


func is_full_map_open() -> bool:
	return _is_full_open


func refresh_localization() -> void:
	if _mini_title != null:
		_mini_title.text = I18nSync.t("MAP_MINI_HEADER", {"cur": _current_district_idx + 1, "total": TOTAL_DISTRICTS})
	if _mini_hint != null:
		_mini_hint.text = I18nSync.t("MAP_MINI_TAP_HINT", {})
	if _title_lbl != null:
		_title_lbl.text = I18nSync.t("MAP_TITLE_FULL", {})
	if _tab_district_btn != null:
		_tab_district_btn.text = I18nSync.t("MAP_TAB_DISTRICT", {})
	if _tab_city_btn != null:
		_tab_city_btn.text = I18nSync.t("MAP_TAB_CITY", {})
	if _close_btn != null:
		_close_btn.text = I18nSync.t("UI_CLOSE", {})
	if _legend_lbl != null:
		_legend_lbl.text = UnslopVisualTheme.get_map_legend(_active_tab == 1)
	map_tab_legend_distinct = UnslopVisualTheme.get_map_legend(false) != UnslopVisualTheme.get_map_legend(true)
	_refresh_selected_district_info()


func _build_ui() -> void:
	# 1. Clickable top-right minimap button (enough width to clear the pause cluster).
	_mini_btn = Button.new()
	_mini_btn.name = "ProgressionMinimapButton"
	_mini_btn.custom_minimum_size = Vector2(190.0, 120.0)
	_mini_btn.focus_mode = Control.FOCUS_NONE
	_mini_btn.add_theme_stylebox_override("normal", MinimalNoSlopHud.make_minimap_frame())
	_mini_btn.add_theme_stylebox_override("hover", MinimalNoSlopHud.make_minimap_frame())
	_mini_btn.add_theme_stylebox_override("pressed", _make_panel_box(COL_BG_DEEP, COL_AMBER, 3, 6))
	_mini_btn.pressed.connect(func() -> void: open_full_map(1))
	add_child(_mini_btn)

	_mini_canvas = Control.new()
	_mini_canvas.name = "MiniCanvas"
	_mini_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mini_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mini_canvas.offset_left = 6.0
	_mini_canvas.offset_top = 24.0
	_mini_canvas.offset_right = -6.0
	_mini_canvas.offset_bottom = -20.0
	_mini_canvas.texture_filter = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR
	_mini_canvas.draw.connect(_draw_minimap)
	_mini_btn.add_child(_mini_canvas)
	_mini_fog = _make_fog_layer(_mini_canvas)
	_mini_marks = _make_marks_layer(_mini_canvas, true)

	_mini_title = Label.new()
	_mini_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mini_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_mini_title.offset_top = 3.0
	_mini_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mini_title.add_theme_font_size_override("font_size", 12)
	_mini_title.add_theme_color_override("font_color", COL_BRASS)
	_mini_btn.add_child(_mini_title)

	_mini_hint = Label.new()
	_mini_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mini_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_mini_hint.offset_top = -18.0
	_mini_hint.offset_bottom = -2.0
	_mini_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mini_hint.add_theme_font_size_override("font_size", 11)
	_mini_hint.add_theme_color_override("font_color", COL_TEXT_MAIN)
	_mini_btn.add_child(_mini_hint)

	# 2. Full-screen expandable overview map modal.
	_overlay_root = ColorRect.new()
	_overlay_root.name = "FullMapOverlay"
	_overlay_root.color = Color(0.015, 0.024, 0.028, 0.84)
	_overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_root.visible = false
	add_child(_overlay_root)

	var frame: PanelContainer = PanelContainer.new()
	frame.name = "MapModalFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 44.0
	frame.offset_top = 28.0
	frame.offset_right = -44.0
	frame.offset_bottom = -28.0
	frame.add_theme_stylebox_override("panel", _make_panel_box(COL_BG_DEEP, COL_BRASS, 2, 10))
	_overlay_root.add_child(frame)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	frame.add_child(vbox)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	_title_lbl = Label.new()
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_lbl.add_theme_font_size_override("font_size", 20)
	_title_lbl.add_theme_color_override("font_color", COL_BRASS)
	header.add_child(_title_lbl)

	_tab_city_btn = _make_action_btn(180.0, 56.0)
	_tab_city_btn.pressed.connect(func() -> void: _set_tab(1))
	header.add_child(_tab_city_btn)

	_tab_district_btn = _make_action_btn(180.0, 56.0)
	_tab_district_btn.pressed.connect(func() -> void: _set_tab(0))
	header.add_child(_tab_district_btn)

	_close_btn = _make_action_btn(128.0, 56.0)
	_close_btn.pressed.connect(close_full_map)
	header.add_child(_close_btn)

	_full_canvas = Control.new()
	_full_canvas.name = "FullMapCanvas"
	_full_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_full_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_full_canvas.texture_filter = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR
	_full_canvas.draw.connect(_draw_full_map)
	_full_canvas.resized.connect(_position_city_buttons)
	vbox.add_child(_full_canvas)
	_full_fog = _make_fog_layer(_full_canvas)
	_full_marks = _make_marks_layer(_full_canvas, false)

	# Clickable transparent buttons over the 11 district nodes on the City Map.
	_district_buttons.clear()
	for i in range(TOTAL_DISTRICTS):
		var db: Button = Button.new()
		db.name = "CityNodeBtn_%d" % i
		db.flat = true
		db.custom_minimum_size = Vector2(56.0, 56.0)
		db.focus_mode = Control.FOCUS_NONE
		var captured_i: int = i
		db.pressed.connect(func() -> void: _select_district(captured_i))
		_full_canvas.add_child(db)
		_district_buttons.append(db)

	_info_lbl = Label.new()
	_info_lbl.add_theme_font_size_override("font_size", 16)
	_info_lbl.add_theme_color_override("font_color", COL_TEXT_MAIN)
	_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_info_lbl)

	_legend_lbl = Label.new()
	_legend_lbl.add_theme_font_size_override("font_size", 13)
	_legend_lbl.add_theme_color_override("font_color", COL_TEXT_MUTED)
	_legend_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_legend_lbl)


func _make_fog_layer(parent: Control) -> Control:
	var layer: Control = Control.new()
	layer.name = "FogFilter"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.texture_filter = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	layer.material = mat
	layer.draw.connect(_draw_fog_layer.bind(layer))
	parent.add_child(layer)
	return layer


func _make_marks_layer(parent: Control, is_mini: bool) -> Control:
	var layer: Control = Control.new()
	layer.name = "MapMarks"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.draw.connect(_draw_marks.bind(layer, is_mini))
	parent.add_child(layer)
	return layer


func _layout_safe_area() -> void:
	if _mini_btn == null or get_viewport() == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	layout_in_safe_area(vp_size, UiScale.insets(vp_size))


func layout_in_safe_area(vp_size: Vector2, inset: Vector4) -> void:
	_mini_btn.position = Vector2(vp_size.x - inset.z - 300.0, inset.y + 12.0)
	_mini_btn.size = Vector2(190.0, 120.0)
	var frame := _overlay_root.get_node("MapModalFrame") as Control
	frame.offset_left = 44.0 + inset.x
	frame.offset_top = 28.0 + inset.y
	frame.offset_right = -44.0 - inset.z
	frame.offset_bottom = -28.0 - inset.w
	_position_city_buttons()


func _set_tab(tab_idx: int) -> void:
	_active_tab = clampi(tab_idx, 0, 1)
	_update_tab_visuals()
	refresh_localization()
	_redraw_all()


func _update_tab_visuals() -> void:
	var show_city: bool = (_active_tab == 1)
	for b in _district_buttons:
		b.visible = show_city
	if _full_fog != null:
		_full_fog.visible = not show_city
	if _full_marks != null:
		_full_marks.visible = not show_city
	if _tab_city_btn != null:
		_tab_city_btn.add_theme_stylebox_override("normal", _make_panel_box(COL_BG_DEEP, COL_AMBER if show_city else COL_BRASS, 2 if show_city else 1, 6))
	if _tab_district_btn != null:
		_tab_district_btn.add_theme_stylebox_override("normal", _make_panel_box(COL_BG_DEEP, COL_AMBER if (not show_city) else COL_BRASS, 2 if (not show_city) else 1, 6))
	_position_city_buttons()


func _position_city_buttons() -> void:
	if _full_canvas == null:
		return
	var rect: Rect2 = Rect2(Vector2.ZERO, _full_canvas.size)
	for i in range(mini(_district_buttons.size(), CITY_NODE_UV.size())):
		var pt: Vector2 = _city_point(i, rect)
		_district_buttons[i].position = pt - Vector2(28.0, 28.0)
		_district_buttons[i].size = Vector2(56.0, 56.0)


func _select_district(idx: int) -> void:
	_selected_district_idx = clampi(idx, 0, TOTAL_DISTRICTS - 1)
	_refresh_selected_district_info()
	_redraw_all()
	district_inspected.emit(_selected_district_idx)


func _refresh_selected_district_info() -> void:
	if _info_lbl == null:
		return
	var d_num: int = _selected_district_idx + 1
	var d_key: String = "DISTRICT_NAME_%02d" % d_num
	var d_name: String = I18nSync.t(d_key, {})
	var status_str: String = ""
	if _completed_districts.has(_selected_district_idx):
		status_str = I18nSync.t("MAP_STATUS_RESTORED", {})
	elif _selected_district_idx == _current_district_idx:
		status_str = I18nSync.t("MAP_STATUS_CURRENT", {"step": _current_step})
	elif _selected_district_idx == _current_district_idx + 1 and _exit_gate_unlocked:
		status_str = I18nSync.t("MAP_STATUS_UNLOCKED", {})
	else:
		status_str = I18nSync.t("MAP_STATUS_LOCKED", {})
	_info_lbl.text = "%02d. %s  —  %s" % [d_num, d_name, status_str]


func _redraw_all() -> void:
	if _mini_canvas != null:
		_mini_canvas.queue_redraw()
	if _full_canvas != null and _is_full_open:
		_full_canvas.queue_redraw()


func _refresh_fog_texture() -> void:
	if not _fog_dirty or _fog_image == null:
		return
	if _fog_tex == null:
		_fog_tex = ImageTexture.create_from_image(_fog_image)
	else:
		_fog_tex.update(_fog_image)
	_fog_dirty = false


func _sync_player() -> void:
	var node: Node = get_tree().get_first_node_in_group("player")
	if node is Node3D:
		var p: Node3D = node as Node3D
		_player_pos = Vector2(p.global_position.x, p.global_position.z)
		_player_yaw = p.global_rotation.y


func _draw_minimap() -> void:
	if _mini_canvas == null:
		return
	_draw_district_fog_view(_mini_canvas, _mini_fog, _mini_marks, Rect2(Vector2.ZERO, _mini_canvas.size), true)


func _draw_full_map() -> void:
	if _full_canvas == null:
		return
	var rect: Rect2 = Rect2(Vector2.ZERO, _full_canvas.size)
	if _active_tab == 0:
		_draw_district_fog_view(_full_canvas, _full_fog, _full_marks, rect, false)
	else:
		_draw_city_progression_view(_full_canvas, rect)


func _draw_district_fog_view(canvas: Control, fog_layer: Control, marks_layer: Control, rect: Rect2, is_mini: bool) -> void:
	_sync_player()
	_refresh_fog_texture()
	var view_min: Vector2 = _world_min
	var view_span: Vector2 = _world_max - _world_min
	if is_mini:
		var half: float = MINI_HALF_SPAN_M
		var cx: float = clampf(_player_pos.x, _world_min.x + half, _world_max.x - half)
		var cy: float = clampf(_player_pos.y, _world_min.y + half, _world_max.y - half)
		view_min = Vector2(cx - half, cy - half)
		view_span = Vector2(half * 2.0, half * 2.0)
	if view_span.x <= 0.1 or view_span.y <= 0.1:
		return
	_fog_view_min = view_min
	_fog_view_span = view_span

	# Deep blueprint ground of the explored city.
	canvas.draw_rect(rect, UnslopVisualTheme.COL_MAP_BG, true)

	# Thin blueprint grid. Every segment used to be its own draw_line, and a
	# 48 m minimap window carries ~14 of them; draw_multiline puts the whole
	# grid into ONE draw call.
	var grid_step: float = 8.0
	var grid_lines := PackedVector2Array()
	var gx: float = floorf(view_min.x / grid_step) * grid_step
	while gx <= view_min.x + view_span.x:
		var px: float = rect.position.x + (gx - view_min.x) / view_span.x * rect.size.x
		grid_lines.append(Vector2(px, rect.position.y))
		grid_lines.append(Vector2(px, rect.end.y))
		gx += grid_step
	var gz: float = floorf(view_min.y / grid_step) * grid_step
	while gz <= view_min.y + view_span.y:
		var py: float = rect.position.y + (gz - view_min.y) / view_span.y * rect.size.y
		grid_lines.append(Vector2(rect.position.x, py))
		grid_lines.append(Vector2(rect.end.x, py))
		gz += grid_step
	if grid_lines.size() >= 2:
		canvas.draw_multiline(grid_lines, COL_GRID, 1.0, true)

	# Street bands.
	var street_w: float = maxf(2.0, rect.size.x / view_span.x * 3.0)
	var street_lines := PackedVector2Array()
	var sx: float = floorf(view_min.x / STREET_STEP_M) * STREET_STEP_M
	while sx <= view_min.x + view_span.x:
		var px: float = rect.position.x + (sx - view_min.x) / view_span.x * rect.size.x
		street_lines.append(Vector2(px, rect.position.y))
		street_lines.append(Vector2(px, rect.end.y))
		sx += STREET_STEP_M
	var sz: float = floorf(view_min.y / STREET_STEP_M) * STREET_STEP_M
	while sz <= view_min.y + view_span.y:
		var py: float = rect.position.y + (sz - view_min.y) / view_span.y * rect.size.y
		street_lines.append(Vector2(rect.position.x, py))
		street_lines.append(Vector2(rect.end.x, py))
		sz += STREET_STEP_M
	if street_lines.size() >= 2:
		canvas.draw_multiline(street_lines, UnslopVisualTheme.COL_MAP_STREET, street_w, true)

	# REAL building footprints from skyline, drawn as a filled plan with a crisp
	# edge. The outlines of the whole plan go into ONE draw_multiline; only the
	# fills stay one call each.
	var edges := PackedVector2Array()
	for b: Rect2 in _buildings:
		var rp: Vector2 = _world_to_rect(b.position, rect, view_min, view_span)
		var re: Vector2 = _world_to_rect(b.end, rect, view_min, view_span)
		var br: Rect2 = Rect2(rp, re - rp)
		if not br.intersects(rect):
			continue
		canvas.draw_rect(br, UnslopVisualTheme.COL_MAP_BLDG_FILL, true)
		# draw_multiline takes PAIRS of points, one segment each - so a
		# rectangle contributes four pairs, not five points.
		edges.append(br.position)
		edges.append(Vector2(br.end.x, br.position.y))
		edges.append(Vector2(br.end.x, br.position.y))
		edges.append(br.end)
		edges.append(br.end)
		edges.append(Vector2(br.position.x, br.end.y))
		edges.append(Vector2(br.position.x, br.end.y))
		edges.append(br.position)
	if edges.size() >= 2:
		canvas.draw_multiline(edges, UnslopVisualTheme.COL_MAP_BLDG_EDGE, 1.5, true)

	# Soft-edged fog multiplication over the plan, then crisp marks above it.
	if fog_layer != null:
		fog_layer.queue_redraw()
	if marks_layer != null:
		marks_layer.queue_redraw()


func _draw_marks(layer: Control, is_mini: bool) -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, layer.size)
	var view_min: Vector2 = _fog_view_min
	var view_span: Vector2 = _fog_view_span
	if view_span.x <= 0.1 or view_span.y <= 0.1:
		return

	# Soft amber halos for lit streetlamps. One soft ring instead of four
	# stacked circles: the full city map carries every lamp of the district,
	# and four circles each were four draw calls per lamp - the single biggest
	# draw-call cost in the whole HUD. Every ring of the map now goes into one
	# draw_multiline, so the whole district of lamps costs one call.
	var rings := PackedVector2Array()
	var dots := PackedVector2Array()
	var ring_w: float = 2.0
	for lamp: Vector2 in _lit_lamps:
		var lp: Vector2 = _world_to_rect(lamp, rect, view_min, view_span)
		var hr: float = maxf(7.0, rect.size.x / view_span.x * 5.0)
		ring_w = maxf(2.0, hr * 0.34)
		_append_ring(rings, lp, hr * 0.82, 14)
		dots.append(lp)
		dots.append(lp)
	if rings.size() >= 2:
		layer.draw_multiline(rings, Color(COL_AMBER.r, COL_AMBER.g, COL_AMBER.b, 0.09), ring_w, true)
	if dots.size() >= 2:
		layer.draw_multiline(dots, COL_AMBER, 2.0, true)

	# Amber player arrow, always visible above the fog.
	var pp: Vector2 = _world_to_rect(_player_pos, rect, view_min, view_span)
	UnslopVisualTheme.draw_player_arrow(layer, pp, _player_yaw, 6.0 if is_mini else 9.0)
	map_player_arrow_drawn = true

	if _exit_gate_exists and _is_world_point_revealed(_exit_gate_pos):
		var gp: Vector2 = _world_to_rect(_exit_gate_pos, rect, view_min, view_span)
		var hw: float = 3.0 if is_mini else 6.0
		layer.draw_line(gp - Vector2(hw, 0.0), gp + Vector2(hw, 0.0), COL_BRASS, 2.0, true)

	UnslopVisualTheme.draw_corner_ticks(layer, rect, 7.0, COL_BRASS)
	layer.draw_rect(rect, COL_BRASS * Color(1.0, 1.0, 1.0, 0.45), false, 1.0)


## A ring as the flat point pairs draw_multiline expects: every edge of the
## polygon is written out twice, so one call can carry many rings.
func _append_ring(out: PackedVector2Array, center: Vector2, radius: float, segments: int) -> void:
	var prev: Vector2 = center + Vector2(radius, 0.0)
	for i in range(1, segments + 1):
		var a: float = TAU * float(i) / float(segments)
		var p: Vector2 = center + Vector2(cos(a), sin(a)) * radius
		out.append(prev)
		out.append(p)
		prev = p


func _draw_fog_layer(layer: Control) -> void:
	if _fog_tex == null:
		return
	var world_span: Vector2 = _world_max - _world_min
	if world_span.x <= 0.1 or world_span.y <= 0.1:
		return
	var u0: float = clampf((_fog_view_min.x - _world_min.x) / world_span.x, 0.0, 1.0)
	var v0: float = clampf((_fog_view_min.y - _world_min.y) / world_span.y, 0.0, 1.0)
	var u1: float = clampf((_fog_view_min.x + _fog_view_span.x - _world_min.x) / world_span.x, 0.0, 1.0)
	var v1: float = clampf((_fog_view_min.y + _fog_view_span.y - _world_min.y) / world_span.y, 0.0, 1.0)
	if u1 <= u0 or v1 <= v0:
		return
	var region := Rect2(u0 * float(FOG_GRID_RES), v0 * float(FOG_GRID_RES),
		(u1 - u0) * float(FOG_GRID_RES), (v1 - v0) * float(FOG_GRID_RES))
	layer.draw_texture_rect_region(_fog_tex, Rect2(Vector2.ZERO, layer.size), region)


func _draw_city_progression_view(canvas: Control, rect: Rect2) -> void:
	canvas.draw_rect(rect, UnslopVisualTheme.COL_MAP_BG, true)

	# Night-city schematic: quarter blocks. The outline of every block used to
	# be its own draw_rect, so the grid cost fifty-six calls; one
	# draw_multiline carries all of them.
	var cols: int = 7
	var rows: int = 4
	var cell: Vector2 = Vector2(rect.size.x / float(cols), rect.size.y / float(rows))
	var quarter_edges := PackedVector2Array()
	for gy in range(rows):
		for gx in range(cols):
			var q: Rect2 = Rect2(rect.position + Vector2(float(gx) * cell.x, float(gy) * cell.y) + Vector2(5.0, 5.0),
				Vector2(maxf(1.0, cell.x - 10.0), maxf(1.0, cell.y - 10.0)))
			canvas.draw_rect(q, COL_QUARTER, true)
			quarter_edges.append(q.position); quarter_edges.append(Vector2(q.end.x, q.position.y))
			quarter_edges.append(Vector2(q.end.x, q.position.y)); quarter_edges.append(q.end)
			quarter_edges.append(q.end); quarter_edges.append(Vector2(q.position.x, q.end.y))
			quarter_edges.append(Vector2(q.position.x, q.end.y)); quarter_edges.append(q.position)
	if quarter_edges.size() >= 2:
		canvas.draw_multiline(quarter_edges, Color(0.14, 0.20, 0.23, 0.6), 1.0, true)

	# River silhouette.
	var river := PackedVector2Array([
		Vector2(rect.position.x, rect.position.y + rect.size.y * 0.82),
		Vector2(rect.position.x + rect.size.x * 0.28, rect.position.y + rect.size.y * 0.60),
		Vector2(rect.position.x + rect.size.x * 0.60, rect.position.y + rect.size.y * 0.68),
		Vector2(rect.end.x, rect.position.y + rect.size.y * 0.32),
	])
	canvas.draw_polyline(river, COL_RIVER, maxf(10.0, rect.size.y * 0.035), true)
	canvas.draw_polyline(river, Color(0.10, 0.20, 0.23, 0.5), 1.0, true)

	# Highway silhouette.
	var highway := PackedVector2Array([
		Vector2(rect.position.x, rect.position.y + rect.size.y * 0.16),
		Vector2(rect.position.x + rect.size.x * 0.34, rect.position.y + rect.size.y * 0.28),
		Vector2(rect.position.x + rect.size.x * 0.68, rect.position.y + rect.size.y * 0.14),
		Vector2(rect.end.x, rect.position.y + rect.size.y * 0.22),
	])
	canvas.draw_polyline(highway, COL_HIGHWAY, 5.0, true)
	canvas.draw_polyline(highway, COL_BRASS * Color(1.0, 1.0, 1.0, 0.22), 1.0, true)

	# Smooth route line, coloured per completed segment. Ten polylines became
	# two: the lit run and the dark run each go into one draw_multiline.
	var pts: Array[Vector2] = []
	for i in range(TOTAL_DISTRICTS):
		pts.append(_city_point(i, rect))
	var route_lit := PackedVector2Array()
	var route_dark := PackedVector2Array()
	for i in range(TOTAL_DISTRICTS - 1):
		var prev: Vector2 = pts[maxi(0, i - 1)]
		var next: Vector2 = pts[mini(TOTAL_DISTRICTS - 1, i + 2)]
		var curve: PackedVector2Array = _smooth_segment(pts[i], pts[i + 1], prev, next, 10)
		var lit: bool = _completed_districts.has(i) or (i == _current_district_idx and _exit_gate_unlocked)
		if lit:
			for k in range(curve.size() - 1):
				route_lit.append(curve[k])
				route_lit.append(curve[k + 1])
		else:
			for k in range(curve.size() - 1):
				route_dark.append(curve[k])
				route_dark.append(curve[k + 1])
	if route_lit.size() >= 2:
		canvas.draw_multiline(route_lit, COL_AMBER, 3.0, true)
	if route_dark.size() >= 2:
		canvas.draw_multiline(route_dark, COL_ROUTE_DARK, 2.0, true)

	# District nodes with localized RU/EN names placed without overlap.
	# The rims of the eleven nodes used to be eleven draw_arc calls; they now
	# share one draw_multiline.
	var font: Font = ThemeDB.fallback_font
	var placed: Array[Rect2] = []
	var rim_brass := PackedVector2Array()
	var rim_dim := PackedVector2Array()
	var rim_cur := PackedVector2Array()
	var rim_sel := PackedVector2Array()
	for i in range(TOTAL_DISTRICTS):
		var p: Vector2 = pts[i]
		var is_done: bool = _completed_districts.has(i)
		var is_cur: bool = (i == _current_district_idx)
		var is_sel: bool = (i == _selected_district_idx)
		if is_cur:
			canvas.draw_circle(p, 26.0, Color(COL_AMBER.r, COL_AMBER.g, COL_AMBER.b, 0.20))
			_append_ring(rim_cur, p, 22.0, 24)
		if is_sel:
			_append_ring(rim_sel, p, 28.0, 24)
		var fill_c: Color = COL_AMBER if is_done else (Color(0.28, 0.24, 0.14, 1.0) if is_cur else Color(0.10, 0.15, 0.18, 1.0))
		canvas.draw_circle(p, 15.0, fill_c)
		if is_done or is_cur:
			_append_ring(rim_brass, p, 15.0, 20)
		else:
			_append_ring(rim_dim, p, 15.0, 20)
		if font != null:
			canvas.draw_string(font, p + Vector2(-8.0, 5.0), "%02d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
				COL_BG_DEEP if is_done else COL_TEXT_MAIN)
			var name_key := "DISTRICT_NAME_%02d" % (i + 1)
			var nm: String = I18nSync.t(name_key, {})
			var tw: float = font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			var cands: Array[Vector2] = [
				p + Vector2(-tw * 0.5, 24.0),
				p + Vector2(-tw * 0.5, -36.0),
				p + Vector2(-tw * 0.5, 42.0),
				p + Vector2(-tw * 0.5, -54.0),
			]
			for c in cands:
				var cpos: Vector2 = Vector2(clampf(c.x, rect.position.x + 3.0, rect.end.x - tw - 3.0),
					clampf(c.y, rect.position.y + 3.0, rect.end.y - 16.0))
				var lr: Rect2 = Rect2(cpos, Vector2(tw + 6.0, 15.0))
				if _rect_free(lr, placed):
					placed.append(lr)
					canvas.draw_string(font, cpos, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COL_TEXT_MUTED)
					break
	if rim_brass.size() >= 2:
		canvas.draw_multiline(rim_brass, COL_BRASS, 2.0, true)
	if rim_dim.size() >= 2:
		canvas.draw_multiline(rim_dim, Color(0.32, 0.38, 0.42, 0.8), 2.0, true)
	if rim_cur.size() >= 2:
		canvas.draw_multiline(rim_cur, COL_AMBER, 2.5, true)
	if rim_sel.size() >= 2:
		canvas.draw_multiline(rim_sel, COL_TEXT_MAIN, 1.5, true)
	UnslopVisualTheme.draw_corner_ticks(canvas, rect, 8.0, COL_BRASS)
	canvas.draw_rect(rect, COL_BRASS * Color(1.0, 1.0, 1.0, 0.55), false, 1.5)


func _city_point(i: int, rect: Rect2) -> Vector2:
	return Vector2(rect.position.x + CITY_NODE_UV[i].x * rect.size.x,
		rect.position.y + CITY_NODE_UV[i].y * rect.size.y)


func _smooth_segment(a: Vector2, b: Vector2, prev: Vector2, next: Vector2, steps: int) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var c1: Vector2 = a + (b - prev) * 0.16
	var c2: Vector2 = b - (next - a) * 0.16
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var u: float = 1.0 - t
		out.append(u * u * u * a + 3.0 * u * u * t * c1 + 3.0 * u * t * t * c2 + t * t * t * b)
	return out


func _rect_free(candidate: Rect2, others: Array[Rect2]) -> bool:
	for r: Rect2 in others:
		if candidate.grow(2.0).intersects(r):
			return false
	return true


func _is_world_point_revealed(pt: Vector2) -> bool:
	var span: Vector2 = _world_max - _world_min
	if not Rect2(_world_min, span).has_point(pt):
		return false
	var gx: int = clampi(int(floorf(((pt.x - _world_min.x) / span.x) * float(FOG_GRID_RES))), 0, FOG_GRID_RES - 1)
	var gz: int = clampi(int(floorf(((pt.y - _world_min.y) / span.y) * float(FOG_GRID_RES))), 0, FOG_GRID_RES - 1)
	return _fog_cells[gz * FOG_GRID_RES + gx] != 0


func _world_to_rect(pt: Vector2, rect: Rect2, view_min: Vector2, view_span: Vector2) -> Vector2:
	return Vector2(
		rect.position.x + (pt.x - view_min.x) / maxf(0.1, view_span.x) * rect.size.x,
		rect.position.y + (pt.y - view_min.y) / maxf(0.1, view_span.y) * rect.size.y)


func _make_action_btn(min_w: float, min_h: float) -> Button:
	var b: Button = Button.new()
	b.custom_minimum_size = Vector2(min_w, min_h)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", COL_TEXT_MAIN)
	b.add_theme_stylebox_override("normal", _make_panel_box(COL_BG_DEEP, COL_BRASS, 1, 6))
	b.add_theme_stylebox_override("hover", _make_panel_box(COL_BG_DEEP, COL_AMBER, 2, 6))
	b.add_theme_stylebox_override("pressed", _make_panel_box(COL_BG_DEEP, COL_AMBER, 2, 6))
	return b


func _make_panel_box(bg: Color, border: Color, border_w: int, radius: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = border_w
	sb.border_width_top = border_w
	sb.border_width_right = border_w
	sb.border_width_bottom = border_w
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb
