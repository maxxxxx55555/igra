class_name BaseMonster
extends CharacterBody3D

const _HIT_SFX := preload("res://assets/audio/sfx/sfx_hit.wav")
const _ROSTER := preload("res://data/balance/enemy_stats.tres")

enum State { IDLE, PATROL, INVESTIGATE, CHASE, ATTACK, FLEE, STUN, DEAD }

@export var monster_id: StringName = &"base_monster"
@export var max_hp: float = 50.0
@export var speed: float = 2.0
@export var chase_speed: float = 3.0
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.5
@export var attack_range: float = 1.5
@export var detect_range: float = 10.0
@export var vision_range: float = 10.0
@export var vision_angle: float = 90.0
@export var peripheral_range: float = 0.0
@export var peripheral_angle: float = 0.0
@export var noise_threshold: float = 0.3
@export var patrol_radius: float = 5.0
@export var armor: float = 0.0
@export var light_damage_per_sec: float = 0.0
@export var stun_duration: float = 2.0
@export var flee_duration: float = 3.0
@export var light_flee: bool = true

var ai_state: State = State.IDLE
var hp: float = 0.0
var _hp_initialized: bool = false
var _ng_scaled: bool = false
var player_ref: Node3D = null
var attack_timer: float = 0.0
var _nav_agent: NavigationAgent3D
var _detect_area: Area3D
var _idle_timer: float = 0.0
var _base_speed: float = 5.0
var _stun_timer: float = 0.0
var _flee_timer: float = 0.0
var _investigate_timer: float = 0.0
var _investigate_point: Vector3 = Vector3.ZERO
var _death_timer: float = 0.0
var _rage_active: bool = false
var _rage_timer: float = 0.0
var _slow_active: bool = false
var _vision_lost_timer: float = 0.0
var _light_exposure_timer: float = 0.0
var _is_in_flashlight: bool = false
var _net_active: bool = false
var _remote_pos: Vector3 = Vector3.ZERO
var _remote_rot: float = 0.0
var _net_sync_timer: float = 0.0
var _telegraph: Node = null

# --- status effects (P7-data2) ---
var _status_node: Node = null

## Параметры статусов, которые монстр накладывает при попадании (inflicts ростера).
const _STATUS_PARAMS: Dictionary = {
	EnemyRosterData.Status.BLEED: {"duration": 4.0, "dps": 2.0},
	EnemyRosterData.Status.BURN: {"duration": 3.0, "dps": 3.0},
	EnemyRosterData.Status.POISON: {"duration": 5.0, "dps": 1.5},
	EnemyRosterData.Status.SLOW: {"duration": 2.0, "power": 0.5},
	EnemyRosterData.Status.STUN: {"duration": 1.5},
	EnemyRosterData.Status.FEAR: {"duration": 3.0},
}

## Публичный вход для статусов НА монстра (оружие, стробоскоп, UV).
func apply_status(status: int, duration: float, dps: float = 0.0, power: float = 0.0) -> void:
	if _status_node:
		_status_node.apply(status, duration, dps, power)

## Накладывает на цель статусы из поля inflicts ростера (если цель их поддерживает).
## ponytail: у игрока пока нет apply_status — вызов graceful no-op, проводка на монстрах есть.
func _inflict_statuses(target: Node) -> void:
	var inf: Array = roster_entry.get("inflicts", [])
	if inf.is_empty() or not target.has_method("apply_status"):
		return
	for s in inf:
		var p: Dictionary = _STATUS_PARAMS.get(int(s), {"duration": 2.0})
		target.apply_status(int(s), float(p.get("duration", 2.0)), float(p.get("dps", 0.0)), float(p.get("power", 0.0)))

