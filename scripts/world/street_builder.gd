extends Node3D
class_name StreetBuilder

signal streets_ready

@export var district_id: StringName = &""
@export var tile_size: float = 2.0
@export var road_width: float = 6.0
@export var sidewalk_width: float = 2.0
@export var lane_mark_spacing: float = 2.0
## The markings are whole tiles lying on the road tiles: at the same height they z-fought, which drew stacked dark stripes and
## wedges wherever the lamp or the flashlight lit the road (the first screen of a game).
const MARKING_LIFT: float = 0.02
## Height of every street tile, mesh and collision box alike.
const TILE_THICKNESS: float = 0.1
## Шаг сетки кварталов в метрах. roads хранит перекрёстки в клетках (0..3),
## и без умножения на этот шаг четыре параллельные улицы ложились на
## z = 0,1,2,3 — то есть слипались в одну полосу шириной 3 метра вместо
## квартальной сетки 48x48 м.
@export var grid_spacing: float = 16.0
@export var prop_seed: int = 0

var roads: Array[Dictionary] = []
var _center: Vector2 = Vector2.ZERO
## Milliseconds the deferred build() took, for WorldRuntime.get_last_load_stats().
var build_ms: float = 0.0

var _road_mm: MultiMeshInstance3D
var _sidewalk_mm: MultiMeshInstance3D
var _marking_mm: MultiMeshInstance3D
var _curb_mm: MultiMeshInstance3D
var _damage_mm: MultiMeshInstance3D
var _collision: StaticBody3D
var _surfaces: Array[ShaderMaterial] = []

## WAVE 6 P4: registers the item that fuels scripts/generator.gd
## (gas_station.tscn's GasGenerator instance) - previously no constant
## existed anywhere naming the real fuel item at all.
const GENERATOR_FUEL: StringName = &"gas_canister"

const _TEX_ASPHALT   := "res://assets/textures/environment/asphalt.png"
const _TEX_CONCRETE  := "res://assets/textures/environment/concrete.png"
const _ROAD := preload("res://assets/shaders/soviet_road.gdshader")
## A lane dash: 1.2 m of paint every 2 m (lane_mark_spacing), 16 cm wide.
const MARK_LENGTH: float = 1.2
const MARK_WIDTH: float = 0.16

func _ready() -> void:
	_ensure_mm()
	if prop_seed == 0:
		prop_seed = hash(str(district_id))
	_init_mm(_road_mm,     _make_road_mesh())
	_init_mm(_sidewalk_mm, _make_sidewalk_mesh())
	_init_mm(_marking_mm,  _make_marking_mesh())
	_init_mm(_curb_mm,     _make_curb_mesh())
	_init_mm(_damage_mm,   _make_damage_mesh())
	_set_detail()
	EventBus.settings_changed.connect(_set_detail)
	call_deferred("build")

func _make_road_mesh() -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(tile_size, TILE_THICKNESS, tile_size)
	m.material = _surface(_TEX_ASPHALT, Vector3(0.110, 0.115, 0.125), 0.0316, 0.0, 2.0)
	return m

func _make_sidewalk_mesh() -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(tile_size, TILE_THICKNESS, tile_size)
	m.material = _surface(_TEX_CONCRETE, Vector3(0.115, 0.120, 0.115), 0.1156, 0.0, 1.0)
	return m

func _make_marking_mesh() -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(MARK_LENGTH, TILE_THICKNESS, MARK_WIDTH)
	m.material = _surface("", Vector3(0.45, 0.43, 0.36), 1.0, 1.0, 0.0)
	return m

func _make_curb_mesh() -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(tile_size, 0.17, 0.22)
	m.material = _surface(_TEX_CONCRETE, Vector3(0.125, 0.130, 0.125), 0.1156, 0.0, 1.0)
	return m

func _make_damage_mesh() -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(2.2, 0.012, 0.9)
	m.material = _surface(_TEX_ASPHALT, Vector3(0.052, 0.058, 0.064), 0.0316, 0.0, 2.0)
	return m

