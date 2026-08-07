extends Node
## Autoload "LANNetwork".  ENet host/join + rpc state sync.

const DEFAULT_PORT := 7777
const MAX_CLIENTS := 4

enum Role { OFFLINE, HOST, CLIENT }
var role: int = Role.OFFLINE
var connected: bool = false
var _peer: ENetMultiplayerPeer

func host(port: int = DEFAULT_PORT) -> int:
	leave()
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		# push_warning("[LAN] host failed err=%d" % err)
		return err
	multiplayer.multiplayer_peer = _peer
	role = Role.HOST
	connected = true
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.lan_hosted.emit(port)
	return OK

func join(host_ip: String, port: int = DEFAULT_PORT) -> int:
	leave()
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(host_ip, port)
	if err != OK:
		# push_warning("[LAN] join failed err=%d" % err)
		return err
	multiplayer.multiplayer_peer = _peer
	role = Role.CLIENT
	connected = true
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	return OK

func leave() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	role = Role.OFFLINE
	connected = false
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.lan_disconnected.emit()

func is_host() -> bool: return role == Role.HOST
func is_client() -> bool: return role == Role.CLIENT
func is_online() -> bool: return connected

func _on_peer_connected(id: int) -> void:
	print("[LAN] peer connected ", id)
func _on_peer_disconnected(id: int) -> void:
	print("[LAN] peer disconnected ", id)
func _on_connected_to_server() -> void:
	print("[LAN] connected to server")
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.lan_joined.emit(multiplayer.get_unique_id())
func _on_connection_failed() -> void:
	print("[LAN] connection failed")
	leave()
func _on_server_disconnected() -> void:
	print("[LAN] server disconnected")
	leave()

@rpc("any_peer", "call_local", "unreliable")
func rpc_player_state(peer_id: int, pos: Vector3, yaw: float, district: StringName) -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.remote_player_state.emit(peer_id, pos, yaw, district)

@rpc("any_peer", "call_local", "reliable")
func rpc_power_changed(district: StringName, powered: bool) -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.remote_power_changed.emit(district, powered)

func broadcast_player_state(pos: Vector3, yaw: float, district: StringName) -> void:
	if not connected:
		return
	rpc_player_state.rpc(multiplayer.get_unique_id(), pos, yaw, district)

func broadcast_power(district: StringName, powered: bool) -> void:
	if not connected:
		return
	rpc_power_changed.rpc(district, powered)