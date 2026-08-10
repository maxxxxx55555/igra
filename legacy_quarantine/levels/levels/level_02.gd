
extends Node3D

@export 
var enemy_scene: PackedScene = preload("res://legacy_quarantine/enemies2d/scenes/enemy_fps.tscn")

@export 
var fast_zombie_scene: PackedScene = preload("res://legacy_quarantine/enemies2d/scenes/fast_zombie.tscn")

@export 
var checkpoint_scene: PackedScene

@export 
var item_scene: PackedScene

@onready 
var player_spawn: Marker3D = $SpawnPlayer

@onready 
var nav_region: NavigationRegion3D = $NavigationRegion3D

@onready 
var wave_manager: Node3D = $WaveManager

func _ready() -> void:
	GameManager.current_level = 2
	GameManager.reset_run()
	_spawn_player()
	_setup_waves()
	_spawn_checkpoints()
	_spawn_items()
	_start_music()

func _spawn_player() -> void:
	
	var player := preload("res://scenes/player_fps.tscn").instantiate() as Node3D
	player.position = player_spawn.position
	add_child(player)

func _setup_waves() -> void:
	if not wave_manager:
		return
	wave_manager.enemy_scenes = {"basic": enemy_scene, "fast": fast_zombie_scene}
	wave_manager.waves = [
		_create_wave(3, 2.0),
		_create_wave(5, 1.5),
		_create_wave(3, 1.0, true)  # fast zombies
	]
	wave_manager.all_waves_completed.connect(_on_all_waves_done)
	wave_manager.start_waves()

func _create_wave(count: int, delay: float, fast: bool = false) -> Dictionary:
	return {
		"enemy_count": count,
		"spawn_interval": delay,
		"enemy_types": ["fast"] if fast else ["basic"],
		"health_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"speed_multiplier": 1.0,
	}

func _spawn_checkpoints() -> void:
	if checkpoint_scene:
		for marker in get_tree().get_nodes_in_group("checkpoint_spawn"):
			var cp := checkpoint_scene.instantiate()
			cp.position = marker.position
			add_child(cp)

func _spawn_items() -> void:
	if item_scene:
		for marker in get_tree().get_nodes_in_group("item_spawn"):
			var item := item_scene.instantiate()
			item.position = marker.position
			add_child(item)

func _start_music() -> void:
	
	var player := AudioStreamPlayer.new()
	if ResourceLoader.exists("res://assets/audio/music/music_combat.wav"):
		player.stream = load("res://assets/audio/music/music_combat.wav")
		player.autoplay = true
		player.bus = "Music"
	add_child(player)

func _on_all_waves_done() -> void:
	EventBus.level_completed.emit(2)
