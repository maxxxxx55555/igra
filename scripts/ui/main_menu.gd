extends Control
## Main menu: фон menu_bg.png, кнопки с hover/pressed стилями из ThemeProvider,
## tween-появление панели при открытии, переход через FadeTransition.

func _ready() -> void:
	_build()
	_animate_in()
	if not LocalizationManager.language_changed.is_connected(_on_lang_changed):
		LocalizationManager.language_changed.connect(_on_lang_changed)

func _on_lang_changed(_lang: String) -> void:
	_rebuild()

func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_build()

func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var legacy_vbox := get_node_or_null("VBox")
	if legacy_vbox:
		legacy_vbox.queue_free()
	theme = ThemeProvider.build_theme()
	# Фон
	if AssetRegistry.has("menu_bg.png"):
		var bg := TextureRect.new()
		bg.texture = AssetRegistry.get_tex("menu_bg.png")
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.modulate = Color(1, 1, 1, 0.55)
		add_child(bg)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		var bg := ColorRect.new()
		bg.color = Color(0.04, 0.05, 0.07, 0.72)
		add_child(bg)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Панель кнопок
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(420, 340)
	panel.modulate = Color(1, 1, 1, 0.0)  # начало tween
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	var title := Label.new()
	title.text = LocalizationManager.t("menu_title")
	title.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_HUGE)
	title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := Label.new()
	sub.text = LocalizationManager.t("menu_subtitle")
	sub.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(sub)
	_add_btn(vb, LocalizationManager.t("new_game"),    func() -> void: FadeTransition.fade_to(func() -> void: GameManager.start_new_game()))
	var cont := Button.new()
	cont.text = LocalizationManager.t("continue")
	cont.focus_mode = Control.FOCUS_NONE
	cont.disabled = not (SaveSystem and SaveSystem.has_save())
	cont.pressed.connect(func() -> void: FadeTransition.fade_to(func() -> void: GameManager.continue_game()))
	vb.add_child(cont)
	_add_btn(vb, LocalizationManager.t("settings"),    func() -> void: UIManager.open(&"settings"))
	_add_btn(vb, LocalizationManager.t("multiplayer"), func() -> void: FadeTransition.fade_to(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn")))
	_add_btn(vb, LocalizationManager.t("quit"),        func() -> void: get_tree().quit())

func _animate_in() -> void:
	var panel: Control = get_node_or_null("Panel")
	if panel == null:
		return
	panel.position.y += 24.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate", Color(1, 1, 1, 1.0), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(panel, "position:y", panel.position.y - 24.0, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _add_btn(parent: Node, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	parent.add_child(b)
