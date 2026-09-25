extends Node
## C4 TZ-VERIFY: windowed-only. Boots into real gameplay, puts each applied
## TZ row into its state, saves one frame per row to docs/stills/tzverify/
## and prints the row's numeric evidence. A saved PNG is REBACK_UNVERIFIED
## until someone actually looks at it.
##   tools/qa_sim/tz_verify   (the runner refuses a direct godot launch: it rewrites the
##   real user:// profile and only the wrapper's guard restores it after a crash)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var r := Node.new()
	r.name = "TzVerifyRunner"
	r.set_script(load("res://scripts/tools/_tz_verify_runner.gd"))
	get_tree().root.add_child(r)
