extends Node
## Perf gate: draw calls, primitives and objects once real gameplay is running, then the frame time and the video memory of the first
## and the last district, against the budgets of _perf_check_runner.gd (D1 < 200 and D11 < 350 draw calls, p95 <= 33 ms, 512 MiB).
## It fails the build when one is over; a headless run only skips (the dummy renderer counts no draw calls).
##
##   tools/qa_sim/guarded_windowed res://scenes/tools/perf_check_scene.tscn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var r := Node.new()
	r.name = "PerfCheckRunner"
	r.set_script(load("res://scripts/tools/_perf_check_runner.gd"))
	get_tree().root.add_child(r)
