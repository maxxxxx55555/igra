extends Node
## Bootstrap for the GUI exploration driver. Same pattern as
## _capture_stills_bootstrap.gd: the driver (tools/qa_sim/gui_explore_runner.gd)
## must outlive the Routes scene swaps it triggers, so it is parented to
## get_tree().root instead of living as this scene's own root.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var r := Node.new()
	r.name = "GuiExploreRunner"
	r.set_script(load("res://tools/qa_sim/gui_explore_runner.gd"))
	get_tree().root.add_child(r)
