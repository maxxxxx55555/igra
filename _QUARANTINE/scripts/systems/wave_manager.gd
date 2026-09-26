extends Node3D
signal wave_started(wave_number: int, wave_data: Dictionary)
signal wave_completed(wave_number: int)
signal all_waves_completed
signal enemy_spawned(enemy: Node3D)

@export var enemy_scenes: Dictionary = {}  # "enemy_type" -> PackedScene
@export var spawn_points: Array[Node3D] = []
@export var waves: Array = []

var current_wave: int = 0
var enemies_alive: int = 0
var _wave_active: bool = false
var _spawned_enemies: Array[Node3D] = []

func _ready() -> void:
	# Connect to enemy death signal
	EventBus.enemy_killed.connect(_on_any_enemy_died)

func start_waves() -> void:
	current_wave = 0
	_start_next_wave()

func stop_waves() -> void:
	_wave_active = false
	for enemy in _spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_spawned_enemies.clear()
	enemies_alive = 0

func _start_next_wave() -> void:
	if current_wave >= waves.size():
		all_waves_completed.emit()
		return
	
	_wave_active = true
	var wave_data = waves[current_wave].duplicate()
	
	# Scale difficulty based on player count
	if multiplayer.has_multiplayer_peer():
		var player_count = multiplayer.get_peers().size() + 1
		wave_data["enemy_count"] = int(wave_data.get("enemy_count", 5) * (0.8 + player_count * 0.2))
		wave_data["health_multiplier"] = wave_data.get("health_multiplier", 1.0) * (1.0 + (player_count - 1) * 0.15)
	
	wave_started.emit(current_wave + 1, wave_data)
	_spawn_wave(wave_data)

func _spawn_wave(wave_data: Dictionary) -> void:
	var count = wave_data.get("enemy_count", 5)
	var interval = wave_data.get("spawn_interval", 1.0)
	var enemy_types = wave_data.get("enemy_types", ["basic"])
	var health_mult = wave_data.get("health_multiplier", 1.0)
	var damage_mult = wave_data.get("damage_multiplier", 1.0)
	var speed_mult = wave_data.get("speed_multiplier", 1.0)
	
	for i in range(count):
		await get_tree().create_timer(interval * (0.8 + randf() * 0.4)).timeout
		if not _wave_active:
			return
		
		var enemy_type = enemy_types[randi() % enemy_types.size()]
		_spawn_enemy(enemy_type, health_mult, damage_mult, speed_mult)
	
	enemies_alive = count

func _spawn_enemy(enemy_type: StringName, health_mult: float, damage_mult: float, speed_mult: float) -> void:
	if not enemy_scenes.has(enemy_type) or spawn_points.is_empty():
		return
	
	var scene = enemy_scenes[enemy_type]
	var point = spawn_points[randi() % spawn_points.size()]
	var enemy = scene.instantiate()
	enemy.global_position = point.global_position
	
	# Apply difficulty scaling
	if enemy.has_method("set_max_health"):
		enemy.set_max_health(enemy.max_health * health_mult)
	elif enemy.has_property("max_hp"):
		enemy.max_hp *= health_mult
	if enemy.has_method("set_damage"):
		enemy.set_damage(enemy.attack_damage * damage_mult)
	elif enemy.has_property("attack_damage"):
		enemy.attack_damage *= damage_mult
	if enemy.has_property("speed"):
		enemy.speed *= speed_mult
	
	# Set wave reference for cleanup
	enemy.set("wave_manager", self)
	
	add_child(enemy)
	_spawned_enemies.append(enemy)
	enemy_spawned.emit(enemy)
	
	# Connect death signal
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died.bind(enemy))
	else:
		enemy.connect("tree_exiting", _on_enemy_died.bind(enemy))

func _on_enemy_died(enemy: Node3D) -> void:
	if not _spawned_enemies.has(enemy):
		return
	
	enemies_alive -= 1
	_spawned_enemies.erase(enemy)
	
	# XP reward
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		var xp: int = 25 if enemy.get("xp_reward") == null else enemy.get("xp_reward")
		EventBus.xp_gained.emit(xp)
	
	if enemies_alive <= 0 and _wave_active:
		_wave_active = false
		wave_completed.emit(current_wave + 1)
		
		# Bonus for completing wave
		if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
			EventBus.wave_completed.emit(current_wave + 1)
		
		await get_tree().create_timer(4.0).timeout
		if _wave_active:
			return
		current_wave += 1
		_start_next_wave()

func _on_any_enemy_died(monster_id: StringName) -> void:
	# Track for progress tracker
	ProgressTracker._on_kill(monster_id)

func get_current_wave() -> int:
	return current_wave

func get_enemies_alive() -> int:
	return enemies_alive

func get_total_waves() -> int:
	return waves.size()

func skip_wave() -> void:
	if _wave_active:
		# Kill all current enemies
		for enemy in _spawned_enemies.duplicate():
			if is_instance_valid(enemy) and enemy.has_method("take_damage"):
				enemy.take_damage(9999)