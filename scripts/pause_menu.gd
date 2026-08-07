extends Control

func _ready() -> void:
	add_to_group("ui_root")
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	$VBox/Resume.pressed.connect(func(): get_tree().paused = false; hide())
	$VBox/Settings.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/settings.tscn"))
	$VBox/Menu.pressed.connect(func(): get_tree().paused = false; get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	$VBox/Quit.pressed.connect(func(): get_tree().quit())
