extends Control

func _ready() -> void:
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
    panel.custom_minimum_size = Vector2(520, 580)
    add_child(panel)
    
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 10)
    panel.add_child(vb)
    
    var t := Label.new()
    t.text = tr("SETTINGS")
    t.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
    t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
    t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vb.add_child(t)
    
    # ===== TAB CONTAINER =====
    var tab_container := TabContainer.new()
    tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vb.add_child(tab_container)
    
    # --- GAME TAB ---
    var game_tab := VBoxContainer.new()
    game_tab.name = tr("SETTINGS_GAME")
    tab_container.add_child(game_tab)
    _build_game_tab(game_tab)
    
    # --- CONTROLS TAB ---
    var controls_tab := VBoxContainer.new()
    controls_tab.name = tr("SETTINGS_CONTROLS")
    tab_container.add_child(controls_tab)
    _build_controls_tab(controls_tab)
    
    # --- GRAPHICS TAB ---
    var graphics_tab := VBoxContainer.new()
    graphics_tab.name = tr("SETTINGS_GRAPHICS")
    tab_container.add_child(graphics_tab)
    _build_graphics_tab(graphics_tab)
    
    # --- AUDIO TAB ---
    var audio_tab := VBoxContainer.new()
    audio_tab.name = tr("SETTINGS_AUDIO")
    tab_container.add_child(audio_tab)
    _build_audio_tab(audio_tab)
    
    # --- ACCESSIBILITY TAB ---
    var access_tab := VBoxContainer.new()
    access_tab.name = tr("SETTINGS_ACCESSIBILITY")
    tab_container.add_child(access_tab)
    _build_accessibility_tab(access_tab)
    
    # Back button
    var b := Button.new()
    b.text = tr("Back")
    b.focus_mode = Control.FOCUS_NONE
    b.pressed.connect(func() -> void: UIManager.close(&"settings"))
    vb.add_child(b)

func _build_game_tab(parent: VBoxContainer) -> void:
    parent.add_theme_constant_override("separation", 14)
    
    # Difficulty
    _dropdown(parent, tr("Difficulty"), "difficulty", ["Easy", "Normal", "Hard"], 
        func(idx: int) -> void: SettingsManager.set_difficulty(idx))
    
    # Auto-save
    _toggle(parent, tr("Auto-save"), "autosave")
    
    # Hints
    _toggle(parent, tr("Hints"), "hints")
    
    # Hardcore mode
    _toggle(parent, tr("Hardcore Mode"), "hardcore")
    
    # Objective markers on HUD
    _toggle(parent, tr("Objective Markers"), "objective_markers")
    
    # Language. Список строится из LocalizationManager: раньше здесь было 8
    # захардкоженных названий из 13 поддерживаемых, и порядок не совпадал с
    # индексом, который читает _dropdown — выбор прыгал на чужой язык.
    var lang_codes: Array = LocalizationManager.SUPPORTED
    var lang_names: Array = []
    for code in lang_codes:
        lang_names.append(String(LocalizationManager.LANG_NAMES.get(code, code)))
    _dropdown(parent, tr("Language"), "language", lang_names,
        func(idx: int) -> void:
            SettingsManager.set_language(lang_codes[idx])
    )

func _build_controls_tab(parent: VBoxContainer) -> void:
    parent.add_theme_constant_override("separation", 14)
    
    _slider(parent, tr("Sensitivity"), "sensitivity", 0.5, 2.0, 0.05,
        func(v: float) -> void: SettingsManager.set_sensitivity(v))
    
    _slider(parent, tr("Deadzone"), "deadzone", 0.05, 0.25, 0.01,
        func(v: float) -> void: SettingsManager.set_deadzone(v))
    
    _dropdown(parent, tr("Dodge Gesture"), "dodge_gesture", 
        ["Double Tap", "Swipe", "Button"],
        func(idx: int) -> void: SettingsManager.set_dodge_gesture(idx))
    
    _dropdown(parent, tr("Crouch Input"), "crouch_input",
        ["Long Press Joystick", "Button", "Disabled"],
        func(idx: int) -> void: SettingsManager.set_crouch_input(idx))
    
    _slider(parent, tr("HUD Opacity"), "hud_opacity", 0.5, 1.0, 0.05,
        func(v: float) -> void: SettingsManager.set_hud_opacity(v))
    
    _slider(parent, tr("Button Size"), "button_size", 0.8, 1.5, 0.05,
        func(v: float) -> void: SettingsManager.set_button_size(v))

