extends Area2D
@export var item_id: StringName
@export var amount: int = 1
func _ready() -> void:
    add_to_group("interactable")
    monitorable = true
func interact(_player: Node) -> void:
    if InventoryManager.try_add(item_id, amount):
        queue_free()