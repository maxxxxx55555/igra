extends Area3D
## DistrictTrigger: placed in each district scene; emits district_entered on body enter.

@export var district_id: StringName = &""
@export var one_shot: bool = false

var _bus: Node
var _fired: bool = false

func _ready() -> void:
	_bus = get_node_or_null("/root/EventBus")
	body_entered.connect(_on_body_entered)

func _on_body_entered(b: Node) -> void:
	if one_shot and _fired:
		return
	if not b.is_in_group("player"):
		return
	if district_id == &"":
		return
	_fired = true
	if _bus != null and _bus.has_method("emit_district_entered"):
		_bus.emit_district_entered(district_id)
	else:
		print("[DistrictTrigger] entered: ", district_id)