# publish_fix.ps1
# THE_LAST_STREETLIGHT - cleanup, fix parse errors, create check/publish, push.

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

# ---------- 1. delete debug leftovers ----------
$diagTargets = @(
	@{ Dir = 'scripts/tools'; Filter = '_diag_*.gd' },
	@{ Dir = 'scripts/tools'; Filter = '_diag_*.gd.uid' },
	@{ Dir = 'scenes/tools';  Filter = 'diag_*_scene.tscn' },
	@{ Dir = 'scenes/tools';  Filter = 'diag_*_scene.tscn.uid' },
)
foreach ($t in $diagTargets) {
	$dirFull = Join-Path $root $t.Dir
	if (-not (Test-Path $dirFull)) { continue }
	Get-ChildItem -Path $dirFull -Filter $t.Filter -ErrorAction SilentlyContinue | ForEach-Object {
		Remove-Item $_.FullName -Force
		$rel = $_.FullName.Substring($root.Length + 1)
		Write-Host ('DELETED  ' + $rel)
	}
}

# ---------- 2. rewrite fixed GDScript files ----------
$street_builder = @'
extends Node3D
class_name StreetBuilder

## Procedurally builds the road grid for a district.
## Requires children RoadMM, SidewalkMM, MarkingMM (MultiMeshInstance3D).

signal streets_ready

@export var district_id: StringName = &""
@export var tile_size: float = 4.0
@export var road_width: float = 6.0
@export var sidewalk_width: float = 1.5
@export var lane_mark_spacing: float = 2.0
@export var random_seed: int = 0

var roads: Array[Dictionary] = []

const ROAD_MESH := preload("res://meshes/street/road_tile.tres")
const SIDEWALK_MESH := preload("res://meshes/street/sidewalk_tile.tres")
const MARKING_MESH := preload("res://meshes/street/lane_mark.tres")

@onready var _road_mm: MultiMeshInstance3D = $RoadMM
@onready var _sidewalk_mm: MultiMeshInstance3D = $SidewalkMM
@onready var _marking_mm: MultiMeshInstance3D = $MarkingMM

func _ready() -> void:
	if random_seed == 0:
		random_seed = hash(str(district_id))
	_init_mm(_road_mm, ROAD_MESH)
	_init_mm(_sidewalk_mm, SIDEWALK_MESH)
	_init_mm(_marking_mm, MARKING_MESH)
	call_deferred("build")

func _init_mm(mm: MultiMeshInstance3D, mesh: Mesh) -> void:
	mm.multimesh = MultiMesh.new()
	mm.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mm.multimesh.mesh = mesh

func build() -> void:
	_layout()
	_fill_roads()
	_fill_sidewalks()
	_fill_markings()
	streets_ready.emit()

func _layout() -> void:
	roads.clear()
	var cols: int = 3
	var rows: int = 3
	var spacing: float = 16.0
	if _has_layouts():
		var layout: Dictionary = DistrictLayouts.get(district_id)
		cols = int(layout.get("street_cols", cols))
		rows = int(layout.get("street_rows", rows))
		spacing = float(layout.get("street_spacing", spacing))
	for r in range(rows + 1):
		var h_start: Vector2i = Vector2i(0, r)
		var h_end: Vector2i = Vector2i(cols, r)
		var h_length: float = float(cols) * spacing
		roads.append({"start": h_start, "end": h_end, "dir": "h", "length": h_length})
	for c in range(cols + 1):
		var v_start: Vector2i = Vector2i(c, 0)
		var v_end: Vector2i = Vector2i(c, rows)
		var v_length: float = float(rows) * spacing
		roads.append({"start": v_start, "end": v_end, "dir": "v", "length": v_length})

func _has_layouts() -> bool:
	return get_node_or_null("/root/DistrictLayouts") != null

func road_step_pos(road: Dictionary, step: int) -> Vector3:
	var start: Vector2i = Vector2i(road["start"])
	var end: Vector2i = Vector2i(road["end"])
	var dir: Vector2 = (Vector2(end) - Vector2(start)).normalized()
	var p: Vector2 = Vector2(start) + dir * float(step) * tile_size
	return Vector3(p.x, 0.01, p.y)

