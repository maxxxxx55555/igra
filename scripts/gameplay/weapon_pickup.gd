extends Area3D
## G25 (GDD §18): a firearm lying in a street (DistrictLoot.WEAPON_FINDS). Touching it unlocks the weapon
## for the run and puts a magazine's worth of rounds in the shared reserve.

@export var weapon_name: String = "pistol"  # pistol, rifle, shotgun
@export var ammo_amount: int = 12

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.706, 0.271, 0.184)
	mat.emission_enabled = true
	mat.emission = Color(0.706, 0.271, 0.184)
	mat.emission_energy_multiplier = 0.6
	mesh.material_override = mat
	_animate_float()

func _animate_float() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(mesh, "position:y", 0.8, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(mesh, "position:y", 0.5, 1.0).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node3D) -> void:
	var manager := body.get_node_or_null("WeaponManager") as WeaponManager
	if manager == null or not body.is_in_group("player"):
		return
	manager.unlock(StringName(weapon_name))
	manager.add_ammo(ammo_amount)
	queue_free()
