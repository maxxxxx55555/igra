class_name Wave2ProgressionMap
extends CanvasLayer

## Dual-layer Map & Progression System for The Last Streetlight:
## 1) Always-visible clickable Progression Minimap (top-right safe area) showing current district
##    illumination-only fog-of-war + district progression pill.
## 2) Clicking/tapping the minimap (or pressing toggle_map / M) opens the Full Game Overview Map
##    with 2 tabs: [District Illumination Map] and [Full City 11-District Progression Map].
## HARD RULE: NEVER accepts or displays enemies, scrap, batteries, or any loot items.

signal map_opened
signal map_closed
signal district_inspected(district_index: int)

const COL_BG_DARK: Color = Color(0.0588, 0.0745, 0.0784, 0.92)      # #0f1314
const COL_BG_DEEP: Color = Color(0.0235, 0.0588, 0.0745, 0.96)      # #060f13
const COL_BRASS: Color = Color(0.7882, 0.6353, 0.2902, 1.0)         # #c9a24a
const COL_AMBER: Color = Color(0.8314, 0.6627, 0.3059, 1.0)         # #d4a94e
const COL_TEXT_MAIN: Color = Color(0.902, 0.871, 0.784, 1.0)        # #e6dec8
const COL_TEXT_MUTED: Color = Color(0.569, 0.620, 0.643, 1.0)       # #919ea4
const COL_BLDG_REVEALED: Color = Color(0.184, 0.243, 0.278, 0.95)
const COL_FOG_UNSEEN: Color = Color(0.024, 0.039, 0.047, 0.96)
const COL_LIT_GROUND: Color = Color(0.118, 0.165, 0.188, 0.92)

const TOTAL_DISTRICTS: int = 11
const FOG_GRID_RES: int = 64

var _world_min: Vector2 = Vector2(-60.0, -60.0)
var _world_max: Vector2 = Vector2(60.0, 60.0)
var _fog_cells: PackedByteArray = PackedByteArray()
var _buildings: Array[Rect2] = []
var _lit_lamps: Array[Vector2] = []
var _exit_gate_pos: Vector2 = Vector2.ZERO
var _exit_gate_exists: bool = false
var _exit_gate_unlocked: bool = false
var _player_pos: Vector2 = Vector2.ZERO
var _player_yaw: float = 0.0

var _current_district_idx: int = 0
var _completed_districts: Dictionary = {}
var _current_step: int = 1
var _selected_district_idx: int = 0
var _active_tab: int = 1  # 0 = District Illumination Map, 1 = Full City 11-District Map
var _is_full_open: bool = false

# UI nodes
var _mini_btn: Button = null
var _mini_canvas: Control = null
var _mini_title: Label = null
var _mini_hint: Label = null
var _overlay_root: Control = null
var _title_lbl: Label = null
var _tab_district_btn: Button = null
var _tab_city_btn: Button = null
var _close_btn: Button = null
var _full_canvas: Control = null
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
	_fog_cells.resize(FOG_GRID_RES * FOG_GRID_RES)
	_fog_cells.fill(0)
	_build_ui()
	_layout_safe_area()
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_layout_safe_area):
		get_viewport().size_changed.connect(_layout_safe_area)
	refresh_localization()


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


func configure_district(district_index: int, world_min_xz: Vector2, world_max_xz: Vector2, building_rects: Array[Rect2], gate_xz: Vector2, has_gate: bool) -> void:
	_current_district_idx = clampi(district_index, 0, TOTAL_DISTRICTS - 1)
	_selected_district_idx = _current_district_idx
	_world_min = world_min_xz
	_world_max = Vector2(maxf(world_min_xz.x + 8.0, world_max_xz.x), maxf(world_min_xz.y + 8.0, world_max_xz.y))
	_buildings = building_rects.duplicate()
	_lit_lamps.clear()
	_exit_gate_pos = gate_xz
	_exit_gate_exists = has_gate
	_exit_gate_unlocked = false
	_fog_cells.fill(0)
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


