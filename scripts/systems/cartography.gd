extends Node
## Autoload "Cartography": the remembered architecture of each district (the owner's map rules of 2026-11-05).
## A ground cell of 2 m is charted only when a streetlight the player's restoration powered lights it, nothing blocks
## that light, and the player sees the cell unobstructed from where they stand. A flashlight, walking, waiting or a
## monster never charts anything, and this memory holds nothing but cells: no occupant, item, marker or player position.
## Charted cells stay charted after the lamp goes out; a saved memory of another layout revision is dropped.

const CELL: float = 2.0
## How far a lit street can be made out from where the player stands.
const SEE_RANGE: float = 28.0
const TICK: float = 0.5
## Bounded sampling: at most this many cells are tested (two rays each) per pass.
const CELLS_PER_TICK: int = 48
## Bump when the district layouts change: the cells of an older layout would chart the wrong streets.
const LAYOUT_REV: int = 1
## A district is at most 3 blocks of 40 m with its streets: a forged cell beyond this is refused.
const CELL_LIMIT: int = 128
const MAX_CELLS: int = 16384
## The ground point a ray aims at stands this high above the road, so the road itself does not block it.
const GROUND_LIFT: float = 0.15

var _charted: Dictionary = {}  # district id (String) -> {Vector2i: true}
var _timer: float = 0.0
var _next_lamp: int = 0
## Per-lamp resume index into its cell loop: a wall that blocks the first cells of a pass must not spend the whole
## budget on them forever and starve the visible cells after them.
var _cell_cursor: Dictionary = {}  # lamp instance id (int) -> next linear cell index (int)

func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = TICK
	if GameManager.is_playing():
		survey()

## One bounded pass over the powered streetlights near the player.
func survey() -> void:
	var cam := get_viewport().get_camera_3d()
	var dm := get_node_or_null("/root/DistrictManager")
	if cam == null or dm == null or String(dm.current_district) == "":
		return
	var district := String(dm.current_district)
	if not _charted.has(district):
		_charted[district] = {}
	var cells: Dictionary = _charted[district]
	var origin := district_origin()
	var space := cam.get_world_3d().direct_space_state
	var eye := cam.global_position
	var ahead := -cam.global_transform.basis.z
	var lamps := get_tree().get_nodes_in_group(&"streetlights")
	var budget := CELLS_PER_TICK
	# the lamps take turns, so the cells a wall hides from one lamp do not starve the others
	for k: int in lamps.size():
		var lamp := lamps[(_next_lamp + k) % lamps.size()] as Node3D
		if budget <= 0:
			break
		# only a lamp the player's restoration powered (an authored always-on lamp is not the player's doing)
		if lamp == null or not lamp.is_visible_in_tree() or not bool(lamp.get("_on")) or bool(lamp.get("force_on")):
			continue
		# chart only what actually renders: the LightLimiter hides a far glow (visible=false) while its energy stays, so a
		# hidden glow contributes nothing and only the still-visible spotlight's pool is charted
		var glow := lamp.get_node_or_null("Glow") as OmniLight3D
		var spot := lamp.get_node_or_null("SpotLight") as SpotLight3D
		var glow_on := glow != null and glow.is_visible_in_tree() and glow.light_energy > 0.01
		var spot_on := spot != null and spot.is_visible_in_tree() and spot.light_energy > 0.01
		if not glow_on and not spot_on:
			continue
		var head: Vector3 = (glow if glow_on else spot).global_position
		var reach := _ground_reach(glow if glow_on else null, spot if spot_on else null, head.y - origin.y)
		if reach <= 0.0:
			continue
		var foot := Vector3(head.x, origin.y, head.z)
		if Vector2(foot.x - eye.x, foot.z - eye.z).length() > SEE_RANGE + reach or ahead.dot(foot - eye) < -reach:
			continue
		var centre := cell_of(foot - origin)
		var span := ceili(reach / CELL)
		var width := span * 2 + 1
		var total := width * width
		var id := lamp.get_instance_id()
		var start: int = int(_cell_cursor.get(id, 0)) % total
		# resume where the last pass spent its budget, so blocked prefix cells cannot starve the visible cells after them
		for step: int in total:
			if budget <= 0:
				break
			var i := (start + step) % total
			var cell := centre + Vector2i(i % width - span, int(float(i) / float(width)) - span)
			if cells.has(cell):
				continue
			_cell_cursor[id] = (i + 1) % total
			var ground := origin + Vector3((cell.x + 0.5) * CELL, GROUND_LIFT, (cell.y + 0.5) * CELL)
			if Vector2(ground.x - foot.x, ground.z - foot.z).length() > reach:
				continue
			if eye.distance_to(ground) > SEE_RANGE or not cam.is_position_in_frustum(ground):
				continue
			budget -= 1
			if _clear(space, head, ground) and _clear(space, eye, ground):
				cells[cell] = true
	_next_lamp = (_next_lamp + 1) % maxi(lamps.size(), 1)
	var live := {}
	for lamp: Node3D in lamps:
		if lamp != null:
			live[lamp.get_instance_id()] = true
	for id: int in _cell_cursor.keys():
		if not live.has(id):
			_cell_cursor.erase(id)

