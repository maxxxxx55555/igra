extends CanvasLayer
## A1: Victory - titry + statistika + Novaja igra+

@onready var title: Label = $Panel/Title
@onready var stats_label: Label = $Panel/StatsLabel
@onready var next_btn: Button = $Panel/NextButton
@onready var ng_btn: Button = $Panel/NGButton
@onready var menu_btn: Button = $Panel/MenuButton

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _apply_loc()
    stats_label.text = "Время: %ds | Убито: %d" % [int(GameManager.play_time), GameManager.enemies_killed]
    _show_endings()
    next_btn.pressed.connect(_on_next)
    ng_btn.pressed.connect(_on_ng)
    menu_btn.pressed.connect(_on_menu)
    if AchievementManager:
        AchievementManager.unlock("architect")
    LocalizationManager.language_changed.connect(_apply_loc)

## language_changed передаёт код языка; без параметра обработчик не срабатывает.
func _apply_loc(_lang: Variant = null) -> void:
    title.text = LocalizationManager.t("victory")
    next_btn.text = LocalizationManager.t("next_level")
    ng_btn.text = "Новая игра+"
    menu_btn.text = LocalizationManager.t("back_menu")

func _show_endings() -> void:
    var ends: Array = Endings.evaluate()
    print("[ENDINGS] achieved: ", ends.size())
    for e in ends:
        print("[ENDINGS] - ", e.get("id"), ": ", e.get("title"), " (", e.get("tier"), ")")
    if ends.is_empty():
        title.text += "\nБез концовки"
        stats_label.text += "\nУсловия концовок не выполнены."
        return
    var main: Dictionary = ends[0]
    title.text += "\nКонцовка: " + str(main.get("title"))
    stats_label.text += "\n" + str(main.get("desc"))
    for i in range(1, ends.size()):
        stats_label.text += "\n• " + str(ends[i].get("title"))

func _on_next() -> void:
    get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_ng() -> void:
    NewGamePlus.activate_ng_plus()
    get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_menu() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")