func update_player_illumination(player_world_pos: Vector3, player_yaw_rad: float, flashlight_on: bool, flashlight_range_m: float = 12.0, ambient_reveal_m: float = 3.2) -> void:
	_player_pos = Vector2(player_world_pos.x, player_world_pos.z)
	_player_yaw = player_yaw_rad
	reveal_circle(_player_pos, ambient_reveal_m)
	if flashlight_on and flashlight_range_m > 0.5:
		var fwd: Vector2 = Vector2(-sin(player_yaw_rad), -cos(player_yaw_rad)).normalized()
		var samples: int = 5
		for s in range(1, samples + 1):
			var frac: float = float(s) / float(samples)
			var sample_pt: Vector2 = _player_pos + fwd * (flashlight_range_m * frac)
			var cone_r: float = lerpf(1.8, 4.4, frac)
			reveal_circle(sample_pt, cone_r)
	_redraw_all()


func register_lit_streetlight(lamp_world_pos: Vector3, light_radius_m: float = 9.0) -> void:
	var pt: Vector2 = Vector2(lamp_world_pos.x, lamp_world_pos.z)
	for existing in _lit_lamps:
		if existing.distance_squared_to(pt) < 1.0:
			return
	_lit_lamps.append(pt)
	reveal_circle(pt, light_radius_m)
	_redraw_all()


func reveal_circle(center_xz: Vector2, radius_m: float) -> void:
	var span: Vector2 = _world_max - _world_min
	if span.x <= 0.1 or span.y <= 0.1:
		return
	var r2: float = radius_m * radius_m
	var gx_min: int = clampi(int(floorf(((center_xz.x - radius_m - _world_min.x) / span.x) * float(FOG_GRID_RES))), 0, FOG_GRID_RES - 1)
	var gx_max: int = clampi(int(ceilf(((center_xz.x + radius_m - _world_min.x) / span.x) * float(FOG_GRID_RES))), 0, FOG_GRID_RES - 1)
	var gz_min: int = clampi(int(floorf(((center_xz.y - radius_m - _world_min.y) / span.y) * float(FOG_GRID_RES))), 0, FOG_GRID_RES - 1)
	var gz_max: int = clampi(int(ceilf(((center_xz.y + radius_m - _world_min.y) / span.y) * float(FOG_GRID_RES))), 0, FOG_GRID_RES - 1)

	for gz in range(gz_min, gz_max + 1):
		var wz: float = _world_min.y + ((float(gz) + 0.5) / float(FOG_GRID_RES)) * span.y
		var row_off: int = gz * FOG_GRID_RES
		for gx in range(gx_min, gx_max + 1):
			var wx: float = _world_min.x + ((float(gx) + 0.5) / float(FOG_GRID_RES)) * span.x
			var dx: float = wx - center_xz.x
			var dz: float = wz - center_xz.y
			if (dx * dx + dz * dz) <= r2:
				_fog_cells[row_off + gx] = 1


func toggle_full_map() -> void:
	if _is_full_open:
		close_full_map()
	else:
		open_full_map(1)  # Opens Full City Progression Map by default on click, with instant switch to District Map


func open_full_map(default_tab: int = 1) -> void:
	_is_full_open = true
	_active_tab = clampi(default_tab, 0, 1)
	if _overlay_root != null:
		_overlay_root.visible = true
	_update_tab_visuals()
	_redraw_all()
	map_opened.emit()


func close_full_map() -> void:
	_is_full_open = false
	if _overlay_root != null:
		_overlay_root.visible = false
	map_closed.emit()


func is_full_map_open() -> bool:
	return _is_full_open


