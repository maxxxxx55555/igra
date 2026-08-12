extends Node

func _ready() -> void:
	await get_tree().process_frame
	if get_tree().current_scene == null or get_tree().current_scene.name == "":
		Routes.goto("res://scenes/ui/splash.tscn")