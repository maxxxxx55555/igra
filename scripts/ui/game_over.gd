
extends CanvasLayer

@onready 
var lbl_stats: Label = $Control/VBoxContainer/LblStats

@onready 
var btn_restart: Button = $Control/VBoxContainer/BtnRestart

@onready 
var btn_menu: Button = $Control/VBoxContainer/BtnMenu

func _ready() -> void:
	btn_restart.pressed.connect(_on_restart)
	btn_menu.pressed.connect(_on_menu)
	EventBus.player_died.connect(show_game_over)
	hide()

func show_game_over() -> void:
	show()
	get_tree().paused = true
	
	var time := int(GameManager.play_time)
	var kills := GameManager.enemies_killed
	lbl_stats.text = "Время: %ds | Убито: %d" % [time, kills]

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