## One surface of the street: its texture (none for the paint), its mean albedo in linear light, the texture's mean luminance and the kind of wear it carries (`surface` of the road shader: 1 slabs, 2 asphalt); `detail` follows the graphics tier.
func _surface(texture_path: String, tint: Vector3, mean_lum: float, paint: float, surface: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _ROAD
	if texture_path != "" and ResourceLoader.exists(texture_path):
		mat.set_shader_parameter("tex", load(texture_path))
	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("mean_lum", mean_lum)
	mat.set_shader_parameter("paint", paint)
	mat.set_shader_parameter("surface", surface)
	_surfaces.append(mat)
	return mat

func _set_detail(key: String = "graphics_tier", _value: Variant = null) -> void:
	if key == "graphics_tier":
		var detail := float(clampi(int(SettingsManager.get_setting("graphics_tier", 2)), 0, 2))
		for mat: ShaderMaterial in _surfaces:
			mat.set_shader_parameter("detail", detail)

func _init_mm(mm: MultiMeshInstance3D, mesh: Mesh) -> void:
	mm.multimesh = MultiMesh.new()
	mm.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mm.multimesh.mesh = mesh

func build() -> void:
	var started: int = Time.get_ticks_usec()
	_layout()
	_fill_roads()
	_fill_sidewalks()
	_fill_markings()
	_fill_curbs()
	_fill_damage()
	build_ms = float(Time.get_ticks_usec() - started) / 1000.0
	streets_ready.emit()

func _layout() -> void:
	roads.clear()
	var cols := 3
	var rows := 3
	for r in range(rows + 1):
		roads.append({"start": Vector2i(0, r), "end": Vector2i(cols, r), "dir": "h", "length": float(cols) * grid_spacing})
	for c in range(cols + 1):
		roads.append({"start": Vector2i(c, 0), "end": Vector2i(c, rows), "dir": "v", "length": float(rows) * grid_spacing})
	_update_center()

## Точка на дороге по номеру плитки. Начало дороги переводится из клеток
## сетки в метры (× grid_spacing), иначе улицы строятся вплотную друг к другу.
func road_step_pos(road: Dictionary, step: int) -> Vector3:
	return road_pos_at(road, float(step) * tile_size)

## Точка на дороге по расстоянию от её начала в метрах.
## Сетка центрируется на нуле: лут (радиус 6..22 м) и точки появления врагов
## (±17 м) рассчитаны от начала координат района, а не от его угла.
func road_pos_at(road: Dictionary, distance_m: float) -> Vector3:
	var dir: Vector2 = (Vector2(road.end) - Vector2(road.start)).normalized()
	var p: Vector2 = Vector2(road.start) * grid_spacing + dir * distance_m - _center
	return Vector3(p.x, 0.01, p.y)

## Половина габарита квартальной сетки — сдвиг, центрирующий район на нуле.
## Считается один раз в _layout(): road_pos_at вызывается на каждую плитку.
func _update_center() -> void:
	var mx := 0.0
	var mz := 0.0
	for r in roads:
		mx = maxf(mx, float(r.end.x) * grid_spacing)
		mz = maxf(mz, float(r.end.y) * grid_spacing)
	_center = Vector2(mx, mz) * 0.5

func _fill_roads() -> void:
	# round, а не int: при road_width 6 м и плитке 4 м усечение давало одну
	# полосу вместо двух, и проезжая часть выходила уже тротуара.
	var lanes: int = maxi(1, int(round(road_width / tile_size)))
	var total := 0
	for r in roads:
		total += int(r.length / tile_size) * lanes
	_road_mm.multimesh.instance_count = total
	var idx := 0
	for r in roads:
		var steps := int(r.length / tile_size)
		var w := lanes
		for s in range(steps):
			var pos: Vector3 = road_step_pos(r, s)
			for wi in range(w):
				var off: float = -road_width * 0.5 + float(wi) * tile_size + tile_size * 0.5
				var t := Transform3D()
				t.origin = pos + (Vector3(0, 0, off) if r.dir == "h" else Vector3(off, 0, 0))
				if r.dir == "v":
					t.basis = t.basis.rotated(Vector3.UP, PI * 0.5)
				_road_mm.multimesh.set_instance_transform(idx, t)
				if s == 0:
					_create_collision(t.origin, r, steps, &"asphalt_dry")
				idx += 1

func _fill_sidewalks() -> void:
	# sidewalk_width (1.5 м) меньше плитки (4 м), поэтому int(1.5/4.0) давал 0
	# и тротуары не строились ни разу. Полоса всегда хотя бы одна.
	var lanes: int = maxi(1, int(round(sidewalk_width / tile_size)))
	var total := 0
	for r in roads:
		total += 2 * int(r.length / tile_size) * lanes
	_sidewalk_mm.multimesh.instance_count = total
	var idx := 0
	for r in roads:
		var steps := int(r.length / tile_size)
		var w := lanes
		for s in range(steps):
			var pos: Vector3 = road_step_pos(r, s)
			for side in [-1, 1]:
				for wi in range(w):
					var off: float = (road_width * 0.5 + sidewalk_width * 0.5 - float(wi) * tile_size) * float(side)
					var t := Transform3D()
					t.origin = pos + (Vector3(0, 0, off) if r.dir == "h" else Vector3(off, 0, 0))
					if r.dir == "v":
						t.basis = t.basis.rotated(Vector3.UP, PI * 0.5)
					_sidewalk_mm.multimesh.set_instance_transform(idx, t)
					if s == 0:
						_create_collision(t.origin, r, steps, &"concrete")
					idx += 1

## Разметка идёт со своим шагом, а не с шагом плитки дороги, и лежит над дорогой на MARKING_LIFT.
func marking_origin(road: Dictionary, step: int) -> Vector3:
	return road_pos_at(road, float(step) * lane_mark_spacing) + Vector3(0.0, MARKING_LIFT, 0.0)

func _fill_markings() -> void:
	var total := 0
	for r in roads:
		total += int(r.length / lane_mark_spacing)
	_marking_mm.multimesh.instance_count = total
	var idx := 0
	for r in roads:
		var count := int(r.length / lane_mark_spacing)
		for s in range(count):
			var t := Transform3D()
			t.origin = marking_origin(r, s)
			if r.dir == "v":
				t.basis = t.basis.rotated(Vector3.UP, PI * 0.5)
			_marking_mm.multimesh.set_instance_transform(idx, t)
			idx += 1

## Raised kerbs separate the road from the walk on every block edge; the gaps at crossings read as
## dropped kerbs and keep the old visual road grid from looking like one poured slab.
func _fill_curbs() -> void:
	var xforms: Array[Transform3D] = []
	var crossing := maxi(1, int(round(grid_spacing / tile_size)))
	for r in roads:
		var steps := int(r.length / tile_size)
		for s in range(steps):
			if s % crossing == 0:
				continue
			var pos: Vector3 = road_step_pos(r, s)
			for side in [-1.0, 1.0]:
				var off: float = (road_width * 0.5 + 0.11) * side
				var t := Transform3D()
				t.origin = pos + (Vector3(0.0, 0.115, off) if r.dir == "h" else Vector3(off, 0.115, 0.0))
				if r.dir == "v":
					t.basis = t.basis.rotated(Vector3.UP, PI * 0.5)
				xforms.append(t)
	_curb_mm.multimesh.instance_count = xforms.size()
	for i in xforms.size():
		_curb_mm.multimesh.set_instance_transform(i, xforms[i])

## Dark, shallow patches break the tiling of the asphalt without changing its collision or wetness.
func _fill_damage() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(district_id) + "_road_damage")
	var chance: float = [0.16, 0.26, 0.38][clampi(int(SettingsManager.get_setting("graphics_tier", 2)), 0, 2)]
	var xforms: Array[Transform3D] = []
	for r in roads:
		var steps := int(r.length / tile_size)
		for s in range(steps):
			if s % 4 == 0 or rng.randf() >= chance:
				continue
			var pos: Vector3 = road_step_pos(r, s)
			var off: float = rng.randf_range(-road_width * 0.42, road_width * 0.42)
			var t := Transform3D()
			t.origin = pos + (Vector3(0.0, 0.061, off) if r.dir == "h" else Vector3(off, 0.061, 0.0))
			t.basis = Basis(Vector3.UP, rng.randf_range(-0.10, 0.10))
			var scale: float = rng.randf_range(0.55, 1.35)
			t.basis = t.basis.scaled(Vector3(scale, 1.0, rng.randf_range(0.45, 0.95)))
			if r.dir == "v":
				t.basis = t.basis.rotated(Vector3.UP, PI * 0.5)
			xforms.append(t)
	_damage_mm.multimesh.instance_count = xforms.size()
	for i in xforms.size():
		_damage_mm.multimesh.set_instance_transform(i, xforms[i])