func _build_graphics_tab(parent: VBoxContainer) -> void:
    parent.add_theme_constant_override("separation", 14)
    
    _dropdown(parent, tr("Graphics Tier"), "graphics_tier",
        ["Low (30fps, 720p)", "Medium (30fps, 1080p)", "High (60fps, 1080p)", "Ultra (60fps, 1440p)"],
        func(idx: int) -> void: SettingsManager.set_graphics_tier(idx))
    
    _dropdown(parent, tr("Resolution"), "resolution",
        ["720p", "1080p", "1440p"],
        func(idx: int) -> void: SettingsManager.set_resolution(idx))
    
    _toggle(parent, tr("VSync"), "vsync")
    _dropdown(parent, tr("FPS Cap"), "fps_cap", ["30", "60", "120"],
        func(idx: int) -> void: SettingsManager.set_fps_cap(idx))
    
    _dropdown(parent, tr("Shadow Quality"), "shadows",
        ["Low", "Medium", "High"],
        func(idx: int) -> void: SettingsManager.set_shadow_quality(idx))
    
    _dropdown(parent, tr("Texture Quality"), "textures",
        ["Low", "Medium", "High"],
        func(idx: int) -> void: SettingsManager.set_texture_quality(idx))
    
    _dropdown(parent, tr("Effects Quality"), "effects",
        ["Low", "Medium", "High"],
        func(idx: int) -> void: SettingsManager.set_effects_quality(idx))
    
    _slider(parent, tr("Draw Distance"), "draw_distance", 0.0, 100.0, 5.0,
        func(v: float) -> void: SettingsManager.set_draw_distance(v))

func _build_audio_tab(parent: VBoxContainer) -> void:
    parent.add_theme_constant_override("separation", 14)
    
    _slider(parent, tr("Master Volume"), "master", 0.0, 1.0, 0.05,
        func(v: float) -> void: SettingsManager.set_volume("Master", v))
    _slider(parent, tr("Music Volume"), "music", 0.0, 1.0, 0.05,
        func(v: float) -> void: SettingsManager.set_volume("Music", v))
    _slider(parent, tr("SFX Volume"), "sfx", 0.0, 1.0, 0.05,
        func(v: float) -> void: SettingsManager.set_volume("SFX", v))
    _slider(parent, tr("Voice Volume"), "voice", 0.0, 1.0, 0.05,
        func(v: float) -> void: SettingsManager.set_volume("Voice", v))

func _build_accessibility_tab(parent: VBoxContainer) -> void:
    parent.add_theme_constant_override("separation", 14)
    
    # Colorblind mode
    _dropdown(parent, tr("Colorblind Mode"), "colorblind",
        ["Off", "Deuteranopia", "Protanopia", "Tritanopia"],
        func(idx: int) -> void: SettingsManager.set_colorblind_mode(idx))
    
    # Text size
    _dropdown(parent, tr("Text Size"), "text_size",
        ["Small", "Medium", "Large"],
        func(idx: int) -> void: SettingsManager.set_text_size(idx))
    
    # Dyslexia font
    _toggle(parent, tr("Dyslexia Font (OpenDyslexic)"), "dyslexia_font")
    
    # High contrast
    _toggle(parent, tr("High Contrast"), "high_contrast")
    
    # Auto-aim assist
    _toggle(parent, tr("Auto-aim Assist"), "auto_aim")
    
    # Arachnophobia mode
    _toggle(parent, tr("Arachnophobia Mode"), "arachnophobia")

# Helper functions
func _slider(parent: Node, label: String, key: String, min_v: float, max_v: float, step: float, callback) -> void:
    var row := HBoxContainer.new()
    parent.add_child(row)
    var l := Label.new()
    l.text = label
    l.custom_minimum_size.x = 180
    row.add_child(l)
    var s := HSlider.new()
    s.min_value = min_v
    s.max_value = max_v
    s.step = step
    s.value = SettingsManager.get_setting(key, (min_v + max_v) / 2)
    s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    s.value_changed.connect(func(v: float) -> void: 
        SettingsManager.set_setting(key, v)
        callback.call(v)
    )
    row.add_child(s)

func _toggle(parent: Node, label: String, key: String) -> void:
    var row := HBoxContainer.new()
    parent.add_child(row)
    var l := Label.new()
    l.text = label
    l.custom_minimum_size.x = 180
    row.add_child(l)
    var cb := CheckBox.new()
    cb.button_pressed = SettingsManager.get_setting(key, false)
    cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cb.toggled.connect(func(pressed: bool) -> void:
        SettingsManager.set_setting(key, pressed)
    )
    row.add_child(cb)

func _dropdown(parent: Node, label: String, key: String, options: Array, callback) -> void:
    var row := HBoxContainer.new()
    parent.add_child(row)
    var l := Label.new()
    l.text = label
    l.custom_minimum_size.x = 180
    row.add_child(l)
    var ob := OptionButton.new()
    ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for opt in options:
        ob.add_item(opt)
    var current = SettingsManager.get_setting(key, 0)
    ob.selected = clamp(current, 0, options.size() - 1)
    ob.item_selected.connect(func(idx: int) -> void:
        SettingsManager.set_setting(key, idx)
        callback.call(idx)
    )
    row.add_child(ob)