extends Node
## Bootstrap for the still-capture tool. Same pattern as _boot_check.gd /
## _gameplay_shot.gd: the driver (tools/qa_sim/capture_stills.gd) must
## outlive the Routes scene swaps it triggers, so it is parented to
## get_tree().root instead of living as this scene's own root.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var r := Node.new()
	r.name = "CaptureStillsRunner"
	r.set_script(load("res://tools/qa_sim/capture_stills.gd"))
	get_tree().root.add_child(r)
