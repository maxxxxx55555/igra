# ВНИМАНИЕ: этот файл НЕ загружается в рантайме — живой экран паузы: UIManager.SCREENS["pause"] = res://scripts/ui/pause_menu.gd. Правки здесь не влияют на игру.
extends CanvasLayer

@export var enable_pause_menu: bool = true

var _is_open: bool = false

func _ready() -> void:
    visible = false
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_ui()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.name = "Bg"
    bg.color = Color("#0c1016")
    bg.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(bg)

    var panel := ColorRect.new()
    panel.name = "Panel"
    panel.color = Color("#141b24")
    panel.size = Vector2(400, 500)
    panel.position = Vector2(get_viewport().size.x / 2.0 - 200, get_viewport().size.y / 2.0 - 250)
    bg.add_child(panel)

    var title := Label.new()
    title.text = tr("SETTINGS_PAUSE")
    title.add_theme_color_override("font_color", Color("#d8d2c4"))
    title.add_theme_font_size_override("font_size", 24)
    title.size = Vector2(400, 40)
    title.position = Vector2(0, 20)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    panel.add_child(title)

    var buttons := ["RESUME", "SAVE", "LOAD", "SETTINGS", "MAIN_MENU"]
    var btn_labels := {
        "RESUME": tr("BTN_RESUME"),
        "SAVE": tr("BTN_SAVE"),
        "LOAD": tr("BTN_LOAD"),
        "SETTINGS": tr("MAIN_SETTINGS"),
        "MAIN_MENU": tr("BTN_MAIN_MENU"),
    }
    var y := 80
    for action in buttons:
        var btn := Button.new()
        btn.text = btn_labels.get(action, action)
        btn.size = Vector2(300, 60)
        btn.position = Vector2(50, y)
        btn.add_theme_color_override("font_color", Color("#c9a24a"))
        btn.add_theme_stylebox_override("normal", _make_btn_style())
        match action:
            "RESUME": btn.pressed.connect(_on_resume)
            "SAVE": btn.pressed.connect(_on_save)
            "LOAD": btn.pressed.connect(_on_load)
            "SETTINGS": btn.pressed.connect(_on_settings)
            "MAIN_MENU": btn.pressed.connect(_on_main_menu)
        panel.add_child(btn)
        y += 80

func _make_btn_style() -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color("#141b24")
    sb.border_color = Color("#2a3340")
    sb.border_width_left = 1
    sb.border_width_right = 1
    sb.border_width_top = 1
    sb.border_width_bottom = 1
    sb.corner_radius_top_left = 0
    sb.corner_radius_top_right = 0
    sb.corner_radius_bottom_left = 0
    sb.corner_radius_bottom_right = 0
    return sb

func open() -> void:
    _is_open = true
    visible = true
    get_tree().paused = true
    print("PAUSE_MENU open=true")

func close() -> void:
    _is_open = false
    visible = false
    get_tree().paused = false
    print("PAUSE_MENU open=false")

func _on_resume() -> void: close()
func _on_save() -> void:
    var sm := get_tree().root.get_node_or_null("SaveSystem")
    if sm and sm.has_method("save_slot"):
        sm.save_slot(1)
    _show_feedback("SAVED")
func _on_load() -> void:
    var sm := get_tree().root.get_node_or_null("SaveSystem")
    if sm and sm.has_method("load_slot"):
        sm.load_slot(1)
    close()
func _on_settings() -> void:
    UIManager.open(&"settings")
    close()
func _on_main_menu() -> void:
    get_tree().paused = false
    var gm := get_tree().root.get_node_or_null("GameManager")
    if gm and gm.has_method("return_to_menu"):
        gm.return_to_menu()
    get_tree().change_scene_to_file("res://scenes/main_3d.tscn")
    print("PAUSE_MENU main_menu=true")

func _show_feedback(text: String) -> void:
    var lbl := Label.new()
    lbl.text = text
    lbl.add_theme_color_override("font_color", Color("#c9a24a"))
    lbl.size = Vector2(400, 30)
    lbl.position = Vector2(0, 460)
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var panel = get_node_or_null("Panel")
    if panel:
        panel.add_child(lbl)
        var tween := create_tween()
        tween.tween_property(lbl, "modulate", Color(1,1,1,0), 1.5)
        tween.tween_callback(lbl.queue_free)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        if _is_open:
            close()
        else:
            open()
