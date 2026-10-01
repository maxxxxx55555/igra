extends Node
## rc15 closeout gate (docs/FUNCTION_MATRIX.md X43-X53): the features the GDD promised and the code did not carry
## (firearms, workbench blueprints, photo album, hiding spots, the visibility model, the inventory screen, the
## achievements without a trigger, difficulty, the settings Back button). The runner lives under /root so the scene
## swap of its last check does not free it.
##   tools/qa_sim/closeout_check

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var runner := Node.new()
	runner.name = "CloseoutRunner"
	runner.set_script(load("res://scripts/tools/_closeout_check_runner.gd"))
	get_tree().root.add_child(runner)
