extends WeaponBase
class_name WeaponShotgun

@export var pellet_damage: int = 8
@export var pellet_count: int = 5
@export var spread_degrees: float = 15.0

@onready var _rays: Node3D = $Rays
@onready var _sfx: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready() -> void:
	super._ready()
	# P2 (FINAL INTEGRATION wave): was never set here (unlike weapon_pistol.gd),
	# so weapon_compare_ui.gd's "from -> to" title showed a blank name every
	# time the player switched to or from the shotgun.
	weapon_name = "Shotgun"
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
		var ray_list: Array = _rays.get_children()
		# Раньше пучок стрелял по жёстко прописанным в сцене смещениям 0.05-0.1 м
		# на 10 м (~0.5°) — «разброс дробовика» был уже, чем у автомата.
		# Теперь конус считается из spread_degrees.
		var spread_units: float = 2.0 * tan(deg_to_rad(spread_degrees) * 0.5)
		var pellets: int = mini(pellet_count, ray_list.size())
		for i in pellets:
			var ray := ray_list[i] as RayCast3D
			hitscan_ray(ray, spread_units, float(pellet_damage))
	_spawn_muzzle(from_pos)
	if _sfx:
		_sfx.pitch_scale = 0.9
		_sfx.play()
	fired.emit()
	return true
