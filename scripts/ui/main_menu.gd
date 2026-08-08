extends Control
func _ready() -> void:
    _build()
func _build() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    # set_anchors_preset() ставит только якоря — сам Control оставался размером
    # 0x0, и панель, "отцентрованная" внутри него, липла к левому верхнему углу.
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var legacy_vbox := get_node_or_null("VBox")
    if legacy_vbox:
        legacy_vbox.queue_free()
    theme = ThemeProvider.build_theme()
    if AssetRegistry.has("menu_bg.png"):
        var bg := TextureRect.new()
        bg.texture = AssetRegistry.get_tex("menu_bg.png")
        bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        bg.modulate = Color(1, 1, 1, 0.55)
        add_child(bg)
        bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    else:
        # Не глухая заливка: за меню виден живой ночной город, и это лучший фон,
        # который у игры есть. Затемняем его, чтобы читались кнопки.
        var bg := ColorRect.new()
        bg.color = Color(0.04, 0.05, 0.07, 0.72)
        add_child(bg)
        bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(420, 340)
    add_child(panel)
    # Пресет считает offsets относительно родителя, поэтому его выставляют
    # ПОСЛЕ add_child. Панель стояла у левого края (CENTER_LEFT + position.x = 80)
    # и налезала на полосы HP/стамины/батареи — меню должно быть по центру.
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 14)
    panel.add_child(vb)
    var title := Label.new()
    title.text = "THE LAST\nSTREETLIGHT"
    title.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_HUGE)
    title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
    vb.add_child(title)
    var sub := Label.new()
    sub.text = LocalizationManager.t("menu_subtitle")
    sub.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
    sub.autowrap_mode = TextServer.AUTOWRAP_WORD
    vb.add_child(sub)
    _add_btn(vb, LocalizationManager.t("new_game"), func() -> void: GameManager.start_new_game())
    var cont := Button.new()
    cont.text = LocalizationManager.t("continue")
    cont.focus_mode = Control.FOCUS_NONE
    cont.disabled = SaveSystem and SaveSystem.has_save()
    cont.pressed.connect(func() -> void: GameManager.continue_game())
    vb.add_child(cont)
    _add_btn(vb, LocalizationManager.t("settings"), func() -> void: UIManager.open(&"settings"))
    _add_btn(vb, LocalizationManager.t("multiplayer"), func() -> void: get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn"))
    _add_btn(vb, LocalizationManager.t("quit"), func() -> void: get_tree().quit())
func _add_btn(parent: Node, text: String, cb: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.focus_mode = Control.FOCUS_NONE
    b.pressed.connect(cb)
    parent.add_child(b)