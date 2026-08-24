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
	# THEME UNIFICATION P0: was the only screen with no local theme override
	# at all - ThemeSetup's window-wide default doesn't reliably propagate
	# to Controls added after boot in this engine build (Control-to-Control
	# inheritance does; Window.theme does not - confirmed via probe), so
	# this screen silently rendered with zero chrome. Every other screen in
	# the project already opts in exactly like this.
	theme = ThemeProvider.build_theme()
	var vb: Node = get_node_or_null("VBox")
	if vb == null:
		return
	_install_background()
	_start_flicker()
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

## T14: живой параллакс-фон (NIGHT/DAY/GENERATOR) между BG и Flicker.
func _install_background() -> void:
	if get_node_or_null("MenuBackground") != null:
		return
	var bg_script := load("res://scripts/ui/menu_background.gd")
	var bg := Control.new()
	bg.name = "MenuBackground"
	bg.set_script(bg_script)
	add_child(bg)
	var bg_flat := get_node_or_null("BG")
	move_child(bg, (bg_flat.get_index() + 1) if bg_flat else 0)

## Flicker стоял в сцене с color.a = 0.15 и без единой строчки кода, которая
## бы его двигала — ровный тёплый засвет поверх всего меню 24/7 вместо
## задуманного мерцания лампы (см. комментарий T14 у _install_background).
## Приглушаем базовую альфу и гоняем её неровными рывками, как дышащий
## на ладан фонарь.
func _start_flicker() -> void:
	var f: ColorRect = get_node_or_null("Flicker")
	if f == null:
		return
	f.color.a = 0.04
	_flicker_step(f)

func _flicker_step(f: ColorRect) -> void:
	if not is_instance_valid(f):
		return
	var tw := create_tween()
	tw.tween_property(f, "color:a", randf_range(0.02, 0.07), randf_range(0.15, 0.6))
	tw.tween_callback(_flicker_step.bind(f))

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
	if not b.pressed.is_connected(UISFX.click):
		b.pressed.connect(UISFX.click)
	if not b.mouse_entered.is_connected(UISFX.hover):
		b.mouse_entered.connect(UISFX.hover)

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
