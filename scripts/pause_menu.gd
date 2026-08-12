extends Control

func _ready() -> void:
	add_to_group("ui_root")
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	$VBox/Resume.pressed.connect(func(): get_tree().paused = false; hide())
	$VBox/Settings.pressed.connect(func(): Routes.goto(Routes.SETTINGS))
	$VBox/Menu.pressed.connect(func(): Routes.to_menu())
	$VBox/Quit.pressed.connect(func(): get_tree().quit())
