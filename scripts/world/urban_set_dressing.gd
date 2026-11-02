extends Node3D
## Curated street clutter beyond litter and bins: wrecks, pallets, pipes, cabinets, barriers, tyres,
## sacks and dead shrubs. Visual only, seeded, batched by kind, and kept clear of every interaction.

const _Parts := preload("res://scripts/art/part_mesh.gd")
const _PBR := preload("res://scripts/world/pbr_sets.gd")
const KEEP_CLEAR_M: float = 1.8

const KIT := {
	&"suburbs": {"wreck": 1, "pallets": 2, "pipes": 1, "cabinet": 1, "barrier": 2, "tyres": 1, "sacks": 1, "shrub": 4},
	&"residential": {"wreck": 2, "pallets": 2, "pipes": 2, "cabinet": 1, "barrier": 2, "tyres": 2, "sacks": 1, "shrub": 3},
	&"park": {"wreck": 0, "pallets": 1, "pipes": 0, "cabinet": 1, "barrier": 3, "tyres": 0, "sacks": 1, "shrub": 8},
	&"school": {"wreck": 1, "pallets": 2, "pipes": 1, "cabinet": 2, "barrier": 2, "tyres": 1, "sacks": 1, "shrub": 3},
	&"hospital": {"wreck": 1, "pallets": 1, "pipes": 1, "cabinet": 2, "barrier": 3, "tyres": 1, "sacks": 1, "shrub": 2},
	&"gas_station": {"wreck": 2, "pallets": 2, "pipes": 2, "cabinet": 2, "barrier": 2, "tyres": 3, "sacks": 2, "shrub": 1},
	&"police": {"wreck": 2, "pallets": 1, "pipes": 1, "cabinet": 2, "barrier": 3, "tyres": 1, "sacks": 1, "shrub": 2},
	&"warehouses": {"wreck": 2, "pallets": 4, "pipes": 3, "cabinet": 2, "barrier": 2, "tyres": 3, "sacks": 2, "shrub": 0},
	&"industrial": {"wreck": 3, "pallets": 3, "pipes": 5, "cabinet": 3, "barrier": 2, "tyres": 4, "sacks": 2, "shrub": 0},
	&"substation": {"wreck": 1, "pallets": 1, "pipes": 4, "cabinet": 3, "barrier": 3, "tyres": 1, "sacks": 1, "shrub": 0},
	&"power_station": {"wreck": 1, "pallets": 2, "pipes": 4, "cabinet": 3, "barrier": 3, "tyres": 2, "sacks": 1, "shrub": 0},
}

const LOOK := {
	"wreck": [Color(0.14, 0.15, 0.16), "rusted_metal", 1.4],
	"pallets": [Color(0.33, 0.24, 0.14), "plywood", 0.9],
	"pipes": [Color(0.27, 0.18, 0.14), "rusted_metal", 1.1],
	"cabinet": [Color(0.19, 0.22, 0.21), "rusted_metal", 0.7],
	"barrier": [Color(0.40, 0.33, 0.21), "plywood", 0.75],
	"tyres": [Color(0.055, 0.055, 0.06), "", 0.7],
	"sacks": [Color(0.18, 0.16, 0.12), "cracked_concrete", 0.75],
	"shrub": [Color(0.10, 0.085, 0.07), "", 0.8],
}

var _rng := RandomNumberGenerator.new()
var _mesh_cache: Dictionary = {}
var _mat_cache: Dictionary = {}

func build(district_id: StringName, sb: Node, clear: Array[Vector2], grid: float, inner: float) -> void:
	_rng.seed = hash("urban_set_" + String(district_id))
	var kit: Dictionary = KIT.get(district_id, KIT[&"suburbs"])
	var low: bool = int(SettingsManager.get_setting("graphics_tier", 2)) == 0
	var shadows := get_node_or_null("../../ContactShadows") as MultiMeshInstance3D  # the district's one board, made by StreetProps before this node
	for kind: String in kit:
		var count: int = int(kit[kind])
		if low:
			count = maxi(1, count / 2)
		var xforms: Array[Transform3D] = []
		var spots: Array[Vector3] = []
		for i in count:
			var at: Vector3 = _spot(clear, grid, inner)
			if at == Vector3.INF:
				continue
			var body := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), at)
			xforms.append(body)
			spots.append(at)
		if xforms.is_empty():
			continue
		_add_batch("Urban_" + kind.capitalize(), kind, xforms)
		if shadows != null:
			shadows.stamp_all(spots, 0.8 if kind in ["wreck", "pipes", "cabinet"] else 0.5)
	_street_clutter(sb, clear, low, shadows)

