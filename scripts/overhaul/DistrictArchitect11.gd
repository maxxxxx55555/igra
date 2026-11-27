class_name DistrictArchitect11
extends RefCounted

## Authoritative 11-District Blueprint for Last Streetlight.
## Guarantees every single district (01..11) has distinct physical dimensions (meters),
## architectural layout archetype, atmospheric palette, fog/rain intensity, enterable buildings,
## and pacing — eliminating identical grid rooms.

const DISTRICTS: Array[Dictionary] = [
	{
		"index": 1, "id": "d01_outskirts_yard",
		"name_ru": "Окраинный двор", "name_en": "Outskirts Yard",
		"width_m": 68.0, "length_m": 68.0, "layout": "courtyard_loop",
		"building_stories_min": 2, "building_stories_max": 4,
		"enterable_count": 2, "enterable_themes": ["guardhouse", "stairwell"],
		"ambient_hex": "#162632", "fog_hex": "#0c171f", "lamp_hex": "#d4a94e",
		"fog_density": 0.014, "rain_intensity": 0.25, "cold_mult": 0.85,
		"enemy_count": 2, "parts_required": 6,
		"landmark_ru": "Старая будка охраны и дворовая арка", "landmark_en": "Old guardhouse and yard archway",
	},
	{
		"index": 2, "id": "d02_wet_alleys",
		"name_ru": "Сырые переулки", "name_en": "Wet Alleys",
		"width_m": 74.0, "length_m": 64.0, "layout": "tight_alleys",
		"building_stories_min": 3, "building_stories_max": 5,
		"enterable_count": 2, "enterable_themes": ["corner_shop", "passage"],
		"ambient_hex": "#13242e", "fog_hex": "#0b161c", "lamp_hex": "#cfa24a",
		"fog_density": 0.017, "rain_intensity": 0.45, "cold_mult": 0.92,
		"enemy_count": 3, "parts_required": 6,
		"landmark_ru": "Узкие проходные дворы и лавка", "landmark_en": "Tight through-alleys and corner shop",
	},
	{
		"index": 3, "id": "d03_flicker_depot",
		"name_ru": "Трамвайное депо", "name_en": "Tram Depot",
		"width_m": 84.0, "length_m": 72.0, "layout": "depot_lanes",
		"building_stories_min": 2, "building_stories_max": 4,
		"enterable_count": 3, "enterable_themes": ["dispatcher", "workshop", "shelter"],
		"ambient_hex": "#15232b", "fog_hex": "#0d161b", "lamp_hex": "#d9a246",
		"fog_density": 0.018, "rain_intensity": 0.35, "cold_mult": 0.96,
		"enemy_count": 3, "parts_required": 6,
		"landmark_ru": "Диспетчерская и ремонтный ангар", "landmark_en": "Dispatcher cabin and repair bay",
	},
	{
		"index": 4, "id": "d04_frost_promenade",
		"name_ru": "Морозный бульвар", "name_en": "Frost Promenade",
		"width_m": 92.0, "length_m": 70.0, "layout": "wide_avenue",
		"building_stories_min": 4, "building_stories_max": 6,
		"enterable_count": 3, "enterable_themes": ["pharmacy", "foyer", "kiosk"],
		"ambient_hex": "#152b3b", "fog_hex": "#0d1d29", "lamp_hex": "#c9ad68",
		"fog_density": 0.019, "rain_intensity": 0.20, "cold_mult": 1.22,
		"enemy_count": 4, "parts_required": 6,
		"landmark_ru": "Широкая аллея с открытой аптекой", "landmark_en": "Wide icy boulevard with open pharmacy",
	},
	{
		"index": 5, "id": "d05_canal_fog",
		"name_ru": "Туманный канал", "name_en": "Foggy Canal",
		"width_m": 88.0, "length_m": 82.0, "layout": "split_canal",
		"building_stories_min": 3, "building_stories_max": 5,
		"enterable_count": 2, "enterable_themes": ["boathouse", "warehouse"],
		"ambient_hex": "#12262d", "fog_hex": "#0c1b20", "lamp_hex": "#c99f4c",
		"fog_density": 0.025, "rain_intensity": 0.55, "cold_mult": 1.06,
		"enemy_count": 4, "parts_required": 6,
		"landmark_ru": "Набережная и складские ворота", "landmark_en": "Embankment and canal warehouse",
	},
	{
		"index": 6, "id": "d06_old_market",
		"name_ru": "Старый рынок", "name_en": "Old Market",
		"width_m": 96.0, "length_m": 88.0, "layout": "market_plaza",
		"building_stories_min": 2, "building_stories_max": 5,
		"enterable_count": 3, "enterable_themes": ["pavilion", "bakery", "storage"],
		"ambient_hex": "#18242a", "fog_hex": "#10171b", "lamp_hex": "#d9a64c",
		"fog_density": 0.020, "rain_intensity": 0.40, "cold_mult": 1.10,
		"enemy_count": 5, "parts_required": 6,
		"landmark_ru": "Крытый павильон и торговые ряды", "landmark_en": "Covered market pavilion and stalls",
	},
	{
		"index": 7, "id": "d07_industrial_substation",
		"name_ru": "Подстанция-7", "name_en": "Substation 7",
		"width_m": 102.0, "length_m": 86.0, "layout": "industrial_grid",
		"building_stories_min": 2, "building_stories_max": 4,
		"enterable_count": 3, "enterable_themes": ["control_room", "turbine_hall", "guardhouse"],
		"ambient_hex": "#142228", "fog_hex": "#0b1418", "lamp_hex": "#d4983e",
		"fog_density": 0.021, "rain_intensity": 0.50, "cold_mult": 1.15,
		"enemy_count": 5, "parts_required": 6,
		"landmark_ru": "Пультовая подстанции и трансформаторы", "landmark_en": "Substation control room and transformers",
	},
	{
		"index": 8, "id": "d08_frozen_clinic",
		"name_ru": "Тихая лечебница", "name_en": "Silent Clinic",
		"width_m": 106.0, "length_m": 92.0, "layout": "hospital_campus",
		"building_stories_min": 4, "building_stories_max": 6,
		"enterable_count": 3, "enterable_themes": ["reception", "archive", "boiler_room"],
		"ambient_hex": "#132938", "fog_hex": "#0c1b26", "lamp_hex": "#c8ae74",
		"fog_density": 0.023, "rain_intensity": 0.65, "cold_mult": 1.34,
		"enemy_count": 6, "parts_required": 6,
		"landmark_ru": "Приёмный покой и внутренний сквер", "landmark_en": "Clinic reception hall and courtyard",
	},
	{
		"index": 9, "id": "d09_tenement_blocks",
		"name_ru": "Панельный массив", "name_en": "Tenement Blocks",
		"width_m": 112.0, "length_m": 98.0, "layout": "staggered_towers",
		"building_stories_min": 5, "building_stories_max": 8,
		"enterable_count": 4, "enterable_themes": ["entrance_hall", "laundry", "grocery", "shelter"],
		"ambient_hex": "#12212b", "fog_hex": "#0a1319", "lamp_hex": "#d4a448",
		"fog_density": 0.024, "rain_intensity": 0.60, "cold_mult": 1.25,
		"enemy_count": 6, "parts_required": 6,
		"landmark_ru": "Высокие подъезды и сквозные арки", "landmark_en": "Tall residential lobbies and archways",
	},
	{
		"index": 10, "id": "d10_blackout_station",
		"name_ru": "Вокзальный узел", "name_en": "Blackout Station",
		"width_m": 118.0, "length_m": 106.0, "layout": "station_concourse",
		"building_stories_min": 3, "building_stories_max": 6,
		"enterable_count": 4, "enterable_themes": ["ticket_hall", "waiting_room", "luggage", "signal_box"],
		"ambient_hex": "#101e28", "fog_hex": "#081016", "lamp_hex": "#cf9c42",
		"fog_density": 0.026, "rain_intensity": 0.75, "cold_mult": 1.32,
		"enemy_count": 7, "parts_required": 6,
		"landmark_ru": "Кассовый зал и пустые перроны", "landmark_en": "Ticket concourse and empty platforms",
	},
	{
		"index": 11, "id": "d11_last_streetlight_plaza",
		"name_ru": "Площадь Последнего Фонаря", "name_en": "Last Streetlight Plaza",
		"width_m": 124.0, "length_m": 116.0, "layout": "radial_finale_plaza",
		"building_stories_min": 5, "building_stories_max": 9,
		"enterable_count": 4, "enterable_themes": ["city_hall_foyer", "clock_base", "archive", "sanctuary_vestibule"],
		"ambient_hex": "#132330", "fog_hex": "#09131b", "lamp_hex": "#e0b052",
		"fog_density": 0.022, "rain_intensity": 0.80, "cold_mult": 1.38,
		"enemy_count": 7, "parts_required": 6,
		"landmark_ru": "Центральный монумент и ратуша", "landmark_en": "Central monument and city hall foyer",
	},
]


