extends Control
## Pause menu: Resume / Settings / Restart / Quit + затемнение + tween-появление.

func _ready() -> void:
	_build()
	_animate_in()
	if not LocalizationManager.language_changed.is_connected(_on_lang_changed):
		LocalizationManager.language_changed.connect(_on_lang_changed)

func _on_lang_changed(_lang: String) -> void:
	for c in get_children():
		c.queue_free()
	_build()

func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()
	# Затемнение фона
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.0, 0.0, 0.0, 0.0)  # начало tween
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# Панель
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(380, 320)
	panel.modulate = Color(1, 1, 1, 0.0)  # начало tween
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var t := Label.new()
	t.text = LocalizationManager.t("paused")
	t.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	_btn(vb, LocalizationManager.t("resume"),   func() -> void: UIManager.close(&"pause"); GameManager.resume_game())
	_btn(vb, LocalizationManager.t("settings"), func() -> void: UIManager.open(&"settings"))
	_btn(vb, LocalizationManager.t("restart"),  func() -> void: FadeTransition.fade_to(func() -> void: get_tree().reload_current_scene()))
	_btn(vb, LocalizationManager.t("back_menu"),func() -> void: FadeTransition.fade_to(func() -> void: GameManager.return_to_menu()))

func _animate_in() -> void:
	var bg: ColorRect = get_node_or_null("BG")
	var panel: Control = get_node_or_null("Panel")
	var tw := create_tween()
	tw.set_parallel(true)
	if bg:
		tw.tween_property(bg, "color", Color(0.0, 0.0, 0.0, 0.55), 0.3).set_ease(Tween.EASE_OUT)
	if panel:
		tw.tween_property(panel, "modulate", Color(1, 1, 1, 1.0), 0.3).set_ease(Tween.EASE_OUT)

func _btn(p: Node, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	p.add_child(b)
