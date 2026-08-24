extends Node3D
class_name CityStreetProps
## Reads StreetBuilder.roads, spawns poles+lamps+benches+trees+cones per theme.

@export var street_builder_path: NodePath
@export var density: float = 1.0
@export var random_seed: int = 0

var _rng := RandomNumberGenerator.new()
var _pole: CylinderMesh
var _lamp: SphereMesh
var _bench: BoxMesh
var _trunk: CylinderMesh
var _leaf: SphereMesh
var _cone: CylinderMesh

## P2 (THEME UNIFICATION wave): same batching for the other static,
## never-reactive props street_props.gd spawns - benches/trees/cones never
## change appearance after spawn (no signal hookups, no _process), so like
## the streetlights they're pure MultiMesh candidates.
var _bench_positions: Array[Vector3] = []
var _tree_positions: Array[Vector3] = []
var _cone_positions: Array[Vector3] = []

## P3: local-space positions of every streetlight_3d.tscn instance spawned
## this build() pass, so their static Pole/Lamp meshes can be batched into
## two MultiMeshInstance3D draw calls afterwards instead of 2 draw calls
## PER lamp (RESCUE WAVE measured 370 draw calls/scene; this was the
## identified but previously-unfixed root cause).
var _lamp_local_positions: Array[Vector3] = []

const _TEX_BRICK       := "res://assets/textures/environment/brick.png"
const _TEX_RUSTY_METAL := "res://assets/textures/environment/rusty_metal.png"
const _TEX_STREETLIGHT := "res://assets/textures/surfaces/streetlight_metal_512.png"
const _TEX_BENCH       := "res://assets/textures/surfaces/bench_wood_512.png"

## Returns a StandardMaterial3D with albedo_texture loaded from path.
## Falls back to albedo_color if the texture file is missing.
static func _wall_material(tex_path: String, fallback_color: Color) -> StandardMaterial3D:
	return _prop_material(tex_path, fallback_color, 0.9, 0.0)

