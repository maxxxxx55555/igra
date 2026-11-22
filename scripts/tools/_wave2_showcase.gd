extends Node
## Adds the Wave 2 showcase runner under /root so scene swaps do not free it.
##   tools/qa_sim/guarded_windowed res://scenes/tools/wave2_showcase_scene.tscn 900

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var r := Node.new()
	r.name = "Wave2ShowcaseRunner"
	r.set_script(load("res://scripts/tools/_wave2_showcase_runner.gd"))
	get_tree().root.add_child(r)
