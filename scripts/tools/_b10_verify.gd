extends Node
## B10 render verification launcher (see _b10_verify_runner.gd).
##   tools/qa_sim/guarded_windowed res://scenes/tools/b10_verify_scene.tscn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var r := Node.new()
	r.name = "B10VerifyRunner"
	r.set_script(load("res://scripts/tools/_b10_verify_runner.gd"))
	get_tree().root.add_child(r)