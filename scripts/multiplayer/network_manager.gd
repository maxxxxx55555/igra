extends Node

signal player_connected(id: int)
signal player_disconnected(id: int)
signal connection_failed
signal server_created
signal server_disconnected

const DEFAULT_PORT: int = 7777
const MAX_PLAYERS: int = 4

## UPnP нужен только для игры через интернет. Для игры в одной комнате (LAN)
## он бесполезен, а UPNP.discover() блокирует главный поток ~2 сек.
## Поэтому по умолчанию выключен, а когда включён — крутится в отдельном потоке.
var enable_upnp: bool = false

var _peer: ENetMultiplayerPeer
var _is_host: bool = false
var _upnp: UPNP
var _upnp_thread: Thread
var public_ip: String = ""

func _ready() -> void:
	# Подключаемся ровно один раз за время жизни автолоада.
	# Раньше connect() вызывался в create_server()/join_server(), и цикл
	# «Хост → Назад → Хост» дублировал player_connected, плодя лишних игроков.
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _exit_tree() -> void:
	_join_upnp_thread()

func create_server() -> void:
	shutdown()
	_peer = ENetMultiplayerPeer.new()
	var err = _peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	if err != OK:
		_peer = null
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = _peer
	_is_host = true
	if enable_upnp:
		_start_upnp_async()
	server_created.emit()

func join_server(ip: String) -> void:
	shutdown()
	_peer = ENetMultiplayerPeer.new()
	var err = _peer.create_client(ip, DEFAULT_PORT)
	if err != OK:
		_peer = null
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = _peer

func _start_upnp_async() -> void:
	_join_upnp_thread()
	_upnp_thread = Thread.new()
	_upnp_thread.start(_upnp_worker)

func _upnp_worker() -> void:
	var up = UPNP.new()
	if up.discover() != UPNP.UPNP_RESULT_SUCCESS:
		return
	if up.add_port_mapping(DEFAULT_PORT, DEFAULT_PORT, "TLS_Game", "UDP", 0) != UPNP.UPNP_RESULT_SUCCESS:
		return
	var addr = up.query_external_address()
	_upnp = up
	call_deferred("_on_upnp_ready", addr)

func _on_upnp_ready(addr: String) -> void:
	public_ip = addr

func _join_upnp_thread() -> void:
	if _upnp_thread and _upnp_thread.is_started():
		_upnp_thread.wait_to_finish()
	_upnp_thread = null

func _on_peer_connected(id: int) -> void:
	player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	player_disconnected.emit(id)

func _on_connected() -> void:
	pass

func _on_connection_failed() -> void:
	connection_failed.emit()

func _on_server_disconnected() -> void:
	server_disconnected.emit()

func is_host() -> bool:
	return _is_host

func shutdown() -> void:
	_join_upnp_thread()
	if _upnp:
		_upnp.delete_port_mapping(DEFAULT_PORT, "UDP")
		_upnp = null
	public_ip = ""
	if _peer:
		_peer.close()
		_peer = null
	multiplayer.multiplayer_peer = null
	_is_host = false
