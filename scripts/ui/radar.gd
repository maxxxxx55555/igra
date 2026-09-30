extends Control

@export var radar_enabled: bool = true
@export var radar_radius_px: float = 82.0
@export var world_range_m: float = 20.0

var _player: Node3D = null
var _entities: Array[Dictionary] = []
## Live enemy positions, refilled by _scan_entities() every frame.
var _enemy_positions: Array[Vector3] = []

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
	# Enemies are scanned from the "enemies" group like every other entity type
	# below. They used to be fed by EventBus.enemy_spawned/enemy_died into an
	# array of Vector3 snapshots, so every red dot stayed frozen at the spot its
	# monster first appeared (monsters move - they chase the player), and a
	# killed monster's dot was only removed when it happened to die within
	# 0.1 m of that same spawn point. No signal bookkeeping is needed now.

## The scan walks five groups (lights, interactives, pickups, objectives, props)
## plus enemies every frame, and the overlay redraws straight after. The minimap
## - a bigger version of the same thing - has ticked at 10 Hz since it was
## written; on this 164 px disc a 4 m/s chaser moves under 2 px per tick, so the
## radar now ticks at the same rate instead of at display refresh. It also skips
## the walk entirely while the HUD is hidden (menus, pause, photo mode), when
## nothing it could find is on screen anyway.
const SCAN_INTERVAL: float = 0.1
var _scan_timer: float = 0.0

func _process(delta: float) -> void:
	if not radar_enabled or not is_visible_in_tree():
		return
	_find_player()
	if not _player:
		return
	_scan_timer -= delta
	if _scan_timer > 0.0:
		return
	_scan_timer = SCAN_INTERVAL
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

	# Enemies - positions read live, so a chasing monster's dot moves with it and
	# a dead one disappears the same frame (base_monster keeps its node around
	# after death, so DEAD has to be filtered by state, not by validity).
	_enemy_positions.clear()
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Node3D) or not is_instance_valid(e):
			continue
		if "ai_state" in e and int(e.ai_state) == BaseMonster.State.DEAD:
			continue
		_enemy_positions.append((e as Node3D).global_position)

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
	
	# Draw enemies (ember color #b4452f)
	for enemy_pos in _enemy_positions:
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
