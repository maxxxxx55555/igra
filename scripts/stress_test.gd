extends Node


func _ready() -> void:
	await get_tree().create_timer(5.0).timeout
	_run()


func _run() -> void:
	var monsters: int = get_tree().get_nodes_in_group("monsters").size()
	var lights: int = get_tree().get_nodes_in_group("streetlights").size()
	var districts: int = PowerGrid.total_count()
	var fps: int = Engine.get_frames_per_second()
	var mem: int = OS.get_static_memory_usage() / 1024 / 1024
	var _pass: bool = fps >= 20 and mem < 512

