$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-Utf8([string]$rel, [string]$content) {
	$full = Join-Path $root $rel
	$dir = Split-Path -Parent $full
	if (-not (Test-Path $dir)) { [void](New-Item -ItemType Directory -Force -Path $dir) }
	[System.IO.File]::WriteAllText($full, $content, $utf8)
	Write-Host ('WROTE    ' + $rel)
}

function Add-Autoload([string]$name, [string]$path) {
	$gf = Join-Path $root 'project.godot'
	$text = [System.IO.File]::ReadAllText($gf, $utf8)
	if ($text -match ('^' + [regex]::Escape($name) + '=')) { Write-Host ('AUTOLOAD ' + $name + ' (exists)'); return }
	$entry = $name + '="*' + $path + '"' + [Environment]::NewLine
	if ($text -match '\[autoload\]\s*\r?\n') {
		$newText = [regex]::Replace($text, '(\[autoload\]\s*\r?\n)', ('$1' + $entry), 1)
		[System.IO.File]::WriteAllText($gf, $newText, $utf8)
	} else {
		[System.IO.File]::AppendAllText($gf, [Environment]::NewLine + '[autoload]' + [Environment]::NewLine + $entry, $utf8)
	}
	Write-Host ('AUTOLOAD ' + $name)
}

# ===== UISFX (новый autoload с бипами) =====
@'
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
'@ | Write-Utf8 'scripts/systems/uisfx.gd' -ErrorAction SilentlyContinue
# Write-Utf8 принимает 2 параметра; используем прямой вызов:
[System.IO.File]::WriteAllText((Join-Path $root 'scripts\systems\uisfx.gd'), (@'
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
'@), $utf8)
Write-Host 'WROTE    scripts/systems/uisfx.gd'

# ===== music_manager (фикс bus_get_names) =====
$mm = Get-Content scripts\audio\music_manager.gd -Raw
$mm = $mm.Replace('AudioServer.bus_get_names()', 'AudioServer.get_bus_names()')
[System.IO.File]::WriteAllText((Join-Path $root 'scripts\audio\music_manager.gd'), $mm, $utf8)
Write-Host 'FIXED    music_manager.gd'

# ===== world_bootstrap (load() вместо class_name) =====
[System.IO.File]::WriteAllText((Join-Path $root 'scripts\world\world_bootstrap.gd'), (@'
extends Node

func _ready() -> void:
	call_deferred("_wire_all")

func _wire_all() -> void:
	var districts: Array[Node] = []
	for d in get_tree().get_nodes_in_group(&"district"):
		districts.append(d)
	var root: Node = get_tree().current_scene
	if root != null:
		_collect(root, districts)
	for d in districts:
		_wire(d)

func _collect(n: Node, out: Array[Node]) -> void:
	if n.is_in_group(&"district") or String(n.name).begins_with("district_"):
		if not out.has(n):
			out.append(n)
	for c in n.get_children():
		_collect(c, out)

func _wire(d: Node) -> void:
	var sb: Node = _find(d, &"StreetBuilder")
	if sb == null:
		return
	if _find(d, &"Props") == null:
		var ps: Script = load("res://scripts/world/street_props.gd")
		var props: Node = ps.new()
		props.name = "Props"
		props.set("street_builder_path", sb.get_path())
		d.add_child(props)
	if _find(d, &"Windows") == null:
		var ws: Script = load("res://scripts/world/emissive_windows.gd")
		var win: Node = ws.new()
		win.name = "Windows"
		d.add_child(win)
	if _find(d, &"Grading") == null:
		var gs: Script = load("res://scripts/world/district_grading.gd")
		var grading: Node = gs.new()
		grading.name = "Grading"
		grading.set("district_root_path", d.get_path())
		d.add_child(grading)

func _find(n: Node, nm: StringName) -> Node:
	for c in n.get_children():
		if c.name == nm:
			return c
	return null
'@), $utf8)
Write-Host 'FIXED    world_bootstrap.gd'

# ===== autoloads =====
Add-Autoload 'LightGrid' 'res://scripts/lighting/light_grid.gd'
Add-Autoload 'UISFX' 'res://scripts/systems/uisfx.gd'
Add-Autoload 'WorldBootstrap' 'res://scripts/world/world_bootstrap.gd'

# ===== гейт + пуш =====
$godot = "C:\Users\Maxsim\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
& $godot --headless --path . res://scenes/tools/compile_scene.tscn 2>&1 | Select-String "BAD|FAILED" | Select-Object -Last 3
git add -A
git commit -m "part5: autoloads + uisfx + api fixes"
git push
Write-Host "PART5 DONE" -ForegroundColor Green