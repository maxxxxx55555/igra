$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

# ===== 1. streetlight_spawner.gd — фонари вдоль улиц =====
@'
extends Node3D
class_name StreetLightSpawner

## Спавнит OmniLight3D + emissive-столб вдоль улиц при сигнале StreetBuilder.streets_ready.
## Без теней, маленький energy — мобильный бюджет.

@export var street_builder_path: NodePath = ^"StreetBuilder"
@export var spacing: float = 12.0
@export var light_color: Color = Color("#f4c95d")
@export var light_energy: float = 1.2
@export var light_range: float = 6.0

var _rng := RandomNumberGenerator.new()
var _street = null

func _ready() -> void:
	_street = get_node_or_null(street_builder_path)
	if _street == null:
		return
	if not _street.streets_ready.is_connected(_spawn_lights):
		_street.streets_ready.connect(_spawn_lights)

func _spawn_lights() -> void:
	var roads: Array = _street.roads
	var tile: float = _street.tile_size
	for road in roads:
		var dir: String = String(road.get("dir", "h"))
		var rl: float = float(road.get("length", 0.0))
		var steps: int = int(rl / tile)
		for s in range(0, steps, int(spacing / tile)):
			var pos: Vector3 = _street.road_step_pos(road, s)
			_place_lamp(pos, dir)

func _place_lamp(pos: Vector3, dir: String) -> void:
	var lateral: Vector3 = Vector3(0, 0, 4.0) if dir == "h" else Vector3(4.0, 0, 0)
	var base: Vector3 = pos + lateral

	# столб (боксом, emissive-основание)
	var pole := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.15, 3.5, 0.15)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#1a1a1a")
	bm.material = mat
	pole.mesh = bm
	pole.position = base + Vector3(0, 1.75, 0)
	add_child(pole)

	# плафон (маленький emissive-куб)
	var head := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.3, 0.15, 0.3)
	var hm_mat := StandardMaterial3D.new()
	hm_mat.albedo_color = Color.BLACK
	hm_mat.emission_enabled = true
	hm_mat.emission = light_color
	hm_mat.emission_energy_multiplier = 3.0
	hm.material = hm_mat
	head.mesh = hm
	head.position = base + Vector3(0, 3.6, 0)
	add_child(head)

	# OmniLight3D без теней (мобильный бюджет)
	var lamp := OmniLight3D.new()
	lamp.light_color = light_color
	lamp.light_energy = light_energy
	lamp.omni_range = light_range
	lamp.shadow_enabled = false
	lamp.light_negative = false
	lamp.position = base + Vector3(0, 3.4, 0)
	add_child(lamp)
'@ | Set-Content -Path "scripts\world\streetlight_spawner.gd" -Encoding UTF8

# ===== 2. atmosphere.gd — меняет небо/туман по району =====
@'
extends Node
class_name DistrictAtmosphere

## Слушает EventBus.district_entered и плавно меняет Environment под тему района.
## Вешается на /root. Ищет WorldEnvironment в главной сцене.

var _env: Environment = null
var _target_fog_color: Color = Color.BLACK
var _target_sky_color: Color = Color.BLACK
var _target_ambient: Color = Color.BLACK
var _lerp_speed: float = 0.8

func _ready() -> void:
	await get_tree().process_frame
	var we = get_tree().get_first_node_in_group("world_env")
	if we == null:
		we = get_tree().root.get_node_or_null("Main3D/WorldEnvironment")
	if we != null and we.environment != null:
		_env = we.environment
		_target_fog_color = _env.fog_light_color
		_target_sky_color = _env.background_color
		_target_ambient = _env.ambient_light_color
	if EventBus.has_signal("district_entered"):
		EventBus.district_entered.connect(_on_district)

func _on_district(id: StringName) -> void:
	if _env == null:
		return
	if not DistrictThemes.has(id):
		return
	var t: Dictionary = DistrictThemes.get_theme(id)
	_target_fog_color = t.get("fog", Color.BLACK)
	_target_sky_color = t.get("sky", Color.BLACK)
	_target_ambient = t.get("ambient", Color.BLACK)

func _process(delta: float) -> void:
	if _env == null:
		return
	var k: float = clamp(delta * _lerp_speed, 0.0, 1.0)
	_env.fog_light_color = _env.fog_light_color.lerp(_target_fog_color, k)
	_env.background_color = _env.background_color.lerp(_target_sky_color, k)
	_env.ambient_light_color = _env.ambient_light_color.lerp(_target_ambient, k)
'@ | Set-Content -Path "scripts\world\district_atmosphere.gd" -Encoding UTF8

# ===== 3. world_env.tscn — ночной туман и небо =====
@'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world_env_setup.gd" id="1_setup"]

[sub_resource type="Environment" id="env_night"]
background_mode = 2
background_color = Color(0.02, 0.03, 0.06, 1)
background_energy_multiplier = 0.3
ambient_light_source = 2
ambient_light_color = Color(0.08, 0.09, 0.14, 1)
ambient_light_energy = 0.35
tonemap_mode = 2
tonemap_exposure = 0.9
ssao_enabled = true
ssil_enabled = false
glow_enabled = true
glow_intensity = 0.35
glow_strength = 0.8
glow_bicubic_upscale = true
fog_enabled = true
fog_light_color = Color(0.08, 0.09, 0.12, 1)
fog_light_energy = 0.6
fog_density = 0.012
fog_aerial_perspective = 0.4
volumetric_fog_enabled = false

[node name="WorldEnvironment" type="WorldEnvironment"]
environment = SubResource("env_night")
script = ExtResource("1_setup")
'@ | Set-Content -Path "scenes\environment\world_env.tscn" -Encoding UTF8

# ===== 4. Правка main_3d.tscn: Moon.energy + StreetLightSpawner + DistrictAtmosphere =====
$c = Get-Content scenes\main_3d.tscn -Raw
# Луна
$c = $c.Replace("light_energy = 0.0", "light_energy = 0.35")
# Добавить StreetLightSpawner и DistrictAtmosphere в конец
if ($c -notmatch "StreetLightSpawner") {
	$c = $c.TrimEnd() + @"

[node name="StreetLightSpawner" type="Node3D" parent="."]
script = ExtResource("7")
'@
}
Set-Content scenes\main_3d.tscn -Value $c -Encoding UTF8 -NoNewline

# Добавим DistrictAtmosphere в autoloads
$pc = Get-Content project.godot -Raw
if ($pc -notmatch "DistrictAtmosphere=") {
	$pc = $pc -replace "DistrictThemes=[^\r\n]+\r?\n", "`$0DistrictAtmosphere=`"*res://scripts/world/district_atmosphere.gd`"`n"
	Set-Content project.godot -Value $pc -Encoding UTF8 -NoNewline
}

# ===== 5. compile gate =====
$godot = "C:\Users\Maxsim\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
& $godot --headless --path . res://scenes/tools/compile_scene.tscn 2>&1 | Select-Object -Last 4

# ===== 6. push =====
git add -A
git commit -m "stage D: night atmosphere + streetlights"
git push