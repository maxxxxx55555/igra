extends Control
## P2.5: size bump 180->220 (was on the open backlog since VISUAL_AUDIT) +
## real frame/player-arrow textures from the delivered minimap kit, layered
## on top of the existing procedural draw (kept as the functional fallback).
const SIZE := Vector2(220, 220)
const SCALE := 0.06
const _FRAME_TEX: Texture2D = preload("res://assets/textures/ui/minimap_frame_256.png")
const _ARROW_TEX: Texture2D = preload("res://assets/textures/ui/minimap_player_arrow_32.png")
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
## GDD V.1 3.4 / V.4 8.5: the minimap drew district dots, a stage colour and a
## player arrow with no key to read them by ("Minimap есть, легенда отсутствует").
## On a 1280x720 phone every corner already belongs to another HUD element, so
## the legend is on demand: a chip in the frame's lower-left corner opens a panel
## parked to the left of the frame, where nothing else is anchored.
const LEGEND_W: float = 300.0
const LEGEND_H: float = 180.0
const _LEGEND_ROW_H: float = 22.0

var _tick: float = 0.0
var _current_district: StringName = &""
var _legend: PanelContainer = null
var _legend_title: Label = null
var _legend_chip: Button = null
## [Label] of every legend row, so a language switch can re-text them in place.
var _legend_row_labels: Array[Label] = []

func _ready() -> void:
	# Нажатие по миникарте открывает полную карту города — привычный жест
	# из мобильных игр. Раньше стоял MOUSE_FILTER_IGNORE, и клик проваливался
	# сквозь неё в игровой мир: игрок жал по карте, а персонаж стрелял.
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = LocalizationManager.t("MAP_OPEN_HINT")
	# Static audit 2026-09-08: tooltip was set once and never retranslated
	# on this persistent always-on HUD element.
	LocalizationManager.language_changed.connect(func(_l: String) -> void:
		tooltip_text = LocalizationManager.t("MAP_OPEN_HINT"))
	custom_minimum_size = SIZE
	size = SIZE
	anchor_left = 1.0
	anchor_right = 1.0
	offset_left = -SIZE.x - 16
	offset_right = -16
	offset_top = 16
	offset_bottom = 16 + SIZE.y
	_build_legend()
	_retranslate_legend()
	_update_legend_visibility()
	LocalizationManager.language_changed.connect(func(_l: String) -> void: _retranslate_legend())
	EventBus.power_grid_updated.connect(func() -> void: queue_redraw())
	if EventBus.has_signal("district_entered"):
		EventBus.district_entered.connect(func(id: StringName) -> void:
			_current_district = id
			queue_redraw())

## 3.4/8.5: what the minimap actually draws, in reading order - the player
## arrow, the ringed current district, and the three power-grid stages the
## district dots are tinted by.
func _build_legend() -> void:
	_legend_chip = Button.new()
	_legend_chip.name = "LegendChip"
	_legend_chip.text = "?"
	_legend_chip.focus_mode = Control.FOCUS_NONE
	_legend_chip.custom_minimum_size = Vector2(24, 24)
	_legend_chip.anchor_left = 0.0
	_legend_chip.anchor_top = 0.0
	_legend_chip.offset_left = 6.0
	_legend_chip.offset_top = SIZE.y - 30.0
	_legend_chip.offset_right = 30.0
	_legend_chip.offset_bottom = SIZE.y - 6.0
	_legend_chip.visible = false
	_legend_chip.pressed.connect(_toggle_legend)
	add_child(_legend_chip)

	_legend = PanelContainer.new()
	_legend.name = "MinimapLegend"
	_legend.visible = false
	_legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_legend.anchor_left = 1.0
	_legend.anchor_right = 1.0
	_legend.anchor_top = 0.0
	_legend.anchor_bottom = 0.0
	_legend.offset_left = -(SIZE.x + LEGEND_W + 24.0)
	_legend.offset_right = -(SIZE.x + 24.0)
	_legend.offset_top = 16.0
	_legend.offset_bottom = 16.0 + LEGEND_H
	_legend.add_theme_stylebox_override("panel", _legend_style())
	add_child(_legend)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_legend.add_child(vb)
	_legend_title = Label.new()
	_legend_title.add_theme_font_size_override("font_size", 14)
	_legend_title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	vb.add_child(_legend_title)
	_add_legend_row(vb, "HUD_LEGEND_PLAYER", _arrow_swatch())
	_add_legend_row(vb, "HUD_LEGEND_CURRENT", _ring_swatch())
	_add_stage_legend_rows(vb)

