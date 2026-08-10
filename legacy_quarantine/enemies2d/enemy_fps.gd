extends CharacterBody3D

enum State { IDLE, PATROL, CHASE, ATTACK, DEAD }

@export var speed: float = 3.0
@export var detection_range: float = 10.0
@export var attack_range: float = 1.5
@export var max_hp: int = 100
@export var damage: int = 10
@export var xp_reward: int = 25

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var los_ray: RayCast3D = $RayCast3D
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var health: Node = $HealthComponent

var _state: State = State.IDLE
var _target: Node3D = null
var _dead: bool = false
var _stagger_timer: float = 0.0
var _alert_pos: Vector3 = Vector3.ZERO
var _alert_timer: float = 0.0

func _ready() -> void:
	if health and health.has_signal("died"):
		health.died.connect(_on_died)
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _stagger_timer > 0:
		_stagger_timer -= delta
		velocity.x = 0
		velocity.z = 0
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return
	match _state:
		State.IDLE:
			_update_target()
			if _target:
				_change_state(State.CHASE)
			elif _alert_timer > 0:
				_go_alert(delta)
		State.CHASE:
			if not _target or not _can_see_target():
				_target = null
				_change_state(State.IDLE)
			elif global_position.distance_to(_target.global_position) <= attack_range:
				_change_state(State.ATTACK)
			else:
				_do_chase(delta)
		State.ATTACK:
			if not _target or global_position.distance_to(_target.global_position) > attack_range * 1.2:
				_change_state(State.CHASE)
			else:
				_do_attack()
		State.DEAD:
			pass
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func _change_state(s: State) -> void:
	_state = s

func _effective_detection() -> float:
	var d := detection_range
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_node("Camera3D/SpotLight3D"):
		var fl := player.get_node("Camera3D/SpotLight3D")
		if not fl.visible:
			d *= 0.4
	return d

func _update_target() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player and global_position.distance_to(player.global_position) <= _effective_detection():
		_target = player

func _can_see_target() -> bool:
	if not _target or not los_ray:
		return false
	los_ray.target_position = los_ray.to_local(_target.global_position)
	los_ray.force_raycast_update()
	return los_ray.is_colliding() and los_ray.get_collider() == _target

func _do_chase(delta: float) -> void:
	if _target and nav:
		nav.target_position = _target.global_position
		var next := nav.get_next_path_position()
		var dir := global_position.direction_to(next)
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed

func _do_attack() -> void:
	velocity.x = move_toward(velocity.x, 0, speed)
	velocity.z = move_toward(velocity.z, 0, speed)
	if _target and _target.has_method("take_damage"):
		_target.take_damage(damage)

func _go_alert(delta: float) -> void:
	_alert_timer -= delta
	var dir := global_position.direction_to(_alert_pos)
	velocity.x = dir.x * speed * 0.7
	velocity.z = dir.z * speed * 0.7
	if global_position.distance_to(_alert_pos) < 1.0:
		_alert_timer = 0

func alert(pos: Vector3) -> void:
	if _dead:
		return
	_alert_pos = pos
	_alert_timer = 4.0
	if _state == State.IDLE:
		_change_state(State.CHASE)

func stagger(time: float = 0.25) -> void:
	_stagger_timer = max(_stagger_timer, time)

func take_damage(amount: int) -> void:
	if _dead:
		return
	if health and health.has_method("take_damage"):
		health.take_damage(amount)
	stagger(0.2)

func set_max_health(value: float) -> void:
	max_hp = int(value)
	if health and health.has_method("set_max_health"):
		health.set_max_health(int(value))
	elif health:
		health.max_health = int(value)
		health.current_health = int(value)

func _on_died() -> void:
	if _dead:
		return
	_dead = true
	_state = State.DEAD
	GameManager.enemies_killed += 1
	EventBus.enemy_died.emit(global_position)
	EventBus.enemy_killed.emit(&"enemy_fps")
	queue_free()