## Same idea as _wall_material() but for props: optional texture, always a
## deliberate roughness/metallic so nothing renders at the engine's flat-grey
## default (roughness 1 / metallic 0 / albedo ~0.8,0.8,0.8).
static func _prop_material(tex_path: String, fallback_color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = fallback_color
	if not tex_path.is_empty():
		var tex: Texture2D = load(tex_path)
		if tex:
			mat.albedo_texture = tex
	mat.roughness = roughness
	mat.metallic = metallic
	return mat

func _ready() -> void:
	_rng.seed = random_seed if random_seed != 0 else hash(str(global_position))
	_init_meshes()
	call_deferred("build")

func _init_meshes() -> void:
	_pole = CylinderMesh.new()
	_pole.top_radius = 0.06
	_pole.bottom_radius = 0.08
	_pole.height = 4.0
	_lamp = SphereMesh.new()
	_lamp.radius = 0.18
	_lamp.height = 0.36
	_bench = BoxMesh.new()
	_bench.size = Vector3(1.6, 0.4, 0.5)
	_trunk = CylinderMesh.new()
	_trunk.top_radius = 0.12
	_trunk.bottom_radius = 0.18
	_trunk.height = 2.5
	_leaf = SphereMesh.new()
	_leaf.radius = 1.2
	_leaf.height = 2.4
	_cone = CylinderMesh.new()
	_cone.top_radius = 0.0
	_cone.bottom_radius = 0.35
	_cone.height = 0.7

## P2 (EMISSIVE FIX + PERF wave): D1 draw calls measured 234 with full
## density on every tier - benches/trees/cones are the only remaining
## lever (poles are the namesake prop, streetlights already batched).
## LOW skips every other candidate slot (s % 2) rather than truncating
## the finished array, so spacing along the street stays even instead
## of leaving one dense half and one empty half. MED/HIGH/ULTRA unchanged.
var _low_tier: bool = false

func build() -> void:
	var sb: Node = get_node_or_null(street_builder_path)
	if sb == null:
		return
	_low_tier = int(SettingsManager.get_setting("graphics_tier", 2)) == 0
	var district_id: StringName = sb.get("district_id") if "district_id" in sb else &""
	var step: int = 4
	for road in sb.roads:
		var length: float = float(road.get("length", 0.0))
		var count: int = max(1, int(length / (float(step) * 4.0)))
		for s in range(count):
			var pos: Vector3 = sb.road_step_pos(road, s * step)
			_spawn_pole_pair(pos, road, district_id)
			var slot_ok: bool = not _low_tier or s % 2 == 0
			if slot_ok and _rng.randf() < 0.30 * density:
				_spawn_bench(pos, road)
			if slot_ok and _rng.randf() < 0.25 * density:
				_spawn_tree(pos, road)
			if slot_ok and _rng.randf() < 0.15 * density:
				_spawn_cone(pos, road)
	_build_streetlight_multimesh()
	_build_prop_multimesh()

func _side_offset(road: Dictionary, dist: float) -> Vector3:
	var dir: String = String(road.get("dir", "h"))
	return Vector3(0.0, 0.0, dist) if dir == "h" else Vector3(dist, 0.0, 0.0)

## streetlight_3d.tscn (real pole mesh, SpotLight3D+OmniLight3D, hum audio,
## visibility Area3D, and — the point of switching to it — a live
## EventBus.district_stage_changed hookup) already existed unwired the
## whole time; this file's own poles were flat emissive decals with no
## actual Light3D and never reacted to district power stage at all, which
## quietly broke the game's namesake "darkness -> restored power" beat.
## See docs/KNOWN_ISSUES.md. legacy_streetlights=true restores the old
## decals if the real prop ever needs to be bypassed again.
const _STREETLIGHT_3D := preload("res://scenes/props/streetlight_3d.tscn")

func _spawn_pole_pair(center: Vector3, road: Dictionary, district_id: StringName) -> void:
	if ProjectSettings.get_setting("world/legacy_streetlights", false):
		_spawn_pole_pair_legacy(center, road)
		return
	var perp: Vector3 = _side_offset(road, 3.5)
	for side in [-1, 1]:
		var l: Node3D = _STREETLIGHT_3D.instantiate()
		l.set("district_id", district_id)
		l.set("mesh_visible", false)
		l.position = center + perp * float(side)
		add_child(l)
		_lamp_local_positions.append(l.position)

## P3: matches streetlight_3d.tscn's Pole/Lamp mesh+material exactly so the
## batched version is visually identical to the per-instance one it replaces.
const _POLE_MESH := preload("res://assets/mesh/mesh_streetlight_pole.res")
const _LAMP_HEAD_OFFSET := Vector3(1.16, 4.2, 0.0)

func _build_streetlight_multimesh() -> void:
	if _lamp_local_positions.is_empty():
		return
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.165, 0.200, 0.251, 1.0)
	var pole_mm := MultiMesh.new()
	pole_mm.transform_format = MultiMesh.TRANSFORM_3D
	pole_mm.mesh = _POLE_MESH
	pole_mm.instance_count = _lamp_local_positions.size()
	var lamp_mesh := SphereMesh.new()
	lamp_mesh.radius = 0.08
	lamp_mesh.height = 0.12
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(0.788, 0.635, 0.290, 1.0)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1.0, 0.82, 0.48, 1.0)
	lamp_mat.emission_energy_multiplier = 1.6
	var lamp_mm := MultiMesh.new()
	lamp_mm.transform_format = MultiMesh.TRANSFORM_3D
	lamp_mm.mesh = lamp_mesh
	lamp_mm.instance_count = _lamp_local_positions.size()
	for i in _lamp_local_positions.size():
		var pos: Vector3 = _lamp_local_positions[i]
		pole_mm.set_instance_transform(i, Transform3D(Basis(), pos))
		lamp_mm.set_instance_transform(i, Transform3D(Basis(), pos + _LAMP_HEAD_OFFSET))
	var pole_mmi := MultiMeshInstance3D.new()
	pole_mmi.name = "StreetlightPolesBatched"
	pole_mmi.multimesh = pole_mm
	pole_mmi.material_override = pole_mat
	add_child(pole_mmi)
	var lamp_mmi := MultiMeshInstance3D.new()
	lamp_mmi.name = "StreetlightLampsBatched"
	lamp_mmi.multimesh = lamp_mm
	lamp_mmi.material_override = lamp_mat
	add_child(lamp_mmi)

