extends CanvasLayer

@onready var list: VBoxContainer = $Control/ScrollContainer/VBoxContainer
@onready var btn_back: Button = $Control/BtnBack

func _ready() -> void:
	btn_back.pressed.connect(func(): Routes.to_menu())
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
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var badge_path := "res://assets/textures/badges/badge_%s_128.png" % String(id)
		if ResourceLoader.exists(badge_path):
			icon.texture = load(badge_path)
		icon.modulate = Color(1, 1, 1) if ach.unlocked else Color(0.3, 0.3, 0.3)
		var lbl := Label.new()
		lbl.text = "%s: %s" % [ach.title, ach.description]
		if ach.unlocked:
			lbl.text += " [✓]"
		hbox.add_child(icon)
		hbox.add_child(lbl)
		list.add_child(hbox)
