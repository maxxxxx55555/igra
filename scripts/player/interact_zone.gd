extends Area2D
func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
func _on_entered(body: Node) -> void:
	_try_set(body)
func _on_exited(body: Node) -> void:
	_try_clear(body)
func _on_area_entered(area: Area2D) -> void:
	_try_set(area)
func _on_area_exited(area: Area2D) -> void:
	_try_clear(area)
func _try_set(node: Node) -> void:
	if node.is_in_group("interactable"):
		var player := _get_player()
		if player:
			player.set_interact_target(node)
func _try_clear(node: Node) -> void:
	if node.is_in_group("interactable"):
		var player := _get_player()
		if player:
			player.set_interact_target(null)
func _get_player() -> Node:
	var p := get_parent()
	return p if (p and p.has_method("set_interact_target")) else null