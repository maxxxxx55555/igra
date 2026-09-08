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
}

const RADIUS_MIN: float = 6.0
const RADIUS_MAX: float = 22.0
const DROP_Y: float = 0.6

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
	for item_id in items:
		var pos := _scatter(district_root, rng)
		if _spawn_item(district_root, item_id, pos):
			placed += 1

	if DOCUMENTS.has(district_id):
		var dpos := _scatter(district_root, rng)
		if _spawn_document(district_root, String(DOCUMENTS[district_id]), dpos):
			placed += 1
	if LORE_DOCS.has(district_id):
		for doc_id in (LORE_DOCS[district_id] as Array):
			var lpos := _scatter(district_root, rng)
			if _spawn_document(district_root, String(doc_id), lpos):
				placed += 1
	return placed

static func _scatter(root: Node3D, rng: RandomNumberGenerator) -> Vector3:
	var ang := rng.randf_range(0.0, TAU)
	var rad := rng.randf_range(RADIUS_MIN, RADIUS_MAX)
	return root.global_position + Vector3(cos(ang) * rad, DROP_Y, sin(ang) * rad)

static func _spawn_item(root: Node3D, item_id: StringName, pos: Vector3) -> bool:
	var node := PICKUP_SCENE.instantiate() as Node3D
	if node == null:
		return false
	root.add_child(node)
	node.global_position = pos
	if node.has_method("set_item"):
		node.call("set_item", item_id, 1)
	return true

static func _spawn_document(root: Node3D, doc_id: String, pos: Vector3) -> bool:
	var node := DOC_SCENE.instantiate() as Node3D
	if node == null:
		return false
	root.add_child(node)
	node.global_position = pos
	node.set("document_id", doc_id)
	return true

## static funcs have no self/get_node - same autoload-access pattern as
## core/endings.gd's _root().
static func _skill_level(skill_id: StringName) -> int:
	var stm := Engine.get_main_loop().root.get_node_or_null("/root/SkillTreeManager")
	return stm.get_skill_level(skill_id) if stm else 0
