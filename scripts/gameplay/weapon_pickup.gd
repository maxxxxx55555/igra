extends Area3D
## G25 (GDD §18): a firearm lying in a street (DistrictLoot.WEAPON_FINDS). Touching it unlocks the weapon
## for the run and puts a magazine's worth of rounds in the shared reserve. C3 (v1.0.0-ship): the gun lies on the ground on
## its side (scripts/art/weapon_meshes.gd) and turns slowly; it does not bob.

const _Meshes := preload("res://scripts/art/pickup_meshes.gd")

@export var weapon_name: String = "pistol"  # pistol, rifle, shotgun
@export var ammo_amount: int = 12

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_Meshes.dress(self, mesh, StringName(weapon_name))

func _on_body_entered(body: Node3D) -> void:
	var manager := body.get_node_or_null("WeaponManager") as WeaponManager
	if manager == null or not body.is_in_group("player"):
		return
	manager.unlock(StringName(weapon_name))
	manager.add_ammo(ammo_amount)
	queue_free()
