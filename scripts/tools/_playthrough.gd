extends Node
## rc15 play-through scene (see _playthrough_runner.gd). The runner lives under /root so the scene swaps it triggers
## (boot, menu, game) never free it.
##   tools/qa_sim/playthrough [A V B S | L]   (L: the full loop of _loop_runner.gd)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var runner := Node.new()
	runner.name = "PlaythroughRunner"
	var loop := OS.get_environment("PT_MODE").begins_with("L")
	runner.set_script(load("res://scripts/tools/_loop_runner.gd" if loop else "res://scripts/tools/_playthrough_runner.gd"))
	get_tree().root.add_child(runner)
