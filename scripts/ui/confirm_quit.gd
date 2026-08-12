

extends Control
func _ready() -> void:
	_apply_localization()
	LocalizationManager.language_changed.connect(_apply_localization)

## language_changed эмитит код языка. Callable обязан принимать не меньше
## аргументов, чем сигнал, иначе Godot ругается на каждый emit и текст не
## перерисовывается. Параметр со значением по умолчанию сохраняет прямые вызовы.
func _apply_localization(_lang: Variant = null) -> void:
	$Panel/Title.text = LocalizationManager.t("confirm_quit")
	$Panel/Yes.text = LocalizationManager.t("yes")
	$Panel/No.text = LocalizationManager.t("no")

func _on_yes() -> void:
	get_tree().quit()

func _on_no() -> void:
	Routes.to_menu()