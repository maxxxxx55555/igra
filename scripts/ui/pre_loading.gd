extends Control

func _ready() -> void:
	($Label as Label).text = LocalizationManager.t("LOADING_ENTERING_CITY")
	await get_tree().create_timer(1.0).timeout
	Routes.goto(Routes.GAME)