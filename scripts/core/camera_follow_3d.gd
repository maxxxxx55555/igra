extends Node3D

@export var height: float = 7.0
@export var distance: float = 5.0
@export var look_height_offset: float = 2.0
@export var follow_speed: float = 7.0
@export var fov_deg: float = 55.0
@export var target_path: NodePath = ^""

@export var interior_height: float = 4.5
@export var interior_distance: float = 3.5
@export var interior_fov: float = 48.0
@export var interior_lerp_speed: float = 5.0

@export var fps_mode: bool = true
@export var fps_eye_height: float = 1.7
@export var fps_follow_speed: float = 15.0

var _cam: Camera3D = null
var _target: Node3D = null
var _is_interior: bool = false
var _current_height: float
var _current_distance: float
var _current_fov: float
var _pitch: float = 0.0

func _ready() -> void:
	_cam = _find_cam(self)
	if _cam == null:
		# push_warning("camera_follow_3d: Camera3D не найдена")
		return
	_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	_cam.fov = fov_deg
	_current_height = height
	_current_distance = distance
	_current_fov = fov_deg
	_target = _resolve_target()
	var pitch = rad_to_deg(atan2(height - look_height_offset, distance))


func set_pitch(v: float) -> void:
	_pitch = v

func set_fps(v: bool) -> void:
	fps_mode = v


func _process(delta: float) -> void:
	if _cam == null:
		return
	if not is_instance_valid(_target):
		_target = _resolve_target()
	if _target == null:
		return
	if fps_mode:
		_tick_fps(delta)
	else:
		_tick_third(delta)

func _tick_fps(delta: float) -> void:
	var tp: Vector3 = _target.global_position
	var desired: Vector3 = tp + Vector3(0.0, fps_eye_height, 0.0)
	_cam.global_position = _cam.global_position.lerp(desired, clampf(delta * fps_follow_speed, 0.0, 1.0))
	var yaw: float = _target.rotation.y
	_cam.rotation = Vector3(_pitch, yaw, 0.0)
	_cam.fov = lerpf(_cam.fov, _current_fov, clampf(delta * interior_lerp_speed, 0.0, 1.0))
	_tick_interior_target()

func _tick_third(delta: float) -> void:
	_tick_interior()
	var tp: Vector3 = _target.global_position
	var desired: Vector3 = tp + Vector3(0.0, _current_height, _current_distance)
	_cam.global_position = _cam.global_position.lerp(desired, clampf(delta * follow_speed, 0.0, 1.0))
	_cam.look_at(tp + Vector3(0.0, look_height_offset, 0.0), Vector3.UP)
	_cam.fov = lerpf(_cam.fov, _current_fov, clampf(delta * interior_lerp_speed, 0.0, 1.0))

func _tick_interior() -> void:
	var in_interior: bool = false
	if _target and is_instance_valid(_target):
		var zones := get_tree().get_nodes_in_group("interior_zone")
		for z in zones:
			if z is Area3D and _target in z.get_overlapping_bodies():
				in_interior = true
				break
	_apply_interior(in_interior)

func _tick_interior_target() -> void:
	var in_interior: bool = false
	if _target and is_instance_valid(_target):
		var zones := get_tree().get_nodes_in_group("interior_zone")
		for z in zones:
			if z is Area3D and _target in z.get_overlapping_bodies():
				in_interior = true
				break
	_apply_interior(in_interior)

func _apply_interior(in_interior: bool) -> void:
	if in_interior and not _is_interior:
		_is_interior = true

	elif not in_interior and _is_interior:
		_is_interior = false

	var target_h := interior_height if _is_interior else height
	var target_d := interior_distance if _is_interior else distance
	var target_f := interior_fov if _is_interior else fov_deg
	_current_height = lerpf(_current_height, target_h, 0.4)
	_current_distance = lerpf(_current_distance, target_d, 0.4)
	_current_fov = lerpf(_current_fov, target_f, 0.4)

func set_interior(v: bool) -> void:
	if v != _is_interior:
		_is_interior = v

func _resolve_target() -> Node3D:
	if target_path != NodePath(""):
		var n = get_node_or_null(target_path)
		if n is Node3D: return n
	var g = get_tree().get_nodes_in_group("player")
	if g.size() > 0 and g[0] is Node3D: return g[0] as Node3D
	var by_name = _find_by_name(get_tree().current_scene, ["Player", "player"])
	if by_name != null: return by_name
	return _find_first(get_tree().current_scene, "CharacterBody3D") as Node3D

func _find_cam(n: Node) -> Camera3D:
	if n == null: return null
	if n is Camera3D: return n
	for c in n.get_children():
		var r = _find_cam(c)
		if r != null: return r
	return null

func _find_by_name(n: Node, names: Array) -> Node3D:
	if n == null: return null
	if n.name in names and n is Node3D: return n
	for c in n.get_children():
		var r = _find_by_name(c, names)
		if r != null: return r
	return null

func _find_first(n: Node, cls: String) -> Node:
	if n == null: return null
	if n.get_class() == cls: return n
	for c in n.get_children():
		var r = _find_first(c, cls)
		if r != null: return r
	return null
