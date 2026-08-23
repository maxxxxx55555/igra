extends Control
class_name NewGamePlusUI

@onready var ng_label: Label = $MarginContainer/VBoxContainer/NGLabel
@onready var current_level: Label = $MarginContainer/VBoxContainer/CurrentLevel
@onready var multiplier_label: Label = $MarginContainer/VBoxContainer/MultiplierLabel
@onready var activate_button: Button = $MarginContainer/VBoxContainer/ActivateButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh()
	activate_button.pressed.connect(_on_activate)
	back_button.pressed.connect(_close)

func _refresh() -> void:
	var ng = NewGamePlus.get_current_ng_plus()
	ng_label.text = LocalizationManager.tf("NG_PLUS_LEVEL", [ng, NewGamePlus.get_max_ng_plus()])
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

	activate_button.disabled = ng >= NewGamePlus.get_max_ng_plus()

func _on_activate() -> void:
	if NewGamePlus.activate_ng_plus():
		_refresh()
		UIManager.show_notification(LocalizationManager.t("NG_PLUS_ACTIVATED"))

func _close() -> void:
	UIManager.close(&"new_game_plus")