extends Node
## Dynamic resolution (Settings > Graphics, docs/PERF_PASS.md): when the frame rate stays under LOW_FPS for LOW_SEC the 3D scale drops to DROP_SCALE of the
## player's Render Scale; once it stays over HIGH_FPS for HIGH_SEC it goes back. In between nothing moves (a band, so it does not flap). On by default on a
## phone, off on a desktop. The screen's text and the HUD are 2D and are not scaled. A child of SettingsManager.
## Low and Medium cap the frame rate at 30, which reads 29.x at best: both limits are no higher than CAP_SHARE of the cap (CORRECTION_LOG 244, as in the quality
## manager's), and each return doubles the wait for the next, so a phone that holds 27 FPS only at the lower scale does not flip every 6 s.

const LOW_FPS: float = 30.0
const HIGH_FPS: float = 45.0
const LOW_SEC: float = 2.0
const HIGH_SEC: float = 4.0
const DROP_SCALE: float = 0.7
const SAMPLE_SEC: float = 0.5
const CAP_SHARE: float = 0.9

var dropped: bool = false
var _since_sample: float = 0.0
var _low_for: float = 0.0
var _high_for: float = 0.0
var _high_after: float = HIGH_SEC

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	_since_sample += delta
	if _since_sample < SAMPLE_SEC:
		return
	var elapsed: float = _since_sample
	_since_sample = 0.0
	if not bool(SettingsManager.get_setting("dynamic_resolution", false)) or not GameManager.is_playing():
		_low_for = 0.0
		_high_for = 0.0
		if dropped:
			_apply(false)
		return
	step(Engine.get_frames_per_second(), elapsed)

## One reading of the frame rate over `seconds`: the drop and the recovery.
func step(fps: float, seconds: float) -> void:
	var limit: float = float(Engine.max_fps) * CAP_SHARE
	if fps < minf(LOW_FPS, limit):
		_low_for += seconds
		_high_for = 0.0
	elif fps > minf(HIGH_FPS, limit):
		_high_for += seconds
		_low_for = 0.0
	else:
		_low_for = 0.0
		_high_for = 0.0
	if not dropped and _low_for >= LOW_SEC:
		_apply(true)
	elif dropped and _high_for >= _high_after:
		_high_after *= 2.0
		_apply(false)

func _apply(drop: bool) -> void:
	dropped = drop
	_low_for = 0.0
	_high_for = 0.0
	var base: float = float(SettingsManager.get_setting("render_scale", 1.0))
	get_viewport().scaling_3d_scale = base * (DROP_SCALE if drop else 1.0)
