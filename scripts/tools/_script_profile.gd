extends Node
## Bootstrap of the script profile (tools/qa_sim/guarded_windowed res://scenes/tools/script_profile_scene.tscn): the runner lives under /root so the scene swaps of the game's own flow do not free it.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var runner := Node.new()
	runner.name = "ScriptProfileRunner"
	runner.set_script(load("res://scripts/tools/_script_profile_runner.gd"))
	get_tree().root.add_child(runner)
