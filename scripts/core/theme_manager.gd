extends Node

const THEME_PATH: String = "res://data/ui/theme_main.tres"

func _ready() -> void:
    var theme: Theme = load(THEME_PATH) as Theme
    if theme:
        get_tree().root.theme = theme
    else:
        push_error("ThemeManager: не удалось загрузить %s" % THEME_PATH)
        get_window().size = get_window().size
