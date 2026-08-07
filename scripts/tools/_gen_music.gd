extends Node
## Генератор саундтрека: тёмный индустриальный эмбиент в тональности ля-минор.
## Пишет зацикленные WAV (32 кГц, моно, 16 бит) в assets/audio/music/.
## Запуск: godot --headless --quit-after 3000 --path <proj> res://scenes/tools/gen_music_scene.tscn

const MIX: int = 32000
const OUT: String = "res://assets/audio/music/"

# Ля-минор: тоника, квинта, септима — основа всего саундтрека.
const A1: float = 55.0
const A2: float = 110.0
const C3: float = 130.81
const E2: float = 82.41
const E3: float = 164.81
const G3: float = 196.0
const A3: float = 220.0
const C4: float = 261.63
const D4: float = 293.66
const E4: float = 329.63
const G4: float = 392.0
const A4: float = 440.0
const C5: float = 523.25

var _buf: PackedFloat32Array
var _len: int
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 20260803
	var t0 := Time.get_ticks_msec()
	_build_ambient()
	_build_ambient_dark()
	_build_tension()
	_build_battle()
	_build_boss()
	_build_menu()
	_build_victory()
	print("[music] DONE за ", (Time.get_ticks_msec() - t0) / 1000, " c")
	get_tree().quit()

# ---------------- каркас ----------------

func _new(dur: float) -> void:
	_len = int(dur * MIX)
	_buf = PackedFloat32Array()
	_buf.resize(_len)
	_buf.fill(0.0)

func _add(i: int, v: float) -> void:
	if i >= 0 and i < _len:
		_buf[i] += v

## Непрерывный дрон с медленным «дыханием» громкости.
func _drone(freq: float, amp: float, lfo_period: float = 17.0, lfo_phase: float = 0.0) -> void:
	var ph: float = 0.0
	var step: float = TAU * freq / float(MIX)
	for i in _len:
		var t: float = float(i) / float(MIX)
		var lfo: float = 0.75 + 0.25 * sin(TAU * t / lfo_period + lfo_phase)
		_add(i, sin(ph) * amp * lfo)
		ph += step

## Колокол: основной тон + неармоничные обертоны, экспоненциальный спад.
func _bell(t0: float, freq: float, amp: float, decay: float) -> void:
	var start: int = int(t0 * MIX)
	var n: int = int(decay * 3.0 * MIX)
	var partials := [1.0, 2.76, 5.40, 8.93]
	var weights := [1.0, 0.34, 0.16, 0.07]
	for k in partials.size():
		var f: float = freq * float(partials[k])
		if f > float(MIX) * 0.45:
			continue
		var w: float = float(weights[k])
		var step: float = TAU * f / float(MIX)
		var ph: float = 0.0
		var dk: float = decay / (1.0 + float(k) * 0.6)
		for i in n:
			var t: float = float(i) / float(MIX)
			var env: float = exp(-t / dk) * minf(t / 0.012, 1.0)
			_add(start + i, sin(ph) * amp * w * env)
			ph += step

## Низкий удар с падением высоты (пульс/бочка).
func _kick(t0: float, amp: float, f_start: float = 70.0, f_end: float = 40.0, decay: float = 0.22) -> void:
	var start: int = int(t0 * MIX)
	var n: int = int(decay * 4.0 * MIX)
	var ph: float = 0.0
	for i in n:
		var t: float = float(i) / float(MIX)
		var f: float = f_end + (f_start - f_end) * exp(-t * 14.0)
		ph += TAU * f / float(MIX)
		_add(start + i, sin(ph) * amp * exp(-t / decay))

