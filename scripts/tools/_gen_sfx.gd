extends Node
## GDD S9.2/S9.3 SFX generator: per-surface footsteps + monster audio cues.
## 22050 Hz mono 16-bit WAV to assets/audio/sfx/.
## Run: godot --headless --path <proj> res://scenes/tools/gen_sfx_scene.tscn

const MIX: int = 22050
const OUT: String = "res://assets/audio/sfx/"

var _buf: PackedFloat32Array
var _len: int
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 20260804
	var made: int = 0
	# S9.2 footsteps: material = impact transient + resonance + noise burst
	made += _step("step_asphalt_dry", 0.12, 180.0, 0.55, 1400.0, 0.030, 0.85)
	made += _step("step_asphalt_wet", 0.14, 150.0, 0.45, 900.0, 0.045, 0.70)
	made += _step("step_concrete", 0.10, 240.0, 0.60, 2000.0, 0.025, 0.90)
	made += _step("step_wood", 0.16, 320.0, 0.75, 1100.0, 0.035, 0.65)
	made += _step("step_metal", 0.34, 660.0, 0.95, 3200.0, 0.020, 1.00)
	made += _step("step_puddle", 0.20, 90.0, 0.30, 600.0, 0.090, 0.55)
	made += _step("step_glass", 0.26, 1150.0, 0.85, 5200.0, 0.055, 0.80)
	made += _step_gravel()
	made += _step_dirt()
	made += _clank()
	# ambience loops
	made += _lamp_hum()
	made += _wind_ambient()
	# equipment
	made += _flashlight_on()
	made += _flashlight_off()
	# S9.3 monster cues
	made += _shadow_teleport()
	made += _crawler_scratch()
	made += _watcher_breath()
	made += _watcher_scream()
	made += _hunter_roar()
	made += _destroyer_hum()
	print("[sfx] DONE generated=", made)
	get_tree().quit()

# ---------------- framework ----------------

func _new(dur: float) -> void:
	_len = int(dur * MIX)
	_buf = PackedFloat32Array()
	_buf.resize(_len)
	_buf.fill(0.0)

func _add(i: int, v: float) -> void:
	if i >= 0 and i < _len:
		_buf[i] += v

## Damped sine — impact resonance body.
func _tone(t0: float, freq: float, amp: float, decay: float, attack: float = 0.002) -> void:
	var start: int = int(t0 * MIX)
	var n: int = int(decay * 4.0 * MIX)
	var ph: float = 0.0
	var step: float = TAU * freq / float(MIX)
	for i in n:
		var t: float = float(i) / float(MIX)
		var env: float = exp(-t / decay) * minf(t / maxf(attack, 0.0001), 1.0)
		_add(start + i, sin(ph) * amp * env)
		ph += step

## Low-passed noise burst — surface grit / breath / scratch.
func _noise(t0: float, dur: float, amp: float, cut_hz: float, decay: float, attack: float = 0.001) -> void:
	var start: int = int(t0 * MIX)
	var n: int = int(dur * MIX)
	var a: float = clampf(TAU * cut_hz / float(MIX), 0.0, 1.0)
	var lp: float = 0.0
	for i in n:
		var t: float = float(i) / float(MIX)
		lp += a * (_rng.randf_range(-1.0, 1.0) - lp)
		var env: float = exp(-t / maxf(decay, 0.0001)) * minf(t / maxf(attack, 0.0001), 1.0)
		_add(start + i, lp * amp * env)

## Pitch-swept sine — teleport zap, roar, riser.
func _sweep(t0: float, dur: float, f0: float, f1: float, amp: float, curve: float = 1.0) -> void:
	var start: int = int(t0 * MIX)
	var n: int = int(dur * MIX)
	var ph: float = 0.0
	for i in n:
		var t: float = float(i) / float(MIX)
		var k: float = pow(clampf(t / dur, 0.0, 1.0), curve)
		ph += TAU * (f0 + (f1 - f0) * k) / float(MIX)
		_add(start + i, sin(ph) * amp * sin(PI * clampf(t / dur, 0.0, 1.0)))

