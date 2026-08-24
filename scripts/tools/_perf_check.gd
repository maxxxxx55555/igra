extends Node
## RESCUE WAVE P3: perf-guard diagnostic. Prints draw calls / primitives /
## object counts once real gameplay is running. docs/PRODUCTION_BIBLE.md's
## checklist calls this "printed/verified headless, not yet an automated
## gate" - this prints and reports, it doesn't fail the build, since no
## district-by-district draw-call budget is wired to know which of the
## GDD's two budgets (<200 D1 / <350 D11) applies to the spawn district.
##
##   godot --path . --windowed res://scenes/tools/perf_check_scene.tscn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var r := Node.new()
	r.name = "PerfCheckRunner"
	r.set_script(load("res://scripts/tools/_perf_check_runner.gd"))
	get_tree().root.add_child(r)
