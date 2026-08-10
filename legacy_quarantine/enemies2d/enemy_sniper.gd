

extends "res://legacy_quarantine/enemies2d/enemy_fps.gd"

@onready 

var shoot_ray: RayCast3D = $ShootRay

@export 

var shoot_range: float = 25.0

@export 

var shoot_cooldown: float = 3.0
var _can_shoot: bool = true
func _ready() -> void:
	super._ready()
	speed = 0.0  # Ne dvigaetsja
	health.max_health = 40
	detection_range = shoot_range
func _physics_process(delta: float) -> void:
	if _target and _can_shoot and _can_see_target():
		_shoot()
	super._physics_process(delta)

func _shoot() -> void:
	_can_shoot = false
	AudioManager.play_sfx(load("res://assets/audio/sfx/sfx_shoot.wav"))
	if _target and _target.has_method("take_damage"):
		_target.take_damage(15)
	await get_tree().create_timer(shoot_cooldown).timeout
	_can_shoot = true