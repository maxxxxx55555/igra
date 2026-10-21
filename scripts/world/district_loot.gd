extends Node
class_name DistrictLoot
## Раскладка предметов по району.
##
## В 3D-мире не было ни одного подбираемого предмета: расстановка лута жила
## в scripts/world/world_map.gd — сцене Node2D из ранней версии игры, которая
## в main_3d.tscn не участвует. Из-за этого батарейки, аптечки и материалы
## для крафта нельзя было найти нигде, а фонарь садился безвозвратно.
##
## Здесь предметы раскладываются процедурно, но детерминированно: seed
## считается от имени района, поэтому лут лежит на одних и тех же местах
## между перезапусками и совпадает у всех игроков в сетевой игре.

const PICKUP_SCENE: PackedScene = preload("res://scenes/pickups/item_pickup_3d.tscn")
const DOC_SCENE: PackedScene = preload("res://scenes/pickups/document_pickup.tscn")
const SECRET_SCENE: PackedScene = preload("res://scenes/props/secret.tscn")
const WEAPON_PICKUP_SCENE: PackedScene = preload("res://scenes/pickups/weapon_pickup.tscn")
const AMMO_PICKUP_SCENE: PackedScene = preload("res://scenes/pickups/ammo_pickup.tscn")
const STATION_SCENE: PackedScene = preload("res://scenes/gameplay/craft_station.tscn")
const BED_SCRIPT: Script = preload("res://scripts/gameplay/bed.gd")

## content/secrets.json — 26 секретов, авторский контент. Читается один раз
## на запуск: populate() статический и вызывается по разу на район.
const SECRETS_PATH: String = "res://content/secrets.json"
static var _secrets_by_district: Dictionary = {}
static var _secrets_loaded: bool = false

## Базовый набор: встречается почти везде, поддерживает фонарь и здоровье.
## C4: a battery crate holds two (PICKUP_AMOUNT) and the scrap three: the old list of four, in three pickups.
const COMMON: Array[StringName] = [&"battery", &"scrap", &"medkit"]

## Три детали, за которые щит района поднимает стадию (см. power_switch.gd:
## кабель -> PARTIAL, предохранитель -> STREETS, транзистор -> FULL).
## Лежат в каждом районе, и это обязательное условие проходимости: район
## открывается только после того, как предыдущий доведён до FULL, поэтому
## недостающую деталь физически неоткуда принести — игрок запирался бы
## в пригороде навсегда. C4: по ящику каждой детали, и в ящике две штуки
## (PICKUP_AMOUNT): запас на случай, если игрок потратит деталь на соседний
## район или на крафт, лежит в нём же, а на улице три предмета вместо шести.
const REPAIR_PARTS: Array[StringName] = [&"cable", &"fuse", &"transistor"]

## Тематический набор района — то, ради чего в него имеет смысл заходить. C4: только то,
## чего нет в COMMON и REPAIR_PARTS (батарея, аптечка, кабель, предохранитель и транзистор
## и так лежат везде); ключ идёт сразу после деталей, остальное — пока есть место под MAX_PICKUPS.
const BY_DISTRICT: Dictionary = {
	&"suburbs":       [],
	&"residential":   [],
	&"park":          [],
	&"school":        [&"key", &"paper"],
	&"hospital":      [&"serum", &"fabric", &"alcohol"],
	&"gas_station":   [&"gas_canister", &"bottle"],
	&"police":        [&"key", &"tool", &"gunpowder", &"case"],
	&"warehouses":    [],
	&"industrial":    [&"gear", &"metal"],
	&"substation":    [],
	&"power_station": [],
}

## Чертежи — по одному в четырёх районах, как и задумано в старой раскладке
## (world_map.gd BLUEPRINT_SPAWNS), чтобы улучшения фонаря и рюкзака
## оставались достижимы.
const BLUEPRINTS: Dictionary = {
	&"residential": &"blueprint_flashlight_brightness",
	&"park": &"blueprint_flashlight_battery",
	&"police": &"blueprint_backpack_capacity",
	&"warehouses": &"blueprint_backpack_slots",
}

