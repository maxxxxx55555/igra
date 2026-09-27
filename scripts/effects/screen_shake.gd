extends Node
## ScreenShake — подключается к камере. Слушает EventBus.
## Использование: screen_shake.setup(camera); screen_shake.add_trauma(0.5)

@export var shake_intensity: float = 0.5
@export var shake_decay: float = 5.0

var _trauma: float = 0.0
var _camera: Camera3D = null

func _ready() -> void:
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.enemy_died.connect(_on_enemy_died)

func setup(camera: Camera3D) -> void:
	_camera = camera

func add_trauma(amount: float) -> void:
	if SettingsManager.get_setting("reduce_screen_shake", false):
		return
	_trauma = minf(1.0, _trauma + amount)

## Shakes through h_offset/v_offset, never position: camera_follow_3d.gd owns
## the position, and writing it here every frame (even at zero trauma) pinned
## the FPS camera where the scene placed it, (0, 1.7, 0), while the player
## walked away (rc14 final frames).
func _process(delta: float) -> void:
	if _camera == null:
		return
	var t2: float = _trauma * _trauma  # квадратичная кривая — мягче
	_camera.h_offset = randf_range(-1.0, 1.0) * t2 * shake_intensity
	_camera.v_offset = randf_range(-1.0, 1.0) * t2 * shake_intensity
	_trauma = maxf(0.0, _trauma - shake_decay * delta)

func _on_player_damaged(_amount: int) -> void:
	add_trauma(0.3)

func _on_enemy_died(_pos: Vector3) -> void:
	add_trauma(0.15)
