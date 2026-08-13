extends Control
## Главное меню.
##
## Кнопки в main_menu.tscn не имели ни одной подписи (в сцене text не задан
## вообще) — игрок видел пять пустых прямоугольников. Тексты берутся из
## LocalizationManager и обновляются при смене языка.

## Кнопка -> ключ перевода.
const LABELS: Dictionary = {
	"Continue": "continue",
	"Play": "menu_play",
	"Settings": "settings",
	"Difficulty": "difficulty",
	"Credits": "credits",
	"Quit": "menu_quit",
}

func _ready() -> void:
	var vb: Node = get_node_or_null("VBox")
	if vb == null:
		return
	_ensure_continue(vb as VBoxContainer)
	_connect(vb, "Continue", func() -> void:
		# continue_game() поднимает состояние автолоадов; сцену открываем сами.
		GameManager.continue_game()
		if GameManager.is_playing():
			Routes.goto(Routes.GAME))
	_connect(vb, "Play", func() -> void: Routes.start_game())
	_connect(vb, "Settings", func() -> void: Routes.goto(Routes.SETTINGS))
	_connect(vb, "Difficulty", func() -> void: Routes.goto(Routes.DIFFICULTY))
	_connect(vb, "Credits", func() -> void: Routes.goto(Routes.CREDITS))
	_connect(vb, "Quit", func() -> void: Routes.goto("res://scenes/ui/confirm_quit.tscn"))
	_apply_localization()
	LocalizationManager.language_changed.connect(_apply_localization)
	# Возвращаем игру в состояние MENU (иначе после боя курсор остаётся
	# захваченным и по меню нечем кликать), но только если это ещё не сделано:
	# return_to_menu() дергает close_all_blocking() и шлёт game_state_changed.
	if not GameManager.is_menu():
		GameManager.return_to_menu()
	else:
		InputService.refresh_mouse_mode()

## «Продолжить» показываем только при наличии сохранения.
func _ensure_continue(vb: VBoxContainer) -> void:
	if vb.get_node_or_null("Continue") != null:
		return
	if not SaveSystem.has_method("has_save") or not SaveSystem.has_save():
		return
	var b := Button.new()
	b.name = "Continue"
	vb.add_child(b)
	vb.move_child(b, 1)

func _connect(vb: Node, node_name: String, cb: Callable) -> void:
	var b := vb.get_node_or_null(node_name) as Button
	if b == null:
		return
	b.focus_mode = Control.FOCUS_ALL
	if not b.pressed.is_connected(cb):
		b.pressed.connect(cb)

func _apply_localization(_lang: Variant = null) -> void:
	var vb: Node = get_node_or_null("VBox")
	if vb == null:
		return
	for node_name in LABELS:
		var b := vb.get_node_or_null(String(node_name)) as Button
		if b != null:
			b.text = LocalizationManager.t(String(LABELS[node_name]))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Routes.goto("res://scenes/ui/confirm_quit.tscn")
