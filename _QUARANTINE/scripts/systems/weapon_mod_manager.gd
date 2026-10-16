

extends Node

var mods: Dictionary = {
	"silencer": {"name": "Glušitel", "effect": "silent", "damage_mult": 0.9, "recoil_mult": 0.7},
	"scope": {"name": "Pricel", "effect": "zoom", "damage_mult": 1.0, "accuracy_mult": 1.5},
	"extended_mag": {"name": "Rasshirennyj magazin", "effect": "ammo", "ammo_bonus": 10},
	"laser": {"name": "Lazer", "effect": "aim", "recoil_mult": 0.8, "spread_mult": 0.5},
	"grip": {"name": "Rukojatka", "effect": "stability", "recoil_mult": 0.6}}

var equipped_mods: Dictionary = {}  # weapon_id -> Array[mod_id]

func equip_mod(weapon_id: String, mod_id: String) -> bool:
	if not mods.has(mod_id):
		return false
	if not equipped_mods.has(weapon_id):
		equipped_mods[weapon_id] = []
	if equipped_mods[weapon_id].size() >= 3:
		return false  # Max 3 moda
	equipped_mods[weapon_id].append(mod_id)
	_apply_mods(weapon_id)
	return true

func _apply_mods(weapon_id: String) -> void:
	# Primenit k tekuschemu oruzhiju
	pass