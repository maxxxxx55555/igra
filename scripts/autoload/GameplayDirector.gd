extends Node
## Scene contract: player, flashlight, streetlamp, fuse_pickup (integer metadata
## fuse_slot, 0..2), substation, darkness_exit, architect, and shelter groups.
## Interact within reach or call interact() from a touch button. A substation
## may have a RepairPoint child at its panel for first-person aiming.
## The substation can salvage missing fuses. If absent, the district entry acts
## as the service point. State transitions are committed before cues are sent.

enum Objective { FIND_FUSES, RESTORE_POWER, STEALTH_DARKNESS, BOSS_ARCHITECT, DISTRICT_VICTORY }
enum Architect { STALK, TELEGRAPH_SURGE, STAGGERED_CORE }

signal objective_changed(stage: Objective, fuse_count: int)
signal repair_changed(progress: float, spark_pending: bool)
signal survival_changed(battery: float, warmth: float)
signal architect_cue(phase: Architect, duration: float)
signal repair_spark(at: Vector3)
signal boss_telegraph(at: Vector3)
signal core_registered(hitbox: Area3D)
signal hit_stop_requested(seconds: float)
signal camera_impulse_requested(strength: float)
signal district_won(hope: int, streak: int)

@export var player_path: NodePath
@export var flashlight_path: NodePath
@export var vault_path: NodePath = ^"/root/SecurityVault"
@export var interact_action: StringName = &"interact"
@export_range(0.5, 8.0, 0.1) var reach: float = 3.2
@export_flags_3d_physics var core_layer: int = 1 << 8

var objective: Objective = Objective.FIND_FUSES
var architect_phase: Architect = Architect.STALK
var battery: float:
	get: return SecurityVault.get_guarded_float("runtime_survival_battery", 100.0)
	set(value):
		if is_finite(value):
			SecurityVault.set_guarded_float("runtime_survival_battery", clampf(value, 0.0, 100.0))
var warmth: float:
	get: return SecurityVault.get_guarded_float("runtime_survival_warmth", 100.0)
	set(value):
		if is_finite(value):
			SecurityVault.set_guarded_float("runtime_survival_warmth", clampf(value, 0.0, 100.0))
var hope: int = 0
var streak: int = 0
var core_hp: float = 100.0
## Set by Wave2GameBridge from the active district mutator + authored cold_mult.
var tension_cold_mult: float = 1.0
var repair_progress: float = 0.0
var fuse_mask: int = 0

var _vault: Node
var _entry: Vector3
var _has_entry: bool = false
var _last_scene: Node
var _repair_running: bool = false
var _repair_wait: float = 0.0
var _spark_time: float = 0.0
var _spark_count: int = 0
var _dark_time: float = 0.0
var _phase_left: float = 0.0
var _unreachable_time: float = 0.0
var _use_projection: bool = false
var _core: Area3D
var _core_visual: MeshInstance3D
var _fallback_architect: Node3D
var _save_clock: float = 0.0
var _meter_clock: float = 0.0
var _scene_clock: float = 0.0
var _last_day: int = -1
var _loaded: bool = false
var _search_time: float = 0.0
var _int_default: bool = false
var _float_default: bool = false
var _spent_lamp: SpotLight3D
var _lamp_baselines: Dictionary = {}
var _flash_baselines: Dictionary = {}


func _ready() -> void:
	add_to_group(&"gameplay_director")
	# Resolve after sibling autoloads have completed their ready callbacks.
	_initialize_district.call_deferred()


func _initialize_district() -> void:
	if not is_inside_tree():
		return
	_vault = get_node_or_null(vault_path)
	_validate_vault()
	load_progress()


func _player() -> Node3D:
	if not player_path.is_empty():
		var explicit: Node3D = get_node_or_null(player_path) as Node3D
		if is_instance_valid(explicit):
			return explicit
	return get_tree().get_first_node_in_group(&"player") as Node3D


func _flashlight() -> SpotLight3D:
	if not flashlight_path.is_empty():
		var explicit: SpotLight3D = get_node_or_null(flashlight_path) as SpotLight3D
		if is_instance_valid(explicit):
			return explicit
	return get_tree().get_first_node_in_group(&"flashlight") as SpotLight3D


