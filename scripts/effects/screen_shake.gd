
extends Node

@export 
var shake_intensity: float = 0.5

@export 
var shake_decay: float = 5.0

var _trauma: float = 0.0

var _camera: Camera3D = null

var _base_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.enemy_died.connect(_on_enemy_died)

func _process(delta: float) -> void:
	if _trauma > 0 and _camera:
		_camera.position = _base_position + Vector3(
			randf_range(-1, 1) * _trauma * shake_intensity,
			randf_range(-1, 1) * _trauma * shake_intensity,
			0
		)
		_trauma = max(0.0, _trauma - shake_decay * delta)
	elif _camera:
		_camera.position = _base_position

func setup(camera: Camera3D) -> void:
	_camera = camera
	_base_position = camera.position

func add_trauma(amount: float) -> void:
	_trauma = min(1.0, _trauma + amount)

func _on_player_damaged(_amount: int) -> void:
	add_trauma(0.3)

func _on_enemy_died(_pos: Vector3) -> void:
	add_trauma(0.1)
