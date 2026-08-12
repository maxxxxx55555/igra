extends Control

@onready var host_button: Button = $VBoxContainer/HBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var refresh_button: Button = $VBoxContainer/HBoxContainer/RefreshButton
@onready var host_list: ItemList = $VBoxContainer/HostList
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var name_input: LineEdit = $VBoxContainer/NameInput

func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	host_list.item_selected.connect(_on_host_selected)
	
	NetworkManager.server_created.connect(_on_server_created)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connected_to_server.connect(_on_joined)
	LANDiscovery.host_found.connect(_on_host_found)

	start_button.disabled = true
	join_button.disabled = true

	# Auto-start scanning for hosts
	LANDiscovery.start_client()
	status_label.text = tr("Scanning for servers...")

func _on_host_pressed() -> void:
	var player_name = name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	NetworkManager.create_server()
	LANDiscovery.start_host(player_name)
	host_button.disabled = true
	join_button.disabled = true

func _on_join_pressed() -> void:
	var selected = host_list.get_selected_items()
	if selected.size() == 0:
		status_label.text = tr("Select a server first")
		return
	
	var idx = selected[0]
	var host_data = host_list.get_item_metadata(idx)
	if not host_data:
		return
	
	status_label.text = tr("Connecting to %s...") % host_data.name
	NetworkManager.join_server(host_data.ip)

func _on_start_pressed() -> void:
	if not NetworkManager.is_host():
		return
	_start_game.rpc()

@rpc("call_local")
func _start_game() -> void:
	Routes.start_game()

func _on_back_pressed() -> void:
	LANDiscovery.stop()
	NetworkManager.shutdown()
	Routes.to_menu()

func _on_refresh_pressed() -> void:
	host_list.clear()
	LANDiscovery.stop()
	LANDiscovery.start_client()
	status_label.text = tr("Scanning for servers...")

func _on_host_found(host_ip: String, port: int, host_name: String) -> void:
	var idx = host_list.add_item("%s (%s:%d)" % [host_name, host_ip, port])
	host_list.set_item_metadata(idx, {"ip": host_ip, "port": port, "name": host_name})
	join_button.disabled = false
	status_label.text = tr("Found server: %s") % host_name

func _on_host_selected(idx: int) -> void:
	join_button.disabled = false

func _on_server_created() -> void:
	var ip = _get_local_ip()
	if NetworkManager.public_ip != "":
		ip = "%s (global) / %s (local)" % [NetworkManager.public_ip, ip]
	status_label.text = tr("Server: %s : %d") % [ip, NetworkManager.DEFAULT_PORT]
	start_button.disabled = false

func _on_connection_failed() -> void:
	status_label.text = tr("Connection failed!")
	host_button.disabled = false
	join_button.disabled = false
	start_button.disabled = true

## Клиент успешно подключился — только хост может стартовать игру,
## клиент ждёт RPC _start_game.
func _on_joined() -> void:
	status_label.text = tr("Connected. Waiting for host...")
	host_button.disabled = true
	join_button.disabled = true

func _on_server_disconnected() -> void:
	status_label.text = tr("Host closed the game")
	host_button.disabled = false
	join_button.disabled = false
	start_button.disabled = true
	host_list.clear()
	LANDiscovery.start_client()

func _get_local_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return "localhost"

func _exit_tree() -> void:
	LANDiscovery.stop()