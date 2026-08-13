extends Control

signal puzzle_solved
signal puzzle_failed

@export var enable_cable_puzzle: bool = true

const SOURCE_COLORS := {
	"red": Color(0.8, 0.15, 0.15),
	"blue": Color(0.15, 0.35, 0.8),
	"green": Color(0.15, 0.7, 0.15),
	"amber": Color(0.788, 0.635, 0.290)
}
const PANEL := Color("#141b24")
const PANEL_EDGE := Color("#2a3340")
const BRASS := Color("#c9a24a")
const BRASS_DIM := Color("#8a7338")
const EMBER := Color("#b4452f")
const STEEL_TEXT := Color("#aeb6bf")

const LEVELS := [
	{
		"sources": [Vector2(0,1), Vector2(0,2)],
		"targets": [Vector2(2,0), Vector2(3,2)],
		"target_edges": {"red": Vector2(2,0), "blue": Vector2(3,2)}
	},
	{
		"sources": [Vector2(0,0), Vector2(0,1), Vector2(0,2)],
		"targets": [Vector2(3,0), Vector2(2,1), Vector2(3,2)],
		"target_edges": {"red": Vector2(3,0), "green": Vector2(2,1), "blue": Vector2(3,2)}
	}
]

const GRID_COLS := 4
const GRID_ROWS := 3
const GRID_SP := 48.0

var _current_level: int = 0
var _attempts: int = 5
var _connections: Dictionary = {}
var _selected_source: String = ""
var _hint_active: bool = false
var _grid_pos: Dictionary = {}
var _src_colors: Dictionary = {}
var _targets: Array = []
var _sources: Array = []
var _attempt_label: Label
var _toast: Label
var _solved: bool = false
var _hint_tween: Tween

func _ready() -> void:
	if not enable_cable_puzzle: return
	_attempts = 5
	_build_grid()
	_load_level(0)
	_build_ui()


func _build_grid() -> void:
	var rx := size.x - 16.0
	var ty := (size.y - (GRID_ROWS - 1) * GRID_SP) * 0.5
	for col in GRID_COLS:
		for row in GRID_ROWS:
			_grid_pos[Vector2(col, row)] = Vector2(rx - col * GRID_SP, ty + row * GRID_SP)

func _build_ui() -> void:
	_attempt_label = Label.new()
	_attempt_label.text = tr("CABLE_ATTEMPTS") + ": " + str(_attempts)
	_attempt_label.size = Vector2(100, 20)
	_attempt_label.position = Vector2(6, size.y - 44)
	_attempt_label.add_theme_color_override("font_color", STEEL_TEXT)
	_attempt_label.add_theme_font_size_override("font_size", 11)
	add_child(_attempt_label)

	var reset_btn := Button.new()
	reset_btn.text = tr("CABLE_RESET")
	reset_btn.size = Vector2(60, 22)
	reset_btn.position = Vector2(size.x - 68, size.y - 44)
	reset_btn.add_theme_font_size_override("font_size", 10)
	add_child(reset_btn)
	reset_btn.pressed.connect(_reset)

func _load_level(idx: int) -> void:
	var lv: Dictionary = LEVELS[idx]
	_targets = lv["targets"].duplicate()
	_sources = lv["sources"].duplicate()
	_connections.clear()
	_selected_source = ""
	_solved = false
	var ck: Array = lv["target_edges"].keys()
	for i in _sources.size():
		_src_colors[_sources[i]] = ck[i] if i < ck.size() else "amber"
	queue_redraw()

func _draw() -> void:
	for col_name in _connections:
		var tpos: Vector2 = _connections[col_name]
		var sgrid: Variant = _get_src_for_color(col_name)
		if sgrid != null and _grid_pos.has(sgrid) and _grid_pos.has(tpos):
			draw_line(_grid_pos[sgrid], _grid_pos[tpos], SOURCE_COLORS[col_name], 3.0)

	for gpos in _grid_pos:
		var spos: Vector2 = _grid_pos[gpos]
		if gpos in _sources:
			var cn: String = _src_colors[gpos]
			draw_circle(spos, 8, SOURCE_COLORS[cn])
			if _selected_source == cn:
				draw_arc(spos, 13, 0, TAU, 32, BRASS, 2.0)
		elif gpos in _targets:
			var connected := false
			for c in _connections.values():
				if c == gpos: connected = true; break
			draw_circle(spos, 8, PANEL_EDGE if connected else EMBER)
		else:
			draw_circle(spos, 5, PANEL_EDGE)