func refresh_localization() -> void:
	if _mini_title != null:
		_mini_title.text = _tr_fmt("MAP_MINI_HEADER", {"cur": _current_district_idx + 1, "total": TOTAL_DISTRICTS}, "РАЙОН {cur}/{total}", "DISTRICT {cur}/{total}")
	if _mini_hint != null:
		_mini_hint.text = _tr_fmt("MAP_MINI_TAP_HINT", {}, "КАРТА", "MAP")
	if _title_lbl != null:
		_title_lbl.text = _tr_fmt("MAP_TITLE_FULL", {}, "КАРТА ГОРОДА И ПРОДВИЖЕНИЯ", "CITY & PROGRESSION MAP")
	if _tab_district_btn != null:
		_tab_district_btn.text = _tr_fmt("MAP_TAB_DISTRICT", {}, "ТЕКУЩИЙ РАЙОН", "CURRENT DISTRICT")
	if _tab_city_btn != null:
		_tab_city_btn.text = _tr_fmt("MAP_TAB_CITY", {}, "ОБЩАЯ КАРТА (11)", "FULL CITY MAP (11)")
	if _close_btn != null:
		_close_btn.text = _tr_fmt("UI_CLOSE", {}, "ЗАКРЫТЬ", "CLOSE")
	if _legend_lbl != null:
		if _active_tab == 0:
			_legend_lbl.text = _tr_fmt("MAP_LEGEND_DISTRICT", {}, "Открываются только освещённые зоны и здания. Враги и предметы скрыты.", "Only illuminated zones and buildings are charted. Enemies and items stay hidden.")
		else:
			_legend_lbl.text = _tr_fmt("MAP_LEGEND_CITY", {}, "Янтарный — пройден  |  Кольцо — вы здесь  |  Тёмный — закрыт", "Amber — restored  |  Ring — you are here  |  Dark — locked")
	_refresh_selected_district_info()


func _build_ui() -> void:
	# 1. Clickable Top-Right Progression Minimap Button (comfortable touch target, brass style)
	_mini_btn = Button.new()
	_mini_btn.name = "ProgressionMinimapButton"
	_mini_btn.custom_minimum_size = Vector2(152.0, 96.0)
	_mini_btn.focus_mode = Control.FOCUS_NONE
	_mini_btn.add_theme_stylebox_override("normal", _make_panel_box(COL_BG_DARK, COL_BRASS, 2, 6))
	_mini_btn.add_theme_stylebox_override("hover", _make_panel_box(COL_BG_DARK, COL_AMBER, 2, 6))
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
	_mini_canvas.draw.connect(_draw_minimap)
	_mini_btn.add_child(_mini_canvas)

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

	# 2. Full-Screen Expandable Overview Map Modal
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

	# Header Row (Title + Tabs + Comfortable >=52px Close Button)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	_title_lbl = Label.new()
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_lbl.add_theme_font_size_override("font_size", 20)
	_title_lbl.add_theme_color_override("font_color", COL_BRASS)
	header.add_child(_title_lbl)

	_tab_city_btn = _make_action_btn("FULL CITY", 180.0, 52.0)
	_tab_city_btn.pressed.connect(func() -> void: _set_tab(1))
	header.add_child(_tab_city_btn)

	_tab_district_btn = _make_action_btn("DISTRICT", 180.0, 52.0)
	_tab_district_btn.pressed.connect(func() -> void: _set_tab(0))
	header.add_child(_tab_district_btn)

	_close_btn = _make_action_btn("CLOSE", 128.0, 52.0)
	_close_btn.pressed.connect(close_full_map)
	header.add_child(_close_btn)

	# Interactive Map Canvas
	_full_canvas = Control.new()
	_full_canvas.name = "FullMapCanvas"
	_full_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_full_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_full_canvas.draw.connect(_draw_full_map)
	_full_canvas.resized.connect(_position_city_buttons)
	vbox.add_child(_full_canvas)

	# Clickable transparent buttons over the 11 district nodes on City Map
	_district_buttons.clear()
	for i in range(TOTAL_DISTRICTS):
		var db: Button = Button.new()
		db.name = "CityNodeBtn_%d" % i
		db.flat = true
		db.custom_minimum_size = Vector2(54.0, 54.0)
		db.focus_mode = Control.FOCUS_NONE
		var captured_i: int = i
		db.pressed.connect(func() -> void: _select_district(captured_i))
		_full_canvas.add_child(db)
		_district_buttons.append(db)

	# Footer: Selected District Info + Illumination Legend
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


