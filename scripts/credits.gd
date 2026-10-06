extends Control

func _ready() -> void:
	add_to_group("ui_root")
	$VBox/Back.text = LocalizationManager.t("back_menu")
	$VBox/Title.text = LocalizationManager.t("credits")
	$VBox/L2.text = LocalizationManager.t("CREDITS_DESIGN")
	$VBox/L3.text = LocalizationManager.t("CREDITS_MUSIC")
	$VBox/L4.text = LocalizationManager.t("CREDITS_ART")
	$VBox/L5.text = LocalizationManager.t("CREDITS_THANKS")
	$VBox/Back.pressed.connect(func(): Routes.to_menu())
