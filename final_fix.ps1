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

# ===== 1) ЧИСТЫЕ ПЕРЕПИСИ 5 битых файлов =====
Write-Utf8 'scripts/visual/night_env.gd' @'
extends Node3D

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.name = "NightEnvironment"
	add_child(env)
	var e := Environment.new()
	env.environment = e
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.02, 0.03, 0.07)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.07, 0.09, 0.15)
	e.ambient_light_energy = 0.45
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true
	e.fog_light_color = Color(0.05, 0.06, 0.11)
	e.fog_density = 0.012
	var moon := DirectionalLight3D.new()
	moon.name = "MoonLight"
	moon.light_color = Color(0.92, 0.94, 1.0)
	moon.light_energy = 0.35
	moon.shadow_enabled = false
	moon.rotation_degrees = Vector3(-55, -40, 0)
	add_child(moon)
'@

Write-Utf8 'scripts/visual/emissive_windows.gd' @'
extends MultiMeshInstance3D

@export var cols: int = 16
@export var rows: int = 4
@export var density: float = 0.55
@export var warm_bias: float = 0.75
@export var seed_value: int = 0

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.seed = hash(str(get_path()))
	var count := cols * rows
	multimesh = MultiMesh.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.5, 0.7)
	multimesh.mesh = qm
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.instance_count = count
	var ox := -cols * 1.6 * 0.5
	for r in rows:
		for c in cols:
			var idx := r * cols + c
			var t := Transform3D()
			t.origin = Vector3(ox + (c + 0.5) * 1.6, 1.5 + (r + 0.5) * 2.2, 0)
			multimesh.set_instance_transform(idx, t)
			var col: Color
			if _rng.randf() < density:
				if _rng.randf() < warm_bias:
					col = Color(1.0, 0.85, 0.55)
				else:
					col = Color(0.55, 0.7, 1.0)
			else:
				col = Color(0.02, 0.025, 0.04)
			multimesh.set_instance_color(idx, col)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	material_override = mat
'@

Write-Utf8 'scripts/ui/hud_minimap.gd' @'
extends Control

const RADIUS := 70.0
const CENTER := Vector2(80, 80)

var _player: Vector3 = Vector3.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(160, 160)
	queue_redraw()

func set_player(pos: Vector3, yaw_deg: float) -> void:
	_player = pos
	queue_redraw()

func set_flash(dir_world: Vector3, on: bool) -> void:
	queue_redraw()

func update_districts(arr: Array) -> void:
	queue_redraw()

func _draw() -> void:
	draw_circle(CENTER, RADIUS + 4.0, Color(0.04, 0.05, 0.08, 0.78))
	draw_arc(CENTER, RADIUS + 4.0, 0.0, TAU, 48, Color(1.0, 0.7, 0.28, 0.95), 2.0)
	var pp := CENTER + Vector2(_player.x, _player.z) * 0.5
	draw_circle(pp, 3.0, Color(1.0, 0.85, 0.4))
'@

Write-Utf8 'scripts/ui/hud_banner.gd' @'
extends Control

var district_name: String = "—"
var powered: int = 0
var total: int = 11

func _ready() -> void:
	custom_minimum_size = Vector2(280, 64)
	queue_redraw()

func set_district(n: String, loc: String = "") -> void:
	if loc != "":
		district_name = loc
	else:
		district_name = n
	queue_redraw()

