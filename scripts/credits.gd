extends Control

func _ready() -> void:
	add_to_group("ui_root")
	$VBox/Back.pressed.connect(func(): Routes.to_menu())
