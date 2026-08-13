class_name DistrictSceneFactory
extends Node

const DISTRICTS: Array[StringName] = [
	&"suburbs", &"residential", &"park", &"school", &"hospital",
	&"gas_station", &"police", &"warehouses", &"industrial",
	&"substation", &"power_station",
]
const ENEMY_POOL_SCRIPT: Script = preload("res://scripts/enemies/enemy_pool.gd")
const LOOT_SCRIPT: Script = preload("res://scripts/world/district_loot.gd")
const HIDING_SPOT_SCRIPT: Script = preload("res://scripts/gameplay/hiding_spot.gd")

## Укрытия (GDD S2.3). Класс HidingSpot был написан целиком — с мешем,
## коллизией и подсказкой, — но его никто не создавал в мире, поэтому
## спрятаться от монстра было физически негде. Расставляем по району
## детерминированно, тем же приёмом, что и лут.
const HIDING_SPOT_TYPES: Array[String] = ["locker", "dumpster", "car", "crate"]
const HIDING_SPOTS_PER_DISTRICT: int = 5
const HIDING_RADIUS_MIN: float = 8.0
const HIDING_RADIUS_MAX: float = 24.0

static func build(parent: Node, district_id: StringName) -> Node3D:
	var resolved_id: StringName = district_id if DISTRICTS.has(district_id) else &"suburbs"
	var scene_path: String = "res://scenes/districts/%s.tscn" % String(resolved_id)
	if ResourceLoader.exists(scene_path):
		var district_scene: PackedScene = load(scene_path) as PackedScene
		if district_scene != null:
			var district_root: Node3D = district_scene.instantiate() as Node3D
			if district_root != null:
				parent.add_child(district_root)
				_spawn_district_enemies(district_root)
				LOOT_SCRIPT.populate(district_root, resolved_id)
				_spawn_hiding_spots(district_root, resolved_id)
				EventBus.district_entered.emit(resolved_id)
				return district_root
	var root: Node3D = Node3D.new()
	root.name = StringName("District_" + String(resolved_id))
	parent.add_child(root)
	var theme: Dictionary = DistrictThemes.get_theme(resolved_id)
	var world_env: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	DistrictThemes.apply_to_environment(env, resolved_id)
	world_env.environment = env
	world_env.name = "WorldEnvironment"
	root.add_child(world_env)
	var sb_script: Script = load("res://scripts/world/street_builder.gd") as Script
	if sb_script != null:
		var sb: Node3D = Node3D.new()
		sb.set_script(sb_script)
		sb.name = "StreetBuilder3D"
		sb.set("district_id", resolved_id)
		root.add_child(sb)
	var wx_script: Script = load("res://scripts/effects/weather_vfx.gd") as Script
	if wx_script != null:
		var wx: Node3D = Node3D.new()
		wx.set_script(wx_script)
		wx.name = "WeatherVFX"
		wx.set("weather_kind", String(theme.get("weather", "fog_light")))
		root.add_child(wx)
	_spawn_district_enemies(root)
	LOOT_SCRIPT.populate(root, resolved_id)
	_spawn_hiding_spots(root, resolved_id)
	EventBus.district_entered.emit(resolved_id)
	return root

## Раскладывает укрытия по кругу вокруг центра района. Seed от имени района —
## значит, расположение стабильно между перезапусками и совпадает в сетевой игре.
static func _spawn_hiding_spots(district_root: Node3D, district_id: StringName) -> void:
	if district_root == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("hiding_" + String(district_id))
	for i in HIDING_SPOTS_PER_DISTRICT:
		var spot := Node3D.new()
		spot.set_script(HIDING_SPOT_SCRIPT)
		spot.name = "HidingSpot%d" % i
		spot.set("spot_type", HIDING_SPOT_TYPES[i % HIDING_SPOT_TYPES.size()])
		district_root.add_child(spot)
		var ang := rng.randf_range(0.0, TAU)
		var rad := rng.randf_range(HIDING_RADIUS_MIN, HIDING_RADIUS_MAX)
		spot.global_position = district_root.global_position + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)

static func _spawn_district_enemies(district_root: Node3D) -> void:
	var pool: Node = ENEMY_POOL_SCRIPT.new()
	pool.name = "EnemyPool"
	district_root.add_child(pool)
	pool.spawn_for_district(district_root)

static func district_count() -> int:
	return DISTRICTS.size()

static func district_id_at(index: int) -> StringName:
	if index < 0 or index >= DISTRICTS.size():
		return &"suburbs"
	return DISTRICTS[index]