## Шум через однополюсный фильтр НЧ — ветер, шорох, индустриальный фон.
func _noise(t0: float, dur: float, amp: float, cut_hz: float, env_attack: float = 0.05) -> void:
	var start: int = int(t0 * MIX)
	var n: int = int(dur * MIX)
	var a: float = clampf(TAU * cut_hz / float(MIX), 0.0, 1.0)
	var lp: float = 0.0
	for i in n:
		var t: float = float(i) / float(MIX)
		lp += a * (_rng.randf_range(-1.0, 1.0) - lp)
		var env: float = minf(t / maxf(env_attack, 0.001), 1.0) * minf((dur - t) / maxf(env_attack, 0.001), 1.0)
		_add(start + i, lp * amp * clampf(env, 0.0, 1.0))
	
## Дальний металлический удар: резонансный шумовой всплеск.
func _clang(t0: float, amp: float, res_hz: float, decay: float) -> void:
	var start: int = int(t0 * MIX)
	var n: int = int(decay * 3.0 * MIX)
	var ph: float = 0.0
	var lp: float = 0.0
	var a: float = clampf(TAU * 2200.0 / float(MIX), 0.0, 1.0)
	for i in n:
		var t: float = float(i) / float(MIX)
		lp += a * (_rng.randf_range(-1.0, 1.0) - lp)
		ph += TAU * res_hz / float(MIX)
		var env: float = exp(-t / decay)
		_add(start + i, (sin(ph) * 0.7 + lp * 0.5) * amp * env)

## Пилообразный тон (сумма гармоник) — остинато и «духовые» удары.
func _saw(t0: float, freq: float, amp: float, dur: float, decay: float, harm: int = 5) -> void:
	var start: int = int(t0 * MIX)
	var n: int = int(dur * MIX)
	for h in range(1, harm + 1):
		var f: float = freq * float(h)
		if f > float(MIX) * 0.45:
			break
		var w: float = 1.0 / float(h)
		var step: float = TAU * f / float(MIX)
		var ph: float = 0.0
		for i in n:
			var t: float = float(i) / float(MIX)
			var env: float = exp(-t / decay) * minf(t / 0.006, 1.0)
			_add(start + i, sin(ph) * amp * w * env)
			ph += step

## Восходящий вой — нагнетание.
func _riser(t0: float, dur: float, f0: float, f1: float, amp: float) -> void:
	var start: int = int(t0 * MIX)
	var n: int = int(dur * MIX)
	var ph: float = 0.0
	for i in n:
		var t: float = float(i) / float(MIX)
		var k: float = t / dur
		var f: float = f0 + (f1 - f0) * k * k
		ph += TAU * f / float(MIX)
		var env: float = sin(PI * k)
		_add(start + i, sin(ph) * amp * env)

## Бесшовный луп: хвост подмешивается в начало, затем обрезается.
func _loop_fade(fade: float) -> void:
	var n: int = int(fade * MIX)
	if n <= 0 or n * 2 >= _len:
		return
	for i in n:
		var k: float = float(i) / float(n)
		_buf[i] = _buf[i] * k + _buf[_len - n + i] * (1.0 - k)
	_len -= n
	_buf.resize(_len)

func _save(name_no_ext: String) -> void:
	# нормализация + мягкое ограничение
	var peak: float = 0.0
	for i in _len:
		peak = maxf(peak, absf(_buf[i]))
	var norm: float = 0.82 / maxf(peak, 0.0001)
	var data := PackedByteArray()
	data.resize(_len * 2)
	for i in _len:
		var v: float = _buf[i] * norm
		v = v / (1.0 + absf(v) * 0.28)  # мягкое насыщение
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = MIX
	s.stereo = false
	s.data = data
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = _len
	var path: String = OUT + name_no_ext + ".wav"
	var err := s.save_to_wav(path)
	print("[music] ", "ok  " if err == OK else "FAIL", path, "  ", "%.1f" % (float(_len) / float(MIX)), " c")

# ---------------- треки ----------------

