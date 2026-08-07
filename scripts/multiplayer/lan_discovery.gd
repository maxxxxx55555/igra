extends Node

signal host_found(host_ip: String, port: int, host_name: String)

const DISCOVERY_PORT = 7778
const GAME_PORT = 7777
const MAGIC = "TLS_LAN_DISCOVERY"

## Интервал между широковещательными пакетами хоста (сек).
## Раньше пакет уходил каждый кадр — ~60 бродкастов в секунду на весь LAN.
const BROADCAST_INTERVAL = 1.0

var _udp: PacketPeerUDP = null
var _is_host = false
var _host_name = "TLS Game"
var _scan_timer = 0.0
var _found_hosts: Dictionary = {}

func _ready() -> void:
	set_process(false)

func start_host(host_name: String = "TLS Game") -> void:
	stop()
	_is_host = true
	_host_name = host_name
	_scan_timer = 0.0
	_udp = PacketPeerUDP.new()
	_udp.set_broadcast_enabled(true)
	_udp.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	set_process(true)

func start_client() -> void:
	stop()
	_is_host = false
	_udp = PacketPeerUDP.new()
	if _udp.bind(DISCOVERY_PORT) != OK:
		# push_warning("LANDiscovery: port %d busy, scan disabled" % DISCOVERY_PORT)
		_udp = null
		return
	set_process(true)

func stop() -> void:
	set_process(false)
	if _udp:
		_udp.close()
		_udp = null
	_found_hosts.clear()

func _process(delta: float) -> void:
	if _udp == null:
		return
	if _is_host:
		_scan_timer -= delta
		if _scan_timer <= 0.0:
			_scan_timer = BROADCAST_INTERVAL
			_broadcast_presence()
	else:
		_listen_for_hosts()

func _broadcast_presence() -> void:
	var local_ip = _get_lan_ip()
	var msg = "%s|%s|%d|%s" % [MAGIC, local_ip, GAME_PORT, _host_name]
	_udp.put_packet(msg.to_utf8_buffer())

func _listen_for_hosts() -> void:
	while _udp.get_available_packet_count() > 0:
		var packet = _udp.get_packet()
		var msg = packet.get_string_from_utf8()
		var parts = msg.split("|")
		if parts.size() == 4 and parts[0] == MAGIC:
			var host_ip = parts[1]
			var port = parts[2].to_int()
			var label = parts[3]
			var key = "%s:%d" % [host_ip, port]
			if not _found_hosts.has(key):
				_found_hosts[key] = {"ip": host_ip, "port": port, "name": label}
				host_found.emit(host_ip, port, label)

func _get_lan_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return "127.0.0.1"

func get_found_hosts() -> Array:
	var result = []
	for key in _found_hosts:
		result.append(_found_hosts[key])
	return result