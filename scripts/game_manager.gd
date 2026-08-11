

extends Node
var player: Node3D = null
var current_level: String = ""

var is_paused: bool = false
func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)

func _on_player_died() -> void:
	get_tree().paused = true
	is_paused = true