## Исследование: пустой ночной город. Дрон, ветер, редкие колокола и дальний лязг.
func _build_ambient() -> void:
	_new(50.0)
	_drone(A1, 0.20, 19.0, 0.0)
	_drone(A1 * 1.0016, 0.15, 23.0, 1.1)   # биения — «живой» гул
	_drone(E2, 0.11, 17.0, 2.0)
	_drone(A2, 0.085, 29.0, 0.5)
	_drone(E3, 0.040, 31.0, 3.0)
	_noise(0.0, 50.0, 0.055, 420.0, 3.0)
	_noise(6.0, 12.0, 0.030, 900.0, 4.0)
	_noise(28.0, 14.0, 0.028, 700.0, 5.0)
	var bell_t := [5.4, 13.8, 22.3, 30.1, 38.6]
	var bell_f := [A4, C5, E4, G4, C4]
	for i in bell_t.size():
		_bell(float(bell_t[i]), float(bell_f[i]), 0.115, 3.2)
	_clang(9.7, 0.075, 520.0, 1.5)
	_clang(27.4, 0.060, 380.0, 1.8)
	_clang(43.2, 0.055, 640.0, 1.2)
	_kick(0.0, 0.10, 48.0, 36.0, 1.6)
	_kick(16.5, 0.09, 48.0, 36.0, 1.6)
	_kick(33.0, 0.09, 48.0, 36.0, 1.6)
	_loop_fade(2.0)
	_save("music_ambient")

## Эмбиент старого района: ниже, темнее, без мелодии — заброшенность и гниль.
func _build_ambient_dark() -> void:
	_new(46.0)
	_drone(A1 * 0.5, 0.22, 23.0, 0.0)            # суб-океан
	_drone(A1 * 0.5 * 1.0595, 0.10, 19.0, 1.7)   # малая секунда в басу — тревога
	_drone(A1, 0.13, 29.0, 0.8)
	_drone(E2, 0.06, 31.0, 2.4)
	_noise(0.0, 46.0, 0.065, 260.0, 4.0)
	_noise(12.0, 16.0, 0.030, 520.0, 5.0)
	var groan_t := [7.2, 19.6, 33.8]
	for i in groan_t.size():
		_riser(float(groan_t[i]), 3.2, 60.0, 34.0, 0.05)  # нисходящий стон металла
	_clang(15.3, 0.06, 240.0, 2.2)
	_clang(38.9, 0.05, 300.0, 1.9)
	_bell(26.0, A3, 0.07, 4.0)
	_kick(0.0, 0.09, 42.0, 30.0, 1.8)
	_kick(23.0, 0.08, 42.0, 30.0, 1.8)
	_loop_fade(2.0)
	_save("music_ambient_dark")

## Напряжение: рядом монстр. Сердцебиение, диссонансный пад, подъёмы.
func _build_tension() -> void:
	_new(26.0)
	_drone(A1, 0.14, 11.0, 0.0)
	_drone(A3, 0.045, 7.0, 1.0)
	_drone(A3 * 1.0595, 0.038, 9.0, 2.2)   # малая секунда — тревога
	_noise(0.0, 26.0, 0.020, 600.0, 2.0)
	var t: float = 0.0
	while t < 24.0:
		_kick(t, 0.30, 52.0, 40.0, 0.24)
		_kick(t + 0.17, 0.20, 48.0, 38.0, 0.20)
		t += 2.0
	_riser(6.0, 2.6, 180.0, 820.0, 0.055)
	_riser(17.5, 2.6, 160.0, 900.0, 0.055)
	_clang(12.4, 0.05, 700.0, 1.0)
	_loop_fade(1.5)
	_save("music_tension")

