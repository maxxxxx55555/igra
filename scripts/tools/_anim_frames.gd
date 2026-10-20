extends Node
## Pose frames bootstrap (scenes/tools/anim_frames_scene.tscn): the runner lives under /root like the density frames' one.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var runner := Node.new()
	runner.name = "AnimFramesRunner"
	runner.set_script(load("res://scripts/tools/_anim_frames_runner.gd"))
	get_tree().root.add_child(runner)
