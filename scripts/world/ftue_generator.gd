extends Area2D

var completed: bool = false
var action_name: String = ""
var objective_text: String = ""

func _ready() -> void:
	add_to_group("interactable")
	monitorable = true

func set_ftue_objective(text: String) -> void:
	objective_text = text

func interact(_player: Node) -> void:
	if completed:
		return
	completed = true
	var power_grid := get_node_or_null("/root/PowerGrid")
	if power_grid == null or not power_grid.advance_district(&"suburbs", DistrictData.Stage.STREETS):
		completed = false
		return
	EventBus.toast_requested.emit(tr("FTUE_STREET_LIT"), "objective")
	EventBus.inventory_notice.emit(tr("FTUE_OBJECTIVE_UPDATED"))
	modulate = Color(0.5, 0.5, 0.5, 0.6)