func _layout_safe_area() -> void:
	if _mini_btn == null or get_viewport() == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var safe_r: Rect2i = DisplayServer.get_display_safe_area()
	var right_inset: float = maxf(16.0, vp_size.x - float(safe_r.position.x + safe_r.size.x)) if safe_r.size.x > 0 else 16.0
	var top_inset: float = maxf(14.0, float(safe_r.position.y)) if safe_r.size.y > 0 else 14.0
	# Place progression minimap cleanly left of the Pause button at Top-Right
	_mini_btn.position = Vector2(vp_size.x - right_inset - 232.0, top_inset)
	_mini_btn.size = Vector2(154.0, 96.0)
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
	if _tab_city_btn != null:
		_tab_city_btn.add_theme_stylebox_override("normal", _make_panel_box(COL_BG_DARK, COL_AMBER if show_city else COL_BRASS, 2 if show_city else 1, 6))
	if _tab_district_btn != null:
		_tab_district_btn.add_theme_stylebox_override("normal", _make_panel_box(COL_BG_DARK, COL_AMBER if (not show_city) else COL_BRASS, 2 if (not show_city) else 1, 6))
	_position_city_buttons()


func _position_city_buttons() -> void:
	if _full_canvas == null:
		return
	var sz: Vector2 = _full_canvas.size
	for i in range(mini(_district_buttons.size(), CITY_NODE_UV.size())):
		var pt: Vector2 = Vector2(CITY_NODE_UV[i].x * sz.x, CITY_NODE_UV[i].y * sz.y)
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
	var d_name: String = _tr_fmt("DISTRICT_NAME_%02d" % d_num, {}, "Район %d" % d_num, "District %d" % d_num)
	var status_str: String = ""
	if _completed_districts.has(_selected_district_idx):
		status_str = _tr_fmt("MAP_STATUS_RESTORED", {}, "Освещён и пройден", "Restored & cleared")
	elif _selected_district_idx == _current_district_idx:
		status_str = _tr_fmt("MAP_STATUS_CURRENT", {"step": _current_step}, "Текущий район (этап {step}/3)", "Current district (step {step}/3)")
	elif _selected_district_idx == _current_district_idx + 1 and _exit_gate_unlocked:
		status_str = _tr_fmt("MAP_STATUS_UNLOCKED", {}, "Ворота открыты — можно перейти", "Gate open — ready to enter")
	else:
		status_str = _tr_fmt("MAP_STATUS_LOCKED", {}, "Во тьме (не открыт)", "In darkness (locked)")
	_info_lbl.text = "%02d. %s  —  %s" % [d_num, d_name, status_str]


func _redraw_all() -> void:
	if _mini_canvas != null:
		_mini_canvas.queue_redraw()
	if _full_canvas != null and _is_full_open:
		_full_canvas.queue_redraw()


func _draw_minimap() -> void:
	if _mini_canvas == null:
		return
	_draw_district_fog_view(_mini_canvas, _mini_canvas.get_rect(), true)


func _draw_full_map() -> void:
	if _full_canvas == null:
		return
	var rect: Rect2 = Rect2(Vector2.ZERO, _full_canvas.size)
	if _active_tab == 0:
		_draw_district_fog_view(_full_canvas, rect, false)
	else:
		_draw_city_progression_view(_full_canvas, rect)