func _physics_process(delta: float) -> void:
	delta = clampf(delta, 0.0, 0.05) if is_finite(delta) else 0.0
	if not _loaded:
		return
	var actor: Node3D = _player()
	if actor == null:
		_fog_tick(delta)
		return
	if not _has_entry or _last_scene != get_tree().current_scene:
		_last_scene = get_tree().current_scene
		_entry = actor.global_position
		_has_entry = true
		_repair_running = false
		_refresh_scene()
	_scene_clock += delta
	if _scene_clock >= 0.5:
		_scene_clock = 0.0
		_refresh_scene()
	if objective != Objective.DISTRICT_VICTORY:
		_tick_survival(actor, delta)
	match objective:
		Objective.FIND_FUSES:
			_search_time += delta
		Objective.RESTORE_POWER:
			_repair_wait += delta
			_tick_repair(actor, delta)
		Objective.STEALTH_DARKNESS:
			_dark_time += delta
			var exit_node: Node3D = get_tree().get_first_node_in_group(&"darkness_exit") as Node3D
			if (exit_node != null and actor.global_position.distance_to(exit_node.global_position) <= reach) or _dark_time >= 75.0:
				enter_boss_arena()
		Objective.BOSS_ARCHITECT:
			_ensure_core(actor)
			_tick_architect(delta)
	_fog_tick(delta)
	_save_clock += delta
	if _save_clock >= 20.0:
		save_progress()


func _unhandled_input(event: InputEvent) -> void:
	var action: StringName = interact_action if InputMap.has_action(interact_action) else &"ui_accept"
	if event.is_action_pressed(action) and interact():
		get_viewport().set_input_as_handled()


func _station_position() -> Vector3:
	var station: Node3D = get_tree().get_first_node_in_group(&"substation") as Node3D
	if station == null:
		return _entry
	# A blocked or unloaded substation can also be serviced at district entry.
	var actor: Node3D = _player()
	if _repair_wait >= 60.0 and actor != null and actor.global_position.distance_to(_entry) <= reach:
		return _entry
	var panel: Node3D = station.get_node_or_null(^"RepairPoint") as Node3D
	return panel.global_position if panel != null else station.global_position


func _facing_panel(actor: Node3D) -> bool:
	var camera: Camera3D = actor.get_viewport().get_camera_3d()
	var panel := _station_position()
	if camera == null or panel.is_equal_approx(_entry):
		return true
	var offset := panel - camera.global_position
	return offset.length_squared() < 0.04 or -camera.global_basis.z.normalized().dot(offset.normalized()) >= 0.35


func _slot(node: Node) -> int:
	return int(node.get_meta(&"fuse_slot", -1))


func fuse_count() -> int:
	return (fuse_mask & 1) + ((fuse_mask >> 1) & 1) + ((fuse_mask >> 2) & 1)


func collect_fuse(slot: int) -> bool:
	if objective != Objective.FIND_FUSES or slot < 0 or slot > 2 or (fuse_mask & (1 << slot)) != 0:
		return false
	fuse_mask |= 1 << slot
	_search_time = 0.0
	_refresh_fuses()
	if fuse_mask == 7:
		_transition(Objective.RESTORE_POWER)
	else:
		save_progress()
		objective_changed.emit(objective, fuse_count())
	return true


func interact() -> bool:
	var actor: Node3D = _player()
	if actor == null or not _has_entry:
		return false
	var at_station: bool = actor.global_position.distance_to(_station_position()) <= reach
	match objective:
		Objective.FIND_FUSES:
			for node: Node in get_tree().get_nodes_in_group(&"fuse_pickup"):
				var item: Node3D = node as Node3D
				if item != null and item.is_visible_in_tree() and actor.global_position.distance_to(item.global_position) <= reach and collect_fuse(_slot(item)):
					return true
			if at_station:
				# Give placed pickups a search window before allowing emergency salvage.
				for slot: int in range(3):
					if (not _has_placed_fuse(slot) or _search_time >= 90.0) and collect_fuse(slot):
						return true
		Objective.RESTORE_POWER:
			if at_station and _facing_panel(actor):
				if _spark_time > 0.0:
					_clear_spark()
				_repair_running = true
				return true
		Objective.BOSS_ARCHITECT:
			if is_instance_valid(_core) and actor.global_position.distance_to(_core.global_position) <= reach:
				return hit_core(_core, 34.0)
	return false


func _tick_repair(actor: Node3D, delta: float) -> void:
	if not _repair_running:
		return
	if actor.global_position.distance_to(_station_position()) > reach or not _facing_panel(actor):
		_repair_running = false
		return
	if _spark_time > 0.0:
		_spark_time -= delta
		if _spark_time <= 0.0:
			warmth = maxf(0.0, warmth - 3.0)
			_clear_spark()
		return
	var threshold: float = minf(1.0, float(_spark_count + 1) / 3.0)
	repair_progress = minf(threshold, repair_progress + delta / 6.0)
	if repair_progress >= 1.0:
		_transition(Objective.STEALTH_DARKNESS)
	elif repair_progress >= threshold:
		_spark_time = 1.1
		repair_spark.emit(_station_position())
	repair_changed.emit(repair_progress, _spark_time > 0.0)


