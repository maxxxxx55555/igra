extends WeaponBase
class_name WeaponRifle

@export var hitscan_damage: int = 12
@export var hitscan_spread: float = 0.05

@onready var _ray: RayCast3D = $RayCast3D
@onready var _sfx: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready() -> void:
	super._ready()
	damage = hitscan_damage
	if _sfx and ResourceLoader.exists("res://assets/audio/sfx/sfx_shoot.wav"):
		_sfx.stream = load("res://assets/audio/sfx/sfx_shoot.wav")

func fire(from_pos: Vector3 = Vector3.ZERO, direction: Vector3 = Vector3.FORWARD) -> bool:
	if not can_fire():
		return false
	_fire_timer = fire_rate
	current_ammo -= 1
	ammo_changed.emit(current_ammo, max_ammo)
	if _ray:
		_ray.target_position = Vector3(randf() - 0.5, randf() - 0.5, -1) * hitscan_spread + Vector3(0, 0, -10)
		_ray.force_raycast_update()
		if _ray.is_colliding():
			var target := _ray.get_collider()
			if target and target.has_method("take_damage"):
				target.take_damage(hitscan_damage, Vector3.ZERO, EnemyRosterData.DamageType.BULLET)
			elif target and target.has_node("HealthComponent"):
				target.get_node("HealthComponent").take_damage(hitscan_damage)
	if _sfx:
		_sfx.pitch_scale = 1.2
		_sfx.play()
	fired.emit()
	return true
