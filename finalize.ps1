# finalize.ps1 — полное восстановление + фиксы + музыка + пуш
$ErrorActionPreference = "Stop"
$proj = "$([Environment]::GetFolderPath('Desktop'))\TLS_Build\THE_LAST_STREETLIGHT"
cd $proj

Write-Host "=== ШАГ 1: Восстановление файлов из Части 1 ===" -ForegroundColor Cyan

# === district_banner.tscn ===
@'
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/ui/district_banner.gd" id="1_banner"]
[node name="DistrictBanner" type="Control"]
anchor_left = 0.5
anchor_right = 0.5
offset_left = -220.0
offset_top = 110.0
offset_right = 220.0
offset_bottom = 158.0
mouse_filter = 2
script = ExtResource("1_banner")
'@ | Set-Content -Path "scenes\ui\district_banner.tscn" -Encoding UTF8

# === 11 district scenes ===
$districts = @("suburbs","residential","park","school","hospital","gas_station","police","warehouses","industrial","substation","power_station")
foreach ($d in $districts) {
  @"
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/world/district_scene_factory.gd" id="1_factory"]
[node name="District_$d" type="Node3D"]
script = ExtResource("1_factory")
[node name="Meta" type="Node" parent="."]
[node name="district_id" type="Node" parent="Meta"]
"@ | Set-Content -Path "scenes\world\districts\$d.tscn" -Encoding UTF8
}

# === district_banner.gd ===
@'
extends Control
const FADE_IN_TIME := 0.6
const HOLD_TIME := 3.5
const FADE_OUT_TIME := 1.2
const FONT_SIZE := 22
var _label: Label
var _accent: ColorRect
var _t: float = 0.0
var _phase: int = 0
var _modulate: float = 0.0
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_preset(Control.PRESET_CENTER_TOP)
    position = Vector2(-220, 110)
    size = Vector2(440, 48)
    _accent = ColorRect.new()
    _accent.color = ThemeProvider.COLOR_AMBER
    _accent.size = Vector2(4, 36)
    _accent.position = Vector2(0, 6)
    _accent.modulate.a = 0.0
    add_child(_accent)
    _label = Label.new()
    _label.position = Vector2(14, 6)
    _label.size = Vector2(420, 36)
    _label.add_theme_font_size_override("font_size", FONT_SIZE)
    _label.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
    _label.modulate.a = 0.0
    _label.text = ""
    add_child(_label)
    if EventBus.has_signal("district_entered"):
        EventBus.district_entered.connect(_on_district)
    visible = false
func _on_district(id: StringName) -> void:
    var name := PowerGrid.get_district(id)
    var display := name.display_name if name else String(id)
    _label.text = display.to_upper()
    var theme_color: Color = DistrictThemes.get_district_color(id)
    var accent: Color = theme_color.lerp(ThemeProvider.COLOR_AMBER, 0.5)
    accent.a = 1.0
    _accent.color = accent
    _label.add_theme_color_override("font_color", accent)
    _phase = 0
    _t = 0.0
    _modulate = 0.0
    visible = true
func _process(delta: float) -> void:
    if _phase >= 3: return
    _t += delta
    match _phase:
        0:
            _modulate = clamp(_t / FADE_IN_TIME, 0.0, 1.0)
            if _t >= FADE_IN_TIME: _phase = 1; _t = 0.0
        1:
            _modulate = 1.0
            if _t >= HOLD_TIME: _phase = 2; _t = 0.0
        2:
            _modulate = clamp(1.0 - _t / FADE_OUT_TIME, 0.0, 1.0)
            if _t >= FADE_OUT_TIME: _phase = 3; visible = false
    modulate.a = _modulate
'@ | Set-Content -Path "scripts\ui\district_banner.gd" -Encoding UTF8

