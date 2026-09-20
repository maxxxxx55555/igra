extends Control
class_name NewGamePlusUI

@onready var ng_label: Label = $MarginContainer/VBoxContainer/NGLabel
@onready var current_level: Label = $MarginContainer/VBoxContainer/CurrentLevel
@onready var multiplier_label: Label = $MarginContainer/VBoxContainer/MultiplierLabel
@onready var activate_button: Button = $MarginContainer/VBoxContainer/ActivateButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

var _mod_box: VBoxContainer = null
var _help_label: Label = null
## arena design audit P3: cleared on every screen open (_ready()/whenever
## UIManager shows this cached screen again), not persisted - tracks only
## "did the player activate NG+ during THIS visit" so Back can offer
## "continue to main menu" instead of silently just closing the overlay.
var _activated_this_visit: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = ThemeProvider.build_theme()
	_activated_this_visit = false
	_refresh()
	activate_button.pressed.connect(_on_activate)
	back_button.pressed.connect(_on_back)
	# Static audit 2026-09-08: this screen is cached by UIManager (never
	# freed, just hidden) - a language change while it's closed left it
	# stale next time it reopened, since nothing called _refresh() again.
	LocalizationManager.language_changed.connect(func(_l: String) -> void: _refresh())

func _refresh() -> void:
	var ng = NewGamePlus.get_current_ng_plus()
	var max_ng = NewGamePlus.get_max_ng_plus()
	ng_label.text = LocalizationManager.tf("NG_PLUS_LEVEL", [ng, max_ng])
	var run_label := LocalizationManager.tf("NG_PLUS_LABEL", [ng]) if ng > 0 else LocalizationManager.t("NG_PLUS_BASE_GAME")
	current_level.text = LocalizationManager.tf("NG_PLUS_CURRENT_RUN", [run_label])

	var mult = NewGamePlus.get_difficulty_multiplier()
	multiplier_label.text = (
		LocalizationManager.tf("NG_PLUS_STAT_XP", [mult.xp_multiplier]) + "\n" +
		LocalizationManager.tf("NG_PLUS_STAT_ENEMY_HP", [mult.enemy_hp_multiplier]) + "\n" +
		LocalizationManager.tf("NG_PLUS_STAT_ENEMY_DMG", [mult.enemy_damage_multiplier]) + "\n" +
		LocalizationManager.tf("NG_PLUS_STAT_PLAYER_DMG", [mult.player_damage_multiplier]) + "\n" +
		LocalizationManager.tf("NG_PLUS_STAT_LOOT", [mult.loot_chance_multiplier])
	)

	var at_cap := ng >= max_ng
	activate_button.disabled = at_cap
	activate_button.text = LocalizationManager.t("NGP_AT_LIMIT") if at_cap \
		else LocalizationManager.tf("NGP_ACTIVATE_ACTION", [ng + 1])
	back_button.text = LocalizationManager.t("NGP_BACK_CONTINUE") if _activated_this_visit \
		else LocalizationManager.t("NGP_BACK_RETURN")
	if _help_label == null:
		_help_label = Label.new()
		_help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_help_label.modulate.a = 0.75
		ng_label.get_parent().add_child(_help_label)
		ng_label.get_parent().move_child(_help_label, ng_label.get_index() + 1)
	_help_label.text = LocalizationManager.t("NGP_ACTIVATE_HELP")
	_refresh_modifiers()

## Один выбор модификатора на каждый уровень NG+. Список строится кодом, а не
## лежит в .tscn: модификаторы — контентные данные, их количество может
## измениться без правки сцены.
func _refresh_modifiers() -> void:
	if _mod_box == null:
		_mod_box = VBoxContainer.new()
		ng_label.get_parent().add_child(_mod_box)
	for child in _mod_box.get_children():
		child.queue_free()
	var mods: Array = NewGamePlus.get_modifiers()
	if mods.is_empty() or NewGamePlus.get_current_ng_plus() < 1:
		return
	var active: Array = NewGamePlus.get_active_modifiers()
	var title := Label.new()
	title.text = LocalizationManager.tf("NGP_PICK_TITLE", [active.size(), NewGamePlus.get_current_ng_plus()])
	_mod_box.add_child(title)
	# Сводка по «не-множительным» ручкам модификаторов: значения идут через
	# потреблённые геттеры NewGamePlus (hints/cycle/time_pressure/
	# extra_dark_districts), а не читаются из эффектов напрямую.
	var knobs := Label.new()
	knobs.text = "hints:%s · cycle:x%.2f · pressure:%s · dark+:%d" % [
		"on" if NewGamePlus.are_hints_enabled() else "off",
		NewGamePlus.get_night_cycle_multiplier(),
		"on" if NewGamePlus.is_time_pressure_enabled() else "off",
		NewGamePlus.get_extra_dark_districts(),
	]
	knobs.modulate.a = 0.7
	_mod_box.add_child(knobs)
	for m in mods:
		var id := String(m.get("id", ""))
		var keys: Dictionary = m.get("i18n_keys", {})
		var btn := Button.new()
		btn.text = "%s — %s" % [
			LocalizationManager.t(String(keys.get("name", id))),
			LocalizationManager.t(String(keys.get("desc", ""))),
		]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if id in active:
			btn.disabled = true
			btn.text = "[✓] " + btn.text
		elif not NewGamePlus.can_select(id):
			btn.disabled = true
		else:
			btn.pressed.connect(func() -> void:
				if NewGamePlus.select_modifier(id):
					UISFX.click()
					_refresh())
		_mod_box.add_child(btn)

func _on_activate() -> void:
	if NewGamePlus.activate_ng_plus():
		_activated_this_visit = true
		_refresh()
		UIManager.show_notification(LocalizationManager.tf("NGP_ACTIVATE_FEEDBACK", [NewGamePlus.get_current_ng_plus()]))

## arena design audit P3: before activation this just closes the overlay
## (back to the ending/wherever it was opened from); after an activation
## this visit, it routes to the main menu instead - the only place "Play"
## (the actual NG+ run start) lives - via the same close-blocking-screens
## path GameManager.return_to_menu() already uses.
func _on_back() -> void:
	UIManager.close(&"new_game_plus")
	if _activated_this_visit:
		GameManager.return_to_menu()