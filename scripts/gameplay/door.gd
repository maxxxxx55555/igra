
extends StaticBody3D

@export 
var required_key: String = "key_red"

@export 
var is_open: bool = false

@onready 
var mesh: MeshInstance3D = $MeshInstance3D

@onready 
var collision: CollisionShape3D = $CollisionShape3D

func interact(player: Node3D) -> void:
	if is_open:
		return
	
	var inv := player.get_node_or_null("InventoryManager")
	if inv and inv.has_item(required_key):
		_open()
	else:
		_show_locked()

func _open() -> void:
	is_open = true
	
	var tween := create_tween()
	tween.tween_property(mesh, "position:y", -2.0, 1.0).set_trans(Tween.TRANS_QUAD)
	collision.disabled = true

func _show_locked() -> void:
	
	var tween := create_tween()
	tween.tween_property(mesh, "position:z", 0.2, 0.1)
	tween.tween_property(mesh, "position:z", 0.0, 0.1)