## Saw stack — mechanical hum, growl body.
func _saw(t0: float, freq: float, amp: float, dur: float, decay: float, harm: int = 6) -> void:
	var start: int = int(t0 * MIX)
	var n: int = int(dur * MIX)
	for h in range(1, harm + 1):
		var f: float = freq * float(h)
		if f > float(MIX) * 0.45:
			break
		var w: float = 1.0 / float(h)
		var ph: float = 0.0
		var step: float = TAU * f / float(MIX)
		for i in n:
			var t: float = float(i) / float(MIX)
			var env: float = exp(-t / decay) * minf(t / 0.008, 1.0)
			_add(start + i, sin(ph) * amp * w * env)
			ph += step

## Band-passed noise — LP at hi_hz with a low-cut at lo_hz. Wind, air, hiss beds.
func _noise_bp(t0: float, dur: float, amp: float, lo_hz: float, hi_hz: float,
		decay: float, attack: float = 0.001) -> void:
	var start: int = int(t0 * MIX)
	var n: int = int(dur * MIX)
	var ah: float = clampf(TAU * hi_hz / float(MIX), 0.0, 1.0)
	var al: float = clampf(TAU * lo_hz / float(MIX), 0.0, 1.0)
	var hi: float = 0.0
	var lo: float = 0.0
	for i in n:
		var t: float = float(i) / float(MIX)
		hi += ah * (_rng.randf_range(-1.0, 1.0) - hi)
		lo += al * (hi - lo)
		var env: float = exp(-t / maxf(decay, 0.0001)) * minf(t / maxf(attack, 0.0001), 1.0)
		_add(start + i, (hi - lo) * amp * env)

## Periodic amplitude wobble — `cycles` whole periods over the buffer, so a
## looped file stays seamless. Call AFTER _loop_fade(), before _save().
func _wobble(cycles: int, depth: float) -> void:
	if _len <= 0 or cycles <= 0:
		return
	for i in _len:
		var k: float = TAU * float(cycles) * float(i) / float(_len)
		_buf[i] *= 1.0 - depth + depth * (0.5 + 0.5 * sin(k))

func _loop_fade(fade: float) -> void:
	var n: int = int(fade * MIX)
	if n <= 0 or n * 2 >= _len:
		return
	for i in n:
		var k: float = float(i) / float(n)
		_buf[i] = _buf[i] * k + _buf[_len - n + i] * (1.0 - k)
	_len -= n
	_buf.resize(_len)

func _save(base: String, loop: bool = false) -> int:
	var peak: float = 0.0
	for i in _len:
		peak = maxf(peak, absf(_buf[i]))
	var norm: float = 0.88 / maxf(peak, 0.0001)
	var data := PackedByteArray()
	data.resize(_len * 2)
	for i in _len:
		var v: float = _buf[i] * norm
		v = v / (1.0 + absf(v) * 0.22)
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = MIX
	s.stereo = false
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = _len
	var path: String = OUT + base + ".wav"
	var err := s.save_to_wav(path)
	print("[sfx] ", "ok  " if err == OK else "FAIL", path)
	return 1 if err == OK else 0

# ---------------- footsteps ----------------

## One step: low thump (body) + resonant ring (material) + grit noise.
func _step(base: String, dur: float, res_hz: float, ring: float,
		grit_hz: float, grit_decay: float, thump: float) -> int:
	_new(dur)
	_tone(0.0, 55.0, 0.55 * thump, dur * 0.20, 0.001)
	_tone(0.0, res_hz, 0.40 * ring, dur * 0.35, 0.0015)
	_tone(0.0, res_hz * 1.48, 0.18 * ring, dur * 0.22, 0.002)
	_noise(0.0, dur, 0.45, grit_hz, grit_decay, 0.0008)
	return _save(base)

