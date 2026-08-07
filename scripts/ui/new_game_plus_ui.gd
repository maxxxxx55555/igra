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
	ng_label.text = "New Game+ Level: %d / %d" % [ng, NewGamePlus.get_max_ng_plus()]
	current_level.text = "Current Run: " + ("NG+ %d" % ng if ng > 0 else "Base Game")
	
	var mult = NewGamePlus.get_difficulty_multiplier()
	multiplier_label.text = (
		"XP: x%.2f\n" % mult.xp_multiplier +
		"Enemy HP: x%.2f\n" % mult.enemy_hp_multiplier +
		"Enemy Damage: x%.2f\n" % mult.enemy_damage_multiplier +
		"Player Damage: x%.2f\n" % mult.player_damage_multiplier +
		"Loot Chance: x%.2f" % mult.loot_chance_multiplier
	)
	
	activate_button.disabled = ng >= NewGamePlus.get_max_ng_plus()

func _on_activate() -> void:
	if NewGamePlus.activate_ng_plus():
		_refresh()
		UIManager.show_notification("New Game+ Activated! Difficulty increased.")

func _close() -> void:
	UIManager.close(&"new_game_plus")