extends Node
## Sign-off frames: six windowed captures into docs/stills/final/ (see
## _final_frames_runner.gd). Windowed only; the user:// profile is snapshotted
## and restored (qa_launch_guard.gd / tools/qa_sim/guarded_windowed).
##   tools/qa_sim/guarded_windowed res://scenes/tools/final_frames_scene.tscn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var r := Node.new()
	r.name = "FinalFramesRunner"
	r.set_script(load("res://scripts/tools/_final_frames_runner.gd"))
	get_tree().root.add_child(r)
