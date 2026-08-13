extends Control
const SIZE := Vector2(180, 180)
const SCALE := 0.06
const DISTRICT_OFFSETS: Dictionary = {
	&"suburbs": Vector2i(0, 0), &"residential": Vector2i(1, 0), &"park": Vector2i(2, 0), &"school": Vector2i(3, 0),
	&"hospital": Vector2i(0, 1), &"gas_station": Vector2i(1, 1), &"police": Vector2i(2, 1), &"warehouses": Vector2i(3, 1),
	&"industrial": Vector2i(0, 2), &"substation": Vector2i(1, 2), &"power_station": Vector2i(2, 2),
}
const TILE_SIZE: int = 32
const SLOT_W: int = 12
const SLOT_H: int = 9
const DISTRICT_LABELS: Dictionary = {
	&"suburbs": "DIST_SUBURBS", &"residential": "DIST_RESIDENTIAL", &"park": "DIST_PARK", &"school": "DIST_SCHOOL",
	&"hospital": "DIST_HOSPITAL", &"gas_station": "DIST_GAS", &"police": "DIST_POLICE", &"warehouses": "DIST_WAREHOUSES",
	&"industrial": "DIST_INDUSTRIAL", &"substation": "DIST_SUBSTATION", &"power_station": "DIST_POWER",
}
var _tick: float = 0.0
var _current_district: StringName = &""
func _ready() -> void:
	# Нажатие по миникарте открывает полную карту города — привычный жест
	# из мобильных игр. Раньше стоял MOUSE_FILTER_IGNORE, и клик проваливался
	# сквозь неё в игровой мир: игрок жал по карте, а персонаж стрелял.
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = LocalizationManager.t("MAP_OPEN_HINT")
	custom_minimum_size = SIZE
	size = SIZE
	anchor_left = 1.0
	anchor_right = 1.0
	offset_left = -SIZE.x - 16
	offset_right = -16
	offset_top = 16
	offset_bottom = 16 + SIZE.y
	EventBus.power_grid_updated.connect(func() -> void: queue_redraw())
	if EventBus.has_signal("district_entered"):
		EventBus.district_entered.connect(func(id: StringName) -> void:
			_current_district = id
			queue_redraw())
## Открывает полноэкранную карту города по тапу/клику.
func _gui_input(event: InputEvent) -> void:
	if not GameManager.is_playing():
		return
	var tapped: bool = false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		tapped = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		tapped = (event as InputEventScreenTouch).pressed
	if tapped:
		accept_event()
		UIManager.open(&"city_map")

func _process(delta: float) -> void:
	_tick += delta
	if _tick >= 0.1: _tick = 0.0; queue_redraw()
func _draw() -> void:
	if not GameManager.is_playing(): return
	var r := get_rect()
	draw_circle(r.size * 0.5, r.size.x * 0.5, ThemeProvider.COLOR_BG_PANEL)
	draw_arc(r.size * 0.5, r.size.x * 0.5 - 1, 0.0, TAU, 32, ThemeProvider.COLOR_BORDER, 2.0, true)
	var center := r.size * 0.5
	for d in PowerGrid.all_districts():
		var off: Vector2i = DISTRICT_OFFSETS.get(d.id, Vector2i(-99, -99))
		if off.x < 0: continue
		var wp := Vector2(off.x * SLOT_W * TILE_SIZE, off.y * SLOT_H * TILE_SIZE)
		var p := center + (wp - _player_pos()) * SCALE
		var c := _stage_color(d.stage)
		var theme_c := DistrictThemes.get_district_color(d.id)
		var mix := c.lerp(theme_c, 0.45)
		draw_circle(p, 6.5 if d.id == _current_district else 4.0, mix)
		if d.id == _current_district: draw_arc(p, 8.0, 0.0, TAU, 24, ThemeProvider.COLOR_AMBER, 1.5, true)
		var label_key: String = String(DISTRICT_LABELS.get(d.id, ""))
		var label: String = LocalizationManager.t(label_key) if label_key != "" else ""
		if label != "":
			var font := ThemeDB.fallback_font
			draw_string(font, p + Vector2(8, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, ThemeProvider.COLOR_AMBER_DIM)
	draw_circle(center, 3.0, ThemeProvider.COLOR_AMBER)
func _player_pos() -> Vector2:
	var p := get_tree().get_first_node_in_group("player")
	var v3: Vector3 = p.global_position if is_instance_valid(p) else Vector3.ZERO
	return Vector2(v3.x, v3.z)
func _stage_color(stage: int) -> Color:
	match stage:
		1: return ThemeProvider.COLOR_AMBER_DIM
		2: return Color("c98a2e")
		3: return ThemeProvider.COLOR_AMBER
		_: return ThemeProvider.COLOR_BORDER