# === minimap.gd ===
@'
extends Control
const SIZE := Vector2(180, 180)
const SCALE := 0.06
const DISTRICT_OFFSETS: Dictionary = {
    &"suburbs": Vector2i(0, 0), &"residential": Vector2i(1, 0), &"park": Vector2i(2, 0), &"school": Vector2i(3, 0),
    &"hospital": Vector2i(0, 1), &"gas_station": Vector2i(1, 1), &"police": Vector2i(2, 1), &"warehouses": Vector2i(3, 1),
    &"industrial": Vector2i(0, 2), &"substation": Vector2i(1, 2), &"power_station": Vector2i(2, 2),
}
const TILE_SIZE: int = 32
const SLOT_W: int = 12
const SLOT_H: int = 9
const DISTRICT_LABELS: Dictionary = {
    &"suburbs": "Пригород", &"residential": "Жилые", &"park": "Парк", &"school": "Школа",
    &"hospital": "Больница", &"gas_station": "АЗС", &"police": "Полиция", &"warehouses": "Склады",
    &"industrial": "Промзона", &"substation": "Подстанция", &"power_station": "Станция",
}
var _tick: float = 0.0
var _current_district: StringName = &""
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = SIZE
    size = SIZE
    anchor_left = 1.0
    anchor_right = 1.0
    offset_left = -SIZE.x - 16
    offset_right = -16
    offset_top = 16
    offset_bottom = 16 + SIZE.y
    EventBus.power_grid_updated.connect(func() -> void: queue_redraw())
    if EventBus.has_signal("district_entered"):
        EventBus.district_entered.connect(func(id: StringName) -> void:
            _current_district = id
            queue_redraw())
func _process(delta: float) -> void:
    _tick += delta
    if _tick >= 0.1: _tick = 0.0; queue_redraw()