## Metallic clank for heavy loads (>35 kg, every 4th step).
func _clank() -> int:
	_new(0.42)
	_tone(0.0, 430.0, 0.42, 0.14, 0.001)
	_tone(0.0, 1180.0, 0.30, 0.10, 0.001)
	_tone(0.0, 2340.0, 0.16, 0.06, 0.001)
	_noise(0.0, 0.42, 0.35, 4200.0, 0.045, 0.0006)
	return _save("step_clank")

## Gravel: many hard grains on top of the thump, bright crunch, almost no ring.
func _step_gravel() -> int:
	_new(0.18)
	_tone(0.0, 52.0, 0.40, 0.022, 0.001)
	_noise(0.0, 0.18, 0.50, 3600.0, 0.030, 0.0006)
	for k in 7:
		var t: float = float(k) * 0.016 + _rng.randf_range(0.0, 0.006)
		_noise(t, 0.05, 0.26, 5200.0 + float(k) * 340.0, 0.007, 0.0004)
		_tone(t, 900.0 + float(k) * 180.0, 0.06, 0.008, 0.0006)
	return _save("step_gravel")

## Dirt: damped thud, low grit, no material ring.
func _step_dirt() -> int:
	_new(0.15)
	_tone(0.0, 48.0, 0.55, 0.030, 0.0015)
	_tone(0.0, 110.0, 0.20, 0.020, 0.002)
	_noise(0.0, 0.15, 0.38, 700.0, 0.026, 0.0012)
	_noise(0.010, 0.08, 0.14, 1600.0, 0.018, 0.003)
	return _save("step_dirt")

# ---------------- ambience loops ----------------

## Streetlight ballast hum: 50/100 Hz bed + faint 150 Hz + noise floor (loopable).
## 3.0 s minus a 0.20 s crossfade = 2.8 s, a whole number of 50 Hz periods,
## so the head/tail blend stays phase-coherent.
func _lamp_hum() -> int:
	_new(3.0)
	_saw(0.0, 50.0, 0.12, 3.0, 400.0, 2)     # 50 Hz + 100 Hz partial
	_saw(0.0, 100.0, 0.05, 3.0, 400.0, 1)    # 100 Hz body
	_saw(0.0, 150.0, 0.022, 3.0, 400.0, 1)   # faint 3rd
	_noise(0.0, 3.0, 0.030, 260.0, 400.0, 0.0008)
	_loop_fade(0.20)
	_wobble(4, 0.10)                          # slight ~0.7 s amplitude wobble
	return _save("amb_lamp_hum", true)

## Wind: low-cut noise bed with slow gusts (loopable).
## Two coprime wobbles (~1.9 s and ~1.4 s) give an irregular but periodic gust.
func _wind_ambient() -> int:
	_new(6.0)
	_noise_bp(0.0, 6.0, 0.18, 120.0, 3200.0, 600.0, 0.0008)
	_noise_bp(0.0, 6.0, 0.10, 300.0, 6000.0, 600.0, 0.0008)
	_noise(0.0, 6.0, 0.05, 180.0, 600.0, 0.0008)
	_loop_fade(0.30)
	_wobble(3, 0.55)
	_wobble(4, 0.25)
	return _save("amb_wind", true)

# ---------------- equipment ----------------

## Flashlight on: switch snap + short high tick.
func _flashlight_on() -> int:
	_new(0.12)
	_noise(0.0, 0.05, 0.55, 8000.0, 0.006, 0.0003)     # snap
	_tone(0.0, 2400.0, 0.30, 0.010, 0.0004)            # tick
	_tone(0.0, 5200.0, 0.16, 0.005, 0.0003)
	_tone(0.003, 420.0, 0.18, 0.020, 0.0008)           # housing
	_noise(0.045, 0.06, 0.14, 5000.0, 0.012, 0.0006)   # detent release
	return _save("sfx_flashlight_on")

