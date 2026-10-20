extends Node
## Frame runners' bootstrap (scenes/tools/anim_frames_scene.tscn and player_frames_scene.tscn): the runner lives under /root like the density frames' one.

@export_file("*.gd") var runner: String = "res://scripts/tools/_anim_frames_runner.gd"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var node := Node.new()
	node.name = "FramesRunner"
	node.set_script(load(runner))
	get_tree().root.add_child(node)
