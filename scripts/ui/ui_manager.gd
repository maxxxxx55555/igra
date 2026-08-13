extends Node
const SCREENS: Dictionary = {
	# Именно сцена, а не скрипт: main_menu.gd работает с узлом VBox из
	# main_menu.tscn. Инстанс «голого» скрипта давал пустой блокирующий
	# оверлей, который прятал HUD и перехватывал ввод.
	&"main_menu":       "res://scenes/ui/main_menu.tscn",
	&"pause":           "res://scripts/ui/pause_menu.gd",
	&"settings":        "res://scripts/ui/settings_screen.gd",
	&"death":           "res://scripts/ui/death_screen.gd",
	&"win":             "res://scripts/ui/win_screen.gd",
	&"city_map":        "res://scripts/ui/city_map.gd",
	# Пять справочных разделов живут внутри одного экрана «Кодекс» с
	# вкладками. Отдельные записи оставлены: старые вызовы open(&"journal")
	# и т.п. перенаправляются в нужную вкладку через CODEX_TABS.
	&"codex":           "res://scripts/ui/codex_ui.gd",
	&"encyclopedia":    "res://scripts/ui/encyclopedia_ui.gd",
	&"journal":         "res://scripts/ui/journal_ui.gd",
	&"quest_journal":   "res://scripts/ui/quest_journal.gd",
	&"achievements":    "res://scripts/ui/achievements_ui.gd",
	&"stats":           "res://scripts/ui/stats_ui.gd",
	&"workbench":       "res://scripts/ui/workbench.gd",
	&"tutorial":        "res://scripts/ui/tutorial_system.gd",
	&"skill_tree":      "res://scenes/ui/skill_tree_ui.tscn",
	&"new_game_plus":   "res://scenes/ui/new_game_plus.tscn",
}
const BLOCKING: Array = [&"main_menu", &"pause", &"settings", &"death", &"win",
	&"city_map", &"codex", &"encyclopedia", &"journal", &"quest_journal", &"achievements", &"stats", &"workbench", &"photo", &"skill_tree", &"new_game_plus"]

## Старый id раздела -> вкладка «Кодекса». Экраны перечислены и в SCREENS,
## но открываются уже не поодиночке, а как вкладка общего экрана.
const CODEX_TABS: Dictionary = {
	&"journal": &"journal",
	&"quest_journal": &"quests",
	&"achievements": &"achievements",
	&"stats": &"stats",
	&"encyclopedia": &"bestiary",
}
var _layer: CanvasLayer
var _cache: Dictionary = {}
var _open_blocking: Array = []
var _minimap: Control
var _weather_overlay: Control
var _photo: Control
var _quest_hud: Control
var _toast: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 10
	add_child(_layer)
	_minimap = _mk_overlay("res://scripts/ui/minimap.gd", "Minimap")
	_weather_overlay = _mk_overlay("res://scripts/ui/weather_overlay.gd", "WeatherOverlay")
	_photo = _mk_overlay("res://scripts/ui/photo_mode.gd", "PhotoMode")
	_quest_hud = _mk_overlay("res://scripts/ui/quest_tracker_hud.gd", "QuestHUD")
	_quest_hud.visible = false
	EventBus.game_state_changed.connect(_on_game_state)
	EventBus.game_started.connect(func() -> void: close(&"main_menu"))
	_on_game_state(GameManager.current_state)

func _mk_overlay(path: String, node_name: String) -> Control:
	var c := Control.new()
	var s: Script = load(path)
	if s != null:
		c.set_script(s)
	c.name = node_name
	_layer.add_child(c)
	return c

func show_notification(msg: String) -> void:
	if _toast == null:
		_toast = Label.new()
		_toast.name = "Toast"
		_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_toast.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
		_toast.add_theme_font_size_override("font_size", 20)
		_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		_toast.offset_bottom = -80
		_layer.add_child(_toast)
	_toast.text = msg
	_toast.visible = true
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_callback(func() -> void: _toast.visible = false)
func is_hud_blocked() -> bool:
	return (not _open_blocking.is_empty()) or (not GameManager.is_playing())
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("ui_pause"):
			if _is_open(&"pause"):
				close(&"pause")
				GameManager.resume_game()
			elif _topmost_closable() != &"":
				# Escape сначала закрывает открытый справочник/карту. Раньше он
				# сразу открывал паузу поверх «Кодекса»: два блокирующих экрана
				# накладывались, а после «Продолжить» кодекс оставался висеть и
				# продолжал прятать HUD.
				close(_topmost_closable())
			elif GameManager.is_playing():
				open(&"pause")
				GameManager.pause_game()
		elif event.is_action_pressed("photo_mode"):
			_photo.toggle()
		elif event.is_action_pressed("city_map_toggle"):
			toggle(&"city_map")
		elif event.is_action_pressed("encyclopedia_toggle"):
			toggle(&"encyclopedia")
		elif event.is_action_pressed("journal_toggle"):
			toggle(&"journal")
