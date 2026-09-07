extends WeaponBase
class_name WeaponRifle

@export var hitscan_damage: int = 12
@export var hitscan_spread: float = 0.05

@onready var _ray: RayCast3D = $RayCast3D
@onready var _sfx: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready() -> void:
	super._ready()
	# P2 (FINAL INTEGRATION wave): was never set here (unlike weapon_pistol.gd),
	# so weapon_compare_ui.gd's "from -> to" title showed a blank name every
	# time the player switched to or from the rifle.
	weapon_name = "Rifle"
	damage = hitscan_damage
	if _sfx and ResourceLoader.exists("res://assets/audio/sfx/sfx_shoot.wav"):
		_sfx.stream = load("res://assets/audio/sfx/sfx_shoot.wav")

func fire(from_pos: Vector3 = Vector3.ZERO, direction: Vector3 = Vector3.FORWARD) -> bool:
	if not can_fire():
		return false
	_fire_timer = fire_rate
	current_ammo -= 1
	ammo_changed.emit(current_ammo, max_ammo)
	# Общий хитскан WeaponBase: тот же RayCast3D из сцены, но с исключением
	# собственного тела игрока и с реальной точкой попадания в take_damage.
	hitscan_ray(_ray, hitscan_spread, float(hitscan_damage))
	_spawn_muzzle(from_pos)
	if _sfx:
		_sfx.pitch_scale = 1.2
		_sfx.play()
	fired.emit()
	return true
