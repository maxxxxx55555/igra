extends CharacterBody3D
class_name Boss

signal boss_died

enum Phase { RUSH, MINIONS, RAGE }
const PHASE_ONE_MIN: float = 0.70
const PHASE_TWO_MIN: float = 0.30

@export var max_hp: float = 800.0
@export var rush_speed: float = 1.1
@export var minion_scene: PackedScene
var _minion_fallback: PackedScene = preload("res://scenes/enemies/boss_minion.tscn")
@export var minions_per_wave: int = 3
@export var rage_speed_mult: float = 1.8
@export var rage_damage_mult: float = 1.5
@export var attack_damage: float = 40.0
@export var attack_range: float = 3.0
@export var attack_cooldown: float = 1.5
@export var hear_range: float = 20.0

const PROJECTILE_DAMAGE: float = 20.0
const ARENA_BEAM_DAMAGE: float = 40.0
const STROBE_STUN_DURATION: float = 1.5
const PHASE_ONE_TELEPORT_INTERVAL: float = 4.0
const PHASE_THREE_BEAM_MIN: float = 3.0
const PHASE_THREE_BEAM_MAX: float = 5.0

var hp: float
var current_phase: Phase = Phase.RUSH
var _attack_timer: float = 0.0
var _player: Node3D = null
var _music_player: AudioStreamPlayer
var _dead: bool = false
var _phase_one_timer: float = 0.0
var _phase_three_timer: float = 4.0
var _phase_two_minions_spawned: bool = false
var _combo_hits: int = 0
var _strobe_finisher_ready: bool = false
var _arena_beams: Array[Node3D] = []

func _ready() -> void:
	hp = max_hp
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	add_to_group("boss")
	_setup_visuals()
	_enter_phase(Phase.RUSH)
	_phase_one_timer = PHASE_ONE_TELEPORT_INTERVAL
	EventBus.boss_finisher_triggered.connect(_on_finisher_triggered)

func _setup_visuals() -> void:
	var col := $Collision
	if col:
		var shape := CylinderShape3D.new()
		shape.radius = 0.8
		shape.height = 2.2
		col.shape = shape
	var mesh := $Mesh
	if mesh:
		var m := CylinderMesh.new()
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
	if _dead or not (is_instance_valid(GameManager) and GameManager.is_playing()):
		return
	if _attack_timer > 0:
		_attack_timer -= delta
	_phase_one_timer -= delta
	_phase_three_timer -= delta
	if current_phase == Phase.RUSH and _phase_one_timer <= 0.0:
		_phase_one_timer = PHASE_ONE_TELEPORT_INTERVAL
		_teleport_near_player()
		_fire_projectile()
	if current_phase == Phase.RAGE and _phase_three_timer <= 0.0:
		_phase_three_timer = randf_range(PHASE_THREE_BEAM_MIN, PHASE_THREE_BEAM_MAX)
		_spawn_arena_beam()
	_update_phase_visibility()
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
		var cooldown_mult: float = 0.5 if _is_light_slowed() else 1.0
		_attack_timer = attack_cooldown * cooldown_mult
		if _player.has_method("take_damage"):
			_player.take_damage(int(attack_damage * _get_damage_mult()), "boss")
			_combo_hits += 1
			if current_phase == Phase.RAGE and _combo_hits >= 3 and _is_in_flashlight():
				_strobe_finisher_ready = true
				EventBus.boss_finisher_triggered.emit()

func _get_damage_mult() -> float:
	return rage_damage_mult if current_phase == Phase.RAGE else 1.0

func _is_light_slowed() -> bool:
	var player := get_tree().get_first_node_in_group("player")
	var light := player.get_node_or_null("ModelPivot/FlashlightPivot/Flashlight") if player else null
	return light != null and bool(light.get_meta("light_slowed", false))

func _teleport_near_player() -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if not is_instance_valid(_player):
		return
	var angle := randf() * TAU
	var offset := Vector3(cos(angle), 0.0, sin(angle)) * randf_range(4.0, 8.0)
	global_position = _player.global_position + offset

