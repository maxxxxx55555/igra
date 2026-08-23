extends Node
## Shared UI-sound helper. Prefers the real assets/audio/sfx/ui_*.wav files
## from the art pass; falls back to a procedural beep if a file is missing
## (keeps this autoload usable even on a fresh/partial asset checkout).
##
## click()/hover() are wired explicitly from a couple of existing button
## helpers (main_menu.gd, pause_menu.gd). error()/save()/achievement() need
## no per-caller wiring at all — they listen on EventBus signals that
## already fire at the right moments project-wide.

const _DIR: String = "res://assets/audio/sfx/"

func _ready() -> void:
	EventBus.achievement_unlocked.connect(func(_id: String) -> void: achievement())
	EventBus.inventory_notice.connect(func(_msg: String) -> void: error())
	EventBus.purchase_failed.connect(func(_item_id: String, _reason: String) -> void: error())
	EventBus.game_saved.connect(func() -> void: save())

func click() -> void:
	_play("ui_click", 800.0, 0.05)

func hover() -> void:
	_play("ui_hover", 1000.0, 0.03)

func error() -> void:
	_play("ui_error", 260.0, 0.12)

func save() -> void:
	_play("ui_save", 950.0, 0.08)

func achievement() -> void:
	_play("ui_achievement", 1400.0, 0.15)

func pickup() -> void:
	_beep(1200.0, 0.09)

func _play(file: String, fallback_freq: float, fallback_dur: float) -> void:
	var path := _DIR + file + ".wav"
	if ResourceLoader.exists(path):
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		p.stream = load(path)
		add_child(p)
		p.play()
		p.finished.connect(p.queue_free)
	else:
		_beep(fallback_freq, fallback_dur)

func _beep(freq: float, dur: float) -> void:
	var sr := 22050
	var n := int(sr * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / sr
		var env := 1.0 - t / dur
		var v := int(sin(t * freq * TAU) * env * 12000.0)
		data.encode_s16(i * 2, v)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sr
	stream.data = data
	var p := AudioStreamPlayer.new()
	p.bus = &"SFX"
	p.stream = stream
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
