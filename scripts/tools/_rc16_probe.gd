extends Node
## rc16 probe bootstrap (tools/qa_sim/rc16_probe): the runner lives under /root so the scene swaps of the game's own flow do not free it.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var runner := Node.new()
	runner.name = "Rc16ProbeRunner"
	runner.set_script(load("res://scripts/tools/_rc16_probe_runner.gd"))
	get_tree().root.add_child(runner)
