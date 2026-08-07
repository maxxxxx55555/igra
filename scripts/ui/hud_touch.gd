extends Control
class_name HUDTouch

signal stick_input(dir: Vector2)
signal action_pressed(name: StringName)
signal action_released(name: StringName)

const DEAD_ZONE: float = 16.0
const STICK_RADIUS: float = 64.0
const STICK_KNOB: float = 32.0

@export var stick_origin: Vector2 = Vector2(180, 580)
@export var action_button_specs: Array[Dictionary] = [
	{"name": &"flashlight", "pos": Vector2(680, 500), "radius": 56.0, "color": Color(1, 1, 0.6)},
	{"name": &"interact",   "pos": Vector2(580, 580), "radius": 56.0, "color": Color(0.6, 1, 0.6)},
	{"name": &"sprint",     "pos": Vector2(780, 580), "radius": 56.0, "color": Color(0.6, 0.8, 1)},
	{"name": &"pause",      "pos": Vector2(960,  60), "radius": 32.0, "color": Color(1, 1, 1)},
]

var _touch_index: Dictionary = {}
var _last_pos: Dictionary = {}
var _stick_pos: Vector2
var _stick_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	_stick_pos = stick_origin
	set_process(true)
	set_process_input(true)

func _process(_dt: float) -> void:
	var stick_touch: int = -1
	for idx in _touch_index.keys():
		if String(_touch_index[idx]) == "stick":
			stick_touch = int(idx)
			break
	if stick_touch >= 0:
		var pos: Vector2 = _last_pos.get(stick_touch, stick_origin)
		var delta: Vector2 = pos - stick_origin
		if delta.length() > DEAD_ZONE:
			_stick_dir = (delta / STICK_RADIUS).limit_length(1.0)
			_stick_pos = stick_origin + _stick_dir * STICK_RADIUS
		else:
			_stick_dir = Vector2.ZERO
			_stick_pos = stick_origin
	else:
		_stick_dir = Vector2.ZERO
		_stick_pos = stick_origin
	stick_input.emit(_stick_dir)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		if st.pressed:
			_on_touch_begin(st.index, st.position)
		else:
			_on_touch_end(st.index)
	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event
		_on_touch_drag(sd.index, sd.position)

func _on_touch_begin(idx: int, pos: Vector2) -> void:
	for spec in action_button_specs:
		var sp: Vector2 = spec["pos"]
		var r: float = spec["radius"]
		if pos.distance_to(sp) <= r:
			_touch_index[idx] = spec["name"]
			action_pressed.emit(spec["name"])
			UISFX.click()
			return
	if pos.distance_to(stick_origin) <= STICK_RADIUS * 1.6:
		_touch_index[idx] = "stick"
		_last_pos[idx] = pos
		_stick_pos = pos

func _on_touch_drag(idx: int, pos: Vector2) -> void:
	if String(_touch_index.get(idx, "")) == "stick":
		_last_pos[idx] = pos
		_stick_pos = pos

func _on_touch_end(idx: int) -> void:
	var tag: Variant = _touch_index.get(idx)
	if tag == null:
		return
	if tag is StringName:
		action_released.emit(tag)
	_touch_index.erase(idx)
	_last_pos.erase(idx)

func _draw() -> void:
	draw_circle(stick_origin, STICK_RADIUS, Color(1, 1, 1, 0.15))
	draw_circle(_stick_pos, STICK_KNOB, Color(1, 1, 1, 0.5))
	for spec in action_button_specs:
		var p: Vector2 = spec["pos"]
		var r: float = spec["radius"]
		var nm: StringName = spec["name"]
		var pressed: bool = false
		for idx in _touch_index.keys():
			if _touch_index[idx] == nm:
				pressed = true
				break
		var col: Color = spec["color"]
		col.a = 0.85 if pressed else 0.35
		draw_circle(p, r, col)
		var f: Font = ThemeDB.fallback_font
		if f != null:
			draw_string(f, p - Vector2(28, 6), String(nm), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)