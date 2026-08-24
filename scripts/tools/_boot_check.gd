extends Node
## PERMANENT gate (TRUTH WAVE P0.4) bootstrap. The actual driver
## (_boot_check_runner.gd) needs to survive Routes.goto() scene swaps, so
## it's attached to get_tree().root, not to this node — this node itself
## IS the initial current_scene and would be freed by the first scene
## change otherwise (same pattern as _smoke_fps_flow.gd).

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	# _smoke_fps_flow.gd's exact pattern: get_tree().root is still mid-setup
	# during _ready() itself, so a direct add_child() here fails outright
	# ("Parent node is busy setting up children") — deferred to next idle
	# frame, after the tree has finished adding this node as current_scene.
	var r := Node.new()
	r.name = "BootCheckRunner"
	r.set_script(load("res://scripts/tools/_boot_check_runner.gd"))
	get_tree().root.add_child(r)