## Документы двигают сюжет и достижение «Библиотекарь».
## ID берутся из data/documents/documents_catalog.json (33 записи с готовыми
## текстами) — раньше этот каталог не читал никто.
const DOCUMENTS: Dictionary = {
	&"suburbs": "doc_blackout_news",
	&"residential": "doc_old_woman",
	&"park": "doc_streetlight_manifesto",
	&"school": "doc_school_incident",
	&"hospital": "doc_hospital_note",
	&"gas_station": "doc_scavenger",
	&"police": "doc_evacuation_order",
	&"warehouses": "doc_foreman_note",
	&"industrial": "doc_factory_log",
	&"substation": "doc_substation_guard",
	&"power_station": "doc_core_station",
}

## Content-authored lore packs (content/districts/<id>/lore_notes.json), four notes a district (C4: eight
## were eight floating cubes a district): pinned on the streetlight poles by _spawn_mounted_doc, the total of
## documents (Endings.get_total_documents) follows this table.
const LORE_DOCS: Dictionary = {
	&"suburbs": ["suburbs_note_01", "suburbs_note_02", "suburbs_note_03", "suburbs_note_04"],
	&"residential": ["residential_note_01", "residential_note_02", "residential_note_03", "residential_note_04"],
	&"park": ["park_note_01", "park_note_02", "park_note_03", "park_note_04"],
	&"school": ["school_note_01", "school_note_02", "school_note_03", "school_note_04"],
	&"hospital": ["hospital_note_01", "hospital_note_02", "hospital_note_03", "hospital_note_04"],
	&"gas_station": ["gas_station_note_01", "gas_station_note_02", "gas_station_note_03", "gas_station_note_04"],
	&"police": ["police_note_01", "police_note_02", "police_note_03", "police_note_04"],
	&"warehouses": ["warehouses_note_01", "warehouses_note_02", "warehouses_note_03", "warehouses_note_04"],
	&"industrial": ["industrial_note_01", "industrial_note_02", "industrial_note_03", "industrial_note_04"],
	&"substation": ["substation_note_01", "substation_note_02", "substation_note_03", "substation_note_04"],
	&"power_station": ["power_station_note_01", "power_station_note_02", "power_station_note_03", "power_station_note_04"],
}

const RADIUS_MIN: float = 6.0
const RADIUS_MAX: float = 22.0
const DROP_Y: float = 0.6
## C4: where a pickup lies: on the street (the top of the street tiles); DROP_Y is the height of a secret.
const PICKUP_Y: float = 0.05
## At most this many items, guns and boxes of rounds lie in one district (documents are not counted: they are notes on poles).
const MAX_PICKUPS: int = 12
## No two pickups lie closer than this (metres, on the ground plane), and the notes on the poles keep it too.
const MIN_SPACING_M: float = 5.5
const SCATTER_TRIES: int = 24
## A note on a pole: its height over the street and how far it stands from the pole's axis, toward the road.
const MOUNT_Y: float = 1.2
const MOUNT_OFFSET_M: float = 0.14
## The pickups and notes of the district being laid out, for MIN_SPACING_M.
static var _placed: Array[Vector3] = []

## street_builder.gd lays a 3x3 grid of 16 m blocks centred on the district; floor exists only on its
## streets, each a band from axis - 3.75 to axis + 5 (road and sidewalk tiles). Loot scattered into the
## blocks between them hung over the void and could not be walked to, required repair parts included
## (11 districts, 2-4 pickups each: the root cause of the bot's pickup-orbit stall X21).
const STREET_AXES: Array[float] = [-24.0, -8.0, 8.0, 24.0]
const STREET_BAND_LO: float = -3.25
const STREET_BAND_HI: float = 4.5
const STREET_BAND_MID: float = 0.625

