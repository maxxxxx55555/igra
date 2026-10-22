extends Node
## W8 of docs/VISUAL_PASS.md section 8: the slow parallax of a menu backdrop (assets/shaders/menu_parallax.gdshader). attach() puts the backdrop `art` under `screen`, gives it the shader and this node as its driver: the `parallax`
## uniform follows the pointer over the window (the mouse, or the drag of a finger), eased; on the Low tier the pointer counts POINTER_LOW (the idle drift stays); with Motion Comfort or Reduce UI Motion the pointer and the drift are both
## off. The Settings screen is never given one (VISUAL_PASS section 8: it belongs to another file's owner).

const SHADER: String = "res://assets/shaders/menu_parallax.gdshader"
const POINTER_LOW: float = 0.4
const EASE_PER_SEC: float = 4.0
const DRIFT: float = 0.004
const HALF := Vector2(0.5, 0.5)

var _mat: ShaderMaterial = null
var _drag: Vector2 = Vector2.ZERO
var _now: Vector2 = Vector2.ZERO

static func attach(screen: Control, art: TextureRect) -> void:
	screen.add_child(art)
	var driver := new()
	driver._mat = ShaderMaterial.new()
	driver._mat.shader = load(SHADER)
	art.material = driver._mat
	art.add_child(driver)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		_drag = (_drag + (event as InputEventScreenDrag).relative / get_viewport().get_visible_rect().size).clamp(-HALF, HALF)

func _process(delta: float) -> void:
	var calm: bool = bool(SettingsManager.get_setting("reduce_ui_motion", false)) or bool(SettingsManager.get_setting("reduce_camera_motion", false))
	var want: Vector2 = Vector2.ZERO
	if not calm:
		want = (get_viewport().get_mouse_position() / get_viewport().get_visible_rect().size - HALF).clamp(-HALF, HALF) + _drag
		_drag = _drag.lerp(Vector2.ZERO, clampf(delta, 0.0, 1.0))
	_now = _now.lerp(want, clampf(delta * EASE_PER_SEC, 0.0, 1.0))
	var low: bool = int(SettingsManager.get_setting("graphics_tier", 2)) == 0
	_mat.set_shader_parameter("parallax", _now * (POINTER_LOW if low else 1.0))
	_mat.set_shader_parameter("drift_amount", 0.0 if calm else DRIFT)
