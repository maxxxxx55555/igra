extends Node3D

@export var enemy_scene: PackedScene = preload("res://scenes/enemy_fps.tscn")
@export var player_scene: PackedScene = preload("res://scenes/player_fps.tscn")

func _ready() -> void:
	_build_geometry()
	_spawn_player()
	_spawn_enemies()
	_spawn_pickups()
	_bake_navmesh()

func _build_geometry() -> void:
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.2, 0.22, 0.25)
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.3, 0.32, 0.35)
	var floor := CSGBox3D.new()
	floor.size = Vector3(40, 0.5, 40)
	floor.position = Vector3(0, -0.25, 0)
	floor.material = floor_mat
	add_child(floor)
	var walls := [
		{ "size": Vector3(40, 3, 0.5), "pos": Vector3(0, 1.5, -20) },
		{ "size": Vector3(40, 3, 0.5), "pos": Vector3(0, 1.5, 20) },
		{ "size": Vector3(0.5, 3, 40), "pos": Vector3(-20, 1.5, 0) },
		{ "size": Vector3(0.5, 3, 40), "pos": Vector3(20, 1.5, 0) },
	]
	for w in walls:
		var wall := CSGBox3D.new()
		wall.size = w["size"]
		wall.position = w["pos"]
		wall.material = wall_mat
		add_child(wall)
	var inner1 := CSGBox3D.new()
	inner1.size = Vector3(6, 3, 0.5)
	inner1.position = Vector3(0, 1.5, -8)
	inner1.material = wall_mat
	add_child(inner1)
	var inner2 := CSGBox3D.new()
	inner2.size = Vector3(0.5, 3, 6)
	inner2.position = Vector3(8, 1.5, 2)
	inner2.material = wall_mat
	add_child(inner2)

func _spawn_player() -> void:
	var marker := get_node_or_null("SpawnPlayer")
	if not marker:
		return
	var player := player_scene.instantiate()
	add_child(player)
	player.global_position = marker.global_position

func _spawn_enemies() -> void:
	if not enemy_scene:
		return
	for i in 3:
		var marker_name := "EnemySpawn%d" % [i + 1]
		var marker := get_node_or_null(marker_name) as Marker3D
		if not marker:
			continue
		var enemy := enemy_scene.instantiate()
		enemy.global_position = marker.global_position
		var patrol_points := _find_patrol_points(i)
		if patrol_points.size() > 1:
			enemy.patrol_markers = patrol_points
		add_child(enemy)

func _spawn_pickups() -> void:
	pass

func _find_patrol_points(index: int) -> Array[Node3D]:
	var points: Array[Node3D] = []
	var offsets := [
		[Vector3(5, 0.5, -5), Vector3(-5, 0.5, 5), Vector3(5, 0.5, 5)],
		[Vector3(-8, 0.5, 8), Vector3(-3, 0.5, -8), Vector3(-8, 0.5, -3)],
		[Vector3(10, 0.5, 0), Vector3(5, 0.5, 10), Vector3(-5, 0.5, 10)]
	]
	if index < offsets.size():
		for o in offsets[index]:
			var m := Marker3D.new()
			m.global_position = o
			points.append(m)
	return points

func _bake_navmesh() -> void:
	var nav := get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	if not nav:
		return
	var mesh := NavigationMesh.new()
	mesh.agent_radius = 0.3
	mesh.agent_height = 1.2
	mesh.agent_max_slope = 45.0
	nav.navigation_mesh = mesh
	nav.bake_navigation_mesh()
