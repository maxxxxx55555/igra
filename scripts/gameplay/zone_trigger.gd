class_name ZoneTrigger
extends Area3D
## E1: зона исследования. Активирует EXPLORE-квесты и сигналы.

@export var zone_id: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and zone_id != "":
		EventBus.zone_reached.emit(StringName(zone_id))
		EventBus.inventory_notice.emit("ИССЛЕДОВАНО: " + zone_id)
		queue_free()
