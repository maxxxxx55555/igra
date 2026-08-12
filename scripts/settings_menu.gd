extends Control
## Минимальные настройки (GDD §14): SFX / Music / Brightness / Sensitivity + Back.
## Сцена: scenes/ui/settings.tscn. После ec85ba5 остался stub — восстановлен.

func _ready() -> void:
	add_to_group("ui_root")
	var vb := $VBox
	if not vb:
		return

	# Title уже есть в сцене.
	var title: Label = vb.get_node_or_null("Title")
	if title:
		title.add_theme_font_size_override("font_size", 28)
		title.add_theme_color_override("font_color", Color("c9a24a"))

	# Volume slider = Master (из сцены `Volume`, min=0, max=100, val=80).
	var master_slider: HSlider = vb.get_node_or_null("Volume")
	if master_slider:
		master_slider.value = 100.0
		master_slider.value_changed.connect(func(v: float) -> void:
			AudioServer.set_bus_volume_db(0, linear_to_db(v / 100.0))
		)

	# Music Volume отдельно:
	var music_slider := _make_slider(vb, "МУЗЫКА", func(v: float) -> void:
		var bus := AudioServer.get_bus_index("Music")
		if bus >= 0: AudioServer.set_bus_volume_db(bus, linear_to_db(v / 100.0))
	)
	# Яркость:
	_make_slider(vb, "ЯРКОСТЬ", func(v: float) -> void:
		var cam := get_viewport().get_camera_3d()
		if cam:
			var env = cam.world_env
			if env:
				env.environment.adjustment_brightness = v / 50.0
	)
	# Чувствительность:
	_make_slider(vb, "ЧУВСТВИТЕЛЬНОСТЬ", func(v: float) -> void:
		SettingsManager.set_setting("sensitivity", v / 50.0))

	# Back
	var back := _make_button(vb, "НАЗАД")
	back.pressed.connect(func() -> void: Routes.to_menu())

func _make_slider(parent: Node, label_text: String, cb: Callable) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var l := Label.new()
	l.text = label_text
	l.custom_minimum_size.x = 140
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 100.0
	s.step = 1.0
	s.value = 50.0
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(v: float) -> void: cb.call(v))
	row.add_child(s)
	return s

func _make_button(parent: Node, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(200, 40)
	parent.add_child(b)
	return b