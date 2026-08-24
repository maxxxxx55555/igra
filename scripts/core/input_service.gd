extends Node

signal interact_requested()
signal attack_requested()
signal jump_requested()
signal flashlight_requested()
signal dodge_requested(dir: Vector2)
## Клавиши 1-6 были заведены в project.godot, но их никто не слушал:
## быстрые слоты работали только мышью/тачем.
signal quick_slot_requested(index: int)
## Первое реальное действие игрока в текущем забеге — интерстишиалы не
## должны появляться раньше этого (TRUTH WAVE P0.2: "ads never before
## first gameplay input"). Сбрасывается на новую игру (см. game_started).
signal player_acted()

var _player_acted: bool = false

func has_player_acted() -> bool:
	return _player_acted

func _mark_player_acted() -> void:
	if _player_acted:
		return
	_player_acted = true
	player_acted.emit()

var _interact_pressed: bool = false
var _interact_held: bool = false
var _interact_released: bool = false

var _joy_active: bool = false
var _joy_dir: Vector2 = Vector2.ZERO
var _joy_run_held: bool = false
var _joy_stealth_toggled: bool = false
var _stealth_pressed: bool = false
var _stealth_held: bool = false
var _stealth_released: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Курсор пересчитывается на смене состояния игры и открытии/закрытии экранов.
	EventBus.game_state_changed.connect(func(_s: int) -> void: refresh_mouse_mode())
	EventBus.ui_screen_opened.connect(func(_id: String) -> void: refresh_mouse_mode())
	EventBus.ui_screen_closed.connect(func(_id: String) -> void: refresh_mouse_mode())
	EventBus.game_started.connect(func() -> void: _player_acted = false)
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", ev)

func request_interact() -> void:
	interact_requested.emit()
	_interact_pressed = true
	_interact_held = true

func request_attack() -> void:
	attack_requested.emit()

func request_jump() -> void:
	jump_requested.emit()

func request_flashlight() -> void:
	flashlight_requested.emit()

func request_dodge(dir: Vector2) -> void:
	dodge_requested.emit(dir)

func set_joy_move_dir(dir: Vector2) -> void:
	_joy_dir = dir.limit_length(1.0)
	if dir.length_squared() > 0.01:
		_mark_player_acted()

func set_joy_active(active: bool) -> void:
	_joy_active = active

func set_joy_run_held(held: bool) -> void:
	_joy_run_held = held

func set_joy_stealth_toggled(on: bool) -> void:
	_joy_stealth_toggled = on

func get_move_dir() -> Vector2:
	if _joy_active:
		return _joy_dir
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

func is_run_held() -> bool:
	return _joy_run_held or Input.is_action_pressed("run")

func is_stealth_toggled() -> bool:
	return _joy_stealth_toggled

func is_stealth_just_pressed() -> bool:
	var p := _stealth_pressed
	_stealth_pressed = false
	return p

func is_stealth_held() -> bool:
	return _stealth_held

func is_stealth_just_released() -> bool:
	var r := _stealth_released
	_stealth_released = false
	return r

func is_interact_just_pressed() -> bool:
	var p := _interact_pressed
	_interact_pressed = false
	return p

func _unhandled_input(event: InputEvent) -> void:
	# Раньше ветка отпускания вызывала is_action_pressed() на released-событии —
	# оно всегда false, поэтому _stealth_held/_interact_held залипали навсегда.
	# Плюс фильтр «только InputEventKey» глушил геймпад.
	if event.is_echo():
		return
	if event.is_pressed():
		_mark_player_acted()
	for i in range(1, 7):
		if event.is_action_pressed("quick_slot_%d" % i):
			quick_slot_requested.emit(i - 1)
			return
	if event.is_action_pressed("stealth"):
		_joy_stealth_toggled = not _joy_stealth_toggled
		_stealth_pressed = true
		_stealth_held = true
	elif event.is_action_released("stealth"):
		_stealth_held = false
		_stealth_released = true
	elif event.is_action_pressed("interact"):
		interact_requested.emit()
		_interact_pressed = true
		_interact_held = true
	elif event.is_action_released("interact"):
		_interact_held = false
		_interact_released = true

## ── Владение режимом курсора ────────────────────────────────────────────────
## Раньше mouse_mode дёргали 10 файлов вразнобой: пауза отпускала курсор, но
## никто не возвращал захват — после первого Esc камера мышью не управлялась.
## Теперь режим выводится из состояния игры в одном месте.

func is_touch_device() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")

## true, если сейчас игрок должен смотреть камерой (игра идёт и оверлеев нет).
func _should_capture() -> bool:
	if is_touch_device():
		return false
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or not gm.has_method("is_playing") or not gm.is_playing():
		return false
	var ui := get_node_or_null("/root/UIManager")
	if ui != null and ui.has_method("is_hud_blocked") and ui.is_hud_blocked():
		return false
	return true

func refresh_mouse_mode() -> void:
	var want := _should_capture()
	var mode := Input.MOUSE_MODE_CAPTURED if want else Input.MOUSE_MODE_VISIBLE
	if Input.get_mouse_mode() != mode:
		Input.set_mouse_mode(mode)
