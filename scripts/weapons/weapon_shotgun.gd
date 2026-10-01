extends WeaponBase
class_name WeaponShotgun

const SHOOT := preload("res://assets/audio/sfx/sfx_shoot.wav")
const RELOAD := preload("res://assets/audio/sfx/sfx_reload.wav")

func _ready() -> void:
	weapon_name = "Shotgun"
	damage = 8.0
	pellets = 5
	fire_rate = 0.9
	max_ammo = 6
	reload_time = 2.4
	spread = 0.09
	range = 18.0
	fire_sound = SHOOT
	reload_sound = RELOAD
	super._ready()
