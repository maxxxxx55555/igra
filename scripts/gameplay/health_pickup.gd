
extends Area3D

@export 
var heal_amount: int = 25

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	
	var hc := body.get_node_or_null("HealthComponent")
	if hc and hc.has_method("heal"):
		hc.heal(heal_amount)
	queue_free()
