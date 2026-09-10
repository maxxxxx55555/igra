extends Node
## Autoplay-bot bootstrap. Same pattern as _boot_check.gd / _qa_headless_suite.gd:
## the driver (_qa_autoplay_runner.gd) must outlive the Routes scene swaps
## it triggers, so it is parented to get_tree().root.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var r := Node.new()
	r.name = "QAAutoplayRunner"
	r.set_script(load("res://scripts/tools/_qa_autoplay_runner.gd"))
	get_tree().root.add_child(r)
