extends RefCounted
## Menu composition keeps the live controls legible beside the street artwork.

static func install(screen: Control, column: VBoxContainer) -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.58, 1.0])
	gradient.colors = PackedColorArray([Color(0.047, 0.063, 0.086, 0.94), Color(0.047, 0.063, 0.086, 0.48), Color(0.047, 0.063, 0.086, 0.08)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2.RIGHT
	var scrim := TextureRect.new()
	scrim.name = "MenuScrim"
	scrim.texture = texture
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.move_child(scrim, column.get_index())
	fit(screen, column)

static func fit(screen: Control, column: VBoxContainer) -> void:
	var viewport: Vector2 = screen.get_viewport_rect().size
	var scale: float = clampf(viewport.y / 900.0, 0.65, 1.15)
	var text_scale: float = SettingsManager.TEXT_SCALE[clampi(int(SettingsManager.get_setting("text_size", 1)), 0, 2)]
	var margin: float = maxf(24.0, viewport.x * 0.055)
	var width: float = minf(560.0 * scale, viewport.x - margin * 2.0)
	column.set_anchors_preset(Control.PRESET_TOP_LEFT)
	column.add_theme_constant_override("separation", ceili(12.0 * scale))
	for child: Node in column.get_children():
		if child is Button:
			var button := child as Button
			button.custom_minimum_size.y = 52.0 * scale
			button.add_theme_font_size_override("font_size", ceili(24.0 * scale * text_scale))
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		elif child is Label:
			var label := child as Label
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.custom_minimum_size.x = 0.0
			label.add_theme_font_size_override("font_size", ceili((52.0 if child.name == "Title" else 18.0) * scale * text_scale))
			if child.name == "Title":
				label.custom_minimum_size.y = 96.0 * scale
	var daily := column.get_node_or_null("DailyCard") as VBoxContainer
	if daily != null:
		daily.add_theme_constant_override("separation", ceili(5.0 * scale))
		for child: Node in daily.get_children():
			if child is Label:
				var label := child as Label
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				label.add_theme_font_size_override("font_size", ceili(18.0 * scale * text_scale))
	column.size = Vector2(width, column.get_combined_minimum_size().y)
	var fit_scale: float = minf(1.0, maxf(viewport.y - 40.0, 1.0) / maxf(column.size.y, 1.0))
	column.scale = Vector2.ONE * fit_scale
	column.position = Vector2(margin, maxf(20.0, (viewport.y - column.size.y * fit_scale) * 0.5))
