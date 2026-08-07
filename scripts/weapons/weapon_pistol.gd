

extends WeaponBase

const SHOOT := preload("res://assets/audio/sfx/sfx_shoot.wav")
const RELOAD := preload("res://assets/audio/sfx/sfx_reload.wav")

func _ready() -> void:
	super._ready()
	weapon_name = "Pistol"
	damage = 25
	fire_rate = 0.3
	max_ammo = 12
	reload_time = 1.2
	fire_sound = SHOOT
	reload_sound = RELOAD