extends Control

@onready var play_btn: Button = $VBox/Play
@onready var settings_btn: Button = $VBox/Settings
@onready var difficulty_btn: Button = $VBox/Difficulty
@onready var credits_btn: Button = $VBox/Credits
@onready var quit_btn: Button = $VBox/Quit
@onready var flicker: ColorRect = $Flicker

func _ready() -> void:
	add_to_group("ui_root")
	play_btn.text = "ИГРАТЬ"
	settings_btn.text = "НАСТРОЙКИ"
	difficulty_btn.text = "СЛОЖНОСТЬ"
	credits_btn.text = "ТИТРЫ"
	quit_btn.text = "ВЫХОД"
	play_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn"))
	settings_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/settings.tscn"))
	difficulty_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/difficulty.tscn"))
	credits_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/credits.tscn"))
	quit_btn.pressed.connect(_on_quit)
	_start_flicker()

func _start_flicker() -> void:
	var tw = create_tween().set_loops()
	tw.tween_property(flicker, "modulate:a", 0.6, 2.0)
	tw.tween_property(flicker, "modulate:a", 1.0, 0.3)
	tw.tween_property(flicker, "modulate:a", 0.8, 1.5)
	tw.tween_property(flicker, "modulate:a", 1.0, 0.5)

func _on_quit() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/confirm_quit.tscn")