## A second, sparser layer on the walk itself: a service cabinet, a stack of pipes, sandbags or a barrier
## every few metres. These keep the camera's foreground readable without touching a route or an interaction.
func _street_clutter(sb: Node, clear: Array[Vector2], low: bool, shadows: MultiMeshInstance3D) -> void:
	var kinds: Array[String] = ["pallets", "pipes", "sacks", "tyres", "shrub"]  # low things only: a car, a cabinet or a barrier on the walk would be walked through, the layer has no collision
	var batches: Dictionary = {}
	var places: Dictionary = {}
	var chance: float = 0.12 if low else 0.28
	for road: Variant in sb.roads:
		var length: float = float((road as Dictionary).get("length", 0.0))
		var steps: int = maxi(1, int(length / 6.0))
		for step in steps:
			if _rng.randf() >= chance:
				continue
			var pos: Vector3 = sb.road_pos_at(road, float(step) * 6.0 + _rng.randf_range(0.0, 4.0))
			var side: float = -1.0 if _rng.randf() < 0.5 else 1.0
			var off: float = (float(sb.road_width) * 0.5 + 0.85) * side
			var at: Vector3
			var basis := Basis(Vector3.UP, _rng.randf_range(-0.16, 0.16))
			if String((road as Dictionary).get("dir", "h")) == "h":
				at = pos + Vector3(0.0, 0.06, off)
			else:
				at = pos + Vector3(off, 0.06, 0.0)
				basis = basis.rotated(Vector3.UP, PI * 0.5)
			if _blocked(Vector2(at.x, at.z), clear):
				continue
			var kind: String = kinds[_rng.randi() % kinds.size()]
			if not batches.has(kind):
				batches[kind] = []
				places[kind] = []
			(batches[kind] as Array).append(Transform3D(basis, at))
			(places[kind] as Array).append(at)
	for kind: String in batches:
		_add_batch("UrbanStreet_" + kind.capitalize(), kind, batches[kind] as Array[Transform3D])
		if shadows != null:
			var pts: Array[Vector3] = []
			for point: Variant in places[kind]:
				pts.append(point as Vector3)
			shadows.stamp_all(pts, 0.7 if kind in ["wreck", "pipes", "cabinet"] else 0.45)

func _blocked(at: Vector2, clear: Array[Vector2]) -> bool:
	for other in clear:
		if at.distance_to(other) < KEEP_CLEAR_M:
			return true
	return false

func _spot(clear: Array[Vector2], grid: float, inner: float) -> Vector3:
	for attempt in 12:
		var centre := Vector3(_rng.randi_range(-1, 1) * grid, 0.0, _rng.randi_range(-1, 1) * grid)
		var side := _rng.randi_range(0, 3)
		var reach: float = inner - _rng.randf_range(0.6, 1.4)
		var along: float = _rng.randf_range(-inner + 0.7, inner - 0.7)
		var at := Vector3.ZERO
		match side:
			0:
				at = centre + Vector3(along, 0.0, -reach)
			1:
				at = centre + Vector3(reach, 0.0, along)
			2:
				at = centre + Vector3(along, 0.0, reach)
			_:
				at = centre + Vector3(-reach, 0.0, along)
		var blocked := false
		for other in clear:
			if Vector2(at.x, at.z).distance_to(other) < KEEP_CLEAR_M:
				blocked = true
				break
		if not blocked:
			return Vector3(at.x, 0.06, at.z)
	return Vector3.INF