## Flashlight off: same mechanism, duller and lower.
func _flashlight_off() -> int:
	_new(0.10)
	_noise(0.0, 0.05, 0.50, 4200.0, 0.008, 0.0004)
	_tone(0.0, 1500.0, 0.26, 0.012, 0.0006)
	_tone(0.0, 3100.0, 0.10, 0.006, 0.0004)
	_tone(0.004, 300.0, 0.20, 0.026, 0.0010)
	_noise(0.040, 0.05, 0.10, 2600.0, 0.014, 0.0008)
	return _save("sfx_flashlight_off")

# ---------------- monster cues (S9.3) ----------------

## Shadow: no footsteps. Teleport = electric snap.
func _shadow_teleport() -> int:
	_new(0.30)
	_sweep(0.0, 0.09, 2600.0, 340.0, 0.55, 0.55)
	_noise(0.0, 0.30, 0.45, 7000.0, 0.030, 0.0004)
	_tone(0.0, 130.0, 0.28, 0.10, 0.001)
	_tone(0.02, 1900.0, 0.18, 0.05, 0.001)
	return _save("mon_shadow_teleport")

## Crawler: scraping on asphalt, audible at 10 m.
func _crawler_scratch() -> int:
	_new(0.55)
	for k in 5:
		var t: float = float(k) * 0.10
		_noise(t, 0.13, 0.40, 3400.0 + float(k) * 260.0, 0.038, 0.004)
		_tone(t, 240.0 + float(k) * 30.0, 0.12, 0.05, 0.003)
	_noise(0.0, 0.55, 0.14, 900.0, 0.28, 0.020)
	return _save("mon_crawler_scratch")

## Watcher: heavy breathing at 5 m (loopable).
func _watcher_breath() -> int:
	_new(2.60)
	_noise(0.05, 0.70, 0.42, 620.0, 0.90, 0.180)   # inhale
	_noise(0.95, 0.85, 0.34, 380.0, 1.10, 0.120)   # exhale
	_noise(2.00, 0.55, 0.20, 500.0, 0.70, 0.150)
	_tone(0.10, 78.0, 0.10, 0.60, 0.120)
	_tone(1.05, 62.0, 0.09, 0.70, 0.100)
	_loop_fade(0.25)
	return _save("mon_watcher_breath", true)

## Watcher: scream = global AoE cue.
func _watcher_scream() -> int:
	_new(1.30)
	_sweep(0.0, 0.85, 320.0, 1450.0, 0.50, 0.70)
	_sweep(0.05, 0.80, 470.0, 2100.0, 0.28, 0.80)
	_noise(0.0, 1.30, 0.34, 5200.0, 0.42, 0.030)
	_saw(0.0, 190.0, 0.16, 0.95, 0.38, 7)
	_tone(0.60, 96.0, 0.22, 0.45, 0.010)
	return _save("mon_watcher_scream")

## Hunter: roar before charge.
func _hunter_roar() -> int:
	_new(1.10)
	_saw(0.0, 84.0, 0.34, 0.95, 0.42, 8)
	_saw(0.03, 126.0, 0.20, 0.85, 0.34, 6)
	_sweep(0.0, 0.75, 150.0, 74.0, 0.30, 0.60)
	_noise(0.0, 1.10, 0.26, 1700.0, 0.38, 0.025)
	_tone(0.0, 48.0, 0.30, 0.50, 0.008)
	return _save("mon_hunter_roar")

## Destroyer: machinery hum, audible at 12 m (loopable).
func _destroyer_hum() -> int:
	_new(2.20)
	_saw(0.0, 46.0, 0.26, 2.20, 6.0, 7)
	_saw(0.0, 69.0, 0.14, 2.20, 6.0, 5)
	_noise(0.0, 2.20, 0.16, 340.0, 6.0, 0.200)
	for k in 8:
		_tone(float(k) * 0.275, 520.0, 0.07, 0.05, 0.002)   # rhythmic tick
	_loop_fade(0.20)
	return _save("mon_destroyer_hum", true)
