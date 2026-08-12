extends Control

func _ready() -> void:
	add_to_group("ui_root")
	$VBox/Yes.pressed.connect(func(): get_tree().quit())
	$VBox/No.pressed.connect(func(): Routes.to_menu())
