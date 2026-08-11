
extends CanvasLayer

@onready 
var grid: GridContainer = $Control/GridContainer

@onready 
var btn_back: Button = $Control/BtnBack

func _ready() -> void:
	btn_back.pressed.connect(_on_back)
	_setup_levels()

func _setup_levels() -> void:
	for i in range(3):
		var btn := Button.new()
		btn.text = "Уровень %d" % (i + 1)
		btn.custom_minimum_size = Vector2(200, 80)
		var unlocked: bool = i == 0 or GameManager.current_level >= i + 1
		btn.disabled = not unlocked
		if not unlocked:
			btn.modulate = Color(0.3, 0.3, 0.3)
		btn.pressed.connect(_on_level_selected.bind(i + 1))
		grid.add_child(btn)

func _on_level_selected(level: int) -> void:
	
	var path := "res://scenes/levels/level_0%d.tscn" % level
	if level == 3:
		path = "res://scenes/levels/level_03.tscn"
	get_tree().change_scene_to_file(path)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