static func _on_street(v: float) -> bool:
	for axis in STREET_AXES:
		if v >= axis + STREET_BAND_LO and v <= axis + STREET_BAND_HI:
			return true
	return false

static func _nearest_axis(v: float) -> float:
	var best: float = STREET_AXES[0]
	for axis in STREET_AXES:
		if absf(v - axis) < absf(v - best):
			best = axis
	return best

## A point over a street stays; one over the void between streets moves onto the nearest street.
static func _snap_to_street(local: Vector3) -> Vector3:
	if _on_street(local.x) or _on_street(local.z):
		return local
	var to_x: float = _nearest_axis(local.x) + STREET_BAND_MID
	var to_z: float = _nearest_axis(local.z) + STREET_BAND_MID
	if absf(local.x - to_x) <= absf(local.z - to_z):
		local.x = to_x
	else:
		local.z = to_z
	return local

## Раскладывает лут внутри уже собранного района.
static func populate(district_root: Node3D, district_id: StringName) -> int:
	if district_root == null:
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(district_id))

	_placed.clear()
	var themed: Array = BY_DISTRICT.get(district_id, [])
	# C4, in the order of what matters: the repair parts (they open the next district), the blueprint, the key, the common items, the rest of the district's own,
	# cut to the room MAX_PICKUPS leaves after the guns, boxes of rounds and workbench parts of _spawn_extras.
	var wanted: Array[StringName] = []
	wanted.append_array(REPAIR_PARTS)
	if BLUEPRINTS.has(district_id):
		wanted.append(StringName(BLUEPRINTS[district_id]))
	if themed.has(&"key"):
		wanted.append(&"key")
	wanted.append_array(COMMON)
	for it in themed:
		if it != &"key":
			wanted.append(StringName(it))
	var items: Array[StringName] = []
	for i in mini(wanted.size(), MAX_PICKUPS - _extras_max(district_id)):
		items.append(wanted[i])
	# Static audit 2026-09-08: "loot_luck" skill was purchasable but never
	# read anywhere - buying it did nothing. Extra common-item rolls per
	# level; still fully deterministic (same seeded rng as everything else
	# in this function).
	var luck_lvl := _skill_level(&"loot_luck")
	for i in luck_lvl:
		items.append(COMMON[rng.randi() % COMMON.size()])

	var placed := 0
	## QA_SWARM_FINDINGS.md P1 (cheater): the item loop below used to run
	## unconditionally on every populate() call - leaving and re-entering a
	## district (world_runtime.gd rebuilds the scene each visit) restocked
	## every common item AND repair part for free, indefinitely. Secrets
	## already had this gate (_spawn_secrets below); items didn't.
	## The district is rebuilt on every visit, a Continue and a Retry. What was picked up stays gone (the farming
	## fix above), but the flag used to be set when the items SPAWNED: whatever was left on the street when the player
	## died or quit, repair parts included, never came back, and the first district gates every other. Each pickup
	## has a key (district and place in this deterministic list) and only the keys taken are skipped; every position
	## is still drawn from the seeded sequence, so the layout of the rest does not move between visits.
	var pt := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("/root/ProgressTracker")
	var n := 0
	for item_id in items:
		var pos := _scatter(district_root, rng)
		var key := "%s:%d" % [district_id, n]
		n += 1
		if pt == null or not pt.is_loot_taken(key):
			if _spawn_item(district_root, item_id, pos, int(PICKUP_AMOUNT.get(item_id, 1)), key):
				placed += 1

	if DOCUMENTS.has(district_id):
		var dpos := _scatter(district_root, rng)
		if _spawn_document(district_root, String(DOCUMENTS[district_id]), dpos):
			placed += 1
	if LORE_DOCS.has(district_id):
		for doc_id in (LORE_DOCS[district_id] as Array):
			if _spawn_mounted_doc(district_root, String(doc_id), rng):
				placed += 1
	placed += _spawn_secrets(district_root, district_id)
	_spawn_hiding_spots(district_root, district_id)
	_spawn_extras(district_root, district_id)
	placed += _spawn_spare_parts(district_root, district_id)
	return placed