func _ready() -> void:
	_apply_roster_stats()
	_apply_ng_scaling()
	_ensure_hp()
	_nav_agent = get_node_or_null("NavigationAgent3D")
	if not _nav_agent:
		_nav_agent = NavigationAgent3D.new()
		_nav_agent.name = "NavigationAgent3D"
		add_child(_nav_agent)
	_nav_agent.path_desired_distance = 1.0
	_nav_agent.target_desired_distance = 1.5
	_detect_area = get_node_or_null("DetectArea")
	if not _detect_area:
		_detect_area = Area3D.new()
		_detect_area.name = "DetectArea"
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = detect_range
		col.shape = shape
		_detect_area.add_child(col)
		add_child(_detect_area)
	_detect_area.body_entered.connect(_on_detect_body_entered)
	_detect_area.body_exited.connect(_on_detect_body_exited)
	add_to_group("enemies")
	add_to_group("monsters")
	_status_node = load("res://scripts/enemies/status_effects.gd").new()
	_status_node.mob = self
	add_child(_status_node)
	_net_active = multiplayer != null and multiplayer.multiplayer_peer != null
	if _net_active:
		set_multiplayer_authority(1)
	_telegraph = get_node_or_null("MonsterTelegraph")
	if _telegraph == null:
		_telegraph = load("res://scripts/enemies/monster_telegraph.gd").new()
		_telegraph.name = "MonsterTelegraph"
		add_child(_telegraph)
	_build_visual()

func _build_visual() -> void:
	if get_node_or_null("VisualRoot"):
		return
	var root := Node3D.new()
	root.name = "VisualRoot"
	add_child(root)
	if owner and owner != root:
		root.owner = owner
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.08, 0.06, 0.05)
	body_mat.roughness = 0.9
	body_mat.metallic = 0.0
	var body := MeshInstance3D.new()
	body.name = "BodyMesh"
	body.mesh = CylinderMesh.new()
	(body.mesh as CylinderMesh).top_radius = 0.35
	(body.mesh as CylinderMesh).bottom_radius = 0.45
	(body.mesh as CylinderMesh).height = 1.6
	body.material_override = body_mat
	body.position = Vector3(0, 0.8, 0)
	root.add_child(body)
	body.owner = root.owner
	var head := MeshInstance3D.new()
	head.name = "HeadMesh"
	head.mesh = SphereMesh.new()
	(head.mesh as SphereMesh).radius = 0.25
	head.material_override = body_mat
	head.position = Vector3(0, 1.65, 0)
	root.add_child(head)
	head.owner = root.owner

## Применяет канон-статы из data/balance/enemy_stats.tres по monster_id.
## Наследники задают monster_id (либо ai_id который мапится через
## EnemyRosterData.AI_TO_ROSTER). Нечисловые поля (поведение, сопротивления,
## weak_spot) остаются в `roster_entry` для внешних систем (loot, encyclopedia).
var roster_entry: Dictionary = {}

func _apply_roster_stats() -> void:
	roster_entry = _ROSTER.get_entry_for_ai(monster_id)
	if roster_entry.is_empty():
		return
	max_hp = float(roster_entry.get("hp", max_hp))
	attack_damage = float(roster_entry.get("damage", attack_damage))
	armor = float(roster_entry.get("armor", armor)) / 100.0
	var spd: float = float(roster_entry.get("speed", 0.0))
	if spd > 0.0:
		_base_speed = spd
		chase_speed = spd
		speed = spd
	attack_range = float(roster_entry.get("attack_range", attack_range))
	detect_range = float(roster_entry.get("detect_range", detect_range))
	vision_range = maxf(vision_range, detect_range)

## hp инициализируется здесь, а не только в _ready(): монстр попадает в группы
## ещё до входа в дерево, и урон, прилетевший раньше _ready(), бил по hp = 0
## (мгновенная смерть), после чего _ready() воскрешал труп на полном здоровье.
func _ensure_hp() -> void:
	if _hp_initialized:
		return
	_hp_initialized = true
	hp = max_hp

