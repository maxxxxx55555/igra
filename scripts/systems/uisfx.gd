extends Node

func click() -> void:
	_beep(800.0, 0.05)

func pickup() -> void:
	_beep(1200.0, 0.09)

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