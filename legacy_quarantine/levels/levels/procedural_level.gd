extends Node3D

@export var room_count: int = 8
@export var enemy_scene: PackedScene
@export var item_scene: PackedScene

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
