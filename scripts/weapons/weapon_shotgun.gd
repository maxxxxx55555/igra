
extends Node3D

@export 
var damage_per_pellet: int = 8

@export 
var pellets: int = 5

@export 
var fire_rate: float = 0.8

@export 
var ammo: int = 6

@export 
var reload_time: float = 2.5

@export 
var spread_degrees: float = 15.0

@onready 
var rays: Node3D = $Rays

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
	
	var ray_list := rays.get_children() as Array[RayCast3D]
	for ray in ray_list:
		ray.force_raycast_update()
		if ray.is_colliding():
			var target := ray.get_collider()
			if target.has_method("take_damage"):
				target.take_damage(damage_per_pellet)
			elif target.has_node("HealthComponent"):
				target.get_node("HealthComponent").take_damage(damage_per_pellet)
	if sfx:
		sfx.pitch_scale = 0.9
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
