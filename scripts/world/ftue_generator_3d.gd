extends Area3D

signal interaction_completed

var completed: bool = false

func _ready() -> void:
	add_to_group("interactable")
	monitorable = true

func interact(_player: Node) -> void:
	if completed:
		return
	var power_grid := get_node_or_null("/root/PowerGrid")
	if power_grid == null or not power_grid.has_method("advance_district"):
		return
	if not power_grid.advance_district(&"suburbs", DistrictData.Stage.STREETS):
		return
	completed = true
	interaction_completed.emit()
	EventBus.district_stage_changed.emit(&"suburbs", DistrictData.Stage.STREETS)
	EventBus.toast_requested.emit(tr("FTUE_STREET_LIT"), "objective")
	EventBus.inventory_notice.emit(tr("FTUE_OBJECTIVE_UPDATED"))
	var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh != null:
		mesh.modulate = Color(0.35, 0.35, 0.35, 1.0)