## Вызывается до _ensure_hp(), чтобы hp сразу считался от отмасштабированного
## max_hp. Раньше шёл через call_deferred и накручивал множители повторно.
func _apply_ng_scaling() -> void:
	if _ng_scaled:
		return
	_ng_scaled = true
	var ngp := get_node_or_null("/root/NewGamePlus")
	if ngp == null or not ngp.is_ng_plus_active():
		return
	var m_hp: float = ngp.get_enemy_hp_multiplier()
	var m_dmg: float = ngp.get_enemy_damage_multiplier()
	if m_hp != 1.0:
		max_hp *= m_hp
	if m_dmg != 1.0:
		attack_damage *= m_dmg

func _physics_process(delta: float) -> void:
	if _net_active:
		if not is_multiplayer_authority():
			_sync_remote(delta)
			velocity = Vector3.ZERO
			move_and_slide()
			return
		_sync_broadcast(delta)
	attack_timer = maxf(0.0, attack_timer - delta)
	_update_light_exposure(delta)
	_update_timers(delta)
	if ai_state == State.DEAD:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	_tick_ai(delta)
	move_and_slide()

func _tick_ai(delta: float) -> void:
	match ai_state:
		State.IDLE: _state_idle(delta)
		State.PATROL: _state_patrol(delta)
		State.INVESTIGATE: _state_investigate(delta)
		State.CHASE: _state_chase(delta)
		State.ATTACK: _state_attack(delta)
		State.FLEE: _state_flee(delta)
		State.STUN: _state_stun(delta)
		State.DEAD: _state_dead(delta)

func _update_timers(delta: float) -> void:
	if _stun_timer > 0.0:
		_stun_timer -= delta
		if _stun_timer <= 0.0:
			_stun_timer = 0.0
			if player_ref and is_instance_valid(player_ref):
				_change_state(State.CHASE)
			else:
				_change_state(State.PATROL)
		return
	if _flee_timer > 0.0:
		_flee_timer -= delta
		if _flee_timer <= 0.0:
			_flee_timer = 0.0
			if player_ref and is_instance_valid(player_ref):
				_investigate_point = player_ref.global_position
				_investigate_timer = 5.0
				_change_state(State.INVESTIGATE)
			else:
				_change_state(State.PATROL)
		return
	if _investigate_timer > 0.0:
		_investigate_timer -= delta
		if _investigate_timer <= 0.0:
			_change_state(State.PATROL)
		return
	if _rage_timer > 0.0:
		_rage_timer -= delta
		if _rage_timer <= 0.0:
			_rage_active = false
	if _slow_active and not _is_in_flashlight:
		_slow_active = false

