extends Control

func _ready() -> void:
	add_to_group("ui_root")
	$VBox/Back.text = LocalizationManager.t("back_menu")
	$VBox/Title.text = LocalizationManager.t("credits")
	$VBox/Back.pressed.connect(func(): Routes.to_menu())
