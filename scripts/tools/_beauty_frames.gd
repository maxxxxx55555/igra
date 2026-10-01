extends Node
## Beauty-pass frames: 8 windowed captures into docs/stills/beauty/<BEAUTY_TAG>/
## (see _beauty_frames_runner.gd). Windowed only; the user:// profile is
## snapshotted and restored and the Master bus is muted (qa_launch_guard.gd).
##   BEAUTY_TAG=before tools/qa_sim/guarded_windowed res://scenes/tools/beauty_frames_scene.tscn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var r := Node.new()
	r.name = "BeautyFramesRunner"
	r.set_script(load("res://scripts/tools/_beauty_frames_runner.gd"))
	get_tree().root.add_child(r)