## The four power-grid stages, reusing the city map's keys. Written as four
## explicit calls, not "MAP_STAGE_%d" in a loop: the localization audits read
## keys straight out of the source, so a concatenated key is invisible to them
## (same reason city_map.gd keeps STAGE_KEYS as literals). Swatches come from
## _stage_color(), so a recolour of the dots cannot leave the legend behind.
func _add_stage_legend_rows(parent: VBoxContainer) -> void:
	_add_legend_row(parent, "MAP_STAGE_3", _square_swatch(_stage_color(DistrictData.Stage.FULL)))
	_add_legend_row(parent, "MAP_STAGE_2", _square_swatch(_stage_color(DistrictData.Stage.STREETS)))
	_add_legend_row(parent, "MAP_STAGE_1", _square_swatch(_stage_color(DistrictData.Stage.PARTIAL)))
	_add_legend_row(parent, "MAP_STAGE_0", _square_swatch(_stage_color(DistrictData.Stage.DARK)))

func _legend_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(ThemeProvider.COLOR_BG_PANEL.r, ThemeProvider.COLOR_BG_PANEL.g,
		ThemeProvider.COLOR_BG_PANEL.b, 0.92)
	sb.border_color = ThemeProvider.COLOR_BORDER
	sb.set_border_width_all(1)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _add_legend_row(parent: VBoxContainer, key: String, swatch: Control) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.custom_minimum_size = Vector2(0, _LEGEND_ROW_H)
	parent.add_child(hb)
	hb.add_child(swatch)
	var lbl := Label.new()
	lbl.text = LocalizationManager.t(key)
	lbl.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT)
	lbl.set_meta("i18n_key", key)
	hb.add_child(lbl)
	_legend_row_labels.append(lbl)

## The player marker is the real arrow texture, not a stand-in square.
func _arrow_swatch() -> TextureRect:
	var tex := TextureRect.new()
	tex.texture = _ARROW_TEX
	tex.custom_minimum_size = Vector2(16, 16)
	tex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return tex

## The current district is the only dot drawn with an amber ring (_draw()).
## A round swatch is deliberate here: it mirrors a circular marker, which is the
## one case the chamfer-only chrome rule exempts.
func _ring_swatch() -> Control:
	var ring := Panel.new()
	ring.custom_minimum_size = Vector2(16, 16)
	ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = ThemeProvider.COLOR_AMBER
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	ring.add_theme_stylebox_override("panel", sb)
	return ring

func _square_swatch(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.custom_minimum_size = Vector2(12, 12)
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rect

func _toggle_legend() -> void:
	_legend.visible = not _legend.visible
	if _legend.visible:
		_retranslate_legend()

func _retranslate_legend() -> void:
	if _legend_chip != null:
		_legend_chip.tooltip_text = LocalizationManager.t("HUD_LEGEND_TITLE")
	if _legend_title != null:
		_legend_title.text = LocalizationManager.t("HUD_LEGEND_TITLE")
	for lbl in _legend_row_labels:
		lbl.text = LocalizationManager.t(String(lbl.get_meta("i18n_key", "")))

## _draw() early-returns outside play, but child nodes keep rendering - the chip
## and the open panel follow the minimap's own gate instead of floating over
## menus, the pause screen or photo mode.
func _update_legend_visibility() -> void:
	var shown: bool = GameManager.is_playing() and not UIManager.is_hud_blocked()
	if _legend_chip.visible != shown:
		_legend_chip.visible = shown
	if not shown:
		_legend.visible = false
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
	if _tick >= 0.1:
		_tick = 0.0
		queue_redraw()
		_update_legend_visibility()
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
		if d.id == _current_district:
			draw_arc(p, 8.0, 0.0, TAU, 24, ThemeProvider.COLOR_AMBER, 1.5, true)
			# Раньше подписывались все 11 районов сразу — на круге 180px это
			# гарантированно накладывающийся, нечитаемый ком текста. Полные
			# названия и так есть в city_map (открывается тапом); здесь
			# подписываем только текущий район игрока.
			var label_key: String = String(DISTRICT_LABELS.get(d.id, ""))
			var label: String = LocalizationManager.t(label_key) if label_key != "" else ""
			if label != "":
				draw_string(ThemeDB.fallback_font, p + Vector2(10, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ThemeProvider.COLOR_AMBER)
	draw_texture_rect(_ARROW_TEX, Rect2(center - Vector2(8, 8), Vector2(16, 16)), false)
	draw_texture_rect(_FRAME_TEX, Rect2(Vector2.ZERO, r.size), false)
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