func _fill_roads() -> void:
	var total: int = 0
	for r in roads:
		var rl: float = float(r.get("length", 0.0))
		total += int(rl / tile_size) * int(road_width / tile_size)
	_road_mm.multimesh.instance_count = total
	var idx: int = 0
	for r in roads:
		var rl: float = float(r.get("length", 0.0))
		var steps: int = int(rl / tile_size)
		var w: int = int(road_width / tile_size)
		var dir: String = String(r.get("dir", "h"))
		for s in range(steps):
			var pos: Vector3 = road_step_pos(r, s)
			for wi in range(w):
				var off: float = -road_width * 0.5 + float(wi) * tile_size + tile_size * 0.5
				var t: Transform3D = Transform3D()
				t.origin = pos + (Vector3(0.0, 0.0, off) if dir == "h" else Vector3(off, 0.0, 0.0))
				if dir == "v":
					t = t.rotated_local(Vector3.UP, PI * 0.5)
				_road_mm.multimesh.set_instance_transform(idx, t)
				idx += 1

func _fill_sidewalks() -> void:
	var total: int = 0
	for r in roads:
		var rl: float = float(r.get("length", 0.0))
		total += 2 * int(rl / tile_size) * int(sidewalk_width / tile_size)
	_sidewalk_mm.multimesh.instance_count = total
	var idx: int = 0
	for r in roads:
		var rl: float = float(r.get("length", 0.0))
		var steps: int = int(rl / tile_size)
		var w: int = int(sidewalk_width / tile_size)
		var dir: String = String(r.get("dir", "h"))
		for s in range(steps):
			var pos: Vector3 = road_step_pos(r, s)
			for side in [-1, 1]:
				for wi in range(w):
					var off: float = (road_width * 0.5 + sidewalk_width * 0.5 - float(wi) * tile_size - tile_size * 0.5) * float(side)
					var t: Transform3D = Transform3D()
					t.origin = pos + (Vector3(0.0, 0.0, off) if dir == "h" else Vector3(off, 0.0, 0.0))
					if dir == "v":
						t = t.rotated_local(Vector3.UP, PI * 0.5)
					_sidewalk_mm.multimesh.set_instance_transform(idx, t)
					idx += 1

func _fill_markings() -> void:
	var total: int = 0
	for r in roads:
		var rl: float = float(r.get("length", 0.0))
		total += int(rl / lane_mark_spacing)
	_marking_mm.multimesh.instance_count = total
	var idx: int = 0
	for r in roads:
		var rl: float = float(r.get("length", 0.0))
		var count: int = int(rl / lane_mark_spacing)
		var dir: String = String(r.get("dir", "h"))
		for s in range(count):
			var pos: Vector3 = road_step_pos(r, s)
			var t: Transform3D = Transform3D()
			t.origin = pos
			if dir == "v":
				t = t.rotated_local(Vector3.UP, PI * 0.5)
			_marking_mm.multimesh.set_instance_transform(idx, t)
			idx += 1
'@

$district_themes = @'
extends Node
## Autoload (Project Settings > Autoload as "DistrictThemes").
## Per-district visual + audio theme registry.

signal theme_changed(district_id: StringName)

const DEFAULT_THEMES := [
	["downtown",    "#3a4a6b", "#7a8aa9", "#f4c95d", "urban"],
	["industrial",  "#5a4a3a", "#8a7a5a", "#e85d3a", "industrial"],
	["residential", "#6a7a5a", "#9aaa8a", "#f4a35d", "suburban"],
	["park",        "#3a6a4a", "#7aaa6a", "#f4e35d", "nature"],
	["harbor",      "#3a5a7a", "#7a9aaa", "#5dc8f4", "maritime"],
	["default",     "#5a5a5a", "#8a8a8a", "#cccccc", "default"],
]

var _themes: Dictionary = {}
var current_id: StringName = &"default"

func _ready() -> void:
	for entry in DEFAULT_THEMES:
		var id: StringName = StringName(entry[0])
		var primary: Color = Color(entry[1])
		var secondary: Color = Color(entry[2])
		var accent: Color = Color(entry[3])
		var deco_set: String = String(entry[4])
		_themes[id] = {
			"primary": primary,
			"secondary": secondary,
			"accent": accent,
			"sky": secondary.lightened(0.3),
			"fog": secondary.lightened(0.5),
			"ambient": primary.darkened(0.2),
			"music": "res://audio/music/%s.wav" % entry[0],
			"decoration_set": deco_set,
		}

func register(district_id: StringName, theme: Dictionary) -> void:
	_themes[district_id] = theme

func get_theme(district_id: StringName) -> Dictionary:
	if _themes.has(district_id):
		return _themes[district_id]
	return _themes[&"default"]

func has(district_id: StringName) -> bool:
	return _themes.has(district_id)

func list_ids() -> Array[StringName]:
	return _themes.keys()

func set_current(district_id: StringName) -> void:
	if not _themes.has(district_id):
		return
	current_id = district_id
	theme_changed.emit(district_id)

func color_of(district_id: StringName, key: StringName) -> Color:
	return get_theme(district_id).get(key, Color.WHITE)
