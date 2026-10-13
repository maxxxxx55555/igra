extends Node
## Density frames bootstrap (tools/qa_sim/density_frames): the runner lives under /root so the scene swaps of the game's own flow do not free it.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var runner := Node.new()
	runner.name = "DensityFramesRunner"
	runner.set_script(load("res://scripts/tools/_density_frames_runner.gd"))
	get_tree().root.add_child(runner)
