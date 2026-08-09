extends Node
## Recoil — подключается к камере игрока при выстреле.
## Использование: recoil.setup(camera); recoil.add_recoil()

@export var recoil_amount: float = 0.05
@export var recoil_recovery: float = 5.0
@export var recoil_horizontal: float = 0.01  # лёгкое горизонтальное смещение

var _current_recoil: float = 0.0
var _current_h: float = 0.0
var _camera: Camera3D = null

func setup(camera: Camera3D) -> void:
	_camera = camera

func add_recoil(multiplier: float = 1.0) -> void:
	_current_recoil += recoil_amount * multiplier
	_current_h += randf_range(-recoil_horizontal, recoil_horizontal) * multiplier

func _process(delta: float) -> void:
	if _camera == null:
		return
	if _current_recoil > 0.0:
		_camera.rotation.x -= _current_recoil * delta * 60.0
		_current_recoil = move_toward(_current_recoil, 0.0, recoil_recovery * delta)
	if abs(_current_h) > 0.0:
		_camera.rotation.y += _current_h * delta * 60.0
		_current_h = move_toward(_current_h, 0.0, recoil_recovery * delta)
