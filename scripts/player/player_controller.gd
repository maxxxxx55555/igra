extends CharacterBody3D
class_name Player
## FPS controller. Desktop WASD+mouse, Android gets input from HUDTouch.
## Required methods for HUDMain: set_move_input, toggle_flashlight, interact.

@export var walk_speed: float = 5.0
@export var run_multiplier: float = 1.6
@export var gravity: float = 12.0
@export var mouse_sensitivity: float = 0.0025
@export var flashlight_energy: float = 4.0
@export var flashlight_range: float = 18.0

var _move: Vector3 = Vector3.ZERO
var _yaw: float = 0.0
var _pitch: float = 0.0
var _sprinting: bool = false
var _flash_on: bool = false
var _flash: SpotLight3D
var _body: Node3D
var _head: Node3D
var _cam: Camera3D

func _ready() -> void:
	add_to_group(&"player")
	_body = get_node_or_null("Body") as Node3D
	_head = get_node_or_null("Body/Head") as Node3D
	_cam = get_node_or_null("Body/Head/Camera") as Camera3D
	if _cam == null:
		_cam = Camera3D.new()
		_cam.name = &"Camera"
		var parent: Node = _head if _head != null else (_body if _body != null else self)
		parent.add_child(_cam)
	_flash = _cam.get_node_or_null("Flashlight") as SpotLight3D
	if _flash == null:
		_flash = SpotLight3D.new()
		_flash.name = &"Flashlight"
		_flash.spot_range = flashlight_range
		_flash.spot_angle = 35.0
		_flash.light_color = Color(1.0, 0.9, 0.7)
		_flash.light_energy = 0.0
		_flash.add_to_group(&"flashlight")
		_cam.add_child(_flash)
	if not OS.has_feature("android"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_physics_process(true)
	set_process_unhandled_input(true)

func set_move_input(v: Vector3) -> void:
	_move = v

func sprinting_set(on: bool) -> void:
	_sprinting = on

func sprinting_get() -> bool:
	return _sprinting

func toggle_flashlight() -> void:
	_flash_on = not _flash_on
	_flash.light_energy = flashlight_energy if _flash_on else 0.0
	if _flash_on:
		LightGrid.register_light(_flash)
	else:
		LightGrid.unregister_light(_flash)

func interact() -> void:
	if _cam == null:
		return
	var origin: Vector3 = _cam.global_position
	var dir: Vector3 = -_cam.global_transform.basis.z
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * 2.5)
	q.exclude = [get_rid()]
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty():
		return
	var c: Variant = hit["collider"]
	if c is Node:
		var n: Node = c
		if n.has_method("on_interact"):
			n.call("on_interact", self)

func _unhandled_input(event: InputEvent) -> void:
	if OS.has_feature("android"):
		return
	if event is InputEventMouseMotion:
		var m: InputEventMouseMotion = event
		_yaw -= m.relative.x * mouse_sensitivity
		_pitch = clamp(_pitch - m.relative.y * mouse_sensitivity, -1.4, 1.4)
		if _body != null:
			_body.rotation.y = _yaw
		if _head != null:
			_head.rotation.x = _pitch
	elif event is InputEventKey:
		var k: InputEventKey = event
		if k.pressed and k.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if k.keycode == KEY_F:
			toggle_flashlight()
		if k.keycode == KEY_SHIFT:
			_sprinting = k.pressed

func _physics_process(delta: float) -> void:
	var v: Vector3 = _move
	if not OS.has_feature("android"):
		var kb: Vector3 = Vector3.ZERO
		if Input.is_key_pressed(KEY_W): kb.z -= 1.0
		if Input.is_key_pressed(KEY_S): kb.z += 1.0
		if Input.is_key_pressed(KEY_A): kb.x -= 1.0
		if Input.is_key_pressed(KEY_D): kb.x += 1.0
		if kb.length() > 0.01:
			kb = kb.normalized()
			if _body != null:
				kb = _body.global_transform.basis * kb
			v = kb * walk_speed * (run_multiplier if _sprinting else 1.0)
		else:
			v = Vector3.ZERO
	v.y = velocity.y - gravity * delta
	velocity = v
	move_and_slide()