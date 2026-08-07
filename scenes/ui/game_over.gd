extends CanvasLayer

var _reason: String = ""

func _ready() -> void:
    visible = false
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_ui()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#0c1016")
    bg.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(bg)

    var title := Label.new()
    title.text = tr("DEATH_TITLE")
    title.add_theme_color_override("font_color", Color("#b4452f"))
    title.add_theme_font_size_override("font_size", 36)
    title.size = Vector2(600, 60)
    title.position = Vector2(get_viewport().size.x / 2.0 - 300, 150)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    bg.add_child(title)

    var subtitle := Label.new()
    subtitle.text = tr("DEATH_BY")
    subtitle.add_theme_color_override("font_color", Color("#aeb6bf"))
    subtitle.add_theme_font_size_override("font_size", 18)
    subtitle.size = Vector2(600, 30)
    subtitle.position = Vector2(get_viewport().size.x / 2.0 - 300, 220)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    bg.add_child(subtitle)

    var buttons := [
        {"key": "RESTART", "text": tr("BTN_RESTART"), "y": 350},
        {"key": "LOAD", "text": tr("BTN_LOAD"), "y": 420},
        {"key": "MAIN_MENU", "text": tr("DEATH_MAIN_MENU"), "y": 490},
    ]
    for b in buttons:
        var btn := Button.new()
        btn.text = b.text
        btn.size = Vector2(300, 55)
        btn.position = Vector2(get_viewport().size.x / 2.0 - 150, b.y)
        btn.add_theme_color_override("font_color", Color("#c9a24a"))
        match b.key:
            "RESTART": btn.pressed.connect(_on_restart)
            "LOAD": btn.pressed.connect(_on_load)
            "MAIN_MENU": btn.pressed.connect(_on_main_menu)
        bg.add_child(btn)
    print("GAME_OVER_READY")

func _show_ui(reason: String = "") -> void:
    _reason = reason
    visible = true
    get_tree().paused = true
    print("GAME_OVER show=true reason=", reason)

func _on_restart() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene()

func _on_load() -> void:
    if SaveSystem and SaveSystem.has_method("load_slot"):
        SaveSystem.load_slot(1)
    get_tree().paused = false
    get_tree().reload_current_scene()

func _on_main_menu() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/main_3d.tscn")
