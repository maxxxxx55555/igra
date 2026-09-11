extends Control
## AAA touch polish (GOLD MASTER v4 mobile-art pass): radial dead-zone so a
## thumb that barely twitches doesn't creep the player, an exponential
## response curve so fine aiming near center stays precise while a full
## push still reaches max speed fast, a Settings-driven sensitivity
## multiplier, a light haptic tick on touch-down, and a knob that visibly
## scales up while held. Base/knob art: assets/textures/touch/touch_joy_*.
const BASE_COLOR := Color("15181d")
const BASE_RIM := Color("3a3f47")
const KNOB_COLOR := Color("e8a13a")
const KNOB_RADIUS: float = 26.0
const PRESS_SCALE: float = 1.18
const BASE_TEX_PATH := "res://assets/textures/touch/touch_joy_base_256.png"
const KNOB_TEX_PATH := "res://assets/textures/touch/touch_joy_knob_256.png"
var _base_tex: Texture2D = null
var _knob_tex: Texture2D = null
## Response curve exponent: >1 flattens near-center input (precision),
## still reaches 1.0 at full deflection. 1.6 is a common mobile-twin-stick
## default (Deadzone setting already covers 0.15-0.25 per design spec).
const RESPONSE_CURVE: float = 1.6
var _touch_index: int = -1
var _knob_offset: Vector2 = Vector2.ZERO
var _press_anim: float = 0.0
## T18: двойной тап по джойстику — рывок (dodge) в текущем направлении.
const DOUBLE_TAP_WINDOW: float = 0.3
var _last_tap_time: float = -1.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	if ResourceLoader.exists(BASE_TEX_PATH):
		_base_tex = load(BASE_TEX_PATH)
	if ResourceLoader.exists(KNOB_TEX_PATH):
		_knob_tex = load(KNOB_TEX_PATH)
	InputService.set_joy_active(false)
	InputService.set_joy_move_dir(Vector2.ZERO)
func _process(delta: float) -> void:
	var target: float = 1.0 if _touch_index != -1 else 0.0
	if not is_equal_approx(_press_anim, target):
		_press_anim = move_toward(_press_anim, target, delta * 6.0)
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
	var raw: float = (_knob_offset.length() / radius) if radius > 0.0 else 0.0
	var dz: float = clampf(SettingsManager.get_setting("deadzone", 0.15), 0.0, 0.9)
	var dir := Vector2.ZERO
	if raw > dz and radius > 0.0:
		# re-map [dz,1] -> [0,1], then apply the response curve, then the
		# player's touch-sensitivity multiplier (clamped back to unit length
		# so it steers, not runs, past max speed).
		var mag: float = pow(clampf((raw - dz) / (1.0 - dz), 0.0, 1.0), RESPONSE_CURVE)
		mag *= SettingsManager.get_touch_sensitivity()
		dir = _knob_offset.normalized() * clampf(mag, 0.0, 1.0)
	InputService.set_joy_active(_touch_index != -1)
	InputService.set_joy_move_dir(dir)
func _radius() -> float:
	return maxf(1.0, minf(size.x, size.y) * 0.5 - KNOB_RADIUS)
func _draw() -> void:
	var center := size * 0.5
	var radius := _radius() + KNOB_RADIUS
	if _base_tex != null:
		var brect := Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
		draw_texture_rect(_base_tex, brect, false)
	else:
		draw_circle(center, radius, BASE_COLOR)
		draw_arc(center, radius, 0.0, TAU, 32, BASE_RIM, 2.0, true)
	var knob_r: float = KNOB_RADIUS * lerpf(1.0, PRESS_SCALE, _press_anim)
	if _knob_tex != null:
		var krect := Rect2(center + _knob_offset - Vector2.ONE * knob_r, Vector2.ONE * knob_r * 2.0)
		draw_texture_rect(_knob_tex, krect, false)
	else:
		draw_circle(center + _knob_offset, knob_r, KNOB_COLOR)
