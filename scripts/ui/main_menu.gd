extends Control

func _ready() -> void:
	await get_tree().process_frame  # let the scene finish adding its own children
	var vb: Node = get_node_or_null("VBox")
	if not vb: return
	vb.get_node("Play").pressed.connect(func(): Routes.start_game())
	vb.get_node("Settings").pressed.connect(func(): Routes.goto(Routes.SETTINGS))
	vb.get_node("Difficulty").pressed.connect(func(): Routes.goto(Routes.DIFFICULTY))
	vb.get_node("Credits").pressed.connect(func(): Routes.goto(Routes.CREDITS))
	vb.get_node("Quit").pressed.connect(func(): Routes.goto("res://scenes/ui/confirm_quit.tscn"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()