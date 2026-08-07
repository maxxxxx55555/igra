extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var r := Node.new()
	r.name = "SmokeRunner"
	r.set_script(load("res://scripts/tools/_smoke_fps_runner.gd"))
	get_tree().root.add_child(r)
	get_tree().change_scene_to_file("res://scenes/main_3d.tscn")
