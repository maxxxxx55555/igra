class_name BossMonster
extends "res://scripts/enemies/base_monster.gd"

## S7.3 The Architect: P1 ranged+teleport, P2 invisible in dark + 3 shadows, P3 melee enrage + falling beams.

enum Phase { P1, P2, P3 }

const BALL_DAMAGE: float = 20.0
const BEAM_DAMAGE: float = 25.0
const MAX_MINIONS: int = 3
const TELEPORT_INTERVAL: float = 6.0
const BEAM_INTERVAL: float = 4.0

var phase: Phase = Phase.P1
var _summon_timer: float = 0.0
var _teleport_timer: float = 0.0
var _beam_timer: float = 0.0
var _minions: Array[Node] = []
var _minion_seq: int = 0
var _music_started: bool = false

func _init() -> void:
	monster_id = &"boss"

func _ready() -> void:
	super._ready()
	attack_cooldown = 2.0
	light_flee = false
	add_to_group("boss")
	_add_silhouette()

func _tick_ai(delta: float) -> void:
	if ai_state == State.DEAD:
		return
	# Музыка босса — при первом контакте с игроком, а не при спавне.
	if not _music_started and player_ref != null and is_instance_valid(player_ref):
		_music_started = true
		var md := get_node_or_null("/root/MusicManager")
		if md != null and md.has_method("enter_boss"):
			md.enter_boss()
	var ratio: float = hp / max_hp
	if ratio > 0.66:
		phase = Phase.P1
	elif ratio > 0.33:
		if phase == Phase.P1:
			_switch_to_p2()
		phase = Phase.P2
	else:
		if phase == Phase.P2:
			_switch_to_p3()
		phase = Phase.P3
	match phase:
		Phase.P1:
			_tick_p1(delta)
		Phase.P2:
			_tick_p2(delta)
		Phase.P3:
			_tick_p3(delta)

func _tick_p1(delta: float) -> void:
	if ai_state == State.ATTACK and attack_timer > 0.0:
		return
	_teleport_timer -= delta
	if _teleport_timer <= 0.0:
		_teleport_timer = TELEPORT_INTERVAL
		_teleport_near_player()
	if player_ref and is_instance_valid(player_ref):
		_throw_energy_ball()
		var cd: float = attack_cooldown
		if _is_in_light():
			cd *= 1.5
		attack_timer = cd
	_change_state(State.ATTACK)

func _tick_p2(delta: float) -> void:
	if ai_state == State.STUN:
		return
	if not _is_in_light():
		visible = false
		_change_state(State.CHASE)
		if player_ref and is_instance_valid(player_ref):
			set_nav_target(player_ref.global_position)
			_move_to(chase_speed)
	else:
		visible = true
		_change_state(State.ATTACK)
		_summon_timer += delta
		if _summon_timer >= 3.0:
			_summon_timer = 0.0
			_summon_minion()

func _tick_p3(delta: float) -> void:
	if ai_state == State.STUN:
		return
	_beam_timer += delta
	if _beam_timer >= BEAM_INTERVAL:
		_beam_timer = 0.0
		_spawn_falling_beam()
	if player_ref and is_instance_valid(player_ref):
		var dist := global_position.distance_to(player_ref.global_position)
		if dist > attack_range:
			set_nav_target(player_ref.global_position)
			_move_to(chase_speed * 1.3)
		else:
			_perform_melee()

func _throw_energy_ball() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
	var dir := (player_ref.global_position - global_position).normalized()
	dir.y = 0.0
	if dir.length_squared() < 0.001:
		return
	var ball := EnergyBall.new(dir, BALL_DAMAGE)
	get_tree().current_scene.add_child(ball)
	ball.global_position = global_position + Vector3(0, 1.8, 0)

func _teleport_near_player() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
	var ang := randf() * TAU
	var dist := randf_range(6.0, 12.0)
	var target := player_ref.global_position + Vector3(cos(ang), 0.0, sin(ang)) * dist
	global_position = target
	velocity = Vector3.ZERO
	AudioManager.play_sound_3d(_HIT_SFX, global_position, -6.0)

func _summon_minion() -> void:
	var alive: Array[Node] = []
	for m in _minions:
		if is_instance_valid(m):
			alive.append(m)
	_minions = alive
	if _minions.size() >= MAX_MINIONS:
		return
	_minion_seq += 1
	var mname := "BossMinion%d" % _minion_seq
	var pos := global_position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
	var shadow := _spawn_minion_node(mname, pos)
	if shadow == null:
		return
	_minions.append(shadow)
	EventBus.enemy_spawned.emit(shadow)
	if _net_active:
		_spawn_minion_remote.rpc(mname, pos)

