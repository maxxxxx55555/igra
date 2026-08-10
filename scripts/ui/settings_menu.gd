extends Control
func _ready() -> void:
	_build()
	if not LocalizationManager.language_changed.is_connected(_on_lang_changed):
		LocalizationManager.language_changed.connect(_on_lang_changed)

func _on_lang_changed(_lang: String) -> void:
	for c in get_children():
		c.queue_free()
	_build()

func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.07, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(440, 400)
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var t := Label.new()
	t.text = tr("SETTINGS")
	t.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	
	_slider(vb, tr("Master Volume"), "Master")
	_slider(vb, tr("SFX Volume"), "SFX")
	_slider(vb, tr("Music Volume"), "Music")
	
	# Language selector
	var lang_row := HBoxContainer.new()
	vb.add_child(lang_row)
	var lang_label := Label.new()
	lang_label.text = LocalizationManager.t("language")
	lang_label.custom_minimum_size.x = 160
	lang_row.add_child(lang_label)
	var lang_combo := OptionButton.new()
	lang_combo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lang in SettingsManager.get_languages():
		lang_combo.add_item(lang.to_upper())
	var current_idx = SettingsManager.get_languages().find(SettingsManager.get_language())
	if current_idx >= 0:
		lang_combo.selected = current_idx
	lang_combo.item_selected.connect(func(idx: int) -> void:
		var lang = SettingsManager.get_languages()[idx]
		SettingsManager.set_language(lang)
	)
	lang_row.add_child(lang_combo)
	
	var b := Button.new()
	b.text = tr("Back")
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void: UIManager.close(&"settings"))
	vb.add_child(b)

func _slider(parent: Node, label: String, bus: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size.x = 160
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = SettingsManager.get_volume(bus)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(v: float) -> void: SettingsManager.set_volume(bus, v))
	row.add_child(s)