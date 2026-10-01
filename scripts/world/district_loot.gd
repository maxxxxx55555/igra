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
const COMMON: Array[StringName] = [&"battery", &"battery", &"scrap", &"medkit"]

## Три детали, за которые щит района поднимает стадию (см. power_switch.gd:
## кабель -> PARTIAL, предохранитель -> STREETS, транзистор -> FULL).
## Лежат в каждом районе, и это обязательное условие проходимости: район
## открывается только после того, как предыдущий доведён до FULL, поэтому
## недостающую деталь физически неоткуда принести — игрок запирался бы
## в пригороде навсегда. Здесь их по две штуки: запас на случай, если
## игрок потратит деталь на соседний район.
const REPAIR_PARTS: Array[StringName] = [
	&"cable", &"cable", &"fuse", &"fuse", &"transistor", &"transistor",
]

## Тематический набор района — то, ради чего в него имеет смысл заходить.
const BY_DISTRICT: Dictionary = {
	&"suburbs":       [&"battery", &"scrap", &"cable"],
	&"residential":   [&"medkit", &"battery", &"scrap"],
	&"park":          [&"scrap", &"battery", &"cable"],
	&"school":        [&"key", &"scrap", &"battery", &"paper"],
	&"hospital":      [&"medkit", &"medkit", &"serum", &"fabric", &"alcohol"],
	&"gas_station":   [&"gas_canister", &"battery", &"scrap", &"bottle"],
	&"police":        [&"key", &"medkit", &"tool", &"gunpowder", &"case"],
	&"warehouses":    [&"cable", &"fuse", &"scrap"],
	&"industrial":    [&"fuse", &"transistor", &"gear", &"metal"],
	&"substation":    [&"fuse", &"cable", &"transistor"],
	&"power_station": [&"fuse", &"transistor", &"medkit"],
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

## Content-authored lore packs (content/districts/<id>/lore_notes.json),
## one district at a time as ARENA's district passes land. Spawned the same
## way as DOCUMENTS above, just several per district instead of one.
const LORE_DOCS: Dictionary = {
	&"suburbs": [
		"suburbs_note_01", "suburbs_note_02", "suburbs_note_03", "suburbs_note_04",
		"suburbs_note_05", "suburbs_note_06", "suburbs_note_07", "suburbs_note_08",
	],
	&"residential": [
		"residential_note_01", "residential_note_02", "residential_note_03", "residential_note_04",
		"residential_note_05", "residential_note_06", "residential_note_07", "residential_note_08",
	],
	&"park": [
		"park_note_01", "park_note_02", "park_note_03", "park_note_04",
		"park_note_05", "park_note_06", "park_note_07", "park_note_08",
	],
	&"school": [
		"school_note_01", "school_note_02", "school_note_03", "school_note_04",
		"school_note_05", "school_note_06", "school_note_07", "school_note_08",
	],
	&"hospital": [
		"hospital_note_01", "hospital_note_02", "hospital_note_03", "hospital_note_04",
		"hospital_note_05", "hospital_note_06", "hospital_note_07", "hospital_note_08",
	],
	&"gas_station": [
		"gas_station_note_01", "gas_station_note_02", "gas_station_note_03", "gas_station_note_04",
		"gas_station_note_05", "gas_station_note_06", "gas_station_note_07", "gas_station_note_08",
	],
	&"police": [
		"police_note_01", "police_note_02", "police_note_03", "police_note_04",
		"police_note_05", "police_note_06", "police_note_07", "police_note_08",
	],
	&"warehouses": [
		"warehouses_note_01", "warehouses_note_02", "warehouses_note_03", "warehouses_note_04",
		"warehouses_note_05", "warehouses_note_06", "warehouses_note_07", "warehouses_note_08",
	],
	&"industrial": [
		"industrial_note_01", "industrial_note_02", "industrial_note_03", "industrial_note_04",
		"industrial_note_05", "industrial_note_06", "industrial_note_07", "industrial_note_08",
	],
	&"substation": [
		"substation_note_01", "substation_note_02", "substation_note_03", "substation_note_04",
		"substation_note_05", "substation_note_06", "substation_note_07", "substation_note_08",
	],
	&"power_station": [
		"power_station_note_01", "power_station_note_02", "power_station_note_03", "power_station_note_04",
		"power_station_note_05", "power_station_note_06", "power_station_note_07", "power_station_note_08",
	],
}

const RADIUS_MIN: float = 6.0
const RADIUS_MAX: float = 22.0
const DROP_Y: float = 0.6

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

	var items: Array[StringName] = []
	items.append_array(COMMON)
	# Static audit 2026-09-08: "loot_luck" skill was purchasable but never
	# read anywhere - buying it did nothing. Extra common-item rolls per
	# level; still fully deterministic (same seeded rng as everything else
	# in this function).
	var luck_lvl := _skill_level(&"loot_luck")
	for i in luck_lvl:
		items.append(COMMON[rng.randi() % COMMON.size()])
	items.append_array(REPAIR_PARTS)
	var themed: Array = BY_DISTRICT.get(district_id, [])
	for it in themed:
		items.append(StringName(it))
	if BLUEPRINTS.has(district_id):
		items.append(StringName(BLUEPRINTS[district_id]))

	var placed := 0
	## QA_SWARM_FINDINGS.md P1 (cheater): the item loop below used to run
	## unconditionally on every populate() call - leaving and re-entering a
	## district (world_runtime.gd rebuilds the scene each visit) restocked
	## every common item AND repair part for free, indefinitely. Secrets
	## already had this gate (_spawn_secrets below); items didn't.
	var pt := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("/root/ProgressTracker")
	var already_looted: bool = pt != null and pt.is_district_looted(String(district_id))
	if not already_looted:
		for item_id in items:
			var pos := _scatter(district_root, rng)
			if _spawn_item(district_root, item_id, pos):
				placed += 1
		if pt != null:
			pt.mark_district_looted(String(district_id))

	if DOCUMENTS.has(district_id):
		var dpos := _scatter(district_root, rng)
		if _spawn_document(district_root, String(DOCUMENTS[district_id]), dpos):
			placed += 1
	if LORE_DOCS.has(district_id):
		for doc_id in (LORE_DOCS[district_id] as Array):
			var lpos := _scatter(district_root, rng)
			if _spawn_document(district_root, String(doc_id), lpos):
				placed += 1
	placed += _spawn_secrets(district_root, district_id)
	_spawn_hiding_spots(district_root, district_id)
	_spawn_extras(district_root, district_id, already_looted)
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

static func _scatter(root: Node3D, rng: RandomNumberGenerator) -> Vector3:
	var ang := rng.randf_range(0.0, TAU)
	var rad := rng.randf_range(RADIUS_MIN, RADIUS_MAX)
	return root.global_position + _snap_to_street(Vector3(cos(ang) * rad, DROP_Y, sin(ang) * rad))

static func _spawn_item(root: Node3D, item_id: StringName, pos: Vector3, count: int = 1) -> bool:
	var node := PICKUP_SCENE.instantiate() as Node3D
	if node == null:
		return false
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
const PICKUP_AMOUNT: Dictionary = {&"plank": 5}
const AMMO_PER_PICKUP: int = 12
## Ammo lies in every district but the first, twice from the sixth on (police): the guns come late.
const AMMO_DOUBLE_FROM: int = 6
const WORKBENCH_DISTRICTS: Array[StringName] = [&"suburbs", &"police", &"industrial"]
## The bed of the "Midsummer Night's Dream" achievement stands in the first district.
const BED_DISTRICT: StringName = &"suburbs"

static func _spawn_extras(root: Node3D, district_id: StringName, already_looted: bool) -> void:
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
	if already_looted:
		return
	for part in EXTRA_PARTS.get(district_id, []):
		_spawn_item(root, part, _scatter(root, rng), int(PICKUP_AMOUNT.get(part, 1)))
	var index: int = DistrictSceneFactory.DISTRICTS.find(district_id)
	var ammo_count: int = 0 if index <= 0 else (1 if index < AMMO_DOUBLE_FROM else 2)
	for i in ammo_count:
		_spawn_pickup(root, AMMO_PICKUP_SCENE, _scatter(root, rng), "", AMMO_PER_PICKUP)

## A weapon or ammo pickup (Area3D scenes in scenes/pickups); `weapon` names the gun, "" is plain ammo.
static func _spawn_pickup(root: Node3D, scene: PackedScene, pos: Vector3, weapon: String, ammo: int = 0) -> void:
	var node := scene.instantiate() as Node3D
	if weapon != "":
		node.set("weapon_name", weapon)
	if ammo > 0:
		node.set("ammo_amount", ammo)
	root.add_child(node)
	node.global_position = pos

## static funcs have no self/get_node - same autoload-access pattern as
## core/endings.gd's _root().
static func _skill_level(skill_id: StringName) -> int:
	var stm := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("/root/SkillTreeManager")
	return stm.get_skill_level(skill_id) if stm else 0