func _fire_projectile() -> void:
	if not is_instance_valid(_player):
		return
	var projectile := Area3D.new()
	projectile.name = "ArchitectProjectile"
	projectile.global_position = global_position + Vector3(0.0, 1.2, 0.0)
	var shape_node := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.25
	shape_node.shape = shape
	projectile.add_child(shape_node)
	get_tree().current_scene.add_child(projectile)
	var direction := (_player.global_position + Vector3(0.0, 1.0, 0.0) - projectile.global_position).normalized()
	projectile.set_meta("damage", PROJECTILE_DAMAGE)
	projectile.set_meta("direction", direction)
	projectile.body_entered.connect(func(body: Node3D) -> void:
		if body.has_method("take_damage"):
			body.take_damage(PROJECTILE_DAMAGE)
		projectile.queue_free())
	var tween := projectile.create_tween()
	tween.tween_property(projectile, "global_position", projectile.global_position + direction * 20.0, 2.0)
	tween.tween_callback(projectile.queue_free)

func _update_phase_visibility() -> void:
	var mesh := get_node_or_null("Mesh") as MeshInstance3D
	if current_phase != Phase.MINIONS:
		if mesh:
			mesh.transparency = 0.0
		return
	if not is_instance_valid(_player):
		return
	var light := _player.get_node_or_null("ModelPivot/FlashlightPivot/Flashlight") as SpotLight3D
	var visible_in_light := light != null and _is_in_flashlight()
	if mesh:
		mesh.transparency = 0.0 if visible_in_light else 1.0

func _is_in_flashlight() -> bool:
	var light := _player.get_node_or_null("ModelPivot/FlashlightPivot/Flashlight") as SpotLight3D
	if light == null or not light.visible:
		return false
	var to_boss := global_position - _player.global_position
	if to_boss.length() > light.spot_range:
		return false
	var forward := -_player.global_transform.basis.z
	return rad_to_deg(acos(clampf(forward.dot(to_boss.normalized()), -1.0, 1.0))) <= light.spot_angle * 0.5

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
	if pct <= PHASE_TWO_MIN and current_phase != Phase.RAGE:
		_enter_phase(Phase.RAGE)
	elif pct <= PHASE_ONE_MIN and current_phase == Phase.RUSH:
		_enter_phase(Phase.MINIONS)

func _enter_phase(phase: Phase) -> void:
	current_phase = phase
	match phase:
		Phase.RUSH:
			velocity = Vector3.ZERO
			_set_light_slow(true)
		Phase.MINIONS:
			if not _phase_two_minions_spawned:
				_phase_two_minions_spawned = true
				minions_per_wave = 3
				_spawn_minions()
			_set_light_slow(false)
		Phase.RAGE:
			rush_speed *= rage_speed_mult
			attack_cooldown *= 0.6
			_set_light_slow(false)
	EventBus.boss_phase_changed.emit(phase)

func _set_light_slow(_enabled: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var light := player.get_node_or_null("ModelPivot/FlashlightPivot/Flashlight")
		if light != null:
			light.set_meta("light_slowed", _enabled)

func _spawn_minions() -> void:
	var scene := minion_scene if minion_scene else _minion_fallback
	if not scene:
		return
	for i in range(minions_per_wave):
		var m = scene.instantiate()
		get_parent().add_child(m)
		m.global_position = global_position + Vector3(i * 2.0 - minions_per_wave, 0, 2.0)

func _spawn_arena_beam() -> void:
	var beam := Area3D.new()
	beam.name = "ArchitectFallingBeam"
	beam.global_position = global_position + Vector3(randf_range(-6.0, 6.0), 5.0, randf_range(-6.0, 6.0))
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 0.4, 3.0)
	collision.shape = shape
	beam.add_child(collision)
	get_tree().current_scene.add_child(beam)
	beam.body_entered.connect(func(body: Node3D) -> void:
		if body.has_method("take_damage"):
			body.take_damage(ARENA_BEAM_DAMAGE)
		beam.queue_free())
	var tween := beam.create_tween()
	tween.tween_property(beam, "global_position:y", 0.8, 0.8)
	tween.tween_interval(1.0)
	tween.tween_callback(beam.queue_free)
	_arena_beams.append(beam)

func _on_finisher_triggered() -> void:
	if current_phase != Phase.RAGE or not _is_in_flashlight():
		return
	_strobe_finisher_ready = false
	_combo_hits = 0
	apply_stun(STROBE_STUN_DURATION)

func _try_strobe_finisher() -> void:
	if not _strobe_finisher_ready or not _is_in_flashlight():
		return
	_strobe_finisher_ready = false
	_combo_hits = 0
	if has_method("apply_stun"):
		apply_stun(STROBE_STUN_DURATION)

func apply_stun(duration: float = 1.5) -> void:
	_attack_timer = maxf(_attack_timer, duration)
	velocity = Vector3.ZERO

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
