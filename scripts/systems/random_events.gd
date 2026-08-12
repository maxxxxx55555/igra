extends Node
enum Ev { BLACKOUT, SURGE, DISTRESS, ACCIDENT }
const EV_COUNT: int = 4
const NAMES := {
	Ev.BLACKOUT: "EVENT_BLACKOUT",
	Ev.SURGE: "EVENT_SURGE",
	Ev.DISTRESS: "EVENT_DISTRESS",
	Ev.ACCIDENT: "EVENT_ACCIDENT",
}
var _timer: float = 0.0
@export var min_interval: float = 60.0
@export var max_interval: float = 95.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_timer = randf_range(min_interval, max_interval)
func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(min_interval, max_interval)
		_fire()
func _fire() -> void:
	var ev: int = randi() % EV_COUNT
	EventBus.inventory_notice.emit(LocalizationManager.t(NAMES[ev]))
	match ev:
		Ev.BLACKOUT:
			var d := _random_non_full_district()
			if d != &"":
				EventBus.district_blackout.emit(d)
		Ev.SURGE:
			EventBus.light_disrupted.emit()
		Ev.DISTRESS:
			pass
		Ev.ACCIDENT:
			var p := get_tree().get_first_node_in_group("player")
			if is_instance_valid(p):
				EventBus.noise_emitted.emit(Vector2(p.global_position.x, p.global_position.z), 320.0)
func _random_non_full_district() -> StringName:
	var candidates: Array = []
	for d in PowerGrid.all_districts():
		if d.stage < DistrictData.Stage.FULL:
			candidates.append(d.id)
	if candidates.is_empty():
		return &""
	return candidates[randi() % candidates.size()]