func _draw() -> void:
    if not GameManager.is_playing(): return
    var r := get_rect()
    draw_circle(r.size * 0.5, r.size.x * 0.5, ThemeProvider.COLOR_BG_PANEL)
    draw_arc(r.size * 0.5, r.size.x * 0.5 - 1, 0.0, TAU, 32, ThemeProvider.COLOR_BORDER, 2.0, true)
    var center := r.size * 0.5
    for d in PowerGrid.all_districts():
        var off: Vector2i = DISTRICT_OFFSETS.get(d.id, Vector2i(-99, -99))
        if off.x < 0: continue
        var wp := Vector2(off.x * SLOT_W * TILE_SIZE, off.y * SLOT_H * TILE_SIZE)
        var p := center + (wp - _player_pos()) * SCALE
        var c := _stage_color(d.stage)
        var theme_c := DistrictThemes.get_district_color(d.id)
        var mix := c.lerp(theme_c, 0.45)
        draw_circle(p, d.id == _current_district ? 6.5 : 4.0, mix)
        if d.id == _current_district: draw_arc(p, 8.0, 0.0, TAU, 24, ThemeProvider.COLOR_AMBER, 1.5, true)
        var label: String = DISTRICT_LABELS.get(d.id, "")
        if label != "":
            var font := ThemeDB.fallback_font
            draw_string(font, p + Vector2(8, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, ThemeProvider.COLOR_AMBER_DIM)
    draw_circle(center, 3.0, ThemeProvider.COLOR_AMBER)
func _player_pos() -> Vector2:
    var p := get_tree().get_first_node_in_group("player")
    var v3: Vector3 = p.global_position if is_instance_valid(p) else Vector3.ZERO
    return Vector2(v3.x, v3.z)
func _stage_color(stage: int) -> Color:
    match stage:
        1: return ThemeProvider.COLOR_AMBER_DIM
        2: return Color("c98a2e")
        3: return ThemeProvider.COLOR_AMBER
        _: return ThemeProvider.COLOR_BORDER
'@ | Set-Content -Path "scripts\ui\minimap.gd" -Encoding UTF8

# === district_layouts.gd ===
@'
class_name DistrictLayouts
extends RefCounted
const TILE_SIZE: int = 32
const SLOT_W: int = 12
const SLOT_H: int = 9
var OFFSETS: Dictionary = {
    &"suburbs": Vector2i(0,0), &"residential": Vector2i(1,0), &"park": Vector2i(2,0), &"school": Vector2i(3,0),
    &"hospital": Vector2i(0,1), &"gas_station": Vector2i(1,1), &"police": Vector2i(2,1), &"warehouses": Vector2i(3,1),
    &"industrial": Vector2i(0,2), &"substation": Vector2i(1,2), &"power_station": Vector2i(2,2),
}
var LAYOUTS: Dictionary = {
&"suburbs": PackedStringArray(["............",".##......##.",".##..P...##.","....GG......",".##......##.","...KL..b.c..",".##..L...##.",".?o........S","............"]),
&"residential": PackedStringArray(["............",".##.m....##.",".##......##.","...GG..f....",".##......##.",".o.KL..b.##.",".##..T...##.",".S.......C..","............"]),
&"park": PackedStringArray(["............",".dd......dd.","....GG......",".dd..L...dd.","....K....m..",".dd..T...dd.","....L..b....",".?........W.","............"]),
&"school": PackedStringArray(["............",".####..####.",".#GG#..#oo#.",".#..#..#..#.",".#KL####..#.",".#..#m.#b.#.",".#T.#..#..#.",".####..####.",".....C......"]),
&"hospital": PackedStringArray(["............",".####..####.",".#GG#..#m.#.",".#..#..#..#.",".#KL####b.#.",".#..#f.#..#.",".#T.#..#o.#.",".####..####.","..S........."]),
&"gas_station": PackedStringArray(["............",".##......##.","....GG...b..",".##..L...##.","....K....f..",".##..T...##.",".s.......s..",".?o.......C.","............"]),
&"police": PackedStringArray(["............",".####..####.",".#GG#..#k.#.",".#..#..#..#.",".#KL####b.#.",".#..#m.#..#.",".#T.#..#o.#.",".####..####.",".....H......"]),
&"warehouses": PackedStringArray(["............",".###....###.",".#GG#..#s.#.",".#..#..#..#.",".#KL####c.#.",".#..#f.#..#.",".#T.#..#b.#.",".###....###.","..D....?...."]),
&"industrial": PackedStringArray(["............",".###....###.",".#GG#..#s.#.",".#L.#..#..#.",".#KL####c.#.",".#..#f.#o.#.",".#T.#..#b.#.",".###....###.","..D....H...."]),
&"substation": PackedStringArray(["............",".####..####.",".#GG#..#f.#.",".#L.#..#..#.",".#KL####c.#.",".#..#m.#..#.",".#T.#..#o.#.",".####..####.","..D....?...."]),
&"power_station": PackedStringArray(["............",".####..####.",".#GG#..#f.#.",".#L.#..#..#.",".#KL####c.#.",".#..#m.#..#.",".#T.#..#o.#.",".####..####.","..D....B...."]),
}
static func symbol_at(district_id: StringName, x: int, y: int) -> String:
    var layout: PackedStringArray = DistrictLayouts.LAYOUTS.get(district_id, PackedStringArray())
    if y < 0 or y >= layout.size(): return "."
    var row: String = layout[y]
    if x < 0 or x >= row.length(): return "."
    return row.substr(x, 1)
static func for_each_cell(district_id: StringName, cb: Callable) -> void:
    var layout: PackedStringArray = DistrictLayouts.LAYOUTS.get(district_id, PackedStringArray())
    for y in layout.size():
        var row: String = layout[y]
        for x in row.length():
            var s: String = row.substr(x, 1)
            if s == ".": continue
            var wp := Vector3(x * DistrictLayouts.TILE_SIZE, 0.0, y * DistrictLayouts.TILE_SIZE)
            cb.call(s, x, y, wp)
'@ | Set-Content -Path "scripts\world\district_layouts.gd" -Encoding UTF8

# === district_scene_factory.gd (FIXED API) ===
@'
class_name DistrictSceneFactory
extends Node
const DISTRICTS: Array[StringName] = [
    &"suburbs", &"residential", &"park", &"school", &"hospital",
    &"gas_station", &"police", &"warehouses", &"industrial",
    &"substation", &"power_station",
]
static func build(parent: Node, district_id: StringName) -> Node3D:
    var root := Node3D.new()
    root.name = StringName("District_" + String(district_id))
    parent.add_child(root)
    var theme: Dictionary = DistrictThemes.get_theme(district_id)
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    DistrictThemes.apply_to_environment(env, district_id)
    world_env.environment = env
    world_env.name = "WorldEnvironment"
    root.add_child(world_env)
    var sb_script: Script = load("res://scripts/world/street_builder.gd")
    if sb_script != null:
        var sb := Node3D.new()
        sb.set_script(sb_script)
        sb.name = "StreetBuilder3D"
        sb.set("district_id", String(district_id))
        sb.set("theme", theme)
        root.add_child(sb)
    var wx_script: Script = load("res://scripts/effects/weather_vfx.gd")
    if wx_script != null:
        var wx := Node3D.new()
        wx.set_script(wx_script)
        wx.name = "WeatherVFX"
        wx.set("weather_kind", String(theme.get("weather", "fog_light")))
        root.add_child(wx)
    if EventBus.has_signal("district_entered"):
        EventBus.district_entered.emit(district_id)
    return root
static func district_count() -> int:
    return DISTRICTS.size()
static func district_id_at(index: int) -> StringName:
    if index < 0 or index >= DISTRICTS.size(): return &"suburbs"
    return DISTRICTS[index]
'@ | Set-Content -Path "scripts\world\district_scene_factory.gd" -Encoding UTF8

Write-Host "=== ШАГ 2: Восстановление файлов из Части 2 ===" -ForegroundColor Cyan

# === street_builder.gd ===
@'
extends Node3D
class_name StreetBuilder
signal streets_ready
@export var district_id: StringName = &""
@export var tile_size: float = 4.0
@export var road_width: float = 6.0
@export var sidewalk_width: float = 1.5
@export var lane_mark_spacing: float = 2.0
@export var seed: int = 0
var roads: Array[Dictionary] = []
@onready var _road_mm: MultiMeshInstance3D = $RoadMM
@onready var _sidewalk_mm: MultiMeshInstance3D = $SidewalkMM
@onready var _marking_mm: MultiMeshInstance3D = $MarkingMM
func _ready() -> void:
    if seed == 0: seed = hash(str(district_id))
    _init_mm(_road_mm, _make_box_mesh(Color(0.15, 0.15, 0.15)))
    _init_mm(_sidewalk_mm, _make_box_mesh(Color(0.4, 0.4, 0.4)))
    _init_mm(_marking_mm, _make_box_mesh(Color(0.9, 0.9, 0.9)))
    call_deferred("build")
func _make_box_mesh(color: Color) -> BoxMesh:
    var m := BoxMesh.new()
    m.size = Vector3(tile_size, 0.1, tile_size)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    m.material = mat
    return m
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
    var cols := 3
    var rows := 3
    var spacing := 16.0
    for r in rows + 1:
        roads.append({"start": Vector2i(0, r), "end": Vector2i(cols, r), "dir": "h", "length": float(cols) * spacing})
    for c in cols + 1:
        roads.append({"start": Vector2i(c, 0), "end": Vector2i(c, rows), "dir": "v", "length": float(rows) * spacing})
func road_step_pos(road: Dictionary, step: int) -> Vector3:
    var dir := (Vector2(road.end) - Vector2(road.start)).normalized()
    var p := Vector2(road.start) + dir * float(step) * tile_size
    return Vector3(p.x, 0.01, p.y)
func _fill_roads() -> void:
    var total := 0
    for r in roads: total += int(r.length / tile_size) * int(road_width / tile_size)
    _road_mm.multimesh.instance_count = total
    var idx := 0
    for r in roads:
        var steps := int(r.length / tile_size)
        var w := int(road_width / tile_size)
        for s in steps:
            var pos := road_step_pos(r, s)
            for wi in w:
                var off := -road_width * 0.5 + wi * tile_size + tile_size * 0.5
                var t := Transform3D()
                t.origin = pos + (Vector3(0, 0, off) if r.dir == "h" else Vector3(off, 0, 0))
                if r.dir == "v": t = t.rotated_local(Vector3.UP, PI * 0.5)
                _road_mm.multimesh.set_instance_transform(idx, t)
                idx += 1
func _fill_sidewalks() -> void:
    var total := 0
    for r in roads: total += 2 * int(r.length / tile_size) * int(sidewalk_width / tile_size)
    _sidewalk_mm.multimesh.instance_count = total
    var idx := 0
    for r in roads:
        var steps := int(r.length / tile_size)
        var w := int(sidewalk_width / tile_size)
        for s in steps:
            var pos := road_step_pos(r, s)
            for side in [-1, 1]:
                for wi in w:
                    var off := (road_width * 0.5 + sidewalk_width * 0.5 - wi * tile_size - tile_size * 0.5) * side
                    var t := Transform3D()
                    t.origin = pos + (Vector3(0, 0, off) if r.dir == "h" else Vector3(off, 0, 0))
                    if r.dir == "v": t = t.rotated_local(Vector3.UP, PI * 0.5)
                    _sidewalk_mm.multimesh.set_instance_transform(idx, t)
                    idx += 1
func _fill_markings() -> void:
    var total := 0
    for r in roads: total += int(r.length / lane_mark_spacing)
    _marking_mm.multimesh.instance_count = total
    var idx := 0
    for r in roads:
        var count := int(r.length / lane_mark_spacing)
        for s in count:
            var pos := road_step_pos(r, s)
            var t := Transform3D()
            t.origin = pos
            if r.dir == "v": t = t.rotated_local(Vector3.UP, PI * 0.5)
            _marking_mm.multimesh.set_instance_transform(idx, t)
            idx += 1
'@ | Set-Content -Path "scripts\world\street_builder.gd" -Encoding UTF8

# === district_themes.gd (FIXED: added get_theme, get_district_color, apply_to_environment) ===
@'
extends Node
signal theme_changed(district_id: StringName)
const THEMES := {
    &"suburbs": {"primary": Color("#6a7a5a"), "secondary": Color("#9aaa8a"), "accent": Color("#f4a35d"), "sky": Color("#b0c8a0"), "fog": Color("#c8d8c0"), "ambient": Color("#506048"), "music": "res://assets/audio/music/residential.wav", "weather": "clear", "display_name": "Пригород"},
    &"residential": {"primary": Color("#6a7a5a"), "secondary": Color("#9aaa8a"), "accent": Color("#f4a35d"), "sky": Color("#b0c8a0"), "fog": Color("#c8d8c0"), "ambient": Color("#506048"), "music": "res://assets/audio/music/residential.wav", "weather": "clear", "display_name": "Жилые"},
    &"park": {"primary": Color("#3a6a4a"), "secondary": Color("#7aaa6a"), "accent": Color("#f4e35d"), "sky": Color("#a0c8a0"), "fog": Color("#c0d8c0"), "ambient": Color("#305040"), "music": "res://assets/audio/music/park.wav", "weather": "clear", "display_name": "Парк"},
    &"school": {"primary": Color("#5a5a6a"), "secondary": Color("#8a8a9a"), "accent": Color("#f4c95d"), "sky": Color("#b0b0c0"), "fog": Color("#c8c8d8"), "ambient": Color("#484858"), "music": "res://assets/audio/music/residential.wav", "weather": "clear", "display_name": "Школа"},
    &"hospital": {"primary": Color("#5a5a6a"), "secondary": Color("#8a8a9a"), "accent": Color("#5dc8f4"), "sky": Color("#b0b0c0"), "fog": Color("#c8c8d8"), "ambient": Color("#484858"), "music": "res://assets/audio/music/residential.wav", "weather": "clear", "display_name": "Больница"},
    &"gas_station": {"primary": Color("#5a4a3a"), "secondary": Color("#8a7a5a"), "accent": Color("#e85d3a"), "sky": Color("#a09080"), "fog": Color("#c0b0a0"), "ambient": Color("#484038"), "music": "res://assets/audio/music/industrial.wav", "weather": "clear", "display_name": "АЗС"},
    &"police": {"primary": Color("#4a4a6a"), "secondary": Color("#7a7a9a"), "accent": Color("#5d5dc8"), "sky": Color("#a0a0c0"), "fog": Color("#c0c0d8"), "ambient": Color("#404058"), "music": "res://assets/audio/music/residential.wav", "weather": "clear", "display_name": "Полиция"},
    &"warehouses": {"primary": Color("#5a4a3a"), "secondary": Color("#8a7a5a"), "accent": Color("#e85d3a"), "sky": Color("#a09080"), "fog": Color("#c0b0a0"), "ambient": Color("#484038"), "music": "res://assets/audio/music/industrial.wav", "weather": "fog", "display_name": "Склады"},
    &"industrial": {"primary": Color("#5a4a3a"), "secondary": Color("#8a7a5a"), "accent": Color("#e85d3a"), "sky": Color("#a09080"), "fog": Color("#c0b0a0"), "ambient": Color("#484038"), "music": "res://assets/audio/music/industrial.wav", "weather": "fog", "display_name": "Промзона"},
    &"substation": {"primary": Color("#5a5a5a"), "secondary": Color("#8a8a8a"), "accent": Color("#f4f45d"), "sky": Color("#b0b0b0"), "fog": Color("#c8c8c8"), "ambient": Color("#484848"), "music": "res://assets/audio/music/industrial.wav", "weather": "fog", "display_name": "Подстанция"},
    &"power_station": {"primary": Color("#5a5a5a"), "secondary": Color("#8a8a8a"), "accent": Color("#f4f45d"), "sky": Color("#b0b0b0"), "fog": Color("#c8c8c8"), "ambient": Color("#484848"), "music": "res://assets/audio/music/industrial.wav", "weather": "fog", "display_name": "Станция"},
}
func _ready() -> void: pass
func get_theme(district_id: StringName) -> Dictionary:
    return THEMES.get(district_id, THEMES[&"suburbs"])
func get_district_color(district_id: StringName) -> Color:
    var t: Dictionary = get_theme(district_id)
    return t.get("accent", Color.WHITE)
func apply_to_environment(env: Environment, district_id: StringName) -> void:
    var t: Dictionary = get_theme(district_id)
    env.background_color = t.get("sky", Color.BLACK)
    env.ambient_light_color = t.get("ambient", Color.BLACK)
    env.ambient_light_energy = 0.5
    env.fog_enabled = true
    env.fog_light_color = t.get("fog", Color.GRAY)
    env.fog_density = 0.005
func register(district_id: StringName, theme: Dictionary) -> void: pass
func get(district_id: StringName) -> Dictionary: return get_theme(district_id)
func has(district_id: StringName) -> bool: return THEMES.has(district_id)
func list_ids() -> Array[StringName]: return THEMES.keys()
func set_current(district_id: StringName) -> void:
    current_id = district_id
    theme_changed.emit(district_id)
var current_id: StringName = &"suburbs"
func color_of(district_id: StringName, key: StringName) -> Color:
    return get(district_id).get(key, Color.WHITE)
'@ | Set-Content -Path "scripts\world\district_themes.gd" -Encoding UTF8

# === city_decorator.gd ===
@'
extends Node3D
class_name CityDecorator
@export var district_id: StringName = &""
@export var street_builder_path: NodePath
@export var density: float = 1.0
@export var seed: int = 0
@onready var _street: StreetBuilder = get_node_or_null(street_builder_path) as StreetBuilder
var _rng := RandomNumberGenerator.new()
func _ready() -> void:
    if seed == 0: seed = hash(str(district_id))
    _rng.seed = seed
    if _street == null: return
    if not _street.streets_ready.is_connected(_on_streets_ready):
        _street.streets_ready.connect(_on_streets_ready)
    if _street.roads.size() > 0: _on_streets_ready()
func _on_streets_ready() -> void:
    if _street.roads.is_empty(): return
    var total := int(24 * density)
    for i in total:
        var mm := MultiMeshInstance3D.new()
        mm.name = "Prop_%d" % i
        mm.multimesh = MultiMesh.new()
        mm.multimesh.transform_format = MultiMesh.TRANSFORM_3D
        mm.multimesh.mesh = _make_box_mesh(Color(0.3, 0.3, 0.3))
        mm.multimesh.instance_count = 1
        add_child(mm)
        mm.multimesh.set_instance_transform(0, _random_transform())
func _make_box_mesh(color: Color) -> BoxMesh:
    var m := BoxMesh.new()
    m.size = Vector3(0.5, 1.0, 0.5)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    m.material = mat
    return m
func _random_transform() -> Transform3D:
    var road: Dictionary = _street.roads[_rng.randi() % _street.roads.size()]
    var steps := int(road.length / _street.tile_size)
    var s := _rng.randi() % max(1, steps)
    var pos := _street.road_step_pos(road, s)
    var side: float = [-1.0, 1.0][_rng.randi() % 2]
    var off := _street.road_width * 0.5 + 1.0
    var lateral := Vector3(0, 0, off * side) if road.dir == "h" else Vector3(off * side, 0, 0)
    var t := Transform3D()
    t.origin = pos + lateral
    t = t.rotated_local(Vector3.UP, _rng.randf() * TAU)
    return t
'@ | Set-Content -Path "scripts\world\city_decorator.gd" -Encoding UTF8

# === weather_vfx.gd ===
@'
extends Node3D
class_name WeatherVFX
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
    if auto: set_weather(WeatherVFX.random_for(district_id))
    else: set_weather(initial)
func set_weather(w: Weather) -> void:
    if current == w: return
    _apply(current, false)
    current = w
    _apply(current, true)
func _process(_delta: float) -> void: pass
func _apply(w: Weather, on: bool) -> void:
    match w:
        Weather.RAIN: if _rain: _rain.emitting = on
        Weather.SNOW: if _snow: _snow.emitting = on
        Weather.FOG: if _fog: _fog.emitting = on
    if on and _env and _env.environment: _apply_env(w)
func _apply_env(w: Weather) -> void:
    var e := _env.environment
    var theme: Dictionary = DistrictThemes.get(district_id) if DistrictThemes.has(district_id) else {}
    var fog_color: Color = theme.get("fog", Color("#cccccc"))
    match w:
        Weather.CLEAR: e.fog_enabled = false; e.fog_density = 0.0
        Weather.OVERCAST: e.fog_enabled = false
        Weather.RAIN: e.fog_enabled = true; e.fog_density = 0.01; e.fog_light_color = fog_color.darkened(0.1)
        Weather.SNOW: e.fog_enabled = true; e.fog_density = 0.015; e.fog_light_color = Color("#e8eef4")
        Weather.FOG: e.fog_enabled = true; e.fog_density = 0.04; e.fog_light_color = fog_color
static func random_for(district_id: StringName) -> Weather:
    var rng := RandomNumberGenerator.new()
    rng.seed = hash(str(district_id)) + Time.get_ticks_msec()
    var roll := rng.randf()
    if roll < 0.5: return Weather.CLEAR
    if roll < 0.7: return Weather.OVERCAST
    if roll < 0.85: return Weather.RAIN
    if roll < 0.95: return Weather.SNOW
    return Weather.FOG
'@ | Set-Content -Path "scripts\effects\weather_vfx.gd" -Encoding UTF8

# === gen_district_music.py ===
@'
#!/usr/bin/env python3
import argparse, math, os, random, struct, wave
DISTRICTS = [
    ("downtown", 110.0, [0,2,4,5,7,9,11], 90, 3, "warm_major"),
    ("industrial", 73.4, [0,1,4,5,7,8,10], 70, 4, "dark_drone"),
    ("residential", 98.0, [0,2,4,7,9], 85, 2, "soft_pad"),
    ("park", 65.4, [0,2,4,7,9,11], 75, 3, "natural"),
    ("harbor", 82.4, [0,2,3,5,7,8,10], 80, 3, "breezy"),
    ("default", 87.3, [0,3,5,7,10], 80, 2, "neutral"),
]
SR = 22050
def note_hz(root, scale, degree):
    semis = scale[degree % len(scale)] + 12 * (degree // len(scale))
    return root * (2.0 ** (semis / 12.0))
def synth_sample(t, f, mood, rng):
    base = math.sin(2 * math.pi * f * t)
    if mood == "dark_drone": return base * 0.6 + math.sin(2 * math.pi * f * 1.5 * t) * 0.3 + (rng.random() * 2 - 1) * 0.05
    if mood == "warm_major": return base * 0.7 + math.sin(2 * math.pi * f * 2 * t) * 0.2
    if mood == "soft_pad": return base * 0.5 + math.sin(2 * math.pi * f * 0.5 * t) * 0.4
    if mood == "natural": return base * 0.6 + math.sin(2 * math.pi * (f + rng.uniform(-0.5, 0.5)) * t) * 0.3
    if mood == "breezy": return base * 0.5 + math.sin(2 * math.pi * f * 1.25 * t) * 0.2 + (rng.random() * 2 - 1) * 0.04
    return base * 0.6
def synth_track(d, seconds):
    district_id, root, scale, bpm, drone_count, mood = d
    beat = 60.0 / bpm
    bar = beat * 4
    n_bars = max(1, int(seconds / bar))
    total = n_bars * bar
    n = int(total * SR)
    freqs = [note_hz(root, scale, i * 7 % 24) for i in range(drone_count)]
    melody = [note_hz(root * 2, scale, (b * 2 + 1) % len(scale)) for b in range(n_bars)]
    rng = random.Random(int(root * 1000) & 0xFFFFFFFF)
    out = [0.0] * n
    for f in freqs:
        amp = 0.18 / max(1, len(freqs))
        for i in range(n):
            t = i / SR
            env = min(1.0, t * 2.0) * min(1.0, (total - t) * 2.0)
            out[i] += synth_sample(t, f, mood, rng) * amp * env
    for bi, f in enumerate(melody):
        amp = 0.12
        start = int(bi * bar * SR)
        end = min(n, start + int(bar * SR))
        for i in range(start, end):
            t = (i - start) / SR
            env = min(1.0, t * 4.0) * min(1.0, (bar - t) * 4.0)
            out[i] += synth_sample(t, f, mood, rng) * amp * env
    peak = max(1e-6, max(abs(x) for x in out))
    return [max(-1.0, min(1.0, x / peak * 0.85)) for x in out]
def write_wav(path, samples):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32767)) for s in samples))
def main():
    p = argparse.ArgumentParser()
    p.add_argument("--out", default="assets/audio/music")
    p.add_argument("--seconds", type=float, default=24.0)
    args = p.parse_args()
    os.makedirs(args.out, exist_ok=True)
    for d in DISTRICTS:
        samples = synth_track(d, args.seconds)
        path = os.path.join(args.out, d[0] + ".wav")
        write_wav(path, samples)
        print("WROTE " + path)
    print("Done.")
