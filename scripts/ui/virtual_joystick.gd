extends Control
## Reference Style 3 Gritty Directional Virtual Joystick (menu_style_unify_check compliant).
## Single crisp bottom-left circular charcoal pad with weathered bronze rim, 4 subtle directional
## arrows, and dark recessed thumb knob with warm sodium ring on deflection.
## Preserves radial deadzone, exponential curve, double-tap dodge, and 100ms press-scale feel.

const BASE_COLOR := Color("#0f1314")
const BASE_INNER := Color("#161e22")
const BASE_RIM := Color("#5a4a2a")
const KNOB_COLOR := Color("#1c1e1d")
const KNOB_RIM := Color("#c9a24a")
const SODIUM_RING := Color("#d4a94e")
const ARROW_MUTED := Color("#8a8a85")
const KNOB_RADIUS: float = 25.0
const PRESS_SCALE: float = 1.15
const REST_ALPHA: float = 0.82
const RESPONSE_CURVE: float = 1.6
const DOUBLE_TAP_WINDOW: float = 0.3
const PRESS_ANIM_RATE: float = 10.0

var _touch_index: int = -1
var _knob_offset: Vector2 = Vector2.ZERO
var _press_anim: float = 0.0
var _last_tap_time: float = -1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	InputService.set_joy_active(false)
	InputService.set_joy_move_dir(Vector2.ZERO)


func _process(delta: float) -> void:
	var target: float = 1.0 if _touch_index != -1 else 0.0
	if not is_equal_approx(_press_anim, target):
		_press_anim = move_toward(_press_anim, target, delta * PRESS_ANIM_RATE)
		var ring := get_parent() as Panel
		if ring != null:
			ring.modulate.a = lerpf(REST_ALPHA, 1.0, _press_anim)
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_check_double_tap()
			_update_knob(event.position)
			_haptic(15)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_knob_offset = Vector2.ZERO
			_emit_dir()
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_knob(event.position)


func _haptic(ms: int) -> void:
	if OS.has_feature("mobile") and SettingsManager.haptics_enabled():
		Input.vibrate_handheld(ms)


func double_tap_window() -> float:
	return DOUBLE_TAP_WINDOW * (2.0 if bool(SettingsManager.get_setting("one_handed", false)) else 1.0)


func _check_double_tap() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if _last_tap_time >= 0.0 and now - _last_tap_time <= double_tap_window():
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
	var raw: float = (_knob_offset.length() / radius) if radius > 0.0 else 0.0
	var dz: float = clampf(SettingsManager.get_setting("deadzone", 0.15), 0.0, 0.9)
	var dir := Vector2.ZERO
	if raw > dz and radius > 0.0:
		var mag: float = pow(clampf((raw - dz) / (1.0 - dz), 0.0, 1.0), RESPONSE_CURVE)
		mag *= SettingsManager.get_touch_sensitivity()
		dir = _knob_offset.normalized() * clampf(mag, 0.0, 1.0)
	InputService.set_joy_active(_touch_index != -1)
	InputService.set_joy_move_dir(dir)


func _radius() -> float:
	return maxf(1.0, minf(size.x, size.y) * 0.5 - KNOB_RADIUS)


func _draw_chevron(tip: Vector2, dir: Vector2, half_w: float, col: Color) -> void:
	var perp := Vector2(-dir.y, dir.x)
	var base := tip - dir * (half_w * 1.15)
	draw_colored_polygon(PackedVector2Array([tip, base + perp * half_w, base - perp * half_w]), col)


func _draw() -> void:
	var center := size * 0.5
	var radius := _radius() + KNOB_RADIUS
	var deflection: float = _knob_offset.length() / maxf(1.0, _radius())

	# Outer recessed dark charcoal pad + dual weathered bronze bezel (Reference Style 3)
	draw_circle(center, radius, Color(BASE_COLOR, 0.72))
	draw_circle(center, radius * 0.84, Color(BASE_INNER, 0.42))
	draw_arc(center, radius - 1.0, 0.0, TAU, 48, Color(BASE_RIM, 0.88), 2.0, true)
	draw_arc(center, radius * 0.84, 0.0, TAU, 40, Color(BASE_RIM, 0.35), 1.0, true)

	# 4 subtle directional chevrons (Up / Down / Left / Right) like Reference Photo #3
	var arrow_r: float = radius * 0.74
	for d_vec: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var active_dot: float = _knob_offset.normalized().dot(d_vec) if deflection > 0.15 else 0.0
		var col := Color(SODIUM_RING, 0.85) if active_dot > 0.65 else Color(ARROW_MUTED, 0.42)
		_draw_chevron(center + d_vec * (arrow_r + 4.0), d_vec, 4.5, col)

	if deflection > 0.02:
		draw_arc(center, maxf(2.0, radius - 3.5), 0.0, TAU, 48, Color(SODIUM_RING, 0.25 + 0.55 * clampf(deflection, 0.0, 1.0)), 2.0, true)

	# Dark brushed bronze thumb knob with warm inner rim
	var knob_r: float = KNOB_RADIUS * lerpf(1.0, PRESS_SCALE, _press_anim)
	var kpos := center + _knob_offset
	draw_circle(kpos + Vector2(0.0, 2.0), knob_r, Color(BASE_COLOR, 0.60))
	draw_circle(kpos, knob_r, Color(KNOB_COLOR, 0.94))
	draw_arc(kpos, knob_r - 1.0, 0.0, TAU, 32, Color(KNOB_RIM, 0.78 if deflection < 0.05 else 0.98), 2.0, true)
	draw_circle(kpos, knob_r * 0.32, Color(SODIUM_RING, 0.22 + 0.35 * _press_anim))
