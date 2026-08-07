
extends Area3D

@export 
var key_id: String = "key_red"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	
	var inv := body.get_node_or_null("InventoryManager")
	if inv and inv.has_method("add_key"):
		inv.add_key(key_id)
	queue_free()