if __name__ == "__main__": main()
'@ | Set-Content -Path "scripts\tools\gen_district_music.py" -Encoding UTF8

Write-Host "=== ШАГ 3: Создание заглушек мешей ===" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "meshes\street" | Out-Null
New-Item -ItemType Directory -Force -Path "meshes\props" | Out-Null

# road_tile.tres
@'
[gd_resource type="BoxMesh" format=3]
[resource]
size = Vector3(4, 0.1, 4)
'@ | Set-Content -Path "meshes\street\road_tile.tres" -Encoding UTF8

# sidewalk_tile.tres
@'
[gd_resource type="BoxMesh" format=3]
[resource]
size = Vector3(4, 0.15, 1.5)
'@ | Set-Content -Path "meshes\street\sidewalk_tile.tres" -Encoding UTF8

# lane_mark.tres
@'
[gd_resource type="BoxMesh" format=3]
[resource]
size = Vector3(2, 0.02, 0.2)
'@ | Set-Content -Path "meshes\street\lane_mark.tres" -Encoding UTF8

Write-Host "=== ШАГ 4: Модификация district .tscn (добавление MultiMeshInstance3D) ===" -ForegroundColor Cyan
foreach ($d in $districts) {
  @"
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/world/district_scene_factory.gd" id="1_factory"]
[node name="District_$d" type="Node3D"]
script = ExtResource("1_factory")
[node name="RoadMM" type="MultiMeshInstance3D" parent="."]
[node name="SidewalkMM" type="MultiMeshInstance3D" parent="."]
[node name="MarkingMM" type="MultiMeshInstance3D" parent="."]
[node name="Rain" type="GPUParticles3D" parent="."]
[node name="Snow" type="GPUParticles3D" parent="."]
[node name="FogDrops" type="GPUParticles3D" parent="."]
[node name="Meta" type="Node" parent="."]
[node name="district_id" type="Node" parent="Meta"]
"@ | Set-Content -Path "scenes\world\districts\$d.tscn" -Encoding UTF8
}

