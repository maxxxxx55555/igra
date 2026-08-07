extends Area2D

@export var puzzle_id: StringName
@export var district_id: StringName
@export var action_name: String = "Activate"

var solved: bool = false

func _ready() -> void:
	add_to_group("interactable")
	monitorable = true

func interact(_player: Node) -> void:
	if solved:
		return
	var pg := get_node_or_null("/root/PowerGrid")
	if pg != null and pg.has_method("is_powered") and not pg.is_powered(district_id):
		pg.toggle_district(district_id)
	solved = true
	modulate = Color(0.5, 0.5, 0.5, 0.6)