func _clear_spark() -> void:
	_spark_time = 0.0
	_spark_count = mini(2, _spark_count + 1)
	repair_changed.emit(repair_progress, false)


func enter_boss_arena() -> bool:
	if objective != Objective.STEALTH_DARKNESS:
		return false
	_transition(Objective.BOSS_ARCHITECT)
	return true


func _transition(next: Objective) -> void:
	objective = next
	if next == Objective.BOSS_ARCHITECT:
		_unreachable_time = 0.0
		_use_projection = false
		_set_phase(Architect.STALK)
	if next == Objective.DISTRICT_VICTORY:
		_remove_core()
	_refresh_scene()
	save_progress()
	objective_changed.emit(objective, fuse_count())
	if next == Objective.DISTRICT_VICTORY:
		district_won.emit(hope, streak)


func new_game_plus() -> bool:
	if objective != Objective.DISTRICT_VICTORY:
		return false
	hope = mini(hope + 1, 99)
	_repair_wait = 0.0
	fuse_mask = 0
	repair_progress = 0.0
	_repair_running = false
	_spark_count = 0
	_spark_time = 0.0
	_dark_time = 0.0
	core_hp = 100.0
	battery = 100.0
	warmth = 100.0
	_has_entry = false
	_search_time = 0.0
	_fog_reset()
	_transition(Objective.FIND_FUSES)
	return true


func difficulty_multiplier() -> float:
	return 1.0 + 0.12 * float(mini(hope, 10))


func _has_placed_fuse(slot: int) -> bool:
	for node: Node in get_tree().get_nodes_in_group(&"fuse_pickup"):
		var item: Node3D = node as Node3D
		if item != null and item.is_visible_in_tree() and not item.is_queued_for_deletion() and _slot(item) == slot:
			return true
	return false


func _refresh_fuses() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"fuse_pickup"):
		var item: Node3D = node as Node3D
		var slot: int = _slot(node)
		if item == null or slot < 0 or slot > 2:
			continue
		if (fuse_mask & (1 << slot)) != 0:
			if not item.has_meta(&"_district_visible"):
				item.set_meta(&"_district_visible", item.visible)
				item.set_meta(&"_district_process", item.process_mode)
				item.hide()
				item.set_deferred(&"process_mode", Node.PROCESS_MODE_DISABLED)
		elif item.has_meta(&"_district_visible"):
			item.visible = bool(item.get_meta(&"_district_visible"))
			item.set_deferred(&"process_mode", int(item.get_meta(&"_district_process")))
			item.remove_meta(&"_district_visible")
			item.remove_meta(&"_district_process")


func _refresh_scene() -> void:
	_refresh_fuses()
	var dim: bool = objective == Objective.STEALTH_DARKNESS or objective == Objective.BOSS_ARCHITECT
	for node: Node in get_tree().get_nodes_in_group(&"streetlamp"):
		var lamp: Light3D = node as Light3D
		if lamp != null:
			var id: int = lamp.get_instance_id()
			if dim:
				if not _lamp_baselines.has(id):
					_lamp_baselines[id] = lamp.light_energy
				lamp.light_energy = float(_lamp_baselines[id]) * 0.8
			elif _lamp_baselines.has(id):
				lamp.light_energy = float(_lamp_baselines[id])
				_lamp_baselines.erase(id)
	var flash: SpotLight3D = _flashlight()
	if flash != null:
		var id: int = flash.get_instance_id()
		if dim:
			if not _flash_baselines.has(id):
				_flash_baselines[id] = flash.spot_range
			flash.spot_range = 14.0
		elif _flash_baselines.has(id):
			flash.spot_range = float(_flash_baselines[id])
			_flash_baselines.erase(id)


func _tick_survival(actor: Node3D, delta: float) -> void:
	var flash: SpotLight3D = _flashlight()
	var lit: bool = flash != null and flash.is_visible_in_tree() and flash.light_energy > 0.0
	var sheltered: bool = false
	for node: Node in get_tree().get_nodes_in_group(&"shelter"):
		var heat: Node3D = node as Node3D
		if heat != null and actor.global_position.distance_squared_to(heat.global_position) <= 25.0:
			sheltered = true
			break
	var difficulty: float = difficulty_multiplier()
	battery = clampf(battery + delta * (-0.42 * difficulty if lit else 1.25), 0.0, 100.0)
	warmth = clampf(warmth + delta * (2.4 if sheltered else -0.085 * difficulty * clampf(tension_cold_mult, 0.5, 2.0)), 0.0, 100.0)
	if lit and battery <= 0.0:
		flash.visible = false
		_spent_lamp = flash
	elif is_instance_valid(_spent_lamp) and _spent_lamp == flash and battery >= 15.0:
		flash.visible = true
		_spent_lamp = null
	_meter_clock += delta
	if _meter_clock >= 0.25:
		_meter_clock = 0.0
		_sync_meters()
		survival_changed.emit(battery, warmth)


