extends Control

@export var radar_enabled: bool = true
@export var radar_radius_px: float = 82.0
@export var world_range_m: float = 20.0

var _player: Node3D = null
var _entities: Array[Dictionary] = []
var _enemies: Array[Vector3] = []  # Track enemy positions via signals
var _last_radar_count: int = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(164, 164)
	size = Vector2(164, 164)
	anchor_left = 1.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 0.0
	offset_left = -180.0
	offset_top = 16.0
	offset_right = -16.0
	offset_bottom = 180.0
	var vp := get_viewport().get_visible_rect().size if get_viewport() else Vector2(1920, 1080)
	var r := get_global_rect()
	var in_vp := r.size.x > 20 and r.size.y > 20 and visible and modulate.a > 0.1

	
	# Connect to enemy signals
	EventBus.enemy_spawned.connect(_on_enemy_spawned)
	EventBus.enemy_died.connect(_on_enemy_died)

func _process(_delta: float) -> void:
	if not radar_enabled:
		return
	_find_player()
	if not _player:
		return
	_scan_entities()
	queue_redraw()

func _find_player() -> void:
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D

func _scan_entities() -> void:
	_entities.clear()
	if not _player:
		return
	var pp := _player.global_position
	
	# Lights
	var lights := get_tree().get_nodes_in_group("lights")
	for l in lights:
		if l is Node3D:
			var dist: float = l.global_position.distance_to(pp)
			if dist <= world_range_m:
				_entities.append({"pos": l.global_position, "type": "light", "dist": dist})
	
	# Interactives (including pickups and objectives)
	var interactives := get_tree().get_nodes_in_group("interact")
	for i in interactives:
		if i is Node3D:
			var dist: float = i.global_position.distance_to(pp)
			if dist <= world_range_m:
				_entities.append({"pos": i.global_position, "type": "interact", "dist": dist})
	var pickups := get_tree().get_nodes_in_group("pickups")
	for pu in pickups:
		if pu is Node3D:
			var dist: float = pu.global_position.distance_to(pp)
			if dist <= world_range_m:
				_entities.append({"pos": pu.global_position, "type": "interact", "dist": dist})
	var objectives := get_tree().get_nodes_in_group("objectives")
	for o in objectives:
		if o is Node3D:
			var dist: float = o.global_position.distance_to(pp)
			if dist <= world_range_m:
				_entities.append({"pos": o.global_position, "type": "interact", "dist": dist})
	
	# Props
	var props := get_tree().get_nodes_in_group("props")
	for p in props:
		if p is Node3D:
			var dist: float = p.global_position.distance_to(pp)
			if dist <= world_range_m:
				_entities.append({"pos": p.global_position, "type": "prop", "dist": dist})

	if _entities.size() != _last_radar_count:
		_last_radar_count = _entities.size()

func _on_enemy_spawned(enemy: Node3D) -> void:
	if enemy is Node3D:
		_enemies.append(enemy.global_position)

func _on_enemy_died(pos: Vector3) -> void:
	# Remove enemy at this position (if found)
	for i in _enemies.size():
		if _enemies[i].distance_to(pos) < 0.1:  # Small tolerance for floating point
			_enemies.remove_at(i)
			break

func _draw() -> void:
	if not _player:
		return
	var center := Vector2(size.x / 2.0, size.y / 2.0)
	var pp := _player.global_position
	# фон круга — panel alpha0.6
	draw_circle(center, radar_radius_px, Color(0.078, 0.106, 0.141, 0.6))
	# круглая рамка — brass
	draw_arc(center, radar_radius_px, 0.0, TAU, 48, Color(0.541, 0.451, 0.220), 2.0)
	# игрок — brass точка
	draw_circle(center, 3.0, Color(0.788, 0.635, 0.290))
	var angle := _player.rotation.y
	var tri := PackedVector2Array([
		center + Vector2(cos(angle) * 6.0, sin(angle) * 6.0),
		center + Vector2(cos(angle + 2.5) * 3.0, sin(angle + 2.5) * 3.0),
		center + Vector2(cos(angle - 2.5) * 3.0, sin(angle - 2.5) * 3.0),
	])
	draw_colored_polygon(tri, Color(0.788, 0.635, 0.290))
	var scale_f := radar_radius_px / world_range_m
	var clip_radius := radar_radius_px - 4.0
	
	# Draw non-enemy entities (lights, interactives, props)
	for ent in _entities:
		var dx: float = ent.pos.x - pp.x
		var dz: float = ent.pos.z - pp.z
		var lv := Vector2(dx * scale_f, dz * scale_f)
		if lv.length() > clip_radius:
			lv = lv.normalized() * clip_radius
		var ep := center + lv
		match ent.type:
			"light", "interact":
				draw_circle(ep, 2.0, Color(0.788, 0.635, 0.290))
			"prop":
				draw_circle(ep, 1.5, Color(0.682, 0.714, 0.749, 0.5))
	
	# Draw enemies from signals (ember color #b4452f)
	for enemy_pos in _enemies:
		var dx: float = enemy_pos.x - pp.x
		var dz: float = enemy_pos.z - pp.z
		var lv := Vector2(dx * scale_f, dz * scale_f)
		if lv.length() > clip_radius:
			lv = lv.normalized() * clip_radius
		var ep := center + lv
		# Ember color: #b4452f
		draw_circle(ep, 2.5, Color(0.706, 0.271, 0.184))  # Approximate ember #b4452f
	
	var tick_positions := [Vector2(center.x, 0.05 * size.y), Vector2(center.x, 0.95 * size.y), Vector2(0.05 * size.x, center.y), Vector2(0.95 * size.x, center.y)]
	for t in tick_positions:
		draw_rect(Rect2(t.x - 1, t.y - 4, 2, 8), Color(0.541, 0.451, 0.220))
