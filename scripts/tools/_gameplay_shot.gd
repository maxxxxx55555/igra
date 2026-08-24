extends Node
## RESCUE WAVE: one-shot gameplay screenshot bootstrap. Mirrors
## _boot_check.gd's pattern exactly - the actual runner must live under
## get_tree().root, not as this scene's own root, because Routes.goto()
## replaces current_scene and would free a runner living inside it
## mid-coroutine ("Parameter data.tree is null").

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var r := Node.new()
	r.name = "GameplayShotRunner"
	r.set_script(load("res://scripts/tools/_gameplay_shot_runner.gd"))
	get_tree().root.add_child(r)
