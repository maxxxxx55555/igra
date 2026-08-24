extends Node3D
class_name StreetBuilder

signal streets_ready

@export var district_id: StringName = &""
@export var tile_size: float = 4.0
@export var road_width: float = 6.0
@export var sidewalk_width: float = 1.5
@export var lane_mark_spacing: float = 2.0
## Шаг сетки кварталов в метрах. roads хранит перекрёстки в клетках (0..3),
## и без умножения на этот шаг четыре параллельные улицы ложились на
## z = 0,1,2,3 — то есть слипались в одну полосу шириной 3 метра вместо
## квартальной сетки 48x48 м.
@export var grid_spacing: float = 16.0
@export var prop_seed: int = 0

var roads: Array[Dictionary] = []
var _center: Vector2 = Vector2.ZERO

var _road_mm: MultiMeshInstance3D
var _sidewalk_mm: MultiMeshInstance3D
var _marking_mm: MultiMeshInstance3D

## WAVE 6 P4: registers the item that fuels scripts/generator.gd
## (gas_station.tscn's GasGenerator instance) - previously no constant
## existed anywhere naming the real fuel item at all.
const GENERATOR_FUEL: StringName = &"gas_canister"

const _TEX_ASPHALT   := "res://assets/textures/environment/asphalt.png"
const _TEX_CONCRETE  := "res://assets/textures/environment/concrete.png"

func _ready() -> void:
	_ensure_mm()
	if prop_seed == 0:
		prop_seed = hash(str(district_id))
	_init_mm(_road_mm,     _make_road_mesh())
	_init_mm(_sidewalk_mm, _make_sidewalk_mesh())
	_init_mm(_marking_mm,  _make_box_mesh(Color(0.9, 0.9, 0.9)))
	call_deferred("build")

func _make_road_mesh() -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(tile_size, 0.1, tile_size)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.15)
	var tex: Texture2D = load(_TEX_ASPHALT)
	if tex:
		mat.albedo_texture = tex
	mat.roughness = 0.9
	m.material = mat
	return m

func _make_sidewalk_mesh() -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(tile_size, 0.1, tile_size)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.4)
	var tex: Texture2D = load(_TEX_CONCRETE)
	if tex:
		mat.albedo_texture = tex
	mat.roughness = 0.9
	m.material = mat
	return m

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
				_create_collision(t)
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
					var off: float = (road_width * 0.5 + sidewalk_width * 0.5 - float(wi) * tile_size - tile_size * 0.5) * float(side)
					var t := Transform3D()
					t.origin = pos + (Vector3(0, 0, off) if r.dir == "h" else Vector3(off, 0, 0))
					if r.dir == "v":
						t.basis = t.basis.rotated(Vector3.UP, PI * 0.5)
					_sidewalk_mm.multimesh.set_instance_transform(idx, t)
					_create_collision(t)
					idx += 1

func _fill_markings() -> void:
	var total := 0
	for r in roads:
		total += int(r.length / lane_mark_spacing)
	_marking_mm.multimesh.instance_count = total
	var idx := 0
	for r in roads:
		var count := int(r.length / lane_mark_spacing)
		for s in range(count):
			# Разметка идёт со своим шагом, а не с шагом плитки дороги.
			var pos: Vector3 = road_pos_at(r, float(s) * lane_mark_spacing)
			var t := Transform3D()
			t.origin = pos
			if r.dir == "v":
				t.basis = t.basis.rotated(Vector3.UP, PI * 0.5)
			_marking_mm.multimesh.set_instance_transform(idx, t)
			idx += 1

func _ensure_mm() -> void:
	if _road_mm == null:
		_road_mm = MultiMeshInstance3D.new()
		_road_mm.name = "RoadMM"
		add_child(_road_mm)
	if _sidewalk_mm == null:
		_sidewalk_mm = MultiMeshInstance3D.new()
		_sidewalk_mm.name = "SidewalkMM"
		add_child(_sidewalk_mm)
	if _marking_mm == null:
		_marking_mm = MultiMeshInstance3D.new()
		_marking_mm.name = "MarkingMM"
		add_child(_marking_mm)

func _create_collision(t: Transform3D) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(tile_size, 0.1, tile_size)
	shape.shape = box
	body.add_child(shape)
	body.transform = t
	add_child(body)
