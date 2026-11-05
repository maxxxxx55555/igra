extends Node
## Autoload "Cartography": the remembered architecture of each district (the owner's map rules of 2026-11-05).
## A ground cell of 2 m is charted only when a streetlight the player's restoration powered lights it, nothing blocks
## that light, and the player sees the cell unobstructed from where they stand. A flashlight, walking, waiting or a
## monster never charts anything, and this memory holds nothing but cells: no occupant, item, marker or player position.
## Charted cells stay charted after the lamp goes out; a saved memory of another layout revision is dropped.

const CELL: float = 2.0
## How far a lit street can be made out from where the player stands.
const SEE_RANGE: float = 28.0
## Half the angle the player looks across: a cell behind the player is not seen.
const VIEW_HALF_ANGLE: float = 1.1345  # 65 degrees
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
	var budget := CELLS_PER_TICK
	for lamp: Node in get_tree().get_nodes_in_group(&"streetlights"):
		# only a lamp the player's restoration powered: an authored always-on lamp is not the player's doing
		if budget <= 0 or not bool(lamp.get("_on")) or bool(lamp.get("force_on")):
			continue
		var glow := lamp.get_node_or_null("Glow") as OmniLight3D
		if glow == null or not glow.is_visible_in_tree() or glow.light_energy <= 0.01:
			continue
		var head := glow.global_position
		var reach := glow.omni_range
		if Vector2(head.x - eye.x, head.z - eye.z).length() > SEE_RANGE + reach:
			continue
		var centre := cell_of(head - origin)
		var span := ceili(reach / CELL)
		for dx: int in range(-span, span + 1):
			for dz: int in range(-span, span + 1):
				var cell := centre + Vector2i(dx, dz)
				if budget <= 0 or cells.has(cell):
					continue
				var ground := origin + Vector3((cell.x + 0.5) * CELL, GROUND_LIFT, (cell.y + 0.5) * CELL)
				if Vector2(ground.x - head.x, ground.z - head.z).length() > reach:
					continue
				var to_cell := ground - eye
				if to_cell.length() > SEE_RANGE or ahead.angle_to(to_cell) > VIEW_HALF_ANGLE:
					continue
				budget -= 1
				if _clear(space, head, ground) and _clear(space, eye, ground):
					cells[cell] = true

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
	if not (data is Dictionary) or int(data.get("rev", -1)) != LAYOUT_REV or not (data.get("districts") is Dictionary):
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
