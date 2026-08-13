
extends CanvasLayer

@onready 
var lbl_stats: Label = $Control/VBoxContainer/LblStats

@onready 
var btn_restart: Button = $Control/VBoxContainer/BtnRestart

@onready 
var btn_menu: Button = $Control/VBoxContainer/BtnMenu

func _ready() -> void:
	# Экран сам ставит дерево на паузу, поэтому обязан работать во время неё:
	# иначе его же кнопки «Заново» и «В меню» перестают нажиматься и выйти
	# из паузы становится нечем.
	process_mode = Node.PROCESS_MODE_ALWAYS
	btn_restart.pressed.connect(_on_restart)
	btn_menu.pressed.connect(_on_menu)
	EventBus.player_died.connect(show_game_over)
	hide()

func show_game_over() -> void:
	show()
	get_tree().paused = true
	
	var time := int(GameManager.play_time)
	var kills := GameManager.enemies_killed
	lbl_stats.text = LocalizationManager.tf("GAME_OVER_STATS", [time, kills])

func _on_restart() -> void:
	get_tree().paused = false
	Routes.restart_game()

func _on_menu() -> void:
	get_tree().paused = false
	Routes.to_menu()
