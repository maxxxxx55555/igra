extends WeaponBase
class_name WeaponRifle

const SHOOT := preload("res://assets/audio/sfx/sfx_shoot.wav")
const RELOAD := preload("res://assets/audio/sfx/sfx_reload.wav")

func _ready() -> void:
	weapon_name = "Rifle"
	damage = 14.0
	fire_rate = 0.12
	max_ammo = 30
	reload_time = 2.2
	spread = 0.012
	automatic = true
	fire_sound = SHOOT
	reload_sound = RELOAD
	super._ready()