func _draw_district_fog_view(canvas: Control, rect: Rect2, is_mini: bool) -> void:
	canvas.draw_rect(rect, COL_FOG_UNSEEN, true)
	var span: Vector2 = _world_max - _world_min
	if span.x <= 0.1 or span.y <= 0.1:
		return

	var cw: float = rect.size.x / float(FOG_GRID_RES)
	var ch: float = rect.size.y / float(FOG_GRID_RES)
	for gz in range(FOG_GRID_RES):
		var row_off: int = gz * FOG_GRID_RES
		for gx in range(FOG_GRID_RES):
			if _fog_cells[row_off + gx] != 0:
				canvas.draw_rect(Rect2(rect.position.x + float(gx) * cw, rect.position.y + float(gz) * ch, cw + 0.6, ch + 0.6), COL_LIT_GROUND, true)

	# Draw revealed building footprints ONLY where light touched them (zero enemies, zero loot!)
	for b in _buildings:
		if not _is_world_point_revealed(b.get_center()):
			continue
		var p0: Vector2 = _world_to_rect(b.position, rect)
		var p1: Vector2 = _world_to_rect(b.end, rect)
		var br: Rect2 = Rect2(p0, p1 - p0).abs()
		canvas.draw_rect(br, COL_BLDG_REVEALED, true)
		if not is_mini:
			canvas.draw_rect(br, COL_BRASS * Color(1.0, 1.0, 1.0, 0.45), false, 1.2)

	# Draw lit streetlights (safe zones)
	for lamp in _lit_lamps:
		var lp: Vector2 = _world_to_rect(lamp, rect)
		canvas.draw_circle(lp, 4.0 if is_mini else 8.0, Color(COL_AMBER.r, COL_AMBER.g, COL_AMBER.b, 0.28))
		canvas.draw_circle(lp, 2.0 if is_mini else 4.0, COL_AMBER)

	# Draw district exit gate (shown once illuminated or unlocked)
	if _exit_gate_exists and (_exit_gate_unlocked or _is_world_point_revealed(_exit_gate_pos)):
		var gp: Vector2 = _world_to_rect(_exit_gate_pos, rect)
		var g_col: Color = COL_AMBER if _exit_gate_unlocked else Color(0.65, 0.25, 0.20, 0.9)
		var r_sz: float = 4.0 if is_mini else 8.0
		canvas.draw_rect(Rect2(gp - Vector2(r_sz, r_sz * 0.6), Vector2(r_sz * 2.0, r_sz * 1.2)), g_col, true)

	# Draw player directional chevron
	var pp: Vector2 = _world_to_rect(_player_pos, rect)
	var fwd: Vector2 = Vector2(-sin(_player_yaw), -cos(_player_yaw)).normalized()
	var side: Vector2 = Vector2(-fwd.y, fwd.x)
	var tip_len: float = 5.5 if is_mini else 11.0
	var wing: float = 3.5 if is_mini else 6.5
	var tri: PackedVector2Array = PackedVector2Array([
		pp + fwd * tip_len,
		pp - fwd * (tip_len * 0.55) + side * wing,
		pp - fwd * (tip_len * 0.55) - side * wing,
	])
	canvas.draw_colored_polygon(tri, COL_TEXT_MAIN)
	canvas.draw_rect(rect, COL_BRASS * Color(1.0, 1.0, 1.0, 0.55), false, 1.0)


