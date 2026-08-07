extends CharacterBody3D
class_name Boss

signal boss_died

enum Phase { RUSH, MINIONS, RAGE }

@export var max_hp: float = 800.0
@export var rush_speed: float = 6.0
@export var minion_scene: PackedScene
@export var minions_per_wave: int = 3
@export var rage_speed_mult: float = 1.8
@export var rage_damage_mult: float = 1.5
@export var attack_damage: float = 40.0
@export var attack_range: float = 3.0
@export var attack_cooldown: float = 1.5

var hp: float
var current_phase: Phase = Phase.RUSH
var _attack_timer: float = 0.0
var _player: Node3D = null
var _music_player: AudioStreamPlayer
var _dead: bool = false

func _ready() -> void:
	hp = max_hp
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	add_to_group("boss")
	_setup_visuals()
	_enter_phase(Phase.RUSH)

func _setup_visuals() -> void:
	var col := $Collision
	if col:
		var shape := CylinderShape3D.new()
		shape.radius = 0.8
		shape.height = 2.2
		col.shape = shape
	var mesh := $Mesh
	if mesh:
		var m := CylinderMesh3D.new()
		m.top_radius = 0.7
		m.bottom_radius = 0.7
		m.height = 2.0
		m.radial_segments = 12
		mesh.mesh = m
		mesh.position.y = 1.0
	var atk := $AttackRange/AttackCollision
	if atk:
		var s := SphereShape3D.new()
		s.radius = attack_range
		atk.shape = s

func _physics_process(delta: float) -> void:
	if _dead or not GameManager.is_playing():
		return
	if _attack_timer > 0:
		_attack_timer -= delta
	_do_attack()
	_face_player()
	move_and_slide()

func _face_player() -> void:
	if not is_instance_valid(_player):
		return
	var look_pos := _player.global_position
	look_pos.y = global_position.y
	look_at(look_pos)

func _do_attack() -> void:
	if _attack_timer > 0 or not is_instance_valid(_player):
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist <= attack_range:
		_attack_timer = attack_cooldown
		if _player.has_method("take_damage"):
			_player.take_damage(int(attack_damage * _get_damage_mult()), "boss")

func _get_damage_mult() -> float:
	return rage_damage_mult if current_phase == Phase.RAGE else 1.0

func take_damage(amount: float) -> void:
	if _dead:
		return
	hp -= amount
	if hp <= 0:
		die()
		return
	_check_phase_transition()

func _check_phase_transition() -> void:
	var pct := hp / max_hp
	if pct < 0.33 and current_phase != Phase.RAGE:
		_enter_phase(Phase.RAGE)
	elif pct < 0.66 and current_phase == Phase.RUSH:
		_enter_phase(Phase.MINIONS)

func _enter_phase(phase: Phase) -> void:
	current_phase = phase
	match phase:
		Phase.RUSH:
			velocity = Vector3.ZERO
		Phase.MINIONS:
			_spawn_minions()
		Phase.RAGE:
			rush_speed *= rage_speed_mult
			attack_cooldown *= 0.6
	EventBus.boss_phase_changed.emit(phase)

func _spawn_minions() -> void:
	if not minion_scene:
		return
	for i in range(minions_per_wave):
		var m = minion_scene.instantiate()
		get_parent().add_child(m)
		m.global_position = global_position + Vector3(i * 2.0 - minions_per_wave, 0, 2.0)

func die() -> void:
	_dead = true
	_music_player.stop()
	boss_died.emit()
	EventBus.enemy_died.emit(global_position)
	await get_tree().create_timer(2.0).timeout
	EndingsManager.force_ending("victory")
	queue_free()

func set_target(player: Node3D) -> void:
	_player = player
