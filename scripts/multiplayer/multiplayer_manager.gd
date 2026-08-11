

extends Node3D

@export var player_scene: PackedScene
@export var spawn_points: Array[Node3D] = []

var _players: Dictionary = {}

func _ready() -> void:
	if not multiplayer:
		return
	_adopt_local_player()
	NetworkManager.player_connected.connect(_add_player)
	NetworkManager.player_disconnected.connect(_remove_player)
	for id in multiplayer.get_peers():
		_add_player(id)

## Локальный игрок из main_3d.tscn переносится под MultiplayerManager
## с именем = peer_id, чтобы пути RPC совпадали на всех машинах,
## а authority принадлежал владельцу (иначе клиент не управляет собой).
func _adopt_local_player() -> void:
	var local: Node = get_tree().get_first_node_in_group("player")
	if local == null or local.get_parent() == self:
		return
	var my_id: int = multiplayer.get_unique_id()
	local.reparent(self)
	local.name = str(my_id)
	local.set_multiplayer_authority(my_id)
	_players[my_id] = local

func _add_player(id: int) -> void:
	if _players.has(id):
		return
	if id == multiplayer.get_unique_id():
		return
	if player_scene == null:
		return
	var spawn = spawn_points[_players.size() % spawn_points.size()] if spawn_points.size() > 0 else null
	var player = player_scene.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	_players[id] = player
	add_child(player)
	# global_position задаём только после add_child — до входа в дерево
	# трансформ ещё не существует, Godot ругается `!is_inside_tree()`.
	if spawn:
		player.global_position = spawn.global_position

func _remove_player(id: int) -> void:
	if _players.has(id):
		_players[id].queue_free()
		_players.erase(id)