func _ensure_core(actor: Node3D) -> void:
	var boss: Node3D = get_tree().get_first_node_in_group(&"architect") as Node3D
	if boss == null or _use_projection:
		if not is_instance_valid(_fallback_architect):
			_fallback_architect = Node3D.new()
			_fallback_architect.name = &"EmergencyArchitect"
			add_child(_fallback_architect)
			_fallback_architect.global_position = actor.global_position - actor.global_transform.basis.z.normalized() * 2.5
		boss = _fallback_architect
	if is_instance_valid(_core) and _core.get_parent() == boss:
		return
	_remove_core(false)
	_core = Area3D.new()
	_core.name = &"ArchitectCore"
	_core.collision_layer = core_layer
	_core.collision_mask = 0
	_core.monitoring = false
	boss.add_child(_core)
	_core.position = Vector3.UP
	var collider: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.65
	collider.shape = sphere
	_core.add_child(collider)
	var skin: SphereMesh = SphereMesh.new()
	skin.radius = 0.28
	skin.height = 0.56
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("#D99B38")
	skin.material = material
	_core_visual = MeshInstance3D.new()
	_core_visual.mesh = skin
	_core.add_child(_core_visual)
	_core_visual.visible = architect_phase != Architect.STALK
	core_registered.emit(_core)


func architect_position() -> Vector3:
	return _core.global_position if is_instance_valid(_core) else Vector3.INF


func _remove_core(remove_fallback: bool = true) -> void:
	if is_instance_valid(_core):
		_core.queue_free()
	_core = null
	_core_visual = null
	if remove_fallback and is_instance_valid(_fallback_architect):
		_fallback_architect.queue_free()
		_fallback_architect = null


func _set_phase(phase: Architect) -> void:
	architect_phase = phase
	match phase:
		Architect.STALK:
			_phase_left = 3.5 / difficulty_multiplier()
		Architect.TELEGRAPH_SURGE:
			_phase_left = 1.7
			if is_instance_valid(_core):
				boss_telegraph.emit(_core.global_position)
		Architect.STAGGERED_CORE:
			_phase_left = 3.0
	if is_instance_valid(_core_visual):
		_core_visual.visible = phase != Architect.STALK
	architect_cue.emit(phase, _phase_left)


func _tick_architect(delta: float) -> void:
	# If an authored boss is inaccessible or its controller stalls, project a
	# reachable core after a bounded interval without a successful strike.
	_unreachable_time += delta
	if _unreachable_time >= 75.0:
		_unreachable_time = 0.0
		_use_projection = true
		if is_instance_valid(_fallback_architect):
			var rescuer: Node3D = _player()
			if rescuer != null:
				_fallback_architect.global_position = rescuer.global_position - rescuer.global_transform.basis.z.normalized() * 2.5
	if architect_phase == Architect.STALK and is_instance_valid(_fallback_architect) and is_instance_valid(_core) and _core.get_parent() == _fallback_architect:
		var prey: Node3D = _player()
		if prey != null:
			var destination: Vector3 = prey.global_position
			destination.y = _fallback_architect.global_position.y
			if destination.distance_to(_fallback_architect.global_position) > 1.8:
				_fallback_architect.global_position = _fallback_architect.global_position.move_toward(destination, delta * 1.7 * difficulty_multiplier())
	_phase_left -= delta
	if _phase_left > 0.0:
		return
	match architect_phase:
		Architect.STALK:
			_set_phase(Architect.TELEGRAPH_SURGE)
		Architect.TELEGRAPH_SURGE:
			var actor: Node3D = _player()
			if actor != null and is_instance_valid(_core) and actor.global_position.distance_to(_core.global_position) < 4.0:
				warmth = maxf(0.0, warmth - 5.0 * difficulty_multiplier())
				camera_impulse_requested.emit(0.3)
			_set_phase(Architect.STAGGERED_CORE)
		Architect.STAGGERED_CORE:
			_set_phase(Architect.STALK)


## Projectile/raycast callers pass the Area3D collider. Repeated hits from
## the same shot are rejected because a valid hit closes the damage window.
func hit_core(collider: Object, damage: float) -> bool:
	if objective != Objective.BOSS_ARCHITECT or architect_phase != Architect.STAGGERED_CORE:
		return false
	if not is_instance_valid(_core) or collider != _core or not is_finite(damage) or damage <= 0.0:
		return false
	_unreachable_time = 0.0
	var floor_hp: float = 66.0 if core_hp > 66.0 else (33.0 if core_hp > 33.0 else 0.0)
	core_hp = maxf(floor_hp, core_hp - damage)
	if core_hp <= 0.0:
		_transition(Objective.DISTRICT_VICTORY)
	else:
		_set_phase(Architect.STALK)
		save_progress()
	hit_stop_requested.emit(0.055)
	camera_impulse_requested.emit(0.65)
	return true