## Easy puts one more of each repair part on the street (SettingsManager.DIFFICULTY_PRESETS, "extra_parts"). Its own rng stream and its own
## keys, so the positions of the rest do not move with the difficulty and a part taken stays taken.
const SPARE_PARTS: Array[StringName] = [&"cable", &"fuse", &"transistor"]

static func _spawn_spare_parts(root: Node3D, district_id: StringName) -> int:
	var tree := Engine.get_main_loop() as SceneTree
	var settings := tree.root.get_node_or_null("/root/SettingsManager")
	var rounds: int = int(settings.call("difficulty_scale", "extra_parts")) if settings != null else 0
	var pt := tree.root.get_node_or_null("/root/ProgressTracker")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(district_id) + "_spare")
	var placed := 0
	for n in rounds * SPARE_PARTS.size():
		var pos := _scatter(root, rng)
		var key := "%s:spare%d" % [district_id, n]
		if (pt == null or not pt.is_loot_taken(key)) and _spawn_item(root, SPARE_PARTS[n % SPARE_PARTS.size()], pos, 1, key):
			placed += 1
	return placed

## S04 (GDD §7): lockers, car trunks, bushes and dark corners to hide in. Three per district on the outer
## edge of a sidewalk (the benches' and trees' line, floor under the footprint), facing the road. Own rng
## stream, so the loot positions above stay where they were. Not counted in `placed`: they are not loot.
const HIDING_TYPES: Array[String] = ["locker", "dumpster", "car", "crate", "bush", "dark_corner"]
const HIDING_PER_DISTRICT: int = 3
const HIDING_SIDEWALK: float = 3.7
const HIDING_ALONG: float = 20.0

static func _spawn_hiding_spots(root: Node3D, district_id: StringName) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(district_id) + "_hiding")
	var first: int = maxi(DistrictSceneFactory.DISTRICTS.find(district_id), 0) * HIDING_PER_DISTRICT
	for i in HIDING_PER_DISTRICT:
		var pose := _sidewalk_pose(rng)
		var spot := HidingSpot.new()
		spot.spot_type = HIDING_TYPES[(first + i) % HIDING_TYPES.size()]
		spot.exit_dir = pose[1]
		spot.rotation.y = atan2(spot.exit_dir.x, spot.exit_dir.z)
		root.add_child(spot)
		spot.global_position = root.global_position + pose[0]

## A spot on the outer edge of a sidewalk: x = the position, y = the direction toward the road.
static func _sidewalk_pose(rng: RandomNumberGenerator) -> Array[Vector3]:
	var axis: float = STREET_AXES[rng.randi() % STREET_AXES.size()]
	var along: float = rng.randf_range(-HIDING_ALONG, HIDING_ALONG)
	if rng.randf() < 0.5:
		return [Vector3(along, 0.0, axis + HIDING_SIDEWALK), Vector3(0.0, 0.0, -1.0)]
	return [Vector3(axis + HIDING_SIDEWALK, 0.0, along), Vector3(-1.0, 0.0, 0.0)]

