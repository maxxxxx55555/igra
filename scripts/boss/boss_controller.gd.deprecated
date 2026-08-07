extends CharacterBody3D
class_name BossController

# BOSS — 3 фазы: Rush / Minions / Rage
# Переходы: фаза 2 при HP < 66%, фаза 3 при HP < 33%

enum Phase { IDLE, RUSH, MINIONS, RAGE, DEAD }
var current_phase: Phase = Phase.IDLE

@export var max_hp: float = 1000.0
var hp: float = 0.0

@export var minion_scene: PackedScene
@export var spawn_points: Array[Node3D] = []
@export var rush_speed: float = 8.0
@export var normal_speed: float = 4.0
@export var attack_damage: float = 25.0
@export var attack_cooldown: float = 2.0
@export var minions_per_wave: int = 4
@export var minion_spawn_cooldown: float = 10.0

var _player: Node3D = null
var _attack_timer: float = 0.0
var _minion_timer: float = 0.0
var _phase_enter_time: float = 0.0

signal defeated

func _ready() -> void:
	hp = max_hp
	_player = get_tree().get_first_node_in_group("player")
	_enter_phase(Phase.RUSH)

func _physics_process(delta: float) -> void:
	if current_phase == Phase.DEAD or not is_instance_valid(_player):
		return
	
	_attack_timer -= delta
	_minion_timer -= delta
	
	match current_phase:
		Phase.RUSH:
			_update_rush(delta)
		Phase.MINIONS:
			_update_minions(delta)
		Phase.RAGE:
			_update_rage(delta)
		Phase.IDLE:
			pass
		Phase.DEAD:
			pass

func take_damage(amount: float) -> void:
	if current_phase == Phase.DEAD:
		return
	hp -= amount
	_check_phase_transition()
	if hp <= 0:
		_die()

func _check_phase_transition() -> void:
	var pct = hp / max_hp
	if pct <= 0.33 and current_phase != Phase.RAGE:
		_enter_phase(Phase.RAGE)
	elif pct <= 0.66 and current_phase == Phase.RUSH:
		_enter_phase(Phase.MINIONS)

func _enter_phase(phase: Phase) -> void:
	if current_phase == phase:
		return
	current_phase = phase
	_phase_enter_time = 0.0
	_attack_timer = 0.0
	_minion_timer = 0.0
	
	match phase:
		Phase.RUSH:
			pass
		Phase.MINIONS:
			_spawn_minions()
		Phase.RAGE:
			pass
		Phase.DEAD:
			pass

func _update_rush(delta: float) -> void:
	_phase_enter_time += delta
	if not is_instance_valid(_player):
		return
	
	var dist = global_position.distance_to(_player.global_position)
	if dist < 3.0:
		if _attack_timer <= 0.0:
			_attack()
			_attack_timer = attack_cooldown
	else:
		var dir = (_player.global_position - global_position).normalized()
		velocity = dir * rush_speed
		move_and_slide()

func _update_minions(delta: float) -> void:
	_phase_enter_time += delta
	if not is_instance_valid(_player):
		return
	
	# Move towards player slowly
	var dist = global_position.distance_to(_player.global_position)
	if dist > 8.0:
		var dir = (_player.global_position - global_position).normalized()
		velocity = dir * normal_speed
		move_and_slide()
	
	# Spawn minions periodically
	if _minion_timer <= 0.0:
		_spawn_minions()
		_minion_timer = minion_spawn_cooldown
	
	# Occasional attack
	if dist < 4.0 and _attack_timer <= 0.0:
		_attack()
		_attack_timer = attack_cooldown * 1.5

func _update_rage(delta: float) -> void:
	_phase_enter_time += delta
	if not is_instance_valid(_player):
		return
	
	# Fast aggressive movement
	var dist = global_position.distance_to(_player.global_position)
	if dist < 4.0:
		if _attack_timer <= 0.0:
			_attack()
			_attack_timer = attack_cooldown * 0.5  # Faster attacks
	else:
		var dir = (_player.global_position - global_position).normalized()
		velocity = dir * (rush_speed * 1.3)
		move_and_slide()
	
	# Spawn more minions faster
	if _minion_timer <= 0.0:
		_spawn_minions()
		_minion_timer = minion_spawn_cooldown * 0.5

func _spawn_minions() -> void:
	if not minion_scene:
		return
	
	var count = min(minions_per_wave, spawn_points.size())
	for i in range(count):
		var idx = (i + _phase_enter_time as int) % spawn_points.size()
		var spawn_point = spawn_points[idx]
		if spawn_point:
			var minion = minion_scene.instantiate()
			minion.global_position = spawn_point.global_position
			add_child(minion)
			if multiplayer.has_multiplayer_peer():
				minion.set_multiplayer_authority(1)

func _attack() -> void:
	if not is_instance_valid(_player):
		return
	if _player.has_method("take_damage"):
		_player.take_damage(attack_damage)

func _die() -> void:
	current_phase = Phase.DEAD
	velocity = Vector3.ZERO
	defeated.emit()
	EventBus.boss_defeated.emit()
	EventBus.enemy_killed.emit(&"boss")
	queue_free()