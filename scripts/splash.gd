extends Control
## Заставка с логотипом.
##
## Сцена splash.tscn инстанцируется в ДВУХ местах с разным смыслом:
##   1) как отдельная сцена (Bootstrap -> Routes.goto("res://scenes/ui/splash.tscn"));
##   2) как узел внутри scenes/main_3d.tscn.
##
## Раньше скрипт всегда дергал Routes.goto(Routes.BOOT). Внутри игровой сцены
## это означало: игрок запускает уровень -> через 3 секунды его вышвыривает
## обратно на экран загрузки, оттуда в меню. Играть было невозможно.
## Плюс main_3d.tscn выставлял splash-узлу свойство show_splash, которого в
## этом скрипте не было, — Godot ругался при загрузке сцены.

## Показывать ли заставку. В main_3d.tscn узел выключает её через это свойство.
@export var show_splash: bool = true

## Куда уходить после заставки. Пусто = никуда: значит, заставка живёт внутри
## другой сцены и распоряжаться переходами не имеет права.
@export_file("*.tscn") var next_scene: String = ""

const FADE_IN: float = 1.0
const HOLD: float = 2.0

@onready var logo: ColorRect = $Logo
@onready var label: Label = $Title

func _ready() -> void:
	add_to_group("ui_root")
	if not show_splash:
		hide()
		return
	logo.color = Color("#1D1812")
	label.text = "THE LAST STREETLIGHT"
	label.add_theme_color_override("font_color", Color("#E2A33C"))
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, FADE_IN)
	tw.tween_interval(HOLD)
	tw.tween_callback(_finish)

## Переход делаем ТОЛЬКО если заставка — самостоятельная сцена. Внутри
## main_3d.tscn она просто гаснет и освобождает экран.
func _finish() -> void:
	if is_inside_tree() and get_tree().current_scene == self and next_scene != "":
		Routes.goto(next_scene)
		return
	hide()
