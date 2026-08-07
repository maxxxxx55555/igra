extends Control

func _ready() -> void:
	add_to_group("ui_root")
	$VBox/Retry.pressed.connect(func(): get_tree().reload_current_scene())
	$VBox/Menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
