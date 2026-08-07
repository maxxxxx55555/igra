# upgrade.ps1  --  THE_LAST_STREETLIGHT (Godot 4.7, GL Compat, Android)
# Part 1/3: light grid + visual pass. Run from project root AFTER restore_rest.ps1.

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-Utf8([string]$rel, [string]$content) {
	$full = Join-Path $root $rel
	$dir = Split-Path -Parent $full
	if (-not (Test-Path $dir)) { [void](New-Item -ItemType Directory -Force -Path $dir) }
	[System.IO.File]::WriteAllText($full, $content, $utf8)
	Write-Host ('WROTE    ' + $rel)
}

# ============================================================================
# LIGHT GRID  (autoload "LightGrid" -- single source of truth for "is lit?")
# Enemies query cell_brightness(); flashlights self-register via group "flashlight".
# ============================================================================
$light_grid = @'
extends Node
## Autoload "LightGrid". Tracks every OmniLight3D / SpotLight3D, exposes grid
## brightness for AI queries. Build lazily, refresh on register/unregister.

signal grid_rebuilt

const CELL_SIZE: float = 4.0

var _lights: Dictionary = {}
var _grid: Dictionary = {}
var _flashlights: Array[SpotLight3D] = []

func _ready() -> void:
	call_deferred("_initial_scan")

func _initial_scan() -> void:
	var roots := get_tree().get_nodes_in_group(&"world")
	for r in roots:
		_scan_recursive(r)
	_rebuild_grid()

func _scan_recursive(n: Node) -> void:
	if n is OmniLight3D or n is SpotLight3D:
		register_light(n)
	for c in n.get_children():
		_scan_recursive(c)

func register_light(n: Node3D) -> void:
	if n is SpotLight3D and n.is_in_group(&"flashlight"):
		_flashlights.append(n)
	var data: Dictionary = {
		"node": n,
		"pos": n.global_position,
		"range": _range_of(n),
		"intensity": _intensity_of(n),
	}
	_lights[n.get_instance_id()] = data
	_rebuild_grid()

func unregister_light(n: Node3D) -> void:
	var id := n.get_instance_id()
	if _lights.has(id):
		_lights.erase(id)
	if n is SpotLight3D:
		_flashlights.erase(n)
	_rebuild_grid()

func _range_of(n: Node3D) -> float:
	if n is OmniLight3D:
		return (n as OmniLight3D).omni_range
	if n is SpotLight3D:
		return (n as SpotLight3D).spot_range
	return 8.0

func _intensity_of(n: Node3D) -> float:
	if n is OmniLight3D:
		return (n as OmniLight3D).light_energy
	if n is SpotLight3D:
		return (n as SpotLight3D).light_energy
	return 1.0

func _process(_delta: float) -> void:
	var dirty: bool = false
	for id in _lights.keys():
		var data: Dictionary = _lights[id]
		var n: Node3D = data["node"] as Node3D
		if not is_instance_valid(n):
			_lights.erase(id)
			dirty = true
			continue
		data["pos"] = n.global_position
	if dirty:
		_rebuild_grid()

func _rebuild_grid() -> void:
	_grid.clear()
	var cs: float = CELL_SIZE
	for id in _lights.keys():
		var data: Dictionary = _lights[id]
		var pos: Vector3 = data["pos"]
		var rng_v: float = float(data["range"]) * float(data["intensity"])
		if rng_v <= 0.01:
			continue
		var min_x: int = int(floor((pos.x - rng_v) / cs))
		var max_x: int = int(ceil((pos.x + rng_v) / cs))
		var min_z: int = int(floor((pos.z - rng_v) / cs))
		var max_z: int = int(ceil((pos.z + rng_v) / cs))
		for cx in range(min_x, max_x + 1):
			for cz in range(min_z, max_z + 1):
				var cp: Vector3 = Vector3(float(cx) * cs + cs * 0.5, 0.0, float(cz) * cs + cs * 0.5)
				var d: float = cp.distance_to(pos)
				if d > rng_v:
					continue
				var fall: float = clamp(1.0 - d / rng_v, 0.0, 1.0)
				var key: Vector2i = Vector2i(cx, cz)
				_grid[key] = float(_grid.get(key, 0.0)) + fall * float(data["intensity"])
	grid_rebuilt.emit()

func cell_brightness(world_pos: Vector3) -> float:
	var key: Vector2i = Vector2i(int(floor(world_pos.x / CELL_SIZE)), int(floor(world_pos.z / CELL_SIZE)))
	return float(_grid.get(key, 0.0))

