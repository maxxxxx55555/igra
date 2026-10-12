extends Node
## Dynamic resolution (Settings > Graphics, docs/PERF_PASS.md): when the frame rate stays under LOW_FPS for LOW_SEC the 3D scale drops to DROP_SCALE of the
## player's Render Scale; once it stays over HIGH_FPS for HIGH_SEC it goes back. In between nothing moves (a band, so it does not flap). On by default on a
## phone, off on a desktop. The screen's text and the HUD are 2D and are not scaled. A child of SettingsManager.

const LOW_FPS: float = 30.0
const HIGH_FPS: float = 45.0
const LOW_SEC: float = 2.0
const HIGH_SEC: float = 4.0
const DROP_SCALE: float = 0.7
const SAMPLE_SEC: float = 0.5

var dropped: bool = false
var _since_sample: float = 0.0
var _low_for: float = 0.0
var _high_for: float = 0.0

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
	if fps < LOW_FPS:
		_low_for += seconds
		_high_for = 0.0
	elif fps > HIGH_FPS:
		_high_for += seconds
		_low_for = 0.0
	else:
		_low_for = 0.0
		_high_for = 0.0
	if not dropped and _low_for >= LOW_SEC:
		_apply(true)
	elif dropped and _high_for >= HIGH_SEC:
		_apply(false)

func _apply(drop: bool) -> void:
	dropped = drop
	_low_for = 0.0
	_high_for = 0.0
	var base: float = float(SettingsManager.get_setting("render_scale", 1.0))
	get_viewport().scaling_3d_scale = base * (DROP_SCALE if drop else 1.0)
