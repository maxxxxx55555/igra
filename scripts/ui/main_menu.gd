extends Control

func _ready() -> void:
	await get_tree().process_frame  # let the scene finish adding its own children
	var vb: Node = get_node_or_null("VBox")
	if not vb: return
	vb.get_node("Play").pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn"))
	vb.get_node("Settings").pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/settings_screen.tscn"))
	vb.get_node("Difficulty").pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/difficulty_screen.tscn"))
	vb.get_node("Credits").pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/credits.tscn"))
	vb.get_node("Quit").pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/confirm_quit.tscn"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()