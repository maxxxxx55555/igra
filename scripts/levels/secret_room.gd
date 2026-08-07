

extends Node3D

@export var secret_loot: Array[PackedScene] = []
@export var discovery_xp: int = 100

var _discovered: bool = false

func _ready() -> void:
	visible = false
	$Area3D.body_entered.connect(_on_discovered)

func _on_discovered(body: Node3D) -> void:
	if _discovered or not body.is_in_group("player"):
		return
	_discovered = true
	visible = true
	XpManager.add_xp(discovery_xp)
	AchievementManager.unlock("first_light")
	AudioManager.play_sfx(load("res://assets/audio/sfx/sfx_click.wav"))
	# Spawn luta
	for loot in secret_loot:
		var item = loot.instantiate()
		item.position = global_position + Vector3.UP
		add_child(item)