extends Node

signal interact_requested()
signal attack_requested()
signal jump_requested()
signal flashlight_requested()
signal dodge_requested(dir: Vector2)

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
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("stealth"):
			_joy_stealth_toggled = not _joy_stealth_toggled
			_stealth_pressed = true
			_stealth_held = true
		elif event.is_action_pressed("interact"):
			interact_requested.emit()
			_interact_pressed = true
			_interact_held = true
	if event is InputEventKey and not event.pressed and not event.echo:
		if event.is_action_pressed("stealth"):
			_stealth_held = false
			_stealth_released = true
		elif event.is_action_pressed("interact"):
			_interact_held = false
			_interact_released = true