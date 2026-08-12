extends Control
func _ready() -> void:
	add_to_group("ui_root")
	for b in $VBox.get_children():
		if b is Button and b.name != "Back":
			b.pressed.connect(_on_diff.bind(b.text))
	$VBox/Back.pressed.connect(func(): Routes.to_menu())
func _on_diff(d: String) -> void:
	print("Difficulty: ", d)
	Routes.start_game()