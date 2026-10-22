extends Area3D
## G25 (GDD §18): a box of rounds (DistrictLoot.AMMO_PER_PICKUP) for the shared reserve, whatever gun is drawn.
## C3 (v1.0.0-ship): it is a box on the ground (scripts/art/pickup_meshes.gd), not a floating cube.

const _Meshes := preload("res://scripts/art/pickup_meshes.gd")

@export var ammo_amount: int = 12
## Where this box sits in its district's loot list (DistrictLoot): a taken key is not spawned again.
var loot_key: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var piece := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if piece != null:
		_Meshes.dress(self, piece, &"ammo")

func _on_body_entered(body: Node3D) -> void:
	var manager := body.get_node_or_null("WeaponManager") as WeaponManager
	if manager == null or not body.is_in_group("player"):
		return
	manager.add_ammo(ammo_amount)
	if loot_key != "":
		ProgressTracker.mark_loot_taken(loot_key)
	EventBus.inventory_notice.emit(LocalizationManager.tf("AMMO_FOUND", [ammo_amount]))
	queue_free()
