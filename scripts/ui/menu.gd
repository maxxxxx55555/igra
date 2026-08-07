extends Control

func _ready() -> void:
	var play := $VBox/PlayBtn
	if play != null:
		play.pressed.connect(_play)
	var quit := $VBox/QuitBtn
	if quit != null:
		quit.pressed.connect(_quit)

func _play() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/pre_loading.tscn")

func _quit() -> void:
	get_tree().quit()