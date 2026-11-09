extends Node
## Autoload "LightGrid". Tracks every OmniLight3D / SpotLight3D, exposes grid
## brightness for AI queries. Build lazily, refresh on register/unregister.

signal grid_rebuilt

const CELL_SIZE: float = 4.0

var _lights: Dictionary = {}
var _grid: Dictionary = {}
## Lamps register in batches (a district's 48 at a stage change): the grid is rebuilt once, on the next frame or query.
var _dirty: bool = false
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
	if not is_instance_valid(n) or not n.is_inside_tree():
		return
	if n is SpotLight3D and n.is_in_group(&"flashlight"):
		_flashlights.append(n)
	var data: Dictionary = {
		"node": n,
		"pos": n.global_position,
		"range": _range_of(n),
		"intensity": _intensity_of(n),
	}
	_lights[n.get_instance_id()] = data
	_dirty = true

func unregister_light(n: Node3D) -> void:
	var id := n.get_instance_id()
	if n is SpotLight3D:
		_flashlights.erase(n)
	if _lights.erase(id):
		_dirty = true

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
	var dirty: bool = _dirty
	for id in _lights.keys():
		var data: Dictionary = _lights[id]
		# A scene can detach a live light before freeing it; neither state has a usable global transform.
		if not is_instance_valid(data["node"]) or not (data["node"] as Node3D).is_inside_tree():
			_lights.erase(id)
			dirty = true
			continue
		data["pos"] = (data["node"] as Node3D).global_position
	if dirty:
		_rebuild_grid()

func _rebuild_grid() -> void:
	_dirty = false
	_grid.clear()
	var cs: float = CELL_SIZE
	for id in _lights.keys():
		var data: Dictionary = _lights[id]
		var pos: Vector3 = data["pos"]
		# a lamp's pool reaches its range on the ground under it: the distance is taken across the ground, the energy weighs the brightness
		var rng_v: float = float(data["range"])
		if rng_v <= 0.01 or float(data["intensity"]) <= 0.01:
			continue
		var min_x: int = int(floor((pos.x - rng_v) / cs))
		var max_x: int = int(ceil((pos.x + rng_v) / cs))
		var min_z: int = int(floor((pos.z - rng_v) / cs))
		var max_z: int = int(ceil((pos.z + rng_v) / cs))
		for cx in range(min_x, max_x + 1):
			for cz in range(min_z, max_z + 1):
				var cp: Vector3 = Vector3(float(cx) * cs + cs * 0.5, 0.0, float(cz) * cs + cs * 0.5)
				var d: float = Vector2(cp.x - pos.x, cp.z - pos.z).length()
				if d > rng_v:
					continue
				var fall: float = clamp(1.0 - d / rng_v, 0.0, 1.0)
				var key: Vector2i = Vector2i(cx, cz)
				_grid[key] = float(_grid.get(key, 0.0)) + fall * float(data["intensity"])
	grid_rebuilt.emit()

func cell_brightness(world_pos: Vector3) -> float:
	if _dirty:
		_rebuild_grid()
	var key: Vector2i = Vector2i(int(floor(world_pos.x / CELL_SIZE)), int(floor(world_pos.z / CELL_SIZE)))
	return float(_grid.get(key, 0.0))

func is_lit(world_pos: Vector3, threshold: float = 0.3) -> bool:
	return cell_brightness(world_pos) >= threshold

## The registered lights whose pool actually reaches world_pos right now: read live (the grid snapshot goes stale between
## rebuilds), skip a light the LightLimiter hid or its owner put out, respect a spotlight's cone, and leave the player's
## flashlight to the beam test. The radial grid alone lights through walls; a visibility consumer ray-tests each light returned.
func visible_lights_at(world_pos: Vector3, threshold: float = 0.05) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for id in _lights:
		var data: Dictionary = _lights[id]
		if not is_instance_valid(data["node"]):
			continue
		var n := data["node"] as Node3D
		if not n.is_inside_tree() or not n.is_visible_in_tree():
			continue
		if n is SpotLight3D and n.is_in_group(&"flashlight"):
			continue
		var intensity: float = _intensity_of(n)
		var rng_v: float = _range_of(n)
		if intensity <= 0.01 or rng_v <= 0.01:
			continue
		var pos: Vector3 = n.global_position
		var d: float = Vector2(pos.x - world_pos.x, pos.z - world_pos.z).length()
		if d > rng_v:
			continue
		if n is SpotLight3D:
			var spot := n as SpotLight3D
			var to_pos: Vector3 = world_pos - pos
			if to_pos.length() > spot.spot_range or (-spot.global_transform.basis.z).angle_to(to_pos) > deg_to_rad(spot.spot_angle):
				continue
		var fall: float = clampf(1.0 - d / rng_v, 0.0, 1.0)
		if fall * intensity >= threshold:
			out.append(n)
	return out
