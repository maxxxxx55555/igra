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

## GDD.md:45-46 (G02/G03): sprint headbob amplitude (capped low - "не выше,
## укачивание") and the short sprint FOV punch. Gated by reduce_ui_motion,
## same accessibility API uisfx.gd already reads (SettingsManager.get_setting).
const SPRINT_BOB_AMP: float = 0.1
const SPRINT_BOB_FREQ: float = 8.0   ## matches player_3d.gd's own walk-sway rate
const SPRINT_FOV_BONUS: float = 5.0
## A landing after LAND_MIN_AIR_SEC in the air dips the eye by LAND_DIP_M and opens the view LAND_FOV_PUNCH degrees, both gone in LAND_SEC.
const LAND_MIN_AIR_SEC: float = 0.25
const LAND_DIP_M: float = 0.08
const LAND_FOV_PUNCH: float = 2.0
const LAND_SEC: float = 0.2
## At rest the eye breathes: BREATH_M up and down, one breath in about 4 s (none with Motion Comfort).
const BREATH_M: float = 0.004
const BREATH_RAD_PER_SEC: float = 1.6
## A shot kicks the view up RECOIL_PITCH_RAD per unit of the weapon's recoil and a little to a side, and it settles back (none with Motion Comfort).
const RECOIL_PITCH_RAD: float = 0.04
const RECOIL_YAW_RAD: float = 0.012
const RECOIL_SETTLE_PER_SEC: float = 9.0

## GDD 2.2 (CT7): a pinch zooms the camera. The factor only scales the target the camera eases toward (the FOV in
## first person, the boom offset in third person), so the interior blend and the sprint punch keep working on top
## of it; 1.0 is the camera as it was before the pinch existed.
const ZOOM_MIN: float = 0.8
const ZOOM_MAX: float = 1.35
const ZOOM_BLEND_PER_SEC: float = 12.0
## The interior blend closed 40% of the gap on every frame, four times quicker at 120 FPS than at 30. Per second it is
## the same feel at 60 FPS (-60 * ln(1 - 0.4)) and now the same at any frame rate.
const INTERIOR_BLEND_PER_SEC: float = 30.65

var _cam: Camera3D = null
var _target: Node3D = null
var _is_interior: bool = false
var _current_height: float
var _current_distance: float
var _current_fov: float
var _pitch: float = 0.0
var _running: bool = false
var _bob_t: float = 0.0
var _breath_t: float = 0.0
var _zoom: float = 1.0
var _zoom_target: float = 1.0
var _air_sec: float = 0.0
var _was_grounded: bool = true
var _land_kick: float = 0.0
var _recoil: Vector2 = Vector2.ZERO  # x: pitch up, y: yaw

func _ready() -> void:
	_cam = _find_cam(self)
	if _cam == null:
		return
	_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	# FOV, выставленный в сцене, важнее дефолта скрипта: раньше _ready()
	# затирал авторские 80° третьеличными 55° и вид становился «трубой».
	if not is_equal_approx(_cam.fov, 75.0):
		fov_deg = _cam.fov
	_cam.fov = fov_deg
	_current_height = height
	_current_distance = distance
	_current_fov = fov_deg
	_target = _resolve_target()


func set_pitch(v: float) -> void:
	_pitch = v

func set_fps(v: bool) -> void:
	fps_mode = v

func set_running(v: bool) -> void:
	_running = v

## A pinch or a trackpad magnify: `mult` above 1 zooms in, below 1 out. Every call carries one step of the gesture,
## so the steps multiply into the target; letting go simply stops the calls and the zoom stays.
func zoom_by(mult: float) -> void:
	_zoom_target = clampf(_zoom_target * mult, ZOOM_MIN, ZOOM_MAX)

func get_zoom_factor() -> float:
	return _zoom


func _process(delta: float) -> void:
	if _cam == null:
		return
	if not is_instance_valid(_target):
		_target = _resolve_target()
	if _target == null:
		return
	_zoom = lerpf(_zoom, _zoom_target, 1.0 - exp(-ZOOM_BLEND_PER_SEC * delta))
	if fps_mode:
		_tick_fps(delta)
	else:
		_tick_third(delta)