# Accept both getter(key) and getter(key, default). Other signatures are
# rejected before invoking the service, keeping a standalone district playable.
func _validate_vault() -> void:
	if _vault == null:
		return
	var count: int = 0
	for method: Dictionary in _vault.get_method_list():
		var method_name: StringName = method["name"]
		var args: Array = method["args"]
		var defaults: Array = method["default_args"]
		var required: int = args.size() - defaults.size()
		match method_name:
			&"load_game", &"save_game":
				if required == 0:
					count += 1
			&"get_guarded_int", &"get_guarded_float":
				if args.size() >= 1 and required <= 2:
					count += 1
					if method_name == &"get_guarded_int":
						_int_default = args.size() >= 2
					else:
						_float_default = args.size() >= 2
			&"set_guarded_int", &"set_guarded_float":
				if args.size() >= 2 and required <= 2:
					count += 1
	if count != 6:
		push_warning("SecurityVault has an incompatible district persistence interface.")
		_vault = null


func _set_i(key: String, value: int) -> void:
	if is_instance_valid(_vault):
		_vault.call(&"set_guarded_int", "district_" + key, value)


func _get_i(key: String, fallback: int) -> int:
	if not is_instance_valid(_vault):
		return fallback
	var value: Variant = _vault.call(&"get_guarded_int", "district_" + key, fallback) if _int_default else _vault.call(&"get_guarded_int", "district_" + key)
	return int(value) if typeof(value) == TYPE_INT else fallback


func _get_f(key: String, fallback: float, lo: float, hi: float) -> float:
	var value: Variant = _vault.call(&"get_guarded_float", "district_" + key, fallback) if _float_default else _vault.call(&"get_guarded_float", "district_" + key)
	if (typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT) and is_finite(float(value)):
		return clampf(float(value), lo, hi)
	return fallback


func load_progress() -> void:
	_repair_wait = 0.0
	if is_instance_valid(_vault):
		_vault.call(&"load_game")
		if _get_i("version", 0) == 1:
			objective = clampi(_get_i("stage", 0), 0, 4) as Objective
			fuse_mask = _get_i("fuses", 0) & 7
			hope = clampi(_get_i("hope", 0), 0, 99)
			streak = maxi(0, _get_i("streak", 0))
			_last_day = _get_i("day", -1)
			battery = _get_f("battery", 100.0, 0.0, 100.0)
			warmth = _get_f("warmth", 100.0, 0.0, 100.0)
			repair_progress = _get_f("repair", 0.0, 0.0, 1.0)
			core_hp = _get_f("core", 100.0, 0.0, 100.0)
			_dark_time = _get_f("dark", 0.0, 0.0, 75.0)
	# Reconcile checkpoints interrupted at a threshold.
	if fuse_mask == 7 and objective == Objective.FIND_FUSES:
		objective = Objective.RESTORE_POWER
	if objective >= Objective.RESTORE_POWER:
		fuse_mask = 7
	if objective == Objective.RESTORE_POWER and repair_progress >= 1.0:
		objective = Objective.STEALTH_DARKNESS
	if objective >= Objective.STEALTH_DARKNESS:
		repair_progress = 1.0
	_spark_count = mini(2, floori(repair_progress * 3.0))
	_spark_time = 0.0
	_repair_running = false
	if objective == Objective.BOSS_ARCHITECT and core_hp <= 0.0:
		objective = Objective.DISTRICT_VICTORY
	if objective == Objective.BOSS_ARCHITECT:
		_set_phase(Architect.STALK)
	else:
		_remove_core()
	_loaded = true
	_fog_reload()
	_refresh_scene()
	_update_day()
	save_progress()
	objective_changed.emit(objective, fuse_count())
	survival_changed.emit(battery, warmth)


func _update_day() -> void:
	var day: int = floori(Time.get_unix_time_from_system() / 86400.0)
	if day > _last_day:
		streak = mini(streak + 1, 1000000) if day == _last_day + 1 else 1
		_last_day = day


func _sync_meters() -> void:
	if is_instance_valid(_vault):
		_vault.call(&"set_guarded_float", "district_battery", battery)
		_vault.call(&"set_guarded_float", "district_warmth", warmth)
		_vault.call(&"set_guarded_float", "battery", battery)
		_vault.call(&"set_guarded_float", "warmth", warmth)