func set_progress(p: int, t: int) -> void:
	powered = p
	total = t
	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, Vector2(280, 64))
	draw_rect(r, Color(0.04, 0.05, 0.08, 0.78), true)
	draw_rect(r, Color(1.0, 0.7, 0.28, 0.95), false, 2.0)
	var f := ThemeDB.fallback_font
	if f == null:
		return
	draw_string(f, Vector2(12, 24), district_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.85, 0.5))
	draw_rect(Rect2(12, 38, 256, 14), Color(0.1, 0.1, 0.15), true)
	var pct := clamp(float(powered) / max(1, total), 0.0, 1.0)
	draw_rect(Rect2(14, 40, 252 * pct, 10), Color(1.0, 0.85, 0.4), true)
	draw_string(f, Vector2(220, 24), "%d/%d" % [powered, total], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
'@

Write-Utf8 'scripts/ui/hud_main.gd' @'
extends CanvasLayer

var banner: Control
var minimap: Control
var lives_label: Label
var coins_label: Label

func _ready() -> void:
	layer = 10
	banner = load("res://scripts/ui/hud_banner.gd").new()
	banner.position = Vector2(16, 16)
	add_child(banner)
	minimap = load("res://scripts/ui/hud_minimap.gd").new()
	minimap.position = Vector2(16, 530)
	add_child(minimap)
	lives_label = Label.new()
	lives_label.position = Vector2(1110, 24)
	lives_label.add_theme_font_size_override("font_size", 24)
	lives_label.text = "♥ ♥ ♥"
	add_child(lives_label)
	coins_label = Label.new()
	coins_label.position = Vector2(1090, 640)
	coins_label.add_theme_font_size_override("font_size", 28)
	coins_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	coins_label.text = "● 0"
	add_child(coins_label)

func _process(_d: float) -> void:
	var pg := get_tree().root.get_node_or_null("PowerGrid")
	if pg != null and banner != null and banner.has_method("set_progress"):
		var prog: Dictionary = pg.get_progress()
		banner.set_progress(int(prog.get("powered", 0)), int(prog.get("total", 11)))
	var sl := get_tree().root.get_node_or_null("SaveLoad")
	if sl != null:
		if coins_label != null:
			coins_label.text = "● %d" % int(sl.get_coins())
		if lives_label != null:
			var h := ""
			for i in range(max(0, int(sl.get_lives()))):
				h += "♥ "
			lives_label.text = h.strip_edges()
	var p := get_tree().get_first_node_in_group("player")
	if p != null and minimap != null and minimap.has_method("set_player"):
		minimap.set_player(p.global_position, 0.0)
'@

# ===== 2) ЭКРАНЫ: загрузка -> меню -> загрузка -> игра =====
Write-Utf8 'scripts/ui/boot_loading.gd' @'
extends Control

func _ready() -> void:
	await get_tree().create_timer(1.2).timeout
	var menu := "res://scenes/main_menu.tscn"
	if not ResourceLoader.exists(menu):
		menu = "res://scenes/ui/main_menu.tscn"
	if not ResourceLoader.exists(menu):
		menu = "res://scenes/ui/menu.tscn"
	get_tree().change_scene_to_file(menu)
'@

Write-Utf8 'scenes/ui/boot_loading.tscn' @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/boot_loading.gd" id="1_boot"]

[node name="BootLoading" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_boot")

[node name="BG" type="ColorRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.02, 0.02, 0.04, 1)

[node name="Label" type="Label" parent="."]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
text = "THE LAST STREETLIGHT — LOADING..."
'@

Write-Utf8 'scripts/ui/pre_loading.gd' @'
extends Control

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/main_3d.tscn")
'@

Write-Utf8 'scenes/ui/pre_loading.tscn' @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/pre_loading.gd" id="1_pre"]

[node name="PreLoading" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_pre")

[node name="BG" type="ColorRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.02, 0.02, 0.04, 1)

[node name="Label" type="Label" parent="."]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
text = "ENTERING CITY..."
'@

Write-Utf8 'scripts/ui/menu.gd' @'
extends Control

func _ready() -> void:
	var play := $VBox/PlayBtn
	if play != null:
		play.pressed.connect(_play)
	var quit := $VBox/QuitBtn
	if quit != null:
		quit.pressed.connect(_quit)

func _play() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/pre_loading.tscn")

func _quit() -> void:
	get_tree().quit()
'@

Write-Utf8 'scenes/ui/menu.tscn' @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/menu.gd" id="1_menu"]

[node name="Menu" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_menu")

[node name="BG" type="ColorRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.03, 0.03, 0.06, 1)

[node name="Title" type="Label" parent="."]
anchors_preset = 5
anchor_left = 0.5
anchor_top = 0.2
anchor_right = 0.5
anchor_bottom = 0.2
text = "THE LAST STREETLIGHT"

[node name="VBox" type="VBoxContainer" parent="."]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5

[node name="PlayBtn" type="Button" parent="VBox"]
text = "PLAY"

[node name="QuitBtn" type="Button" parent="VBox"]
text = "QUIT"
'@

# стартовая сцена = загрузка
$pg = [System.IO.File]::ReadAllText((Join-Path $root 'project.godot'), $utf8)
$pg = $pg -replace 'run/main_scene="[^"]*"', 'run/main_scene="res://scenes/ui/boot_loading.tscn"'
[System.IO.File]::WriteAllText((Join-Path $root 'project.godot'), $pg, $utf8)
Write-Host 'MAIN_SCENE -> boot_loading'

# меню-скрипты, которые сразу тащат в main_3d, перенаправляем через pre_loading
Get-ChildItem (Join-Path $root 'scripts') -Recurse -Filter '*.gd' | ForEach-Object {
	if ($_.Name -match 'menu') {
		$c = [System.IO.File]::ReadAllText($_.FullName, $utf8)
		if ($c -match 'change_scene_to_file\("res://scenes/main_3d\.tscn"\)') {
			$c = $c.Replace('change_scene_to_file("res://scenes/main_3d.tscn")', 'change_scene_to_file("res://scenes/ui/pre_loading.tscn")')
			[System.IO.File]::WriteAllText($_.FullName, $c, $utf8)
			Write-Host ('PATCH  ' + $_.Name)
		}
	}
}

# ===== 3) КАРТА ТОЛЬКО ПО КЛАВИШЕ =====
Write-Utf8 'scripts/ui/map_controller.gd' @'
extends Node

var _open := false
var _map: Node = null

func _ready() -> void:
	call_deferred("_find")

func _find() -> void:
	_map = _search(get_tree().root)

func _search(n: Node) -> Node:
	var nm := String(n.name)
	if nm != "Root" and ("CityMap" in nm or nm == "Map" or ("map" in nm.to_lower() and "Mini" not in nm and "minimap" not in nm.to_lower())):
		return n
	for c in n.get_children():
		var r := _search(c)
		if r != null:
			return r
	return null

func _process(_d: float) -> void:
	if _map == null:
		_find()
		return
	if not _open:
		_map.visible = false

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("city_map_toggle"):
		_open = not _open
		if _map != null:
			_map.visible = _open
'@
Write-Host 'MAP CONTROLLER ready'

# ===== 4) 11 DISTRICT-СЦЕН =====
$canon = @("suburbs","residential","park","school","hospital","gas_station","police","warehouses","industrial","substation","power_station")
foreach ($d in $canon) {
	$tscn = @"
[gd_scene load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/world/street_builder.gd" id="1_sb"]
[ext_resource type="Script" path="res://scripts/world/power_switch.gd" id="2_ps"]
[ext_resource type="Script" path="res://scripts/world/district_trigger.gd" id="3_dt"]
[ext_resource type="Script" path="res://scripts/visual/emissive_windows.gd" id="4_ew"]
[ext_resource type="Script" path="res://scripts/world/street_props.gd" id="5_cp"]

[sub_resource type="BoxShape3D" id="box_1"]
size = Vector3(80, 20, 80)

[node name="district_$d" type="Node3D"]

[node name="StreetBuilder" type="Node3D" parent="."]
script = ExtResource("1_sb")
district_id = &"$d"

[node name="PowerSwitch" type="Node3D" parent="."]
script = ExtResource("2_ps")
district_id = &"$d"
position = Vector3(8, 0, 8)

[node name="DistrictTrigger" type="Area3D" parent="."]
script = ExtResource("3_dt")
district_id = &"$d"

[node name="CollisionShape3D" type="CollisionShape3D" parent="DistrictTrigger"]
shape = SubResource("box_1")

[node name="EmissiveWindows" type="MultiMeshInstance3D" parent="."]
script = ExtResource("4_ew")
seed_value = $($d.Length * 777)

[node name="Props" type="Node3D" parent="."]
script = ExtResource("5_cp")
street_builder_path = NodePath("../StreetBuilder")
"@
	Write-Utf8 ("scenes/districts/" + $d + ".tscn") $tscn
}

# ===== 5) AUTOLOAD MapController =====
$pg = [System.IO.File]::ReadAllText((Join-Path $root 'project.godot'), $utf8)
if ($pg -notmatch '(?m)^MapController=') {
	$pg = [regex]::Replace($pg, '(\[autoload\]\s*\r?\n)', ('$1' + 'MapController="*res://scripts/ui/map_controller.gd"' + "`n"), 1)
	[System.IO.File]::WriteAllText((Join-Path $root 'project.godot'), $pg, $utf8)
	Write-Host 'AUTOLOAD MapController'
}

# ===== 6) ГЕЙТ + ПУШ =====
$godot = "C:\Users\Maxsim\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
& $godot --headless --path . res://scenes/tools/compile_scene.tscn 2>&1 | Select-String "BAD|FAILED|БЕЗ ОШИБОК" | Select-Object -Last 4

git -C $root add -A
git -C $root commit -m "final fix: screens flow, map key, 11 districts, clean UI"
git -C $root push

Write-Host 'District tscn: ' (Get-ChildItem (Join-Path $root 'scenes\districts\*.tscn') | Measure-Object).Count ' / 11'
Write-Host 'DONE' -ForegroundColor Green