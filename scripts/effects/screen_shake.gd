extends Node
## ScreenShake — подключается к камере. Слушает EventBus.
## Использование: screen_shake.setup(camera); screen_shake.add_trauma(0.5)

@export var shake_intensity: float = 0.5
@export var shake_decay: float = 5.0

var _trauma: float = 0.0
var _camera: Camera3D = null
var _base_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.enemy_died.connect(_on_enemy_died)

func setup(camera: Camera3D) -> void:
	_camera = camera
	_base_position = camera.position

func add_trauma(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)

func _process(delta: float) -> void:
	if _camera == null:
		return
	if _trauma > 0.0:
		var t2: float = _trauma * _trauma  # квадратичная кривая — мягче
		_camera.position = _base_position + Vector3(
			randf_range(-1.0, 1.0) * t2 * shake_intensity,
			randf_range(-1.0, 1.0) * t2 * shake_intensity,
			0.0
		)
		_trauma = maxf(0.0, _trauma - shake_decay * delta)
	else:
		_camera.position = _base_position

func _on_player_damaged(_amount: int) -> void:
	add_trauma(0.3)

func _on_enemy_died(_pos: Vector3) -> void:
	add_trauma(0.15)
