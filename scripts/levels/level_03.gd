
extends Node3D

@export 
var boss_scene: PackedScene

@export 
var checkpoint_scene: PackedScene

@onready 
var player_spawn: Marker3D = $SpawnPlayer

@onready 
var boss_spawn: Marker3D = $BossSpawn

@onready 
var nav_region: NavigationRegion3D = $NavigationRegion3D

func _ready() -> void:
	GameManager.current_level = 3
	GameManager.reset_run()
	_spawn_player()
	_spawn_boss()
	_spawn_checkpoint()
	_start_music()

func _spawn_player() -> void:
	
	var player := preload("res://scenes/player_fps.tscn").instantiate() as Node3D
	player.position = player_spawn.position
	add_child(player)

func _spawn_boss() -> void:
	if not boss_scene:
		return
	
	var boss := boss_scene.instantiate() as Node3D
	boss.position = boss_spawn.position
	boss.get_node("HealthComponent").died.connect(_on_boss_died)
	add_child(boss)

func _spawn_checkpoint() -> void:
	if checkpoint_scene:
		var cp := checkpoint_scene.instantiate()
		cp.position = player_spawn.position + Vector3(2, 0, 0)
		add_child(cp)

func _start_music() -> void:
	
	var player := AudioStreamPlayer.new()
	if ResourceLoader.exists("res://assets/audio/music/music_boss.wav"):
		player.stream = load("res://assets/audio/music/music_boss.wav")
		player.autoplay = true
		player.bus = "Music"
	add_child(player)

func _on_boss_died() -> void:
	AchievementManager.unlock("architect")
	GameManager.unlock_level(3)
	EventBus.level_completed.emit(3)