func is_lit(world_pos: Vector3, threshold: float = 0.3) -> bool:
	return cell_brightness(world_pos) >= threshold

func flashlight_dirs() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for f in _flashlights:
		if not is_instance_valid(f):
			continue
		out.append(-(f.global_transform.basis.z))
	return out

func nearest_flashlight(from: Vector3) -> Variant:
	var best_d: float = 1e9
	var best_pos: Vector3 = Vector3.ZERO
	var found: bool = false
	for f in _flashlights:
		if not is_instance_valid(f):
			continue
		var d: float = from.distance_to(f.global_position)
		if d < best_d:
			best_d = d
			best_pos = f.global_position
			found = true
	if found:
		return [best_pos, best_d]
	return null
'@
Write-Utf8 'scripts/lighting/light_grid.gd' $light_grid

# ============================================================================
# STREET PROPS  (procedural pole/bench/tree/cone -- no .tres assets needed)
# Drop CityStreetProps under each district root, wire street_builder_path.
# ============================================================================
$street_props = @'
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

func build() -> void:
	var sb: Node = get_node_or_null(street_builder_path)
	if sb == null:
		return
	var step: int = 4
	for road in sb.roads:
		var length: float = float(road.get("length", 0.0))
		var count: int = max(1, int(length / (float(step) * 4.0)))
		for s in range(count):
			var pos: Vector3 = sb.road_step_pos(road, s * step)
			_spawn_pole_pair(pos, road)
			if _rng.randf() < 0.30 * density:
				_spawn_bench(pos, road)
			if _rng.randf() < 0.25 * density:
				_spawn_tree(pos, road)
			if _rng.randf() < 0.15 * density:
				_spawn_cone(pos, road)

func _side_offset(road: Dictionary, dist: float) -> Vector3:
	var dir: String = String(road.get("dir", "h"))
	return Vector3(0.0, 0.0, dist) if dir == "h" else Vector3(dist, 0.0, 0.0)

func _spawn_pole_pair(center: Vector3, road: Dictionary) -> void:
	var perp: Vector3 = _side_offset(road, 3.5)
	for side in [-1, 1]:
		var p := MeshInstance3D.new()
		p.mesh = _pole
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(0.15, 0.15, 0.18)
		p.material_override = pm
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
	var b := MeshInstance3D.new()
	b.mesh = _bench
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.35, 0.25, 0.15)
	b.material_override = m
	b.position = center + _side_offset(road, 2.8)
	add_child(b)

func _spawn_tree(center: Vector3, road: Dictionary) -> void:
	var off: Vector3 = _side_offset(road, 2.8)
	var t := MeshInstance3D.new()
	t.mesh = _trunk
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color(0.3, 0.18, 0.08)
	t.material_override = tm
	t.position = center + off
	add_child(t)
	var l := MeshInstance3D.new()
	l.mesh = _leaf
	l.position = t.position + Vector3(0.0, 1.8, 0.0)
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(0.15, 0.45, 0.18)
	l.material_override = lm
	add_child(l)

func _spawn_cone(center: Vector3, road: Dictionary) -> void:
	var c := MeshInstance3D.new()
	c.mesh = _cone
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.55, 0.1)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.45, 0.05)
	m.emission_energy_multiplier = 0.6
	c.material_override = m
	c.position = center + _side_offset(road, 2.4)
	add_child(c)
'@
Write-Utf8 'scripts/world/street_props.gd' $street_props

# ============================================================================
# DISTRICT GRADING  (applies DistrictThemes tint/fog to WorldEnvironment)
# ============================================================================
$district_grading = @'
extends Node
## Per-district visual grading. Drives Environment tints + fog.
## Listens to DistrictThemes.theme_changed.

@export var world_environment_path: NodePath
@export var district_root_path: NodePath

var _env: WorldEnvironment
var _root: Node3D
var _ready_done: bool = false

func _ready() -> void:
	_env = get_node_or_null(world_environment_path) as WorldEnvironment
	_root = get_node_or_null(district_root_path) as Node3D
	if not DistrictThemes.theme_changed.is_connected(_apply):
		DistrictThemes.theme_changed.connect(_apply)
	_ready_done = true
	call_deferred("_apply", DistrictThemes.current_id)

