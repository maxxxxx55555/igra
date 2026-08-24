extends Area3D
## WAVE 6 P3: generic "reach this landmark" quest trigger. Mirrors
## district_trigger.gd's exact pattern but emits EventBus.zone_reached
## (String, per event_bus.gd's signature) instead of district_entered.
## Feeds q_explore_school/q_find_engineers (both EXPLORE-type quests in
## quest_manager.gd, target_count=1) - neither had any real trigger
## anywhere, so both were permanently stuck at 0/1.

@export var zone_id: String = ""
@export var one_shot: bool = true

var _fired: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(b: Node) -> void:
	if one_shot and _fired:
		return
	if not b.is_in_group("player"):
		return
	if zone_id == "":
		return
	_fired = true
	EventBus.zone_reached.emit(zone_id)