func _get_src_for_color(col_name: String) -> Variant:
	for gpos in _src_colors:
		if _src_colors[gpos] == col_name:
			return gpos
	return null

func _gui_input(event: InputEvent) -> void:
	if _solved: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mp: Vector2 = event.position
		if _selected_source == "":
			for gpos in _sources:
				var cn: String = _src_colors[gpos]
				if _grid_pos[gpos].distance_to(mp) < 12:
					_selected_source = cn
					queue_redraw()
					return
		else:
			for gpos in _targets:
				if _grid_pos[gpos].distance_to(mp) < 12:
					if _connections.values().has(gpos): return
					var lv: Dictionary = LEVELS[_current_level]
					if lv["target_edges"].get(_selected_source) == gpos:
						_connections[_selected_source] = gpos
						_selected_source = ""
						if _connections.size() == _targets.size():
							_solved = true
							puzzle_solved.emit()
						queue_redraw()
					else:
						_attempts -= 1
						_attempt_label.text = tr("CABLE_ATTEMPTS") + ": " + str(_attempts)
						_show_toast(tr("CABLE_FAIL"))
						_selected_source = ""
						queue_redraw()
						if _attempts <= 0:
							puzzle_failed.emit()
							_show_toast(tr("CABLE_SHORT_CIRCUIT"))
					return
			_selected_source = ""
			queue_redraw()

func show_hint() -> void:
	if _solved or _hint_active or _attempts <= 0: return
	_attempts -= 1
	_attempt_label.text = tr("CABLE_ATTEMPTS") + ": " + str(_attempts)
	if _attempts <= 0:
		puzzle_failed.emit()
		_show_toast(tr("CABLE_SHORT_CIRCUIT"))
		return
	_hint_active = true
	for gpos in _targets:
		if not _connections.values().has(gpos):
			if _hint_tween: _hint_tween.kill()
			_hint_tween = create_tween()
			var r := ColorRect.new()
			r.size = Vector2(28, 28)
			r.position = _grid_pos[gpos] - Vector2(14, 14)
			r.color = BRASS
			r.mouse_filter = Control.MOUSE_FILTER_PASS
			add_child(r)
			_hint_tween.tween_property(r, "modulate:a", 0.3, 0.5).set_trans(Tween.TRANS_SINE)
			_hint_tween.tween_property(r, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
			_hint_tween.tween_callback(func(): r.queue_free(); _hint_active = false)
			return

func _reset() -> void:
	_load_level(_current_level)
	_attempts = 5
	_attempt_label.text = tr("CABLE_ATTEMPTS") + ": " + str(_attempts)

func _show_toast(msg: String) -> void:
	if _toast: _toast.queue_free()
	_toast = Label.new()
	_toast.text = msg
	_toast.size = Vector2(300, 24)
	_toast.position = Vector2(size.x * 0.5 - 150, size.y * 0.5 - 50)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_color_override("font_color", EMBER)
	_toast.add_theme_font_size_override("font_size", 14)
	_toast.modulate = Color(1, 1, 1, 0)
	add_child(_toast)
	# Захватываем КОНКРЕТНУЮ метку, а не поле _toast: пока идёт анимация,
	# следующий вызов _show_toast() уже перезапишет поле, и старый коллбэк
	# удалил бы новую, только что показанную подсказку.
	var label := _toast
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.2)
	tw.tween_property(label, "modulate:a", 0.0, 0.3)
	tw.tween_callback(_drop_toast.bind(label))

## Убирает конкретную подсказку и обнуляет поле, только если оно всё ещё
## указывает на неё.
func _drop_toast(label: Label) -> void:
	if is_instance_valid(label):
		label.queue_free()
	if _toast == label:
		_toast = null