func _apply(district_id: StringName) -> void:
	if not _ready_done:
		return
	var theme: Dictionary = DistrictThemes.get_theme(district_id)
	if _env != null and _env.environment != null:
		var e: Environment = _env.environment
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color(theme.get("sky", Color.BLACK))
		var fog: Color = Color(theme.get("fog", Color.GRAY))
		e.fog_enabled = true
		e.fog_color = fog
		e.fog_density = 0.012 if String(district_id) != "park" else 0.006
		e.ambient_light_color = Color(theme.get("ambient", Color.WHITE))
		e.ambient_light_energy = 0.4
		e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if _root != null:
		_apply_ground(_root, Color(theme.get("primary", Color.GRAY)))

func _apply_ground(root: Node3D, c: Color) -> void:
	for child in root.get_children():
		if child is MeshInstance3D and String((child as MeshInstance3D).name) == "Ground":
			var mi: MeshInstance3D = child
			var m := StandardMaterial3D.new()
			m.albedo_color = c
			m.roughness = 0.95
			mi.material_override = m
'@
Write-Utf8 'scripts/world/district_grading.gd' $district_grading

# ============================================================================
# EMISSIVE WINDOWS  (compat-safe: unshaded + emission, NO glow/SSAO/volumetrics)
# Walks MeshInstance3D walls under self, sticks lit window quads on random faces.
# ============================================================================
$emissive_windows = @'
extends Node3D
class_name EmissiveWindows

@export var window_count: int = 60
@export var random_seed: int = 0
@export var lit_chance: float = 0.65
@export var warm_color: bool = true

var _rng := RandomNumberGenerator.new()
var _win_mesh: QuadMesh
var _win_mat: StandardMaterial3D

func _ready() -> void:
	_rng.seed = random_seed if random_seed != 0 else hash(str(global_position))
	_win_mesh = QuadMesh.new()
	_win_mesh.size = Vector2(0.6, 0.9)
	_win_mat = StandardMaterial3D.new()
	_win_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if warm_color:
		_win_mat.albedo_color = Color(1.0, 0.85, 0.45)
		_win_mat.emission = Color(1.0, 0.78, 0.35)
	else:
		_win_mat.albedo_color = Color(0.75, 0.85, 1.0)
		_win_mat.emission = Color(0.55, 0.70, 1.0)
	_win_mat.emission_enabled = true
	_win_mat.emission_energy_multiplier = 1.6
	call_deferred("populate")

func populate() -> void:
	var walls: Array[MeshInstance3D] = []
	_collect_walls(self, walls)
	if walls.is_empty():
		return
	var n: int = mini(window_count, walls.size() * 6)
	for i in range(n):
		var w: MeshInstance3D = walls[_rng.randi_range(0, walls.size() - 1)]
		var aabb: AABB = w.get_aabb()
		if aabb.size.length() < 0.5:
			continue
		var face: int = _rng.randi_range(0, 3)
		var u: float = _rng.randf()
		var v: float = _rng.randf()
		var origin: Vector3 = aabb.position
		var basis: Basis = Basis()
		if face == 0:
			basis = Basis(Vector3.UP, 0.0) * Basis(Vector3.RIGHT, PI * 0.5)
			origin += Vector3(u * aabb.size.x, v * aabb.size.y, aabb.size.z)
		elif face == 1:
			basis = Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, PI * 0.5)
			origin += Vector3(u * aabb.size.x, v * aabb.size.y, 0.0)
		elif face == 2:
			basis = Basis(Vector3.UP, -PI * 0.5) * Basis(Vector3.RIGHT, PI * 0.5)
			origin += Vector3(aabb.size.x, v * aabb.size.y, u * aabb.size.z)
		else:
			basis = Basis(Vector3.UP, PI * 0.5) * Basis(Vector3.RIGHT, PI * 0.5)
			origin += Vector3(0.0, v * aabb.size.y, u * aabb.size.z)
		var node := MeshInstance3D.new()
		node.mesh = _win_mesh
		node.material_override = _win_mat
		node.transform = Transform3D(basis, origin)
		w.add_child(node)
		node.visible = _rng.randf() < lit_chance

func _collect_walls(n: Node, out: Array[MeshInstance3D]) -> void:
	if n is MeshInstance3D and String((n as MeshInstance3D).name) != "Ground":
		out.append(n)
	for c in n.get_children():
		_collect_walls(c, out)
'@
Write-Utf8 'scripts/world/emissive_windows.gd' $emissive_windows

# ==== end of Part 1 ====