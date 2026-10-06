

extends Control
## The three picks (V.2 5.6): each says what it changes. The pick is the SettingsManager's difficulty, which scales
## every monster's health and damage (base_monster.gd).

const PICKS: Array[String] = ["Easy", "Normal", "Hard"]
const DESC_KEYS: Array[String] = ["DIFF_EASY_DESC", "DIFF_NORMAL_DESC", "DIFF_HARD_DESC"]

func _ready() -> void:
	for pick in PICKS:
		var button := get_node("Panel/" + pick) as Button
		var desc := Label.new()
		desc.name = pick + "Desc"
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
		desc.position = Vector2(button.position.x, button.position.y + button.size.y + 2.0)
		desc.size = Vector2(button.size.x, 24.0)
		$Panel.add_child(desc)
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
	for i in PICKS.size():
		($Panel.get_node(PICKS[i] + "Desc") as Label).text = LocalizationManager.t(DESC_KEYS[i])

## A pick is a setting: it used to start a new game, which wiped the save with no question (only Play asks).
func _pick(level: int = 0) -> void:
	SettingsManager.set_difficulty(level)
	SettingsManager.save_to_cfg()
	Routes.to_menu()

func _on_back() -> void:
	Routes.to_menu()