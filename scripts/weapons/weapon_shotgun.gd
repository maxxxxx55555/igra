extends WeaponBase
class_name WeaponShotgun

@export var pellet_damage: int = 8
@export var pellet_count: int = 5
@export var spread_degrees: float = 15.0

@onready var _rays: Node3D = $Rays
@onready var _sfx: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready() -> void:
	super._ready()
	damage = pellet_damage
	if _sfx and ResourceLoader.exists("res://assets/audio/sfx/sfx_shoot.wav"):
		_sfx.stream = load("res://assets/audio/sfx/sfx_shoot.wav")

func fire(from_pos: Vector3 = Vector3.ZERO, direction: Vector3 = Vector3.FORWARD) -> bool:
	if not can_fire():
		return false
	_fire_timer = fire_rate
	current_ammo -= 1
	ammo_changed.emit(current_ammo, max_ammo)
	if _rays:
		var ray_list := _rays.get_children() as Array[RayCast3D]
		for ray in ray_list:
			ray.force_raycast_update()
			if ray.is_colliding():
				var target := ray.get_collider()
				if target and target.has_method("take_damage"):
					target.take_damage(pellet_damage)
				elif target and target.has_node("HealthComponent"):
					target.get_node("HealthComponent").take_damage(pellet_damage)
	if _sfx:
		_sfx.pitch_scale = 0.9
		_sfx.play()
	fired.emit()
	return true
