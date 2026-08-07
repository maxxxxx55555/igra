extends Node

@export var fade_duration: float = 1.5

var _active: AudioStreamPlayer = null
var _fading: AudioStreamPlayer = null

func _ready() -> void:
	_ensure_buses()
	if not DistrictThemes.theme_changed.is_connected(_on_theme):
		DistrictThemes.theme_changed.connect(_on_theme)
	_on_theme(DistrictThemes.current_id)

func _ensure_buses() -> void:
	for n in ["Music", "Ambient", "SFX"]:
		var idx: int = AudioServer.get_bus_index(n)
		if idx < 0:
			AudioServer.add_bus()
			idx = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, n)
		if n == "Ambient":
			AudioServer.set_bus_volume_db(idx, -6.0)
		elif n == "SFX":
			AudioServer.set_bus_volume_db(idx, -3.0)

func _on_theme(district_id: StringName) -> void:
	_crossfade_to(district_id)

func _crossfade_to(district_id: StringName) -> void:
	var id: String = String(district_id)
	var candidates: PackedStringArray = PackedStringArray([
		"res://assets/audio/music/music_%s.wav" % id,
		"res://assets/audio/music/%s.wav" % id,
		"res://audio/music/%s.wav" % id,
	])
	var path: String = ""
	for c in candidates:
		if ResourceLoader.exists(c):
			path = c
			break
	if path == "":
		return
	var stream: AudioStream = load(path)
	if _active != null and _active.stream == stream:
		return
	var next := AudioStreamPlayer.new()
	next.bus = &"Music"
	next.stream = stream
	add_child(next)
	next.volume_db = -60.0
	next.play()
	_fading = _active
	_active = next
	var tw := create_tween()
	tw.tween_property(next, "volume_db", 0.0, fade_duration)
	if _fading != null:
		tw.parallel().tween_property(_fading, "volume_db", -60.0, fade_duration)
	tw.tween_callback(_cleanup_fading)

func _cleanup_fading() -> void:
	if _fading != null:
		_fading.queue_free()
		_fading = null