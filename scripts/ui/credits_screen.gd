extends Control

func _ready() -> void:
	$Panel/Title.text = LocalizationManager.t("credits")
	$Panel/Back.text = LocalizationManager.t("back_menu")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