func _spawn_pole_pair_legacy(center: Vector3, road: Dictionary) -> void:
	var perp: Vector3 = _side_offset(road, 3.5)
	for side in [-1, 1]:
		var p := MeshInstance3D.new()
		p.mesh = _pole
		p.material_override = _prop_material(_TEX_STREETLIGHT, Color(0.15, 0.15, 0.18), 0.55, 0.6)
		p.position = center + perp * float(side)
		add_child(p)
		var l := MeshInstance3D.new()
		l.mesh = _lamp
		var lm := StandardMaterial3D.new()
		lm.albedo_color = Color(1.0, 0.92, 0.75)
		lm.emission_enabled = true
		lm.emission = Color(1.0, 0.85, 0.55)
		lm.emission_energy_multiplier = 2.0
		l.material_override = lm
		l.position = p.position + Vector3(0.0, 2.2, 0.0)
		add_child(l)

func _spawn_bench(center: Vector3, road: Dictionary) -> void:
	_bench_positions.append(center + _side_offset(road, 2.8))

func _spawn_tree(center: Vector3, road: Dictionary) -> void:
	_tree_positions.append(center + _side_offset(road, 2.8))

func _spawn_cone(center: Vector3, road: Dictionary) -> void:
	_cone_positions.append(center + _side_offset(road, 2.4))

func _build_prop_multimesh() -> void:
	_build_one_multimesh(_bench_positions, _bench,
		_prop_material(_TEX_BENCH, Color(0.35, 0.25, 0.15), 0.85, 0.0), "BenchesBatched")
	if not _tree_positions.is_empty():
		_build_one_multimesh(_tree_positions, _trunk,
			_prop_material("", Color(0.3, 0.18, 0.08), 0.95, 0.0), "TreeTrunksBatched")
		var leaf_positions: Array[Vector3] = []
		for p in _tree_positions:
			leaf_positions.append(p + Vector3(0.0, 1.8, 0.0))
		_build_one_multimesh(leaf_positions, _leaf,
			_prop_material("", Color(0.15, 0.45, 0.18), 0.9, 0.0), "TreeLeavesBatched")
	if not _cone_positions.is_empty():
		var cone_mat := _prop_material("", Color(1.0, 0.55, 0.1), 0.6, 0.0)
		cone_mat.emission_enabled = true
		cone_mat.emission = Color(1.0, 0.45, 0.05)
		cone_mat.emission_energy_multiplier = 0.6
		_build_one_multimesh(_cone_positions, _cone, cone_mat, "ConesBatched")

func _build_one_multimesh(positions: Array[Vector3], mesh: Mesh, material: Material, node_name: String) -> void:
	if positions.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = positions.size()
	for i in positions.size():
		mm.set_instance_transform(i, Transform3D(Basis(), positions[i]))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = material
	add_child(mmi)

## Convenience: build a wall MeshInstance3D with brick or rusty_metal texture.
## Call from a building-spawner script: CityStreetProps.make_wall_mesh(...)
static func make_wall_mesh(use_brick: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	mi.material_override = _wall_material(
		_TEX_BRICK if use_brick else _TEX_RUSTY_METAL,
		Color(0.45, 0.32, 0.25) if use_brick else Color(0.35, 0.22, 0.18)
	)
	return mi
