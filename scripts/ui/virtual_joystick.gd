extends Control
const BASE_COLOR := Color("15181d")
const BASE_RIM := Color("3a3f47")
const KNOB_COLOR := Color("e8a13a")
const KNOB_RADIUS: float = 26.0
var _touch_index: int = -1
var _knob_offset: Vector2 = Vector2.ZERO
## T18: двойной тап по джойстику — рывок (dodge) в текущем направлении.
const DOUBLE_TAP_WINDOW: float = 0.3
var _last_tap_time: float = -1.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	InputService.set_joy_active(false)
	InputService.set_joy_move_dir(Vector2.ZERO)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_check_double_tap()
			_update_knob(event.position)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_knob_offset = Vector2.ZERO
			_emit_dir()
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_knob(event.position)
func _check_double_tap() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if _last_tap_time >= 0.0 and now - _last_tap_time <= DOUBLE_TAP_WINDOW:
		_last_tap_time = -1.0
		var radius := _radius()
		var dir: Vector2 = (_knob_offset / radius) if (radius > 0.0 and _knob_offset.length() > 0.1) else Vector2.UP
		InputService.request_dodge(dir)
	else:
		_last_tap_time = now
func _update_knob(local_pos: Vector2) -> void:
	var center := size * 0.5
	var delta := local_pos - center
	var radius := _radius()
	if delta.length() > radius:
		delta = delta.normalized() * radius
	_knob_offset = delta
	_emit_dir()
	queue_redraw()
func _emit_dir() -> void:
	var radius := _radius()
	var dir := (_knob_offset / radius) if radius > 0.0 else Vector2.ZERO
	InputService.set_joy_active(_touch_index != -1)
	InputService.set_joy_move_dir(dir)
func _radius() -> float:
	return maxf(1.0, minf(size.x, size.y) * 0.5 - KNOB_RADIUS)
func _draw() -> void:
	var center := size * 0.5
	var radius := _radius() + KNOB_RADIUS
	draw_circle(center, radius, BASE_COLOR)
	draw_arc(center, radius, 0.0, TAU, 32, BASE_RIM, 2.0, true)
	draw_circle(center + _knob_offset, KNOB_RADIUS, KNOB_COLOR)