@rpc("authority", "reliable")
func _spawn_minion_remote(mname: String, pos: Vector3) -> void:
	if is_multiplayer_authority():
		return
	_spawn_minion_node(mname, pos)

func _spawn_minion_node(mname: String, pos: Vector3) -> Node:
	var shadow_scene := preload("res://scenes/enemies/shadow_3d.tscn")
	if not shadow_scene:
		return null
	var shadow := shadow_scene.instantiate()
	shadow.name = mname
	shadow.position = pos
	get_tree().current_scene.add_child(shadow)
	return shadow

func _spawn_falling_beam() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
	var beam := FallingBeam.new(BEAM_DAMAGE)
	get_tree().current_scene.add_child(beam)
	beam.global_position = player_ref.global_position + Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0))

func _perform_melee() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
	player_ref.take_damage(attack_damage)
	EventBus.enemy_attack.emit(attack_damage)
	attack_timer = attack_cooldown * 0.5

func _switch_to_p2() -> void:
	_teleport_timer = 0.0

func _switch_to_p3() -> void:
	_summon_timer = 0.0
	_beam_timer = 0.0

func take_damage(amount: float, _src_pos: Vector3 = Vector3.ZERO, type: EnemyRosterData.DamageType = EnemyRosterData.DamageType.BULLET) -> void:
	if _net_active and not is_multiplayer_authority():
		_request_damage.rpc_id(1, amount)
		return
	_ensure_hp()
	if ai_state == State.DEAD:
		return
	if phase == Phase.P2 and not _is_in_light():
		return
	var mult: float = 1.0
	if roster_entry.has("resistances"):
		var res: Dictionary = roster_entry["resistances"]
		mult = float(res.get(int(type), 1.0))
	var final_dmg: float = amount * mult * (1.0 - armor)
	hp -= final_dmg
	AudioManager.play_sound_3d(_HIT_SFX, global_position, -6.0)
	if hp <= 0.0:
		_trigger_death()

func _trigger_death() -> void:
	EventBus.boss_defeated.emit()
	super._trigger_death()
	await get_tree().create_timer(2.5).timeout
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/ui/victory_screen.tscn")

func _add_silhouette() -> void:
	if get_node_or_null("BodyMesh"):
		return
	var body := MeshInstance3D.new()
	body.name = "BodyMesh"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.4
	mesh.bottom_radius = 0.55
	mesh.height = 3.2
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.03, 0.03, 0.05)
	mat.roughness = 1.0
	mat.emission_enabled = true
	mat.emission = Color(0.03, 0.0, 0.07)
	mat.emission_energy_multiplier = 0.6
	body.material_override = mat
	body.position = Vector3(0, 1.6, 0)
	add_child(body)

class EnergyBall:
	extends Area3D

	var _dir: Vector3
	var _speed: float = 14.0
	var _damage: float = 20.0
	var _life: float = 5.0

	func _init(direction: Vector3, dmg: float) -> void:
		_dir = direction
		_damage = dmg
		collision_layer = 0
		collision_mask = 1
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.35
		col.shape = shape
		add_child(col)
		var mesh := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.35
		sphere.height = 0.7
		mesh.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.2, 0.9)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.3, 1.0)
		mat.emission_energy_multiplier = 3.0
		mesh.material_override = mat
		add_child(mesh)
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.3, 1.0)
		light.light_energy = 2.0
		light.omni_range = 6.0
		light.shadow_enabled = false
		add_child(light)
		body_entered.connect(_on_body_entered)

	func _physics_process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0:
			queue_free()
			return
		global_position += _dir * _speed * delta
		look_at(global_position + _dir, Vector3.UP)

	func _on_body_entered(body: Node) -> void:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(_damage)
			EventBus.enemy_attack.emit(_damage)
			queue_free()

class FallingBeam:
	extends Area3D

	var _fall_y: float = 12.0
	var _hit: bool = false
	var _damage: float = 25.0
	var _sink: float = 0.0

	func _init(dmg: float) -> void:
		_damage = dmg
		collision_layer = 0
		collision_mask = 1
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.0, 1.0, 1.0)
		col.shape = shape
		add_child(col)
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.0, 1.2, 1.0)
		mesh.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.13, 0.1)
		mat.roughness = 1.0
		mesh.material_override = mat
		add_child(mesh)
		position.y = _fall_y

	func _physics_process(delta: float) -> void:
		if not _hit:
			_fall_y -= 20.0 * delta
			position.y = _fall_y
			if _fall_y <= 0.8:
				_hit = true
				for body in get_overlapping_bodies():
					if body.is_in_group("player") and body.has_method("take_damage"):
						body.take_damage(_damage)
						EventBus.enemy_attack.emit(_damage)
		else:
			_sink += delta
			if _sink > 0.6:
				queue_free()
