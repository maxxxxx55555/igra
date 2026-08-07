extends CanvasLayer

@onready var list: VBoxContainer = $Control/ScrollContainer/VBoxContainer
@onready var btn_back: Button = $Control/BtnBack

func _ready() -> void:
	btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	_populate()

func _populate() -> void:
	if not AchievementManager:
		return
	var ach_dict: Dictionary = AchievementManager.get_achievements()
	for id in ach_dict.keys():
		var ach: Dictionary = ach_dict[id]
		var hbox := HBoxContainer.new()
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		icon.modulate = Color(1, 1, 1) if ach.unlocked else Color(0.3, 0.3, 0.3)
		var lbl := Label.new()
		lbl.text = "%s: %s" % [ach.title, ach.description]
		if ach.unlocked:
			lbl.text += " [✓]"
		hbox.add_child(icon)
		hbox.add_child(lbl)
		list.add_child(hbox)
