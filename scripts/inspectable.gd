extends Area3D

@export var inspect_text: String = ""
@export var inspect_title: String = ""
@export var inspect_icon: String = ""

var _player_nearby: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	var body_col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 2.0
	body_col.shape = shape
	add_child(body_col)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("inspectable")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		EventBus.player_interact_available.emit(true)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		EventBus.player_interact_available.emit(false)

func try_inspect() -> bool:
	if not _player_nearby:
		return false
	var text := inspect_text
	if text.is_empty():
		text = "Nothing of interest."
	EventBus.examine_text.emit(text)
	var sm := get_tree().root.get_node_or_null("/root/StatsManager")
	if sm and sm.has_method("add_inspect"):
		sm.add_inspect()

	return true