'@

$city_decorator = @'
extends Node3D
class_name CityDecorator
## Places street props along the road grid using the district theme.
## street_builder_path must point to a StreetBuilder node (same district).

@export var district_id: StringName = &""
@export var street_builder_path: NodePath
@export var density: float = 1.0
@export var random_seed: int = 0

const PROP_SETS := {
	"default": [
		"res://meshes/props/streetlight.tres",
		"res://meshes/props/bench.tres",
	],
	"urban": [
		"res://meshes/props/streetlight.tres",
		"res://meshes/props/sign.tres",
		"res://meshes/props/hydrant.tres",
		"res://meshes/props/bench.tres",
	],
	"suburban": [
		"res://meshes/props/tree.tres",
		"res://meshes/props/fence.tres",
		"res://meshes/props/mailbox.tres",
	],
	"industrial": [
		"res://meshes/props/container.tres",
		"res://meshes/props/pylon.tres",
		"res://meshes/props/pipe.tres",
	],
	"nature": [
		"res://meshes/props/tree.tres",
		"res://meshes/props/bush.tres",
		"res://meshes/props/rock.tres",
	],
	"maritime": [
		"res://meshes/props/bollard.tres",
		"res://meshes/props/crane.tres",
		"res://meshes/props/rope_pile.tres",
	],
}

@onready var _street: StreetBuilder = get_node_or_null(street_builder_path) as StreetBuilder
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	if random_seed == 0:
		random_seed = hash(str(district_id))
	_rng.seed = random_seed
	if _street == null:
		push_warning("CityDecorator: StreetBuilder missing at " + str(street_builder_path))
		return
	if not _street.streets_ready.is_connected(_on_streets_ready):
		_street.streets_ready.connect(_on_streets_ready)
	if _street.roads.size() > 0:
		_on_streets_ready()

func _on_streets_ready() -> void:
	if _street.roads.is_empty():
		return
	var set_name: String = "default"
	if DistrictThemes.has(district_id):
		var theme_dict: Dictionary = DistrictThemes.get_theme(district_id)
		var deco: Variant = theme_dict.get("decoration_set", "default")
		set_name = String(deco)
	var paths: Array = PROP_SETS.get(set_name, PROP_SETS["default"])
	var total: int = int(48.0 * density)
	var per: int = max(1, total / paths.size())
	for p in paths:
		var mm: MultiMeshInstance3D = MultiMeshInstance3D.new()
		var p_str: String = String(p)
		mm.name = "Prop_" + p_str.get_file().get_basename()
		mm.multimesh = MultiMesh.new()
		mm.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		mm.multimesh.mesh = load(p)
		mm.multimesh.instance_count = per
		add_child(mm)
		for i in range(per):
			mm.multimesh.set_instance_transform(i, _random_transform())

func _random_transform() -> Transform3D:
	var road: Dictionary = _street.roads[_rng.randi() % _street.roads.size()]
	var rl: float = float(road.get("length", 0.0))
	var steps: int = int(rl / _street.tile_size)
	var s: int = _rng.randi() % max(1, steps)
	var pos: Vector3 = _street.road_step_pos(road, s)
	var side: float = ([-1.0, 1.0])[_rng.randi() % 2]
	var off: float = _street.road_width * 0.5 + 1.0
	var dir: String = String(road.get("dir", "h"))
	var lateral: Vector3 = Vector3(0.0, 0.0, off * side) if dir == "h" else Vector3(off * side, 0.0, 0.0)
	var t: Transform3D = Transform3D()
	t.origin = pos + lateral
	t = t.rotated_local(Vector3.UP, _rng.randf() * TAU)
	return t
'@

$weather_vfx = @'
extends Node3D
class_name WeatherVFX
## Weather effect controller. Attach under a district root.
## Children expected: Rain, Snow, FogDrops (GPUParticles3D), and a /root/WorldEnvironment.

enum Weather { CLEAR, OVERCAST, RAIN, SNOW, FOG }

@export var district_id: StringName = &""
@export var initial: Weather = Weather.CLEAR
@export var auto: bool = true

var current: Weather = Weather.CLEAR

@onready var _rain: GPUParticles3D = $Rain
@onready var _snow: GPUParticles3D = $Snow
@onready var _fog: GPUParticles3D = $FogDrops
@onready var _env: WorldEnvironment = get_tree().root.get_node_or_null("WorldEnvironment") as WorldEnvironment

func _ready() -> void:
	if auto:
		set_weather(WeatherVFX.random_for(district_id))
	else:
		set_weather(initial)

func set_weather(w: Weather) -> void:
	if current == w:
		return
	_apply(current, false)
	current = w
	_apply(current, true)

