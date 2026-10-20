extends RefCounted
## The motion of the drawn weapon in the camera's frame (WORKQUEUE A8): it trails the view by LAG_SEC, kicks back for KICK_SEC after a shot and dips and tilts while it reloads.
## All of it is off with Motion Comfort and Reduce UI Motion, the two settings that stop the camera's own motion (camera_follow_3d.gd _calm). It moves the model only: a shot is cast from the camera.

const LAG_SEC: float = 0.06
const LAG_MAX_RAD: float = 0.12
const KICK_BACK_M: float = 0.04
const KICK_PITCH_RAD: float = 0.07
const KICK_SEC: float = 0.05
const RELOAD_DIP_M: float = 0.12
const RELOAD_TILT_RAD: float = 0.45
const RELOAD_PITCH_RAD: float = 0.3
const RELOAD_BLEND_PER_SEC: float = 9.0

var _lag: Basis = Basis()
var _lag_ready: bool = false
var _kick: float = 0.0
var _reload: float = 0.0

## A shot; strength is the weapon's recoil (0.5 for a pistol), and from 0.5 up the kick is the whole of it.
func kick(strength: float) -> void:
	_kick = clampf(strength * 2.0, 0.3, 1.0)

## The extra transform of the weapon, in its own frame, for this frame.
func offset(delta: float, cam_basis: Basis, reloading: bool) -> Transform3D:
	if bool(SettingsManager.get_setting("reduce_ui_motion", false)) or bool(SettingsManager.get_setting("reduce_camera_motion", false)):
		_lag_ready = false
		_kick = 0.0
		_reload = 0.0
		return Transform3D.IDENTITY
	if not _lag_ready:
		_lag = cam_basis
		_lag_ready = true
	_lag = _lag.slerp(cam_basis, 1.0 - exp(-delta / LAG_SEC))
	var trail := Quaternion(cam_basis.inverse() * _lag)
	if trail.get_angle() > LAG_MAX_RAD:
		trail = Quaternion(trail.get_axis(), LAG_MAX_RAD)
	_kick = move_toward(_kick, 0.0, delta / KICK_SEC)
	_reload = move_toward(_reload, 1.0 if reloading else 0.0, delta * RELOAD_BLEND_PER_SEC)
	var tilt := Basis(Vector3.RIGHT, KICK_PITCH_RAD * _kick - RELOAD_PITCH_RAD * _reload) * Basis(Vector3.BACK, RELOAD_TILT_RAD * _reload)
	return Transform3D(Basis(trail) * tilt, Vector3(0.0, -RELOAD_DIP_M * _reload, KICK_BACK_M * _kick))
