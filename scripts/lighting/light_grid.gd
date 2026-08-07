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