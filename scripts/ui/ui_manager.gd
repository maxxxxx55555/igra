extends Node
const SCREENS: Dictionary = {
	&"main_menu":       "res://scripts/ui/main_menu.gd",
	&"pause":           "res://scripts/ui/pause_menu.gd",
	&"settings":        "res://scripts/ui/settings_screen.gd",
	&"death":           "res://scripts/ui/death_screen.gd",
	&"win":             "res://scripts/ui/win_screen.gd",
	&"city_map":        "res://scripts/ui/city_map.gd",
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
	&"city_map", &"encyclopedia", &"journal", &"quest_journal", &"achievements", &"stats", &"workbench", &"photo", &"skill_tree", &"new_game_plus"]
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
	_layer.layer = 15
	add_child(_layer)
	_minimap = _mk_overlay("res://scripts/ui/minimap.gd", "Minimap")
	_minimap.get_parent().layer = 20
	_weather_overlay = _mk_overlay("res://scripts/ui/weather_overlay.gd", "WeatherOverlay")
	_photo = _mk_overlay("res://scripts/ui/photo_mode.gd", "PhotoMode")
	_quest_hud = _mk_overlay("res://scripts/ui/quest_tracker_hud.gd", "QuestHUD")
	_quest_hud.visible = false
	EventBus.game_state_changed.connect(_on_game_state)
	EventBus.game_started.connect(func() -> void: close(&"main_menu"))
	EventBus.toast_requested.connect(func(msg: String, _type: String) -> void: show_notification(msg))
	_on_game_state(int(GameManager.current_state))

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
func open(id: StringName) -> void:
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
	if _is_open(id):
		close(id)
	else:
		open(id)
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
func _set_hud(visible: bool) -> void:
	EventBus.hud_visibility_changed.emit(visible)
func _on_game_state(state: int) -> void:
	var in_game := state == GameManager.GameState.PLAYING
	var paused := state == GameManager.GameState.PAUSED
	for n in [_quest_hud, _weather_overlay]:
		if is_instance_valid(n):
			n.visible = in_game or paused
	if is_instance_valid(_minimap):
		_minimap.visible = false
	match state:
		GameManager.GameState.MENU:
			_set_hud(false)
			open(&"main_menu")
		GameManager.GameState.PLAYING:
			for id in [&"main_menu", &"pause", &"death", &"win"]:
				close(id)
			_set_hud(true)
		GameManager.GameState.PAUSED:
			_set_hud(false)
			open(&"pause")
		GameManager.GameState.DEAD:
			_set_hud(false)
			open(&"death")
		GameManager.GameState.WIN:
			_set_hud(false)
			open(&"win")

