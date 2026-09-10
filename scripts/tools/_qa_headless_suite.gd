extends Node
## GOLD MASTER headless suite bootstrap. Same pattern as _boot_check.gd:
## the real driver (_qa_headless_suite_runner.gd) has to outlive the
## Routes.goto() scene swaps it triggers, so it is parented to
## get_tree().root, not to this node (which is the initial current_scene
## and would be freed by the first scene change).

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var r := Node.new()
	r.name = "QAHeadlessSuiteRunner"
	r.set_script(load("res://scripts/tools/_qa_headless_suite_runner.gd"))
	get_tree().root.add_child(r)
