extends Area3D
## A1: Chekpoint - voskreshenie s etoj tochki

@export var checkpoint_name: String = "Checkpoint"
var _used: bool = false

func _ready() -> void:
	body_entered.connect(_on_body)

func _on_body(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	var lm := get_tree().root.get_node_or_null("/root/LevelManager")
	if lm and lm.has_method("set_checkpoint"):
		lm.set_checkpoint(global_position)
	if not _used:
		_used = true
		_flash()

func _flash() -> void:
	var mi = get_node_or_null("Marker")
	if mi:
		var tw = create_tween()
		tw.tween_property(mi, "modulate", Color(1, 1, 0.4), 0.3)
		tw.tween_property(mi, "modulate", Color.WHITE, 0.6)
