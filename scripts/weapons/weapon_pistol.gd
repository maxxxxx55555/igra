extends WeaponBase

const SHOOT := preload("res://assets/audio/sfx/sfx_shoot.wav")
const RELOAD := preload("res://assets/audio/sfx/sfx_reload.wav")

func _ready() -> void:
	weapon_name = "Pistol"
	damage = 25.0
	fire_rate = 0.3
	max_ammo = 12
	reload_time = 1.2
	spread = 0.015
	fire_sound = SHOOT
	reload_sound = RELOAD
	super._ready()
