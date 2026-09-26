extends Node
## C4 TZ-VERIFY: windowed-only. Boots into real gameplay, puts each applied
## TZ row into its state, saves one frame per row to docs/stills/tzverify/
## and prints the row's numeric evidence. A saved PNG is REBACK_UNVERIFIED
## until someone actually looks at it.
##   tools/qa_sim/tz_verify   (or a direct godot launch of tz_verify_scene.tscn; either way
##   the user:// profile is snapshotted and restored, see qa_launch_guard.gd)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var r := Node.new()
	r.name = "TzVerifyRunner"
	r.set_script(load("res://scripts/tools/_tz_verify_runner.gd"))
	get_tree().root.add_child(r)