func _update_light_exposure(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_is_in_flashlight = false
		return
	var fl: SpotLight3D = player_ref.get_node_or_null("ModelPivot/FlashlightPivot/Flashlight")
	if not fl or not fl.visible or fl.light_energy <= 0.1:
		_is_in_flashlight = false
		return
	var to_monster: Vector3 = global_position - player_ref.global_position
	var dist: float = to_monster.length()
	if dist > 8.0:
		_is_in_flashlight = false
		return
	var forward: Vector3 = -player_ref.global_transform.basis.z
	var angle_deg: float = rad_to_deg(acos(clampf(forward.dot(to_monster.normalized()), -1.0, 1.0)))
	_is_in_flashlight = dist < fl.spot_range and angle_deg < fl.spot_angle * 0.5
	_handle_light_reaction(delta)

func _handle_light_reaction(delta: float) -> void:
	if not _is_in_flashlight:
		_light_exposure_timer = 0.0
		return
	_light_exposure_timer += delta
	if light_damage_per_sec > 0.0 and _light_exposure_timer >= 1.0:
		_light_exposure_timer = 0.0
		take_damage(light_damage_per_sec, Vector3.ZERO, EnemyRosterData.DamageType.FIRE)

func _is_in_light() -> bool:
	return _is_in_flashlight

func _state_idle(delta: float) -> void:
	velocity = Vector3.ZERO
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		_idle_timer = randf_range(1.0, 4.0)
		var target := _pick_patrol_target()
		_set_nav_target(target)
		_change_state(State.PATROL)

func _state_patrol(delta: float) -> void:
	if _nav_agent and _nav_agent.is_navigation_finished():
		_idle_timer = randf_range(2.0, 5.0)
		_change_state(State.IDLE)
		return
	_move_to(_base_speed * 0.3)
	_detect_ambient()

func _state_investigate(delta: float) -> void:
	_set_nav_target(_investigate_point)
	if _nav_agent and _nav_agent.is_navigation_finished():
		_investigate_timer = 5.0
	_move_to(_base_speed * 0.6)
	_detect_ambient()

func _state_chase(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_change_state(State.PATROL)
		return
	_set_nav_target(player_ref.global_position)
	var dist := global_position.distance_to(player_ref.global_position)
	if dist <= attack_range and attack_timer <= 0.0:
		_change_state(State.ATTACK)
		return
	var spd: float = chase_speed
	if _slow_active:
		spd *= 0.5
	if _status_node:
		spd *= _status_node.speed_multiplier()
	if _rage_active:
		spd *= 1.3
	_move_to(spd)

func _state_attack(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_change_state(State.PATROL)
		return
	var dist := global_position.distance_to(player_ref.global_position)
	if dist > attack_range:
		_change_state(State.CHASE)
		return
	if attack_timer <= 0.0:
		_perform_attack()
		attack_timer = attack_cooldown

func _state_flee(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_change_state(State.PATROL)
		return
	var flee_dir := (global_position - player_ref.global_position).normalized()
	_set_nav_target(global_position + flee_dir * 15.0)
	_move_to(_base_speed * 1.2)

func _state_stun(delta: float) -> void:
	velocity = Vector3.ZERO

func _state_dead(delta: float) -> void:
	velocity = Vector3.ZERO
	_death_timer -= delta
	if _death_timer <= 0.0:
		queue_free()

func _detect_ambient() -> void:
	if player_ref and is_instance_valid(player_ref):
		var noise_val: float = 0.0
		if player_ref.has_method("get_noise_level"):
			noise_val = player_ref.get_noise_level()
		if noise_val > noise_threshold and noise_val > 0.0:
			_investigate_point = player_ref.global_position
			_investigate_timer = 5.0
			_change_state(State.INVESTIGATE)
		if _can_see_player():
			_change_state(State.CHASE)

func _perform_attack() -> void:
	if not player_ref or not is_instance_valid(player_ref) or not player_ref.has_method("take_damage"):
		return
	if _telegraph:
		_telegraph.warn(_deal_damage)
	else:
		_deal_damage()

func _deal_damage() -> void:
	if player_ref and is_instance_valid(player_ref) and player_ref.has_method("take_damage"):
		if global_position.distance_to(player_ref.global_position) <= attack_range + 0.5:
			player_ref.take_damage(attack_damage)
			_inflict_statuses(player_ref)
			EventBus.enemy_attack.emit(attack_damage)


func _can_see_player() -> bool:
	if not player_ref or not is_instance_valid(player_ref):
		return false
	var dist := global_position.distance_to(player_ref.global_position)
	if dist > vision_range:
		# Check peripheral vision
		if peripheral_range > 0.0 and dist <= peripheral_range:
			var dir_to := (player_ref.global_position - global_position).normalized()
			var forward := -global_transform.basis.z.normalized()
			var angle := acos(clampf(dir_to.dot(forward), -1.0, 1.0))
			if angle <= deg_to_rad(peripheral_angle):
				return _check_line_of_sight()
		return false
	var dir_to := (player_ref.global_position - global_position).normalized()
	var forward := -global_transform.basis.z.normalized()
	var angle := acos(clampf(dir_to.dot(forward), -1.0, 1.0))
	if angle > deg_to_rad(vision_angle * 0.5):
		# Check peripheral vision
		if peripheral_range > 0.0 and dist <= peripheral_range and angle <= deg_to_rad(peripheral_angle * 0.5):
			return _check_line_of_sight()
		return false
	return _check_line_of_sight()

func _check_line_of_sight() -> bool:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1.0, 0), player_ref.global_position + Vector3(0, 1.0, 0))
	query.exclude = [self]
	var result := space.intersect_ray(query)
	if result.is_empty():
		return false
	return result.collider.is_in_group("player")

func _move_to(spd: float) -> void:
	if not _nav_agent or not _nav_agent.is_inside_tree():
		return
	var next_pos := _nav_agent.get_next_path_position()
	var dir := (next_pos - global_position).normalized()
	dir.y = 0.0
	if dir.length_squared() < 0.001:
		return
	velocity.x = dir.x * spd
	velocity.z = dir.z * spd
	velocity.y += get_gravity().y * get_physics_process_delta_time()
	_look_at_smooth(dir)

func _look_at_smooth(dir: Vector3) -> void:
	var target_angle: float = atan2(dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 10.0 * get_physics_process_delta_time())

func _pick_patrol_target() -> Vector3:
	return global_position + Vector3(randf_range(-patrol_radius, patrol_radius), 0, randf_range(-patrol_radius, patrol_radius))

func _set_nav_target(pos: Vector3) -> void:
	if _nav_agent and _nav_agent.is_inside_tree():
		_nav_agent.target_position = pos

func set_nav_target(pos: Vector3) -> void:
	_set_nav_target(pos)

func _on_detect_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_ref = body as Node3D
		if ai_state == State.IDLE or ai_state == State.PATROL:
			if _can_see_player():
				_change_state(State.CHASE)
			else:
				_investigate_point = body.global_position
				_investigate_timer = 5.0
				_change_state(State.INVESTIGATE)

func _on_detect_body_exited(body: Node) -> void:
	if body == player_ref:
		player_ref = null
		if ai_state == State.CHASE or ai_state == State.ATTACK:
			_change_state(State.PATROL)

func take_damage(amount: float, _src_pos: Vector3 = Vector3.ZERO, type: EnemyRosterData.DamageType = EnemyRosterData.DamageType.BULLET) -> void:
	if _net_active and not is_multiplayer_authority():
		_request_damage.rpc_id(1, amount, int(type))
		return
	_ensure_hp()
	if ai_state == State.DEAD:
		return
	var mult: float = 1.0
	if roster_entry.has("resistances"):
		var res: Dictionary = roster_entry["resistances"]
		mult = float(res.get(int(type), 1.0))
	var reduced: float = amount * mult * (1.0 - armor)
	hp -= reduced
	AudioManager.play_sound_3d(_HIT_SFX, global_position, -6.0)
	_hit_flash()

	if player_ref and is_instance_valid(player_ref):
		if ai_state in [State.IDLE, State.PATROL, State.INVESTIGATE]:
			_change_state(State.CHASE)
	if hp <= 0.0:
		_die()

func _hit_flash() -> void:
	var root = get_node_or_null("VisualRoot")
	if not root:
		return
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		if mesh.material_override:
			var mat = mesh.material_override.duplicate() as StandardMaterial3D
			mat.albedo_color = Color(1, 1, 1)
			mat.emission_enabled = true
			mat.emission = Color(1, 1, 1)
			mat.emission_energy_multiplier = 2.0
			mesh.material_override = mat
			var tw = create_tween()
			tw.tween_callback(func(): mesh.material_override = mesh.material_override.duplicate()).set_delay(0.1)

@rpc("any_peer", "reliable")
func _request_damage(amount: float, type: int = int(EnemyRosterData.DamageType.BULLET)) -> void:
	if _net_active and not is_multiplayer_authority():
		return
	take_damage(clampf(amount, 0.0, 200.0), Vector3.ZERO, type as EnemyRosterData.DamageType)

func stun(duration: float = 2.0) -> void:
	if ai_state == State.DEAD:
		return
	_stun_timer = duration
	_change_state(State.STUN)


func _trigger_flee() -> void:
	if ai_state in [State.FLEE, State.DEAD, State.STUN]:
		return
	_change_state(State.FLEE)
	_flee_timer = flee_duration

func _die() -> void:
	if ai_state == State.DEAD:
		return
	_change_state(State.DEAD)
	_death_timer = 3.0
	EventBus.enemy_killed.emit(monster_id)
	EventBus.enemy_died.emit(global_position)
	EventBus.coins_changed.emit(randi_range(5, 15))
	_death_effect()

func _death_effect() -> void:
	var p := GPUParticles3D.new()
	p.amount = 30
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 1.0
	p.spread = 180
	p.initial_velocity = 5.0
	p.gravity = Vector3(0, -9.8, 0)
	p.global_position = global_position + Vector3(0, 1.0, 0)
	var pm := ParticleProcessMaterial.new()
	pm.color = Color(0.8, 0.6, 0.3, 0.8)
	pm.color_ramp = Gradient.new().set_color_ramp([
		Color(1.0, 0.7, 0.3, 0.8),
		Color(0.5, 0.3, 0.1, 0.0)
	])
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.2, 0.2)
	p.draw_pass_1 = q
	get_tree().root.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free.bind())