## Секреты района из content/secrets.json.
##
## Контент задаёт zone ("z_maple_row") и location_hint словами, но в 3D-районах
## нет именованных маркеров зон — zone существует только как словарь авторов
## в content/districts/<id>/item_spawns.json. Поэтому позиция берётся тем же
## детерминированным разбросом, что и весь остальной лут, но seed считается от
## id самого секрета: место у каждого секрета своё и одинаковое между
## запусками и у всех игроков в сети. Радиус больше обычного — секрет должен
## лежать в стороне от маршрута, а не под ногами.
static func _spawn_secrets(root: Node3D, district_id: StringName) -> int:
	_load_secrets()
	var rows: Array = _secrets_by_district.get(String(district_id), [])
	var placed := 0
	var pt := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("/root/ProgressTracker")
	for row in rows:
		# Район пересобирается заново при каждом входе (world_runtime
		# выбрасывает старый корень и строит новый), поэтому уже взятый секрет
		# иначе появлялся бы снова: награду можно было бы фармить бесконечно,
		# а достижение «seeker» за 10 секретов закрывалось бы одним и тем же.
		# Флаг _taken живёт на освобождённой ноде, так что помнить обязан
		# ProgressTracker.
		if pt != null and pt.is_secret_found(String(row.get("id", ""))):
			continue
		var node := SECRET_SCENE.instantiate() as Node3D
		if node == null:
			continue
		var srng := RandomNumberGenerator.new()
		srng.seed = hash(String(row.get("id", "")))
		var ang := srng.randf_range(0.0, TAU)
		var rad := srng.randf_range(RADIUS_MAX * 0.6, RADIUS_MAX)
		# Same ordering bug class as BREAK_REPORT B2 (documents): add_child()
		# runs _ready() immediately, and _ready()'s own _refresh_gate() reads
		# home_district/min_stage to decide initial visibility - set after
		# add_child, it always saw "" (no gate) and showed the secret before
		# its district reached min_stage. interact() re-checks fresh at
		# interaction time, so this was cosmetic (visible-but-rejected), not
		# a real skip - still real enough to fix while touching this exact
		# spawn order for B9's fix in secret.gd below.
		node.set("secret_id", StringName(String(row.get("id", ""))))
		node.set("home_district", district_id)
		node.set("min_stage", int(row.get("min_stage", 0)))
		var reward: Dictionary = row.get("reward", {})
		node.set("item_id", StringName(String(reward.get("item", "battery"))))
		node.set("amount", int(reward.get("amount", 1)))
		var keys: Dictionary = row.get("i18n_keys", {})
		node.set("title_key", String(keys.get("title", "")))
		root.add_child(node)
		node.global_position = root.global_position + _snap_to_street(Vector3(cos(ang) * rad, DROP_Y, sin(ang) * rad))
		placed += 1
	return placed

