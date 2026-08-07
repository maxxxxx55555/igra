extends Control

func _ready() -> void:
	add_to_group("ui_root")
	$VBox/Menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