## Последний открытый блокирующий экран, который Escape вправе закрыть.
## Само меню и экраны смерти/победы не трогаем: из них выходят кнопками.
const _ESC_KEEP: Array = [&"main_menu", &"death", &"win", &"pause"]

func _topmost_closable() -> StringName:
	for i in range(_open_blocking.size() - 1, -1, -1):
		var id: StringName = _open_blocking[i]
		if not _ESC_KEEP.has(id):
			return id
	return &""

func open(id: StringName) -> void:
	# Справочные разделы больше не открываются сами по себе — только как
	# вкладка «Кодекса», иначе игрок получал бы окно без ряда вкладок.
	if CODEX_TABS.has(id):
		open_codex(CODEX_TABS[id])
		return
	var scr: Control = _get_screen(id)
	if scr == null:
		return
	scr.visible = true
	if BLOCKING.has(id):
		if not _open_blocking.has(id):
			_open_blocking.append(id)
		_set_hud(false)
	EventBus.ui_screen_opened.emit(id)
func close(id: StringName) -> void:
	var scr: Control = _cache.get(id, null)
	if scr != null:
		scr.visible = false
	if _open_blocking.has(id):
		_open_blocking.erase(id)
		if _open_blocking.is_empty():
			_set_hud(true)
	EventBus.ui_screen_closed.emit(id)
func toggle(id: StringName) -> void:
	if CODEX_TABS.has(id):
		# Повторное нажатие той же клавиши закрывает «Кодекс», а нажатие
		# клавиши другого раздела переключает вкладку, не закрывая экран.
		var want: StringName = CODEX_TABS[id]
		var codex: Control = _cache.get(&"codex", null)
		if codex != null and codex.visible and codex.has_method("current_tab"):
			if StringName(codex.call("current_tab")) == want:
				close(&"codex")
				return
		open_codex(want)
		return
	if _is_open(id):
		close(id)
	else:
		open(id)

## Открывает «Кодекс» на конкретной вкладке.
func open_codex(tab: StringName) -> void:
	var codex: Control = _get_screen(&"codex")
	if codex == null:
		return
	codex.visible = true
	if not _open_blocking.has(&"codex"):
		_open_blocking.append(&"codex")
	_set_hud(false)
	if codex.has_method("open_tab"):
		codex.call("open_tab", tab)
	EventBus.ui_screen_opened.emit(&"codex")
func close_all_blocking() -> void:
	for id in _open_blocking.duplicate():
		close(id)
func _is_open(id: StringName) -> bool:
	var scr: Control = _cache.get(id, null)
	return scr != null and scr.visible
func _get_screen(id: StringName) -> Control:
	if _cache.has(id):
		return _cache[id]
	var path: String = SCREENS.get(id, "")
	if path == "":
		return null
	var node: Control = null
	if path.ends_with(".tscn"):
		var ps: PackedScene = load(path)
		if ps != null:
			node = ps.instantiate() as Control
	else:
		var scr: Script = load(path)
		if scr != null:
			node = scr.new() as Control
	if node == null:
		return null
	node.name = String(id)
	node.visible = false
	var is_scene := path.ends_with(".tscn")
	if not is_scene:
		node.size = Vector2(_layer.get_viewport().get_visible_rect().size)
	_layer.add_child(node)
	if not is_scene:
		node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if is_scene:
		var view2 := Vector2(node.get_viewport_rect().size)
		if node.size.x < view2.x or node.size.y < view2.y:
			node.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	_cache[id] = node
	return node
## true, если текущая сцена — само главное меню.
func _in_menu_scene() -> bool:
	var cs := get_tree().current_scene
	return cs != null and cs.scene_file_path == "res://scenes/ui/main_menu.tscn"

func _set_hud(visible: bool) -> void:
	EventBus.hud_visibility_changed.emit(visible)
func _on_game_state(state: int) -> void:
	# Игровые накладки (трекер квестов, миникарта, погода) видны только в игре:
	# в меню и на экранах смерти/победы они висели поверх кнопок.
	var in_game := state == GameManager.GameState.PLAYING
	for n in [_quest_hud, _minimap, _weather_overlay]:
		if is_instance_valid(n):
			n.visible = in_game
	match state:
		GameManager.GameState.MENU:
			# Если игрок уже НА сцене меню, второй экран поверх неё не нужен —
			# иначе main_menu.gd -> return_to_menu() -> MENU -> open(main_menu)
			# уходило в самоповтор и рисовало меню поверх меню.
			if not _in_menu_scene():
				open(&"main_menu")
		GameManager.GameState.PLAYING:
			# Меню закрывалось только по EventBus.game_started. Любой другой путь
			# в PLAYING (загрузка, отладка, конец катсцены) оставлял главное меню
			# висеть поверх игры.
			for id in [&"main_menu", &"death", &"win"]:
				close(id)
		GameManager.GameState.DEAD:
			open(&"death")
		GameManager.GameState.WIN:
			open(&"win")

