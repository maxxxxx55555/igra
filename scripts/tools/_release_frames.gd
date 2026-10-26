extends Node

func _ready() -> void:
	_start.call_deferred()

func _start() -> void:
	var runner := Node.new()
	runner.set_script(load("res://scripts/tools/_release_frames_runner.gd"))
	get_tree().root.add_child(runner)
