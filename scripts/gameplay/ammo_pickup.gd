
extends Area3D

@export 
var weapon_name: String = "pistol"

@export 
var ammo_amount: int = 15

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("add_ammo"):
		body.add_ammo(weapon_name, ammo_amount)
	queue_free()
