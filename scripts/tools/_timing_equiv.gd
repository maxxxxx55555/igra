extends Node
## rc16 O2 frame-independence probe (tools/qa_sim/timing_equiv): spawns the runner under /root so it survives the scene swap of the
## game's own flow, like the closeout gate.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var runner := Node.new()
	runner.name = "TimingEquivRunner"
	runner.set_script(load("res://scripts/tools/_timing_equiv_runner.gd"))
	get_tree().root.add_child(runner)
