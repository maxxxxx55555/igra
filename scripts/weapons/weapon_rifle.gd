
extends Node3D

@export 
var damage: int = 12

@export 
var fire_rate: float = 0.1

@export 
var spread: float = 0.05

@export 
var ammo: int = 30

@export 
var reload_time: float = 2.0

@onready 
var ray: RayCast3D = $RayCast3D

@onready 
var sfx: AudioStreamPlayer3D = $AudioStreamPlayer3D

var _ammo: int

var _can_fire: bool = true

var _reloading: bool = false

func _ready() -> void:
	_ammo = ammo
	if sfx and ResourceLoader.exists("res://assets/audio/sfx/sfx_shoot.wav"):
		sfx.stream = load("res://assets/audio/sfx/sfx_shoot.wav")

func fire() -> void:
	if not _can_fire or _reloading or _ammo <= 0:
		return
	_ammo -= 1
	_can_fire = false
	if ray:
		ray.target_position = Vector3(randf()-0.5, randf()-0.5, -1) * spread + Vector3(0,0,-10)
		ray.force_raycast_update()
		if ray.is_colliding():
			var target := ray.get_collider()
			if target.has_method("take_damage"):
				target.take_damage(damage)
			elif target.has_node("HealthComponent"):
				target.get_node("HealthComponent").take_damage(damage)
	if sfx:
		sfx.pitch_scale = 1.2
		sfx.play()
	await get_tree().create_timer(fire_rate).timeout
	_can_fire = true
	if _ammo <= 0:
		_reload()

func _reload() -> void:
	_reloading = true
	await get_tree().create_timer(reload_time).timeout
	_ammo = ammo
	_reloading = false

func get_ammo() -> int:
	return _ammo
