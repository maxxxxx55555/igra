
extends Node

signal wave_started(wave_num: int)

signal wave_completed

signal all_waves_done

@export 
var enemy_scene: PackedScene

@export 
var fast_zombie_scene: PackedScene

@export 
var waves: Array[Node] = []

var _current_wave: int = 0

var _enemies_remaining: int = 0

var _spawn_points: Array[Marker3D] = []

func _ready() -> void:
	for marker in get_tree().get_nodes_in_group("enemy_spawn"):
		_spawn_points.append(marker)

func start_waves() -> void:
	_current_wave = 0
	_start_next_wave()

func get_current_wave() -> int:
	return _current_wave

func _start_next_wave() -> void:
	if _current_wave >= waves.size():
		all_waves_done.emit()
		return
	
	var wave: Node = waves[_current_wave]
	var count: int = wave.get_meta("count", 3)
	var delay: float = wave.get_meta("delay", 2.0)
	var fast: bool = wave.get_meta("fast", false)
	wave_started.emit(_current_wave + 1)
	_enemies_remaining = count
	for i in range(count):
		await get_tree().create_timer(delay).timeout
		_spawn_enemy(fast)
	_current_wave += 1

func _spawn_enemy(fast: bool) -> void:
	var scene := fast_zombie_scene if fast else enemy_scene
	if not scene:
		return
	var enemy := scene.instantiate() as Node3D
	if _spawn_points.is_empty():
		return
	var point := _spawn_points[randi() % _spawn_points.size()]
	enemy.position = point.global_position + Vector3(randf()-0.5, 0, randf()-0.5) * 2.0
	add_child(enemy)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	_enemies_remaining -= 1
	GameManager.add_kill()
	EventBus.enemy_died.emit(Vector3.ZERO)
	EventBus.xp_gained.emit(10)
	if _enemies_remaining <= 0:
		wave_completed.emit()
		await get_tree().create_timer(3.0).timeout
		_start_next_wave()