func save_progress() -> void:
	_save_clock = 0.0
	if not _loaded or not is_instance_valid(_vault):
		return
	_update_day()
	_sync_meters()
	_fog_flush()
	_vault.call(&"set_guarded_int", "district_version", 1)
	_vault.call(&"set_guarded_int", "district_stage", objective)
	_vault.call(&"set_guarded_int", "district_fuses", fuse_mask)
	_vault.call(&"set_guarded_int", "district_hope", hope)
	_vault.call(&"set_guarded_int", "district_streak", streak)
	_vault.call(&"set_guarded_int", "district_day", _last_day)
	_vault.call(&"set_guarded_float", "district_repair", repair_progress)
	_vault.call(&"set_guarded_float", "district_core", core_hp)
	_vault.call(&"set_guarded_float", "district_dark", _dark_time)
	_vault.call(&"save_game")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_progress()


# A white pixel records an explored road edge or building outline. Dynamic markers
# are separate CanvasItems. Place Path3D curves in "map_outline" or register world
# polylines. World X increases rightwards and world Z increases down the map.
@export_group("District map")
@export var fog_world_origin: Vector2 = Vector2(-128.0, -128.0)
@export_range(32, 1024) var fog_resolution: int = 256
@export_range(0.25, 8.0) var fog_meters_per_pixel: float = 1.0
@export_range(2.0, 64.0) var fog_observer_radius: float = 24.0
@export_flags_3d_physics var fog_occluder_mask: int = 0xffffffff
@export var fog_map_id: String = "district_01"
var fog_texture: ImageTexture
var _fog_image: Image
var _fog_samples: Dictionary[Vector2i, Vector3] = {}
var _fog_paths: Dictionary[int, bool] = {}
var _fog_marker_targets: Dictionary[int, int] = {}
var _fog_lights: Array[Light3D] = []
var _fog_scene_id: int = -1
var _fog_world_id: int = 0
var _fog_ray_budget: int = 0
var _fog_world: World3D
var _fog_refresh: float = 0.0
var _fog_index: int = 0
var _fog_dirty: bool = false

func _fog_init_map() -> void:
	if _fog_image != null:
		return
	_fog_image = Image.create_empty(fog_resolution, fog_resolution, false, Image.FORMAT_L8)
	_fog_image.fill(Color.BLACK)
	fog_texture = ImageTexture.create_from_image(_fog_image)

func _fog_sync_context() -> void:
	var scene: Node = get_tree().current_scene
	var scene_id: int = scene.get_instance_id() if scene != null else 0
	var observer: Node3D = _player()
	var world: World3D = observer.get_world_3d() if is_instance_valid(observer) and observer.is_inside_tree() else null
	var world_id: int = world.get_instance_id() if world != null else 0
	if ((_fog_scene_id > 0 and _fog_scene_id != scene_id)
			or (_fog_world_id != 0 and world_id != 0 and _fog_world_id != world_id)):
		_fog_flush()
		_fog_samples.clear()
		_fog_paths.clear()
		_fog_reload()
	_fog_scene_id = scene_id
	if world_id != 0:
		_fog_world_id = world_id

func fog_world_to_pixel(point: Vector3) -> Vector2i:
	return Vector2i(((Vector2(point.x, point.z) - fog_world_origin) / fog_meters_per_pixel).floor())

func register_map_outline(points: PackedVector3Array, closed: bool = false) -> void:
	_fog_sync_context()
	_fog_init_map()
	if points.size() < 2:
		return
	var bounds := Rect2i(0, 0, fog_resolution, fog_resolution)
	for i: int in range(points.size() - 1 + int(closed)):
		var start: Vector3 = points[i]
		var end: Vector3 = points[(i + 1) % points.size()]
		var span := Vector2(end.x - start.x, end.z - start.z).abs()
		var steps: int = maxi(1, ceili(maxf(span.x, span.y) * 2.0 / fog_meters_per_pixel))
		for j: int in range(steps + 1):
			var point := start.lerp(end, float(j) / float(steps))
			var pixel := fog_world_to_pixel(point)
			if bounds.has_point(pixel) and not _fog_samples.has(pixel):
				_fog_samples[pixel] = point + Vector3.UP * 0.08
				_fog_restore_pixel(pixel)

# Register the map icon, not the enemy mesh. Unregister an item when collected
# if the pickup is pooled and remains visible in its scene.
func register_map_marker(target: Node3D, icon: CanvasItem) -> void:
	if is_instance_valid(target) and is_instance_valid(icon):
		icon.hide()
		_fog_marker_targets[icon.get_instance_id()] = target.get_instance_id()