func _trigger_death() -> void:
	_die()


func _state_name(s: State) -> String:
	match s:
		State.IDLE: return "IDLE"
		State.PATROL: return "PATROL"
		State.INVESTIGATE: return "INVESTIGATE"
		State.CHASE: return "CHASE"
		State.ATTACK: return "ATTACK"
		State.FLEE: return "FLEE"
		State.STUN: return "STUN"
		State.DEAD: return "DEAD"
	return "UNKNOWN"

func _change_state(new_state: State) -> void:
	var prev := ai_state
	ai_state = new_state
	if prev != new_state:
		if new_state == State.CHASE:
			EventBus.player_detected.emit(monster_id)
			play_cue(&"chase")
		elif new_state == State.INVESTIGATE:
			play_cue(&"investigate")
		elif new_state == State.ATTACK:
			play_cue(&"attack")

## S9.3 monster audio cues. Subclasses set CUES via _set_cues() in _ready().
## Each entry: cue name -> {"file": String, "db": float, "range": float}
var _cues: Dictionary = {}
var _cue_cooldown: Dictionary = {}

func _set_cues(cues: Dictionary) -> void:
	_cues = cues

## Plays a positional cue if defined; throttled so chase re-entry cannot spam.
func play_cue(cue: StringName, min_interval: float = 2.0) -> void:
	if ai_state == State.DEAD or not _cues.has(cue):
		return
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	if now - float(_cue_cooldown.get(cue, -999.0)) < min_interval:
		return
	_cue_cooldown[cue] = now
	var data: Dictionary = _cues[cue]
	var path: String = "res://assets/audio/sfx/%s.wav" % String(data.get("file", ""))
	if not ResourceLoader.exists(path):
		return
	var am := get_node_or_null("/root/AudioManager")
	if am == null or not am.has_method("play_sound_3d"):
		return
	am.play_sound_3d(load(path), global_position, float(data.get("db", -6.0)))

func _sync_broadcast(delta: float) -> void:
	_net_sync_timer -= delta
	if _net_sync_timer > 0.0:
		return
	_net_sync_timer = 0.1
	_sync_monster_state.rpc(global_position, rotation.y, ai_state, hp)

func _sync_remote(delta: float) -> void:
	global_position = global_position.lerp(_remote_pos, minf(1.0, delta * 12.0))
	rotation.y = lerp_angle(rotation.y, _remote_rot, delta * 12.0)

@rpc("any_peer", "unreliable")
func _sync_monster_state(pos: Vector3, rot: float, state: int, remote_hp: float) -> void:
	if is_multiplayer_authority():
		return
	_remote_pos = pos
	_remote_rot = rot
	ai_state = state as State
	if remote_hp >= 0.0:
		hp = remote_hp