static func get_district(index_1_based: int) -> Dictionary:
	var idx: int = clampi(index_1_based - 1, 0, DISTRICTS.size() - 1)
	var d: Dictionary = DISTRICTS[idx].duplicate(true)
	d["area_m2"] = int(roundf(float(d["width_m"]) * float(d["length_m"])))
	return d


static func get_all_summaries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(1, DISTRICTS.size() + 1):
		out.append(get_district(i))
	return out

# Fractions of the buildable rectangle. The road builder uses the same axes for
# pavement gaps, placement and the map, so irregular blocks remain navigable.
const AXES := [
	[[-1.0, -0.36, 0.36, 1.0], [-1.0, -0.42, 0.42, 1.0]],
	[[-1.0, -0.68, 0.22, 0.58, 1.0], [-1.0, -0.25, 0.25, 1.0]],
	[[-1.0, -0.48, 0.51, 1.0], [-1.0, -0.65, -0.15, 0.31, 0.69, 1.0]],
	[[-1.0, -0.28, 0.26, 1.0], [-1.0, -0.36, 0.0, 0.41, 1.0]],
	[[-1.0, -0.36, 0.36, 1.0], [-1.0, -0.58, 0.19, 0.65, 1.0]],
	[[-1.0, -0.53, 0.47, 1.0], [-1.0, -0.44, 0.43, 1.0]],
	[[-1.0, -0.52, 0.0, 0.52, 1.0], [-1.0, -0.58, 0.0, 0.58, 1.0]],
	[[-1.0, -0.48, 0.39, 1.0], [-1.0, -0.35, 0.33, 1.0]],
	[[-1.0, -0.67, -0.16, 0.39, 0.71, 1.0], [-1.0, -0.51, -0.08, 0.52, 1.0]],
	[[-1.0, -0.39, 0.42, 1.0], [-1.0, -0.67, -0.23, 0.24, 0.66, 1.0]],
	[[-1.0, -0.53, 0.53, 1.0], [-1.0, -0.52, 0.52, 1.0]],
]

static func blueprint(district_id: StringName) -> Dictionary:
	var ids := [&"suburbs", &"residential", &"park", &"school", &"hospital", &"gas_station", &"police", &"warehouses", &"industrial", &"substation", &"power_station"]
	var index := ids.find(district_id)
	return DISTRICTS[maxi(0, index)]

static func half_size(plan: Dictionary) -> Vector2:
	return Vector2(plan.width_m, plan.length_m) * 0.5

static func interior_at(node: Node, point: Vector3) -> bool:
	for area: Area3D in node.get_tree().get_nodes_in_group("district_interiors"):
		var collider := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collider == null or collider.shape == null:
			continue
		var box := collider.shape as BoxShape3D
		var p := collider.to_local(point).abs()
		var half := box.size * 0.5
		if p.x < half.x and p.y < half.y and p.z < half.z:
			return true
	return false
