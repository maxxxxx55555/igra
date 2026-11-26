extends Node
## Scene-root wrapper for the full-resolution sign-off runner. The runner is
## added under /root so Routes.goto() scene swaps do not free it mid-capture.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")


func _start() -> void:
	var runner := Node.new()
	runner.name = "FinalFramesFullRunner"
	runner.set_script(load("res://scripts/tools/_final_frames_full_runner.gd"))
	get_tree().root.add_child(runner)