## How far from its foot a lamp lights the ground: where its glow's sphere meets the ground, or its spot's pool, whichever is
## wider (the glow hangs about 4.2 m up, so its range alone overstated the pool). A null light is one the limiter hid.
func _ground_reach(glow: OmniLight3D, spot: SpotLight3D, height: float) -> float:
	var reach := 0.0
	if glow != null:
		reach = sqrt(maxf(glow.omni_range * glow.omni_range - height * height, 0.0))
	if spot != null:
		reach = maxf(reach, height * tan(deg_to_rad(spot.spot_angle)))
	return reach

func _clear(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> bool:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to)).is_empty()

## The district's own coordinates start at its street builder (each district scene has its own origin).
func district_origin() -> Vector3:
	var sb := get_tree().get_first_node_in_group(&"street_builder") as Node3D
	return sb.global_position if sb != null else Vector3.ZERO

static func cell_of(local: Vector3) -> Vector2i:
	return Vector2i(floori(local.x / CELL), floori(local.z / CELL))

func charted_cells(district: String) -> Dictionary:
	return _charted.get(district, {})

func reset() -> void:
	_charted.clear()

func to_dict() -> Dictionary:
	var out := {}
	for district: String in _charted:
		var flat: Array = []
		for cell: Vector2i in _charted[district]:
			flat.append(cell.x)
			flat.append(cell.y)
		out[district] = flat
	return {"rev": LAYOUT_REV, "districts": out}

## A save is a trust boundary: a memory of another layout, a bad shape or a cell out of bounds charts nothing, and
## only the map's memory is dropped (never the inventory, progression or quests).
func from_dict(data: Variant) -> void:
	_charted.clear()
	var rev: Variant = data.get("rev") if data is Dictionary else null
	if not (rev is int or rev is float) or int(rev) != LAYOUT_REV or not (data.get("districts") is Dictionary):
		return
	var pg := get_node_or_null("/root/PowerGrid")
	for district: Variant in data["districts"]:
		var flat: Variant = data["districts"][district]
		if not (district is String) or (pg != null and pg.get_district(StringName(district)) == null):
			continue
		if not (flat is Array) or flat.size() % 2 != 0 or flat.size() > MAX_CELLS * 2:
			continue
		var cells := {}
		for i: int in range(0, flat.size(), 2):
			var x: Variant = flat[i]
			var z: Variant = flat[i + 1]
			if typeof(x) not in [TYPE_INT, TYPE_FLOAT] or typeof(z) not in [TYPE_INT, TYPE_FLOAT]:
				cells = {}
				break
			if absi(int(x)) <= CELL_LIMIT and absi(int(z)) <= CELL_LIMIT:
				cells[Vector2i(int(x), int(z))] = true
		_charted[district] = cells
