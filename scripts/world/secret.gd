extends Area2D
@export var item_id: StringName = &"battery"
@export var amount: int = 1
@export var secret_id: StringName = &""
var _taken: bool = false
func _ready() -> void:
	add_to_group("interactable")
	monitorable = true
func interact(_player: Node) -> void:
	if _taken:
		return
	_taken = true
	InventoryManager.try_add(item_id, amount)
	EventBus.secret_found.emit(secret_id)
	EventBus.inventory_notice.emit(tr("SECRET_FOUND"))
	queue_free()