func _tick_fps(delta: float) -> void:
	var tp: Vector3 = _target.global_position
	var eye_y := fps_eye_height
	var reduce_motion: bool = _calm()
	_track_landing(delta)
	if _running and not reduce_motion:
		_bob_t += delta * SPRINT_BOB_FREQ
		eye_y += sin(_bob_t) * SPRINT_BOB_AMP
	else:
		_bob_t = 0.0
	if not reduce_motion:
		_breath_t += delta * BREATH_RAD_PER_SEC
		eye_y += sin(_breath_t) * BREATH_M - LAND_DIP_M * _land_kick
	var desired: Vector3 = tp + Vector3(0.0, eye_y, 0.0)
	_cam.global_position = _cam.global_position.lerp(desired, clampf(delta * fps_follow_speed, 0.0, 1.0))
	var yaw: float = _target.rotation.y
	_cam.rotation = Vector3(_pitch + _recoil.x, yaw + _recoil.y, 0.0)
	_recoil = _recoil.lerp(Vector2.ZERO, clampf(delta * RECOIL_SETTLE_PER_SEC, 0.0, 1.0))
	_cam.fov = lerpf(_cam.fov, fov_target(), clampf(delta * interior_lerp_speed, 0.0, 1.0))
	_tick_interior_target(delta)

## The view the first-person camera eases toward: the zoom, the sprint punch and the landing punch (none with Reduce UI Motion or Motion Comfort).
func fov_target() -> float:
	var punch: float = 0.0 if _calm() else (SPRINT_FOV_BONUS if _running else 0.0) + LAND_FOV_PUNCH * _land_kick
	return _current_fov / _zoom + punch

func kick(amount: float) -> void:
	if not _calm():
		_recoil += Vector2(RECOIL_PITCH_RAD * amount, randf_range(-1.0, 1.0) * RECOIL_YAW_RAD * amount)

func _calm() -> bool:
	return bool(SettingsManager.get_setting("reduce_ui_motion", false)) or bool(SettingsManager.get_setting("reduce_camera_motion", false))

func _track_landing(delta: float) -> void:
	var grounded: bool = _target.is_on_floor()
	if grounded and not _was_grounded and _air_sec >= LAND_MIN_AIR_SEC:
		_land_kick = 1.0
	_air_sec = 0.0 if grounded else _air_sec + delta
	_was_grounded = grounded
	_land_kick = move_toward(_land_kick, 0.0, delta / LAND_SEC)

func _tick_third(delta: float) -> void:
	_tick_interior(delta)
	var tp: Vector3 = _target.global_position
	var desired: Vector3 = tp + Vector3(0.0, _current_height, _current_distance) / _zoom
	_cam.global_position = _cam.global_position.lerp(desired, clampf(delta * follow_speed, 0.0, 1.0))
	_cam.look_at(tp + Vector3(0.0, look_height_offset, 0.0), Vector3.UP)
	_cam.fov = lerpf(_cam.fov, _current_fov, clampf(delta * interior_lerp_speed, 0.0, 1.0))

func _tick_interior(delta: float) -> void:
	var in_interior: bool = false
	if _target and is_instance_valid(_target):
		var zones := get_tree().get_nodes_in_group("interior_zone")
		for z in zones:
			if z is Area3D and _target in z.get_overlapping_bodies():
				in_interior = true
				break
	_apply_interior(in_interior, delta)

func _tick_interior_target(delta: float) -> void:
	var in_interior: bool = false
	if _target and is_instance_valid(_target):
		var zones := get_tree().get_nodes_in_group("interior_zone")
		for z in zones:
			if z is Area3D and _target in z.get_overlapping_bodies():
				in_interior = true
				break
	_apply_interior(in_interior, delta)

func _apply_interior(in_interior: bool, delta: float) -> void:
	if in_interior and not _is_interior:
		_is_interior = true

	elif not in_interior and _is_interior:
		_is_interior = false

	var target_h := interior_height if _is_interior else height
	var target_d := interior_distance if _is_interior else distance
	var target_f := interior_fov if _is_interior else fov_deg
	var blend := 1.0 - exp(-INTERIOR_BLEND_PER_SEC * delta)
	_current_height = lerpf(_current_height, target_h, blend)
	_current_distance = lerpf(_current_distance, target_d, blend)
	_current_fov = lerpf(_current_fov, target_f, blend)

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