func _draw_city_progression_view(canvas: Control, rect: Rect2) -> void:
	canvas.draw_rect(rect, COL_BG_DARK, true)
	# Subtle grid lines
	for gx in range(1, 10):
		var x: float = rect.position.x + rect.size.x * (float(gx) / 10.0)
		canvas.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(0.12, 0.16, 0.19, 0.35), 1.0)
	for gy in range(1, 6):
		var y: float = rect.position.y + rect.size.y * (float(gy) / 6.0)
		canvas.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(0.12, 0.16, 0.19, 0.35), 1.0)

	# Route links between the 11 districts
	for i in range(TOTAL_DISTRICTS - 1):
		var a: Vector2 = Vector2(CITY_NODE_UV[i].x * rect.size.x, CITY_NODE_UV[i].y * rect.size.y)
		var b: Vector2 = Vector2(CITY_NODE_UV[i + 1].x * rect.size.x, CITY_NODE_UV[i + 1].y * rect.size.y)
		var lit_edge: bool = _completed_districts.has(i) or (i == _current_district_idx and _exit_gate_unlocked)
		canvas.draw_line(a, b, COL_AMBER if lit_edge else Color(0.24, 0.30, 0.34, 0.65), 3.0 if lit_edge else 2.0)

	# District nodes
	var font: Font = ThemeDB.fallback_font
	for i in range(TOTAL_DISTRICTS):
		var p: Vector2 = Vector2(CITY_NODE_UV[i].x * rect.size.x, CITY_NODE_UV[i].y * rect.size.y)
		var is_done: bool = _completed_districts.has(i)
		var is_cur: bool = (i == _current_district_idx)
		var is_sel: bool = (i == _selected_district_idx)

		if is_cur:
			canvas.draw_circle(p, 26.0, Color(COL_AMBER.r, COL_AMBER.g, COL_AMBER.b, 0.22))
			canvas.draw_arc(p, 22.0, 0.0, TAU, 32, COL_AMBER, 2.5)
		if is_sel:
			canvas.draw_arc(p, 27.0, 0.0, TAU, 32, COL_TEXT_MAIN, 1.5)

		var fill_c: Color = COL_AMBER if is_done else (Color(0.28, 0.24, 0.14, 1.0) if is_cur else Color(0.11, 0.15, 0.18, 1.0))
		canvas.draw_circle(p, 16.0, fill_c)
		canvas.draw_arc(p, 16.0, 0.0, TAU, 24, COL_BRASS if (is_done or is_cur) else Color(0.32, 0.38, 0.42, 0.8), 2.0)
		if font != null:
			var num_txt: String = "%02d" % (i + 1)
			canvas.draw_string(font, p + Vector2(-8.0, 5.0), num_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, COL_BG_DEEP if is_done else COL_TEXT_MAIN)

	canvas.draw_rect(rect, COL_BRASS * Color(1.0, 1.0, 1.0, 0.6), false, 1.5)


func _is_world_point_revealed(pt: Vector2) -> bool:
	var span: Vector2 = _world_max - _world_min
	if span.x <= 0.1 or span.y <= 0.1:
		return false
	var gx: int = clampi(int(floorf(((pt.x - _world_min.x) / span.x) * float(FOG_GRID_RES))), 0, FOG_GRID_RES - 1)
	var gz: int = clampi(int(floorf(((pt.y - _world_min.y) / span.y) * float(FOG_GRID_RES))), 0, FOG_GRID_RES - 1)
	return _fog_cells[gz * FOG_GRID_RES + gx] != 0


func _world_to_rect(pt: Vector2, rect: Rect2) -> Vector2:
	var span: Vector2 = _world_max - _world_min
	var u: float = clampf((pt.x - _world_min.x) / maxf(0.1, span.x), 0.0, 1.0)
	var v: float = clampf((pt.y - _world_min.y) / maxf(0.1, span.y), 0.0, 1.0)
	return Vector2(rect.position.x + u * rect.size.x, rect.position.y + v * rect.size.y)


func _make_action_btn(label_text: String, min_w: float, min_h: float) -> Button:
	var b: Button = Button.new()
	b.text = label_text
	b.custom_minimum_size = Vector2(min_w, min_h)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", COL_TEXT_MAIN)
	b.add_theme_stylebox_override("normal", _make_panel_box(COL_BG_DARK, COL_BRASS, 1, 6))
	b.add_theme_stylebox_override("hover", _make_panel_box(COL_BG_DARK, COL_AMBER, 2, 6))
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


func _tr_fmt(key: String, args: Dictionary, fb_ru: String, fb_en: String) -> String:
	var raw: String = TranslationServer.translate(key)
	if raw.is_empty() or raw == key:
		raw = fb_ru if TranslationServer.get_locale().to_lower().begins_with("ru") else fb_en
	for k in args.keys():
		raw = raw.replace("{" + String(k) + "}", String(args[k]))
	return raw
