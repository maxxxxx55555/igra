

extends Control
func _ready() -> void:
	_apply_localization()
	LocalizationManager.language_changed.connect(_apply_localization)

## language_changed передаёт код языка — см. confirm_quit.gd: без параметра
## обработчик не вызывается вообще.
func _apply_localization(_lang: Variant = null) -> void:
	$Panel/Title.text = LocalizationManager.t("difficulty")
	$Panel/Easy.text = LocalizationManager.t("diff_easy")
	$Panel/Normal.text = LocalizationManager.t("diff_normal")
	$Panel/Hard.text = LocalizationManager.t("diff_hard")
	$Panel/Back.text = LocalizationManager.t("back_menu")

func _pick(level: int = 0) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("gameplay", "difficulty", level)
	cfg.save("user://settings.cfg")
	Routes.start_game()

func _on_back() -> void:
	Routes.to_menu()