Write-Host "=== ШАГ 5: Патч music_manager.gd ===" -ForegroundColor Cyan
$mm_path = "scripts\systems\music_manager.gd"
if (Test-Path $mm_path) {
    $content = Get-Content $mm_path -Raw
    if ($content -notmatch "_on_district_theme_changed") {
        $patch = @"

var _active_player: AudioStreamPlayer
var _next_player: AudioStreamPlayer
var _pending_fade: bool = false
var _fade_t: float = 0.0
var _fade_duration: float = 2.0
var _current_track: String = ""

func _on_district_theme_changed(district_id: StringName) -> void:
	var theme: Dictionary = DistrictThemes.get(district_id)
	var path: String = theme.get("music", "")
	if path == _current_track: return
	_current_track = path
	if path == "" or not ResourceLoader.exists(path): return
	if _active_player == null:
		_active_player = AudioStreamPlayer.new()
		_active_player.bus = "Music"
		add_child(_active_player)
	_next_player = AudioStreamPlayer.new()
	_next_player.bus = "Music"
	_next_player.stream = load(path)
	_next_player.volume_db = -60.0
	add_child(_next_player)
	_next_player.play()
	_pending_fade = true
	_fade_t = 0.0
"@
        $content += $patch
        Set-Content -Path $mm_path -Value $content -Encoding UTF8 -NoNewline
    }
}

Write-Host "=== ШАГ 6: Установка Python и генерация музыки ===" -ForegroundColor Cyan
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Устанавливаю Python..." -ForegroundColor Yellow
    winget install --id Python.Python.3.12 -e --accept-source-agreements --accept-package-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}
python scripts\tools\gen_district_music.py --out assets\audio\music

Write-Host "=== ШАГ 7: Добавление DistrictThemes в autoload ===" -ForegroundColor Cyan
if ((Get-Content project.godot -Raw) -notmatch "DistrictThemes=") {
    Add-Content project.godot "`nDistrictThemes=`"*res://scripts/world/district_themes.gd`""
}

Write-Host "=== ШАГ 8: Git commit и push ===" -ForegroundColor Cyan
git add -A
git commit -m "district UI: streets, themes, decorator, weather, per-district music"
git push

Write-Host "=== ГОТОВО! ===" -ForegroundColor Green
Write-Host "Открой Godot, нажми F5, проверь районы." -ForegroundColor Cyan