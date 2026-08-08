class_name Minion
extends CharacterBody3D

@export var monster_id: StringName = &"minion"
@export var max_hp: float = 30.0
@export var speed: float = 4.0
@export var detect_range: float = 8.0
@export var attack_range: float = 1.5
@export var attack_damage: float = 5.0
@export var attack_cooldown: float = 1.5

var hp: float = 30.0
var _player: Node3D = null
var _nav_agent: NavigationAgent3D = null
var _ai_timer: float = 0.0
var _ai_interval: float = 0.2
var _attack_timer: float = 0.0
var _lost_timer: float = 0.0
var _player_lost_time: float = 4.0

func _ready() -> void:
	hp = max_hp
	_setup_visuals()
	_nav_agent = get_node_or_null("NavigationAgent3D")
	if not _nav_agent:
		_nav_agent = NavigationAgent3D.new()
		_nav_agent.name = "NavigationAgent3D"
		add_child(_nav_agent)
		_nav_agent.path_desired_distance = 1.0
		_nav_agent.target_desired_distance = 1.5
	add_to_group("enemies")

func _setup_visuals() -> void:
	var col := $CollisionShape3D
	if col and not col.shape:
		var shape := CapsuleShape3D.new()
		shape.radius = 0.4
		shape.height = 1.6
		col.shape = shape
	var mesh := $MeshInstance3D
	if mesh and not mesh.mesh:
		var m := CapsuleMesh.new()
		m.radius = 0.4
		m.height = 1.6
		m.radial_segments = 8
		m.rings = 4
		mesh.mesh = m
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("1a1a2a")
		mat.metallic = 0.3
		mat.roughness = 0.7
		mesh.material_override = mat
	_setup_eyes()

func _setup_eyes() -> void:
	var eye_left := $MeshInstance3D/EyeLeft
	var eye_right := $MeshInstance3D/EyeRight
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color("ff3333")
	eye_mat.emissive_enabled = true
	eye_mat.emissive = Color("ff0000")
	eye_mat.emissive_intensity = 2.0
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.08
	eye_mesh.height = 0.16
	eye_mesh.radial_segments = 6
	eye_mesh.rings = 4
	if eye_left and not eye_left.mesh:
		eye_left.mesh = eye_mesh
		eye_left.material_override = eye_mat
	if eye_right and not eye_right.mesh:
		eye_right.mesh = eye_mesh.duplicate()
		eye_right.material_override = eye_mat

func _physics_process(delta: float) -> void:
	_ai_timer += delta
	if _ai_timer < _ai_interval:
		return
	_ai_timer = 0.0
	_update_ai()

func _update_ai() -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
	if not _player:
		return

	var dist = global_position.distance_to(_player.global_position)
	if dist < detect_range and _can_see_player():
		if dist < attack_range:
			_attack()
		else:
			_chase()
	else:
		_lost_timer += _ai_interval
		if _lost_timer >= _player_lost_time:
			queue_free()

func _can_see_player() -> bool:
	if not _player:
		return false
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 1.0, 0),
		_player.global_position + Vector3(0, 1.0, 0)
	)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return result.is_empty() or result.collider.is_in_group("player")

func _chase() -> void:
	if _nav_agent:
		_nav_agent.target_position = _player.global_position
	var dir = (_player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

func _attack() -> void:
	_attack_timer = attack_cooldown
	if _player and _player.has_method("take_damage"):
		_player.take_damage(attack_damage)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		EventBus.enemy_killed.emit(monster_id)
		queue_free()

func _die() -> void:
	EventBus.enemy_killed.emit(monster_id)
	queue_free()