func _add_batch(node_name: String, kind: String, xforms: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _mesh(kind)
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = _material(kind)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if kind in ["wreck", "cabinet"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

func _material(kind: String) -> StandardMaterial3D:
	if _mat_cache.has(kind):
		return _mat_cache[kind]
	var look: Array = LOOK[kind]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = look[0]
	mat.roughness = 0.88
	mat.metallic = 0.08 if String(look[1]) == "rusted_metal" else 0.0
	mat = _PBR.apply(mat, String(look[1]))
	_mat_cache[kind] = mat
	return mat

func _mesh(kind: String) -> ArrayMesh:
	if _mesh_cache.has(kind):
		return _mesh_cache[kind]
	var p: Array = []
	match kind:
		"wreck":
			p = [
				_Parts.part(&"box", Vector3(4.2, 0.55, 1.9), Vector3(0, 0.62, 0)),
				_Parts.part(&"box", Vector3(2.3, 0.5, 1.7), Vector3(-0.2, 1.10, 0)),
				_Parts.part(&"box", Vector3(2.0, 0.26, 1.72), Vector3(-0.2, 1.16, 0)),
			]
			for x in [-1.35, 1.35]:
				for z in [-0.88, 0.88]:
					p.append(_Parts.part(&"cyl", Vector3(0.34, 0.24, 0.34), Vector3(x, 0.34, z), Vector3(90, 0, 0), 1))
			p.append(_Parts.part(&"box", Vector3(0.1, 0.22, 1.9), Vector3(-2.02, 0.43, 0)))
			p.append(_Parts.part(&"box", Vector3(0.1, 0.22, 1.9), Vector3(2.02, 0.43, 0)))
		"pallets":
			for i in 3:
				p.append(_Parts.part(&"box", Vector3(1.2, 0.07, 0.8), Vector3(0, 0.12 + i * 0.16, 0)))
			for x in [-0.5, 0.5]:
				for z in [-0.33, 0.33]:
					p.append(_Parts.part(&"box", Vector3(0.1, 0.1, 0.1), Vector3(x, 0.05, z)))
		"pipes":
			for i in 4:
				p.append(_Parts.part(&"cyl", Vector3(0.12, 2.4, 0.12), Vector3(0, 0.14 + i * 0.24, -0.42 + i * 0.28), Vector3(0, 0, 90)))
			p.append(_Parts.part(&"box", Vector3(0.18, 0.12, 1.5), Vector3(0, 0.06, 0)))
		"cabinet":
			p = [
				_Parts.part(&"box", Vector3(0.9, 1.5, 0.45), Vector3(0, 0.78, 0)),
				_Parts.part(&"box", Vector3(0.78, 1.24, 0.03), Vector3(0, 0.80, 0.24)),
				_Parts.part(&"box", Vector3(0.08, 0.16, 0.05), Vector3(0.32, 0.82, 0.27)),
				_Parts.part(&"cyl", Vector3(0.045, 1.1, 0.045), Vector3(-0.38, 1.28, -0.18)),
			]
			for i in 5:
				p.append(_Parts.part(&"box", Vector3(0.46, 0.035, 0.03), Vector3(0, 1.22 - i * 0.06, 0.26)))
			for x in [-0.32, 0.32]:
				p.append(_Parts.part(&"box", Vector3(0.12, 0.10, 0.12), Vector3(x, 0.05, 0)))
		"barrier":
			for x in [-0.85, 0.85]:
				p.append(_Parts.part(&"box", Vector3(0.1, 1.1, 0.45), Vector3(x, 0.55, 0)))
				p.append(_Parts.part(&"box", Vector3(0.16, 0.08, 0.7), Vector3(x, 0.04, 0)))
			for y in [0.35, 0.65, 0.95]:
				p.append(_Parts.part(&"box", Vector3(1.8, 0.15, 0.07), Vector3(0, y, 0)))
		"tyres":
			for i in 3:
				p.append(_Parts.part(&"tor", Vector3(0.24, 0.42, 0), Vector3(0, 0.16 + i * 0.18, 0), Vector3(90, 0, 0)))
		"sacks":
			p = [
				_Parts.part(&"sph", Vector3(0.5, 0.32, 0.4), Vector3(-0.22, 0.17, 0)),
				_Parts.part(&"sph", Vector3(0.45, 0.28, 0.38), Vector3(0.22, 0.15, 0.06)),
				_Parts.part(&"sph", Vector3(0.36, 0.24, 0.32), Vector3(0.0, 0.30, -0.03)),
			]
		"shrub":
			for i in 5:
				var angle: float = float(i) / 5.0 * TAU
				p.append(_Parts.part(&"cyl", Vector3(0.02, 0.9, 0.035),
					Vector3(cos(angle) * 0.18, 0.45, sin(angle) * 0.18), Vector3(18, rad_to_deg(angle), 0)))
			p.append(_Parts.part(&"cyl", Vector3(0.035, 0.55, 0.05), Vector3(0, 0.28, 0)))
	var built := _Parts.build(p)
	_mesh_cache[kind] = built
	return built
