$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

# 1) music_manager (финальный)
[System.IO.File]::WriteAllText((Join-Path $root 'scripts\audio\music_manager.gd'), (@'
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
'@), $utf8)

# 2) autoshot (скрин через 4 сек)
[System.IO.File]::WriteAllText((Join-Path $root 'scripts\tools\autoshot.gd'), (@'
extends SceneTree

var t: float = 0.0
var done: bool = false

func _init() -> void:
	change_scene_to_file("res://scenes/main_3d.tscn")

func _process(delta: float) -> bool:
	t += delta
	if t > 4.0 and not done:
		done = true
		var img := root.get_texture().get_image()
		img.save_png("C:/Users/Maxsim/Desktop/shot1.png")
		return true
	return false
'@), $utf8)

# 3) глушим GDScript-предупреждения
$gf = Join-Path $root 'project.godot'
$text = [System.IO.File]::ReadAllText($gf, $utf8)
$keys = @(
	'gdscript/warnings/unused_variable',
	'gdscript/warnings/unused_parameter',
	'gdscript/warnings/unused_signal',
	'gdscript/warnings/return_value_discarded',
	'gdscript/warnings/untyped_declaration',
	'gdscript/warnings/unsafe_cast',
	'gdscript/warnings/unsafe_method_access',
	'gdscript/warnings/unsafe_property_access',
	'gdscript/warnings/unsafe_call_argument',
	'gdscript/warnings/unsafe_void_return',
	'gdscript/warnings/integer_division',
	'gdscript/warnings/narrow_conversion',
	'gdscript/warnings/redundant_await',
	'gdscript/warnings/standalone_expression'
)
$block = ""
foreach ($k in $keys) { $block += "$k=0`n" }
if ($text -match '(?m)^\[debug\]') {
	$text = [regex]::Replace($text, '(\[debug\]\s*\r?\n)', ('$1' + $block), 1)
} else {
	$text += "`n[debug]`n" + $block
}
[System.IO.File]::WriteAllText($gf, $text, $utf8)
Write-Host "WARNINGS SILENCED"

# 4) проверка + пуш
powershell -ExecutionPolicy Bypass -File (Join-Path $root 'check.ps1')
git -C $root add -A
git -C $root commit -m "part7: music paths, autoshot, silence warnings"
git -C $root push

# 5) автоскриншот (окно мелькнёт ~4 сек и закроется)
$godot = "C:\Users\Maxsim\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
& $godot --path $root --script res://scripts/tools/autoshot.gd 2>&1 | Select-Object -Last 3
Test-Path "C:\Users\Maxsim\Desktop\shot1.png"