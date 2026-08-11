class_name TouchControls
extends CanvasLayer

@onready var joystick_area: Control = %JoystickArea
@onready var joystick_knob: Control = %JoystickKnob
@onready var action_button: Button = %ActionButton
@onready var run_button: Button = %RunButton
@onready var stealth_button: Button = %StealthButton
@onready var flashlight_button: Button = %FlashlightButton
@onready var attack_button: Button = %AttackButton

var joystick_active: bool = false
var joystick_touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var joystick_max_radius: float = 50.0
var _output_direction: Vector2 = Vector2.ZERO

signal direction_changed(direction: Vector2)


func _ready() -> void:

	action_button.pressed.connect(_on_action)
	run_button.pressed.connect(_on_run)
	run_button.button_up.connect(_on_run_release)
	stealth_button.toggled.connect(_on_stealth)
	flashlight_button.pressed.connect(_on_flashlight)
	attack_button.pressed.connect(_on_attack)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var rect: Rect2 = joystick_area.get_global_rect()
			if rect.has_point(event.position):
				joystick_active = true
				joystick_touch_index = event.index
				joystick_center = joystick_area.get_global_rect().get_center()
				joystick_knob.position = Vector2.ZERO
		else:
			if event.index == joystick_touch_index:
				_reset_joystick()

	if event is InputEventScreenDrag:
		if event.index == joystick_touch_index and joystick_active:
			var offset: Vector2 = event.position - joystick_center
			var clamped: Vector2 = offset.limit_length(joystick_max_radius)
			joystick_knob.position = clamped
			_output_direction = clamped / joystick_max_radius
			direction_changed.emit(_output_direction)


func _reset_joystick() -> void:
	joystick_active = false
	joystick_touch_index = -1
	joystick_knob.position = Vector2.ZERO
	_output_direction = Vector2.ZERO
	direction_changed.emit(Vector2.ZERO)


func get_direction() -> Vector2:
	return _output_direction


func _on_action() -> void:
	var player: Node = get_tree().root.get_node_or_null("Main3D/Player3D")
	if player and player.has_method("interact"):
		player.interact()


func _on_run() -> void:
	var player: Node = get_tree().root.get_node_or_null("Main3D/Player3D")
	if player:
		player.set_running(true)


func _on_run_release() -> void:
	var player: Node = get_tree().root.get_node_or_null("Main3D/Player3D")
	if player:
		player.set_running(false)


func _on_stealth(toggled_on: bool) -> void:
	var player: Node = get_tree().root.get_node_or_null("Main3D/Player3D")
	if player:
		player.set_stealth(toggled_on)


func _on_flashlight() -> void:
	var player: Node = get_tree().root.get_node_or_null("Main3D/Player3D")
	if player:
		player.toggle_flashlight()


func _on_attack() -> void:
	var player: Node = get_tree().root.get_node_or_null("Main3D/Player3D")
	if player:
		player.attack()