func _process(_delta: float) -> void:
	pass

func _apply(w: Weather, on: bool) -> void:
	match w:
		Weather.RAIN:
			if _rain: _rain.emitting = on
		Weather.SNOW:
			if _snow: _snow.emitting = on
		Weather.FOG:
			if _fog: _fog.emitting = on
	if on and _env and _env.environment:
		_apply_env(w)

func _apply_env(w: Weather) -> void:
	if not _env or not _env.environment:
		return
	var e: Environment = _env.environment
	var theme: Dictionary = DistrictThemes.get_theme(district_id) if DistrictThemes.has(district_id) else {}
	var fog_color: Color = theme.get("fog", Color("#cccccc"))
	match w:
		Weather.CLEAR:
			e.fog_enabled = false
			e.fog_density = 0.0
		Weather.OVERCAST:
			e.fog_enabled = false
		Weather.RAIN:
			e.fog_enabled = true
			e.fog_density = 0.01
			e.fog_light_color = fog_color.darkened(0.1)
		Weather.SNOW:
			e.fog_enabled = true
			e.fog_density = 0.015
			e.fog_light_color = Color("#e8eef4")
		Weather.FOG:
			e.fog_enabled = true
			e.fog_density = 0.04
			e.fog_light_color = fog_color

static func random_for(district_id: StringName) -> Weather:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(str(district_id)) + Time.get_ticks_msec()
	var roll: float = rng.randf()
	if roll < 0.5: return Weather.CLEAR
	if roll < 0.7: return Weather.OVERCAST
	if roll < 0.85: return Weather.RAIN
	if roll < 0.95: return Weather.SNOW
	return Weather.FOG
'@

$files = [ordered]@{
	'scripts/world/street_builder.gd'  = $street_builder
	'scripts/world/district_themes.gd' = $district_themes
	'scripts/world/city_decorator.gd'  = $city_decorator
	'scripts/effects/weather_vfx.gd'   = $weather_vfx
}

foreach ($rel in $files.Keys) {
	$full = Join-Path $root $rel
	$dir  = Split-Path $full -Parent
	if (-not (Test-Path $dir)) {
		New-Item -ItemType Directory -Path $dir -Force | Out-Null
	}
	$content = $files[$rel] -replace "`r`n", "`n"
	if (-not $content.EndsWith("`n")) { $content += "`n" }
	[System.IO.File]::WriteAllText($full, $content, $utf8)
	Write-Host ('WROTE   ' + $rel)
}

# ---------- 3. create check.ps1 ----------
$check_ps1 = @'
# check.ps1 - headless compile check for THE_LAST_STREETLIGHT.
# Exits 0 with "БЕЗ ОШИБОК" if all scripts parse cleanly, else prints BAD list and exits 2.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

$godot = $null
foreach ($c in @('godot', 'godot4')) {
	$f = Get-Command $c -ErrorAction SilentlyContinue
	if ($f) { $godot = $f.Source; break }
}
if (-not $godot) {
	Write-Host 'BAD: godot executable not found in PATH'
	exit 1
}

Set-Location $root
$out = & $godot --headless --path $root res://scenes/tools/compile_scene.tscn 2>&1 | Out-String
$lines = $out -split "`r?`n"
$bad = @()
foreach ($ln in $lines) {
	if ($ln -match 'Parse Error|^ERROR|Failed to') {
		$bad += $ln.Trim()
	}
}
if ($bad.Count -gt 0) {
	Write-Host 'BAD:'
	foreach ($b in $bad) { Write-Host ('  ' + $b) }
	exit 2
}
Write-Host 'БЕЗ ОШИБОК'
exit 0
'@

$checkContent = $check_ps1 -replace "`r`n", "`n"
if (-not $checkContent.EndsWith("`n")) { $checkContent += "`n" }
[System.IO.File]::WriteAllText((Join-Path $root 'check.ps1'), $checkContent, $utf8)
Write-Host 'WROTE   check.ps1'

# ---------- 4. create publish.ps1 ----------
$publish_ps1 = @'
# publish.ps1 - git add/commit/push from project root.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
git add -A
git commit -m 'fix + publish'
git push
'@

$pubContent = $publish_ps1 -replace "`r`n", "`n"
if (-not $pubContent.EndsWith("`n")) { $pubContent += "`n" }
[System.IO.File]::WriteAllText((Join-Path $root 'publish.ps1'), $pubContent, $utf8)
Write-Host 'WROTE   publish.ps1'

# ---------- 5. git add/commit/push ----------
Set-Location $root
git add -A
git commit -m 'fix + publish'
git push