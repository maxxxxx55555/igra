class_name DistrictSceneFactory
extends Node

const DISTRICTS: Array[StringName] = [
	&"suburbs", &"residential", &"park", &"school", &"hospital",
	&"gas_station", &"police", &"warehouses", &"industrial",
	&"substation", &"power_station",
]
const ENEMY_POOL_SCRIPT: Script = preload("res://scripts/enemies/enemy_pool.gd")

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
	EventBus.district_entered.emit(resolved_id)
	return root

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