func _ensure_mm() -> void:
	if _road_mm == null:
		_road_mm = MultiMeshInstance3D.new()
		_road_mm.name = "RoadMM"
		add_child(_road_mm)
		_road_mm.add_child(preload("res://scripts/world/street_wetness.gd").new())  # W5: the road reads wet in rain
	if _sidewalk_mm == null:
		_sidewalk_mm = MultiMeshInstance3D.new()
		_sidewalk_mm.name = "SidewalkMM"
		add_child(_sidewalk_mm)
	if _marking_mm == null:
		_marking_mm = MultiMeshInstance3D.new()
		_marking_mm.name = "MarkingMM"
		add_child(_marking_mm)
	if _curb_mm == null:
		_curb_mm = MultiMeshInstance3D.new()
		_curb_mm.name = "CurbMM"
		add_child(_curb_mm)
	if _damage_mm == null:
		_damage_mm = MultiMeshInstance3D.new()
		_damage_mm.name = "RoadDamageMM"
		add_child(_damage_mm)

## One long box per lane strip instead of one body per tile (about 384 bodies per district): `first` is the origin of the
## strip's first tile and the box runs from it along the road over `steps` tiles. The strips share one StreetCollision body
## and are made from build(), deferred exactly as the tile bodies were.
func _create_collision(first: Vector3, road: Dictionary, steps: int, surface: StringName) -> void:
	if _collision == null:
		_collision = StaticBody3D.new()
		_collision.name = "StreetCollision"
		add_child(_collision)
	var horizontal: bool = road.dir == "h"
	var length: float = float(steps) * tile_size
	var box := BoxShape3D.new()
	box.size = Vector3(length, TILE_THICKNESS, tile_size) if horizontal else Vector3(tile_size, TILE_THICKNESS, length)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.set_meta(&"surface", surface)  # what the footsteps sound like (footstep_system.gd)
	shape.position = first + (Vector3.RIGHT if horizontal else Vector3.BACK) * (length - tile_size) * 0.5
	_collision.add_child(shape)
