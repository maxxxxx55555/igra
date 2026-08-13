extends Control

func _ready() -> void:
	add_to_group("ui_root")
	$VBox/Retry.pressed.connect(func(): Routes.restart_game())
	$VBox/Menu.pressed.connect(func(): Routes.to_menu())