## Бой: индустриальное остинато 120 BPM, бочка, металлический малый, аккордные удары.
func _build_battle() -> void:
	_new(26.0)
	var beat: float = 0.5
	var step: float = beat * 0.5
	_drone(A1, 0.10, 8.0, 0.0)
	var i: int = 0
	var t: float = 0.0
	while t < 24.0:
		var f: float = A1 if (i % 4) < 2 else A1 * 1.0595
		_saw(t, f, 0.075, 0.13, 0.055, 5)
		if i % 4 == 0:
			_kick(t, 0.38)
		if i % 8 == 4:
			_noise(t, 0.10, 0.16, 4000.0, 0.002)   # металлический малый
		if i % 2 == 1:
			_noise(t, 0.035, 0.05, 6000.0, 0.001)  # хэт
		if i % 16 == 0:
			_saw(t, A2, 0.055, 0.6, 0.28, 4)
			_saw(t, C3, 0.045, 0.6, 0.28, 4)
			_saw(t, E3, 0.035, 0.6, 0.28, 3)
		t += step
		i += 1
	_riser(20.0, 3.5, 200.0, 1200.0, 0.05)
	_loop_fade(1.5)
	_save("music_battle")

## Босс «Архитектор»: тяжёлый маршевый ритм 84 BPM, тритон, механический лязг.
func _build_boss() -> void:
	_new(32.0)
	var beat: float = 60.0 / 84.0
	_drone(A1 * 0.5, 0.16, 6.0, 0.0)
	_drone(A1, 0.11, 8.0, 1.0)
	_drone(A1 * 1.4142, 0.055, 5.0, 2.0)   # тритон — «дьявольский интервал»
	_noise(0.0, 32.0, 0.030, 300.0, 2.0)
	var bi: int = 0
	var bt: float = 0.0
	while bt < 30.0:
		if bi % 2 == 0:
			_kick(bt, 0.42, 78.0, 38.0, 0.30)
		else:
			_kick(bt, 0.22, 62.0, 34.0, 0.22)
		if bi % 4 == 2:
			_clang(bt, 0.11, 340.0, 0.9)
		if bi % 8 == 0:
			_saw(bt, A2, 0.085, 0.9, 0.34, 6)
			_saw(bt, A2 * 1.4142, 0.050, 0.9, 0.30, 5)
		if bi % 8 == 6:
			_saw(bt, G3, 0.060, 0.5, 0.22, 5)
		bt += beat
		bi += 1
	_bell(15.0, A3, 0.10, 2.6)
	_riser(26.0, 4.0, 120.0, 900.0, 0.06)
	_loop_fade(1.5)
	_save("music_boss_dark")

## Меню: меланхоличная колокольная мелодия над дроном.
func _build_menu() -> void:
	_new(34.0)
	_drone(A1, 0.13, 21.0, 0.0)
	_drone(A2, 0.085, 17.0, 1.4)
	_drone(E3, 0.050, 25.0, 2.6)
	_noise(0.0, 34.0, 0.026, 350.0, 3.0)
	var mel_t := [1.2, 4.6, 8.0, 12.4, 16.0, 20.4, 24.0, 28.2]
	var mel_f := [A4, G4, E4, D4, C4, E4, A3, C4]
	for i in mel_t.size():
		_bell(float(mel_t[i]), float(mel_f[i]), 0.130, 2.9)
	_clang(18.0, 0.045, 460.0, 1.6)
	_loop_fade(2.0)
	_save("music_menu_dark")

## Победа: свет вернулся — тёплый до-мажор, восходящие колокола.
func _build_victory() -> void:
	_new(16.0)
	_drone(C3, 0.13, 9.0, 0.0)
	_drone(G3, 0.095, 11.0, 1.0)
	_drone(C4, 0.060, 13.0, 2.0)
	_drone(E4, 0.045, 15.0, 3.0)
	_noise(0.2, 3.0, 0.05, 2600.0, 1.2)
	_bell(0.5, C4, 0.16, 3.0)
	_bell(1.3, E4, 0.16, 3.0)
	_bell(2.1, G4, 0.16, 3.2)
	_bell(3.0, C5, 0.18, 3.6)
	_bell(7.5, G4, 0.12, 3.0)
	_bell(11.0, C5, 0.12, 3.4)
	_loop_fade(1.5)
	_save("music_victory")
