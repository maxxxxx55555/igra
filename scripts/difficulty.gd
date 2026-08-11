extends Control
func _ready() -> void:
	add_to_group("ui_root")
	for b in $VBox.get_children():
		if b is Button and b.name != "Back":
			b.pressed.connect(_on_diff.bind(b.text))
	$VBox/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
func _on_diff(d: String) -> void:
	print("Difficulty: ", d)
	get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")