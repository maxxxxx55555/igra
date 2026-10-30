extends RefCounted
## Terminal screens retain physical readability after viewport/text scaling.
const PANEL_COLOR := Color(0.0588235, 0.0745098, 0.0784314, 0.95)

static func build(screen: Control) -> VBoxContainer:
	screen.theme = ThemeProvider.build_theme()
	var art := TextureRect.new()
	art.name = "EndingArt"
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(art)
	var shade := ColorRect.new()
	shade.color = Color(0.0235294, 0.0588235, 0.0745098, 0.45)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(shade)
	var scroll := ScrollContainer.new()
	scroll.name = "EndingScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = ThemeProvider.COLOR_BORDER
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var content := VBoxContainer.new()
	panel.add_child(content)
	var fit: Callable = _fit.bind(screen, scroll, center, panel, content, style)
	screen.resized.connect(fit)
	screen.visibility_changed.connect(fit)
	fit.call_deferred()
	return content

static func set_ending(screen: Control, id: StringName) -> void:
	var art := screen.get_node_or_null("EndingArt") as TextureRect
	if art != null and EndingsManager.ENDING_DATA.has(String(id)):
		art.texture = load("res://assets/store/endings/ending_%s.png" % id) as Texture2D

static func _fit(screen: Control, scroll: ScrollContainer, center: CenterContainer, panel: PanelContainer, content: VBoxContainer, style: StyleBoxFlat) -> void:
	var physical: Vector2 = Vector2(screen.get_window().size)
	var ratio: float = maxf(physical.x / maxf(screen.get_viewport_rect().size.x, 1.0), 0.1)
	var text_scale: float = SettingsManager.TEXT_SCALE[clampi(int(SettingsManager.get_setting("text_size", 1)), 0, 2)]
	var margin: float = 16.0 / ratio
	scroll.offset_left = margin
	scroll.offset_right = -margin
	scroll.offset_top = margin
	scroll.offset_bottom = -margin
	center.custom_minimum_size.y = maxf(0.0, screen.size.y - 2.0 * margin)
	panel.custom_minimum_size.x = maxf(160.0, minf(760.0 / ratio, screen.size.x - 2.0 * margin - 16.0 / ratio))
	for side: String in ["left", "right", "top", "bottom"]:
		style.set("content_margin_" + side, 24.0 / ratio)
	content.add_theme_constant_override("separation", int(14.0 / ratio))
	for child: Node in content.get_children():
		var control := child as Control
		if control is Label or control is Button:
			var font_px: float = 32.0 if child == content.get_child(0) else 18.0
			control.add_theme_font_size_override("font_size", ceili(font_px * text_scale / ratio))
			control.custom_minimum_size.x = 0.0
		if control is Label:
			(control as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if control is Button:
			control.custom_minimum_size.y = 44.0 / ratio
	_wrap_nested(content)

static func _wrap_nested(node: Node) -> void:
	for child in node.get_children():
		if child is Label:
			var label := child as Label
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.custom_minimum_size.x = 0.0
		elif child is Button:
			var button := child as Button
			button.clip_text = true
			button.custom_minimum_size.x = 0.0
		_wrap_nested(child)
