extends Control

func _ready() -> void:
	await get_tree().create_timer(1.2).timeout
	var menu := "res://scenes/main_menu.tscn"
	if not ResourceLoader.exists(menu):
		menu = "res://scenes/ui/main_menu.tscn"
	if not ResourceLoader.exists(menu):
		menu = "res://scenes/ui/menu.tscn"
	get_tree().change_scene_to_file(menu)