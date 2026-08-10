extends Node

signal noise_detected(source_pos: Vector2, radius: float, intensity: float, source_type: String)

@export var max_noise_sources: int = 32

var _sources: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.noise_emitted.connect(_on_noise_emitted)

func _on_noise_emitted(pos: Vector2, radius: float, intensity: float = 1.0, source_type: String = "generic") -> void:
	if _sources.size() >= max_noise_sources:
		_sources.pop_front()
	_sources.append({
		"pos": pos,
		"radius": radius,
		"intensity": intensity,
		"type": source_type,
		"time": Time.get_ticks_msec() * 0.001
	})

func get_noise_at(pos: Vector2) -> float:
	var total: float = 0.0
	var now: float = Time.get_ticks_msec() * 0.001
	for src in _sources:
		var age: float = now - src["time"]
		if age > src["radius"] * 0.5:
			continue
		var dist: float = pos.distance_to(src["pos"])
		if dist <= src["radius"]:
			var falloff: float = 1.0 - (dist / src["radius"])
			total += src["intensity"] * falloff * (1.0 - age * 0.2)
	return clampf(total, 0.0, 1.0)

func get_sources_in_range(pos: Vector2, radius: float) -> Array:
	var result: Array = []
	for src in _sources:
		if src["pos"].distance_to(pos) <= radius:
			result.append(src)
	return result

func clear() -> void:
	_sources.clear()