func unregister_map_marker(icon: CanvasItem) -> void:
	if is_instance_valid(icon):
		_fog_marker_targets.erase(icon.get_instance_id())
		icon.hide()

func _fog_tick(delta: float) -> void:
	_fog_sync_context()
	_fog_init_map()
	var observer: Node3D = _player()
	_fog_lights.clear()
	_fog_world = null
	if is_instance_valid(observer) and observer.is_inside_tree():
		_fog_world = observer.get_world_3d()
		var torch: SpotLight3D = _flashlight()
		if is_instance_valid(torch):
			_fog_add_light(torch)
		for lamp: Node in get_tree().get_nodes_in_group(&"streetlamp"):
			if lamp is Light3D:
				_fog_add_light(lamp as Light3D)
	for id: int in _fog_marker_targets.keys():
		var icon := instance_from_id(id) as CanvasItem
		var target := instance_from_id(_fog_marker_targets[id]) as Node3D
		if icon == null or target == null:
			if icon != null:
				icon.hide()
			_fog_marker_targets.erase(id)
		else:
			icon.visible = (not _fog_lights.is_empty() and target.is_inside_tree()
				and target.is_visible_in_tree() and not target.is_queued_for_deletion()
				and target.get_world_3d() == observer.get_world_3d()
				and observer.global_position.distance_squared_to(target.global_position)
				<= fog_observer_radius * fog_observer_radius
				and _fog_direct_light(target.global_position, target))
	_fog_refresh -= delta
	if _fog_refresh <= 0.0:
		_fog_refresh = 0.10
		update_fog_of_war()

func _fog_add_light(light: Light3D) -> void:
	if not (light is SpotLight3D or light is OmniLight3D):
		return
	if (light.is_inside_tree() and light.is_visible_in_tree() and not light.light_negative
			and light.get_world_3d() == _fog_world and light.light_energy > 0.001 and light.light_color.get_luminance() > 0.001
			and not _fog_lights.has(light)):
		var reach: float = (light as SpotLight3D).spot_range if light is SpotLight3D else (light as OmniLight3D).omni_range
		var observer: Node3D = _player()
		if light.global_position.distance_squared_to(observer.global_position) <= pow(reach + fog_observer_radius, 2.0):
			_fog_lights.append(light)

# Invoke during a physics tick. Occluding walls must have physics geometry on
# fog_occluder_mask. Omni streetlamps reveal a conservative 70-degree downward footprint.
func _fog_direct_light(point: Vector3, target: Node3D = null) -> bool:
	for light: Light3D in _fog_lights:
		if not is_instance_valid(light) or not light.is_inside_tree():
			continue
		var offset := point - light.global_position
		var distance_squared := offset.length_squared()
		if light is SpotLight3D:
			var spot := light as SpotLight3D
			if distance_squared >= spot.spot_range * spot.spot_range:
				continue
			if distance_squared > 0.000001 and (-spot.global_transform.basis.z.normalized()).dot(offset.normalized()) < cos(deg_to_rad(spot.spot_angle)):
				continue
		else:
			var omni := light as OmniLight3D
			if distance_squared >= omni.omni_range * omni.omni_range:
				continue
			if distance_squared > 0.000001 and Vector3.DOWN.dot(offset.normalized()) < 0.34202:
				continue
		if distance_squared <= 0.000001:
			return true
		var excluded: Array[RID] = []
		var owner_node: Node = light.get_parent()
		while owner_node != null:
			if owner_node is CollisionObject3D:
				excluded.append((owner_node as CollisionObject3D).get_rid())
				break
			owner_node = owner_node.get_parent()
		if target == null:
			if _fog_ray_budget <= 0:
				return false
			_fog_ray_budget -= 1
		var query := PhysicsRayQueryParameters3D.create(light.global_position, point, fog_occluder_mask, excluded)
		query.hit_from_inside = true
		var hit: Dictionary = light.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return true
		var surface: Vector3 = hit["position"]
		if target == null and point.distance_squared_to(surface) < 0.0004:
			return true
		var collider: Node = hit.get("collider") as Node
		if target != null and collider != null and (target == collider or target.is_ancestor_of(collider)):
			return true
	return false

