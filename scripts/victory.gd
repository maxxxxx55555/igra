extends Control

func _ready() -> void:
	add_to_group("ui_root")
	$VBox/Menu.pressed.connect(func(): Routes.to_menu())
