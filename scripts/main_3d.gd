extends Node3D

func _ready() -> void:
	_setup_nav_region()
	_setup_world_runtime()
	_auto_start_from_main()
	_setup_multiplayer()
	_setup_screen_shake()

func _auto_start_from_main() -> void:
	var GM = get_node_or_null("/root/GameManager")
	if GM and GM.has_method("is_playing") and GM.is_playing():
		return
	# Главное меню открывает UIManager по событию game_state_changed(MENU).
	# Раньше здесь ещё искали узел Screens по пути "/root/Screens" — его там
	# никогда не было (Screens — потомок Main3D), так что ветка была мёртвой;
	# заодно она грозила вторым меню поверх первого.
	if GM and GM.has_method("_change_state"):
		GM._change_state(GM.GameState.MENU)

## Districts никогда не появлялись в игре: фабрика была, вызова не было.
## WorldRuntime — единственная точка, которая строит и переключает районы.
func _setup_world_runtime() -> void:
	if get_node_or_null("WorldRuntime") != null:
		return
	var wr := Node3D.new()
	wr.set_script(load("res://scripts/world/world_runtime.gd"))
	wr.name = "WorldRuntime"
	add_child(wr)

func _setup_multiplayer() -> void:
	var nm := get_node_or_null("/root/NetworkManager")
	if nm == null or nm.multiplayer.multiplayer_peer == null:
		return
	var mm := Node3D.new()
	mm.set_script(load("res://scripts/multiplayer/multiplayer_manager.gd"))
	mm.name = "MultiplayerManager"
	mm.set("player_scene", preload("res://scenes/player/player_3d.tscn"))
	add_child(mm)

## Тряска камеры. setup() вызывался внутри _setup_multiplayer() — уже ПОСЛЕ
## раннего return для одиночной игры. То есть в обычной игре камера узлу не
## передавалась, _camera оставался null, и тряска не работала вовсе.
## Сам ScreenShake на урон и смерть врага подписан у себя в _ready().
func _setup_screen_shake() -> void:
	var shake := get_node_or_null("ScreenShake")
	var cam := get_node_or_null("Camera3D") as Camera3D
	if shake == null or cam == null:
		return
	shake.setup(cam)

func _setup_nav_region() -> void:
	var nreg := NavigationRegion3D.new()
	var nm := NavigationMesh.new()
	var S := 40.0
	nm.vertices = PackedVector3Array([Vector3(-S,0,-S),Vector3(S,0,-S),Vector3(S,0,S),Vector3(-S,0,S)])
	nm.add_polygon(PackedInt32Array([0,1,2,3]))
	nreg.navigation_mesh = nm
	nreg.add_to_group("nav_region")
	add_child(nreg)

