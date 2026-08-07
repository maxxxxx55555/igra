extends CanvasLayer

func _ready() -> void:
    visible = false
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_ui()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#0c1016")
    add_child(bg)

    var title := Label.new()
    title.text = tr("VICTORY_TITLE")
    title.add_theme_color_override("font_color", Color("#c9a24a"))
    title.add_theme_font_size_override("font_size", 40)
    title.size = Vector2(600, 60)
    title.position = Vector2(get_viewport().size.x / 2.0 - 300, 120)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    bg.add_child(title)

    var stats := Label.new()
    stats.text = "districts 11/11\n" + tr("VICTORY_DOCUMENTS")
    stats.add_theme_color_override("font_color", Color("#aeb6bf"))
    stats.add_theme_font_size_override("font_size", 18)
    stats.size = Vector2(600, 120)
    stats.position = Vector2(get_viewport().size.x / 2.0 - 300, 220)
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    bg.add_child(stats)

    var menu_btn := Button.new()
    menu_btn.text = tr("VICTORY_MAIN_MENU")
    menu_btn.size = Vector2(300, 55)
    menu_btn.position = Vector2(get_viewport().size.x / 2.0 - 150, 400)
    menu_btn.add_theme_color_override("font_color", Color("#c9a24a"))
    menu_btn.pressed.connect(_on_main_menu)
    bg.add_child(menu_btn)

    var new_game_btn := Button.new()
    new_game_btn.text = tr("VICTORY_NEW_GAME")
    new_game_btn.size = Vector2(300, 55)
    new_game_btn.position = Vector2(get_viewport().size.x / 2.0 - 150, 470)
    new_game_btn.add_theme_color_override("font_color", Color("#c9a24a"))
    new_game_btn.pressed.connect(_on_new_game)
    bg.add_child(new_game_btn)
    print("VICTORY_READY")

func _show_ui() -> void:
    visible = true
    get_tree().paused = true
    print("VICTORY show=true")

func _on_main_menu() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/main_3d.tscn")

func _on_new_game() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene()