static func _load_secrets() -> void:
	if _secrets_loaded:
		return
	_secrets_loaded = true
	if not ResourceLoader.exists(SECRETS_PATH):
		return
	var f := FileAccess.open(SECRETS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return
	for row in parsed.get("secrets", []):
		var d := String(row.get("district", ""))
		if not _secrets_by_district.has(d):
			_secrets_by_district[d] = []
		_secrets_by_district[d].append(row)

## A point on the street for a pickup, at least MIN_SPACING_M from every one laid out before it (the same seeded draws, so a layout does not move between visits).
static func _scatter(root: Node3D, rng: RandomNumberGenerator) -> Vector3:
	var pos := Vector3.ZERO
	for attempt in SCATTER_TRIES:
		var ang := rng.randf_range(0.0, TAU)
		var rad := rng.randf_range(RADIUS_MIN, RADIUS_MAX)
		pos = root.global_position + _snap_to_street(Vector3(cos(ang) * rad, PICKUP_Y, sin(ang) * rad))
		if _spaced(pos):
			break
	_placed.append(pos)
	return pos

static func _spaced(at: Vector3) -> bool:
	for other in _placed:
		if Vector2(at.x - other.x, at.z - other.z).length() < MIN_SPACING_M:
			return false
	return true

## What _spawn_extras lays out at most (the workbench blueprint, the gun, the workbench parts and the boxes of rounds), whatever the player has already found: the room the rest of the loot is cut to.
static func _extras_max(district_id: StringName) -> int:
	var index: int = DistrictSceneFactory.DISTRICTS.find(district_id)
	var ammo: int = 0 if index <= 0 else (1 if index < AMMO_DOUBLE_FROM else 2)
	return int(WORKBENCH_BLUEPRINTS.has(district_id)) + int(WEAPON_FINDS.has(district_id)) + (EXTRA_PARTS.get(district_id, []) as Array).size() + ammo

## C4: a lore note pinned upright on a streetlight pole at head height, facing the road: found with the flashlight, not by walking over it. A district without poles gets it on the ground.
static func _spawn_mounted_doc(root: Node3D, doc_id: String, rng: RandomNumberGenerator) -> bool:
	var poles := root.find_child("StreetlightPolesBatched", true, false) as MultiMeshInstance3D
	var spots: Array = poles.get_meta("spots", []) if poles != null else []
	if spots.is_empty():
		return _spawn_document(root, doc_id, _scatter(root, rng))
	var pole := Vector3.ZERO
	for attempt in SCATTER_TRIES:
		var spot: Vector3 = spots[rng.randi() % spots.size()]
		pole = poles.global_transform * spot
		if _spaced(pole):
			break
	var local: Vector3 = pole - root.global_position
	var to_axis := Vector2(_nearest_axis(local.x) + STREET_BAND_MID - local.x, _nearest_axis(local.z) + STREET_BAND_MID - local.z)
	var face := Vector3(signf(to_axis.x), 0.0, 0.0) if absf(to_axis.x) < absf(to_axis.y) else Vector3(0.0, 0.0, signf(to_axis.y))
	var at: Vector3 = Vector3(pole.x, root.global_position.y + MOUNT_Y, pole.z) + face * MOUNT_OFFSET_M
	_placed.append(at)
	var node := DOC_SCENE.instantiate() as Node3D
	if node == null:
		return false
	node.set("document_id", doc_id)
	node.set("mounted", true)
	root.add_child(node)
	node.global_position = at
	node.rotation.y = atan2(face.x, face.z)
	return true

static func _spawn_item(root: Node3D, item_id: StringName, pos: Vector3, count: int = 1, key: String = "") -> bool:
	var node := PICKUP_SCENE.instantiate() as Node3D
	if node == null:
		return false
	node.set("loot_key", key)
	root.add_child(node)
	node.global_position = pos
	if node.has_method("set_item"):
		node.call("set_item", item_id, count)
	return true

static func _spawn_document(root: Node3D, doc_id: String, pos: Vector3) -> bool:
	var node := DOC_SCENE.instantiate() as Node3D
	if node == null:
		return false
	# BREAK_REPORT B2: add_child() runs _ready() immediately (root is already
	# in the tree) - document_id must be set before that, not after, or
	# _ready()'s _load_from_catalog() bails on the still-empty id and never
	# runs again (title/content stay "Untitled"/"" forever, even though the
	# id property itself gets corrected a line later - collecting it still
	# calls unlock_doc with the right id, but the toast/journal show a blank
	# document with no name).
	node.set("document_id", doc_id)
	root.add_child(node)
	node.global_position = pos
	return true

## G25 (GDD §18) and G21 (GDD §9): what the GDD adds to the loot, on an own rng stream so the positions above stay
## put. Weapons and blueprints wait on the street until they are taken; ammo and parts come once, like the loot.
const WORKBENCH_BLUEPRINTS: Dictionary = {
	&"residential": &"blueprint_enhanced_battery",
	&"school": &"blueprint_uv_flashlight",
	&"police": &"blueprint_strobe_flashlight",
	&"warehouses": &"blueprint_portable_workbench",
	&"industrial": &"blueprint_battery_l2",
}
const WEAPON_FINDS: Dictionary = {&"residential": &"pistol", &"police": &"rifle", &"warehouses": &"shotgun"}
## Parts the workbench recipes ask for that no district list carried: boards for the portable workbench,
## transformers for the strobe and the level 2 battery.
const EXTRA_PARTS: Dictionary = {
	&"police": [&"transformer"], &"warehouses": [&"plank", &"metal"], &"industrial": [&"transformer"],
}
## A pickup holds this many (the default is one): the spare repair parts and the second battery are inside the crate, not beside it.
const PICKUP_AMOUNT: Dictionary = {&"plank": 5, &"cable": 2, &"fuse": 2, &"transistor": 2, &"battery": 2, &"scrap": 3}
const AMMO_PER_PICKUP: int = 12
## Ammo lies in every district but the first, twice from the sixth on (the gas station, where the first two Hunters stand: a rise of x1.9 in the enemy strength is paid with it): the guns come late.
const AMMO_DOUBLE_FROM: int = 5
const WORKBENCH_DISTRICTS: Array[StringName] = [&"suburbs", &"police", &"industrial"]
## The bed of the "Midsummer Night's Dream" achievement stands in the first district.
const BED_DISTRICT: StringName = &"suburbs"

static func _spawn_extras(root: Node3D, district_id: StringName) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(district_id) + "_extras")
	if WORKBENCH_BLUEPRINTS.has(district_id):
		var blueprint: StringName = WORKBENCH_BLUEPRINTS[district_id]
		if not ProgressTracker.knows_blueprint(String(blueprint).trim_prefix(ProgressTracker.BLUEPRINT_ITEM_PREFIX)):
			_spawn_item(root, blueprint, _scatter(root, rng))
	if WEAPON_FINDS.has(district_id) and not ProgressTracker.has_weapon(String(WEAPON_FINDS[district_id])):
		_spawn_pickup(root, WEAPON_PICKUP_SCENE, _scatter(root, rng), String(WEAPON_FINDS[district_id]))
	if WORKBENCH_DISTRICTS.has(district_id):
		var pose := _sidewalk_pose(rng)
		var station := STATION_SCENE.instantiate() as Node3D
		station.rotation.y = atan2(pose[1].x, pose[1].z)
		root.add_child(station)
		station.global_position = root.global_position + pose[0]
	if district_id == BED_DISTRICT:
		var bed_pose := _sidewalk_pose(rng)
		var bed := Node3D.new()
		bed.set_script(BED_SCRIPT)
		bed.rotation.y = atan2(bed_pose[1].x, bed_pose[1].z)
		root.add_child(bed)
		bed.global_position = root.global_position + bed_pose[0]
	var extra := 0
	for part in EXTRA_PARTS.get(district_id, []):
		var part_pos := _scatter(root, rng)
		var part_key := "%s:x%d" % [district_id, extra]
		extra += 1
		if not ProgressTracker.is_loot_taken(part_key):
			_spawn_item(root, part, part_pos, int(PICKUP_AMOUNT.get(part, 1)), part_key)
	var index: int = DistrictSceneFactory.DISTRICTS.find(district_id)
	var ammo_count: int = 0 if index <= 0 else (1 if index < AMMO_DOUBLE_FROM else 2)
	for i in ammo_count:
		var ammo_pos := _scatter(root, rng)
		var ammo_key := "%s:a%d" % [district_id, i]
		if not ProgressTracker.is_loot_taken(ammo_key):
			_spawn_pickup(root, AMMO_PICKUP_SCENE, ammo_pos, "", AMMO_PER_PICKUP, ammo_key)

## A weapon or ammo pickup (Area3D scenes in scenes/pickups); `weapon` names the gun, "" is plain ammo.
static func _spawn_pickup(root: Node3D, scene: PackedScene, pos: Vector3, weapon: String, ammo: int = 0, key: String = "") -> void:
	var node := scene.instantiate() as Node3D
	if weapon != "":
		node.set("weapon_name", weapon)
	if ammo > 0:
		node.set("ammo_amount", ammo)
	node.set("loot_key", key)
	root.add_child(node)
	node.global_position = pos

## static funcs have no self/get_node - same autoload-access pattern as
## core/endings.gd's _root().
static func _skill_level(skill_id: StringName) -> int:
	var stm := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("/root/SkillTreeManager")
	return stm.get_skill_level(skill_id) if stm else 0