func update_fog_of_war() -> void:
	_fog_sync_context()
	_fog_init_map()
	_fog_ray_budget = 64
	for path_node: Node in get_tree().get_nodes_in_group(&"map_outline"):
		var path := path_node as Path3D
		if path == null or path.curve == null or path.get_world_3d() != _fog_world or _fog_paths.has(path.get_instance_id()):
			continue
		var points: PackedVector3Array = path.curve.get_baked_points()
		for i: int in range(points.size()):
			points[i] = path.to_global(points[i])
		register_map_outline(points)
		_fog_paths[path.get_instance_id()] = true
	var observer: Node3D = _player()
	if is_instance_valid(observer) and observer.is_inside_tree() and not _fog_lights.is_empty():
		var center := fog_world_to_pixel(observer.global_position)
		var radius := ceili(fog_observer_radius / fog_meters_per_pixel)
		var scan := Rect2i(center - Vector2i(radius, radius), Vector2i.ONE * (2 * radius + 1))
		scan = scan.intersection(Rect2i(0, 0, fog_resolution, fog_resolution))
		var remaining: int = mini(scan.get_area(), 2048)
		var tests: int = 0
		while remaining > 0 and tests < 48 and _fog_ray_budget > 0:
			_fog_index = posmod(_fog_index, scan.get_area())
			@warning_ignore("integer_division")
			var pixel := scan.position + Vector2i(_fog_index % scan.size.x, _fog_index / scan.size.x)
			_fog_index += 1
			remaining -= 1
			if not _fog_samples.has(pixel) or _fog_image.get_pixelv(pixel).r > 0.5:
				continue
			var sample_point: Vector3 = _fog_samples[pixel]
			if observer.global_position.distance_squared_to(sample_point) > fog_observer_radius * fog_observer_radius:
				continue
			tests += 1
			if _fog_direct_light(sample_point):
				_fog_image.set_pixelv(pixel, Color.WHITE)
				_fog_record_pixel(pixel)
				_fog_dirty = true
	_fog_flush()
	if _fog_dirty:
		fog_texture.update(_fog_image)
		_fog_dirty = false

# Pack explored cells into nonnegative 30-bit words in the same Vault save.
# A new run advances the epoch, so district paths can register in any order.
var _fog_epoch: int = -1
var _fog_key_base: String = ""
var _fog_local_epoch: int = 0
var _fog_local_words: Dictionary[String, int] = {}
var _fog_words: Dictionary[int, int] = {}
var _fog_changed: Dictionary[int, bool] = {}

func _fog_open_epoch() -> void:
	if _fog_epoch < 0:
		_fog_epoch = maxi(_get_i("fog_epoch", 0), 0) if is_instance_valid(_vault) else _fog_local_epoch
	_fog_key_base = "fog_%s_%s_%s_%s_%s_" % [
		fog_map_id, _fog_epoch, fog_resolution, fog_meters_per_pixel, fog_world_origin]

func _fog_word(index: int) -> int:
	if not _fog_words.has(index):
		if _fog_key_base.is_empty():
			_fog_open_epoch()
		var key: String = _fog_key_base + str(index)
		_fog_words[index] = (_get_i(key, 0) if is_instance_valid(_vault)
			else int(_fog_local_words.get(key, 0)))
	return _fog_words[index]

func _fog_restore_pixel(pixel: Vector2i) -> void:
	var bit: int = pixel.y * fog_resolution + pixel.x
	@warning_ignore("integer_division")
	if (_fog_word(bit / 30) & (1 << (bit % 30))) != 0:
		_fog_image.set_pixelv(pixel, Color.WHITE)
		_fog_dirty = true

func _fog_record_pixel(pixel: Vector2i) -> void:
	var bit: int = pixel.y * fog_resolution + pixel.x
	@warning_ignore("integer_division")
	var index: int = bit / 30
	_fog_words[index] = _fog_word(index) | (1 << (bit % 30))
	_fog_changed[index] = true

func _fog_flush() -> void:
	for index: int in _fog_changed:
		var key: String = _fog_key_base + str(index)
		if is_instance_valid(_vault):
			_set_i(key, _fog_words[index])
		else:
			_fog_local_words[key] = _fog_words[index]
	_fog_changed.clear()

func _fog_reload() -> void:
	_fog_epoch = -1
	_fog_key_base = ""
	_fog_changed.clear()
	_fog_words.clear()
	if _fog_image != null:
		_fog_image.fill(Color.BLACK)
		for pixel: Vector2i in _fog_samples:
			_fog_restore_pixel(pixel)
		fog_texture.update(_fog_image)

func _fog_reset() -> void:
	_fog_open_epoch()
	_fog_epoch += 1
	_fog_local_epoch = _fog_epoch
	_fog_local_words.clear()
	if is_instance_valid(_vault):
		_set_i("fog_epoch", _fog_epoch)
	_fog_key_base = ""
	_fog_changed.clear()
	_fog_words.clear()
	_fog_index = 0
	for id: int in _fog_marker_targets:
		var icon := instance_from_id(id) as CanvasItem
		if icon != null:
			icon.hide()
	if _fog_image != null:
		_fog_image.fill(Color.BLACK)
		fog_texture.update(_fog_image)
