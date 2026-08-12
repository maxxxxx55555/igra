extends Control
class_name QuestTrackerHUD

# S5.3: HUD quest tracker - right top under minimap
# Shows up to 3 active objectives with progress, optional direction arrow

var _settings: Node = null
var _container: VBoxContainer
var _title_lbl: Label
var _objectives_vbox: VBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_settings = get_node_or_null("/root/SettingsManager")
	_build_ui()
	
	QuestManager.quest_started.connect(_refresh)
	QuestManager.quest_completed.connect(_refresh)
	QuestManager.quest_progress.connect(_refresh)
	
	EventBus.settings_changed.connect(_on_settings_changed)
	_refresh()

func _build_ui() -> void:
	# Main container - top right, under minimap area
	_container = VBoxContainer.new()
	_container.name = "QuestHUDContainer"
	_container.size = Vector2(300, 200)
	_container.anchors_preset = Control.PRESET_TOP_RIGHT
	_container.offset_top = 140  # Below minimap
	_container.offset_right = -20
	_container.add_theme_constant_override("separation", 8)
	add_child(_container)
	
	# Background panel
	var bg := PanelContainer.new()
	bg.size = _container.size
	bg.add_theme_stylebox_override("panel", _make_stylebox())
	_container.add_child(bg)
	
	var inner_vb := VBoxContainer.new()
	inner_vb.size = _container.size
	inner_vb.add_theme_constant_override("separation", 6)
	bg.add_child(inner_vb)
	
	# Title
	_title_lbl = Label.new()
	_title_lbl.text = LocalizationManager.t("QUEST_OBJECTIVES")
	_title_lbl.add_theme_font_size_override("font_size", 14)
	_title_lbl.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vb.add_child(_title_lbl)
	
	# Objectives list
	_objectives_vbox = VBoxContainer.new()
	_objectives_vbox.add_theme_constant_override("separation", 6)
	inner_vb.add_child(_objectives_vbox)
	
	_container.visible = false

func _make_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.07, 0.85)
	sb.border_color = ThemeProvider.COLOR_AMBER
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	return sb

func _on_settings_changed(key: String, value: Variant) -> void:
	if key == "hints" or key == "objective_markers":
		_refresh()

## Три сигнала разной арности: quest_started(1), quest_completed(1),
## quest_progress(3). Берём максимум, иначе трекер не обновляется ни по одному.
func _refresh(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
	for c in _objectives_vbox.get_children():
		c.queue_free()
	
	var active_quests: Array = QuestManager.get_active_quests()
	if active_quests.is_empty():
		_container.visible = false
		return
	
	_container.visible = true
	
	var show_markers = _settings and _settings.get_setting("objective_markers", true)
	
	_title_lbl.text = LocalizationManager.t("QUEST_OBJECTIVES")
	_title_lbl.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)

	var count := 0
	for quest in active_quests:
		if count >= 3:
			break
		var current := int(quest.get("progress", 0))
		var target := int(quest.get("target_count", 1))

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		_objectives_vbox.add_child(hb)

		var checkbox := CheckBox.new()
		checkbox.disabled = true
		checkbox.button_pressed = current >= target
		hb.add_child(checkbox)

		var obj_lbl := Label.new()
		obj_lbl.text = "%s (%d/%d)" % [QuestManager.get_title(quest), current, target]
		obj_lbl.add_theme_font_size_override("font_size", 13)
		obj_lbl.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT)
		obj_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hb.add_child(obj_lbl)

		if show_markers:
			var arrow := TextureRect.new()
			arrow.texture = _make_arrow_texture()
			arrow.size = Vector2(16, 16)
			hb.add_child(arrow)

		count += 1

func _make_arrow_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var color := ThemeProvider.COLOR_AMBER
	# Draw simple arrow pointing right
	for y in range(16):
		for x in range(16):
			if x >= 4 and x <= 11 and y >= 5 and y <= 10:
				if absf(y - 7.5) <= (x - 7.5) * 0.5:
					img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)