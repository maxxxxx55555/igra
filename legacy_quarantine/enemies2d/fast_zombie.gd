
extends CharacterBody3D

enum State { PATROL, CHASE, ATTACK, DEAD }

@export 
var speed: float = 6.0

@export 
var health: int = 30

@export 
var damage: int = 10

@onready 
var nav: NavigationAgent3D = $NavigationAgent3D

@onready 
var attack_area: Area3D = $AttackArea

var _state: State = State.PATROL

var _target: Node3D = null

var _attack_timer: float = 0.0

func _ready() -> void:
	attack_area.body_entered.connect(_on_attack_area)

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	if not _target:
		_target = get_tree().get_first_node_in_group("player") as Node3D
	if _target:
		
		var dist := global_position.distance_to(_target.global_position)
		if dist < 10.0:
			_state = State.CHASE
		if dist < 1.5:
			_state = State.ATTACK
	if _state == State.CHASE or _state == State.ATTACK:
		nav.target_position = _target.global_position
		var next := nav.get_next_path_position()
		var dir := global_position.direction_to(next)
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		velocity += get_gravity() * delta
		move_and_slide()
	_handle_attack(delta)

func _handle_attack(delta: float) -> void:
	if _state != State.ATTACK:
		return
	_attack_timer -= delta
	if _attack_timer <= 0:
		EventBus.player_damaged.emit(damage)
		_attack_timer = 0.8

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		_die()

func _die() -> void:
	_state = State.DEAD
	EventBus.enemy_died.emit(global_position)
	queue_free()

func _on_attack_area(body: Node3D) -> void:
	if body.is_in_group("player"):
		_state = State.ATTACK
