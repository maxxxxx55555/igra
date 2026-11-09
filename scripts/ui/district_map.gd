extends Control
## The map (the owner's rules of 2026-11-05): a north-up architectural drawing of what Cartography has charted in this
## district, nothing else. Charted ground is stone; where it meets a building the edge is drawn stronger. It shows no
## player, monster, item, quest, lamp, route or label, and unknown space stays opaque at every zoom. District travel is
## its own screen (city_map), opened from here.

const STONE := Color(0.24, 0.25, 0.26)
const BUILDING_EDGE := Color(0.54, 0.54, 0.52)
const CANVAS_BG := Color(0.0235294, 0.0588235, 0.0745098)
const ZOOM_MIN: float = 0.5
const ZOOM_MAX: float = 4.0

var _canvas: Control = null
var _blank: Label = null
var _zoom: float = 1.0
var _pan: Vector2 = Vector2.ZERO
var _captions: Dictionary[String, Control] = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()
	var bg := ColorRect.new()
	bg.color = Color(CANVAS_BG, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	root.add_theme_constant_override("separation", 12)
	add_child(root)
	var title := Label.new()
	title.text = LocalizationManager.t("MAP_TITLE")
	title.add_theme_font_override("font", ThemeProvider.heading_font())
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT)
	root.add_child(title)
	_captions["MAP_TITLE"] = title
	_blank = Label.new()
	_blank.text = LocalizationManager.t("MAP_BLANK")
	_blank.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	root.add_child(_blank)
	_captions["MAP_BLANK"] = _blank
	_canvas = Control.new()
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.clip_contents = true
	_canvas.draw.connect(_draw_canvas)
	_canvas.gui_input.connect(_on_canvas_input)
	root.add_child(_canvas)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)
	for spec: Array in [["MAP_ZOOM_IN", func() -> void: _zoom_by(1.25)], ["MAP_ZOOM_OUT", func() -> void: _zoom_by(0.8)],
			["MAP_RESET", _reset_view], ["MAP_DISTRICTS", _open_travel], ["BTN_CLOSE", _close]]:
		var btn := Button.new()
		btn.text = LocalizationManager.t(spec[0])
		btn.custom_minimum_size = Vector2(150, 48)
		btn.pressed.connect(spec[1])
		row.add_child(btn)
		_captions[String(spec[0])] = btn
	LocalizationManager.language_changed.connect(_on_language_changed)
	visibility_changed.connect(func() -> void:
		if visible:
			_reset_view())

func _on_language_changed(_language: String) -> void:
	for key: String in _captions:
		_captions[key].set("text", LocalizationManager.t(key))

func _cells() -> Dictionary:
	var dm := get_node_or_null("/root/DistrictManager")
	return Cartography.charted_cells(String(dm.current_district)) if dm != null else {}

## The bounds of what is charted, in cells: the view never extends to the city's unknown arrangement.
func _bounds(cells: Dictionary) -> Rect2:
	var rect := Rect2()
	var first := true
	for cell: Vector2i in cells:
		var r := Rect2(Vector2(cell), Vector2.ONE)
		rect = r if first else rect.merge(r)
		first = false
	return rect

func _reset_view() -> void:
	_zoom = 1.0
	_pan = Vector2.ZERO
	if _blank != null:
		_blank.visible = _cells().is_empty()
	if _canvas != null:
		_canvas.queue_redraw()

func _zoom_by(factor: float) -> void:
	_zoom = clampf(_zoom * factor, ZOOM_MIN, ZOOM_MAX)
	_canvas.queue_redraw()

func _on_canvas_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		_pan += (event as InputEventMouseMotion).relative
		_canvas.queue_redraw()
	elif event is InputEventScreenDrag:
		_pan += (event as InputEventScreenDrag).relative
		_canvas.queue_redraw()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		match (event as InputEventMouseButton).button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom_by(1.1)
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_by(0.9)

## Cells to canvas pixels: north-up, +X to the right, +Z downwards, the charted bounds fitted to the canvas.
func _to_canvas(cell: Vector2, bounds: Rect2, px: float) -> Vector2:
	return _canvas.size * 0.5 + _pan + (cell - bounds.get_center()) * px

func _draw_canvas() -> void:
	_canvas.draw_rect(Rect2(Vector2.ZERO, _canvas.size), CANVAS_BG)
	var cells := _cells()
	if cells.is_empty():
		return
	var bounds := _bounds(cells)
	var px: float = minf(_canvas.size.x / maxf(bounds.size.x + 4.0, 1.0), _canvas.size.y / maxf(bounds.size.y + 4.0, 1.0)) * _zoom
	var sb := get_tree().get_first_node_in_group(&"street_builder") as Node3D
	var skyline := get_tree().get_first_node_in_group(&"city_skyline") as CitySkyline
	for cell: Vector2i in cells:
		var at := _to_canvas(Vector2(cell), bounds, px)
		_canvas.draw_rect(Rect2(at, Vector2(px, px)), STONE)
		# the edge of a building the lit street runs along: a neighbour inside a block, never charted itself
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + side
			if cells.has(next) or sb == null or not _is_building(sb, skyline, next):
				continue
			var a := at + Vector2(maxi(side.x, 0), maxi(side.y, 0)) * px
			var b := a + (Vector2(0, px) if side.x != 0 else Vector2(px, 0))
			_canvas.draw_line(a, b, BUILDING_EDGE, maxf(1.0, px * 0.12))

## Whether a cell's centre lies in a building. Prefers the skyline's recorded footprints (real front widths and
## alleys), converting the charted cell from street-builder space into skyline-local XZ; falls back to the outer
## ring heuristic only when no skyline has been built (e.g. a headless gate with a bare StreetBuilder).
func _is_building(sb: Node3D, skyline: CitySkyline, cell: Vector2i) -> bool:
	if skyline != null and skyline.has_footprints():
		var local := (Vector2(cell) + Vector2(0.5, 0.5)) * Cartography.CELL
		var world := sb.to_global(Vector3(local.x, 0.0, local.y))
		var point := skyline.to_local(world)
		return skyline.occupies_local(Vector2(point.x, point.z))
	return is_block(sb, cell)

## Whether a cell's centre lies in the ring of buildings round the district (the 3 by 3 lots inside it are open, walkable ground).
static func is_block(sb: Node, cell: Vector2i) -> bool:
	var at := (Vector2(cell) + Vector2(0.5, 0.5)) * Cartography.CELL
	return maxf(absf(at.x), absf(at.y)) > 1.5 * float(sb.get("grid_spacing")) + CitySkyline.RING_GAP

func _open_travel() -> void:
	UIManager.close(&"district_map")
	UIManager.open(&"city_map")

func _close() -> void:
	UIManager.close(&"district_map")
