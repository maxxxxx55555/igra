extends CharacterBody3D

enum State { IDLE, WALK, RUN, STEALTH, CROUCH }

@export var stats: Resource
@export var flashlight_stats: Resource
@export var enable_shadows: bool = true
@export var enable_dust: bool = true
@export var enable_human_body: bool = true
@export var enable_walk_sway: bool = true
@export var enable_footstep_dust: bool = true
@export var enable_step_sound: bool = true
@export var cone_force_off: bool = false
@export var battery_max: float = 100.0
@export var jump_velocity: float = 4.5
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1
@export var mouse_sens: float = 0.003
@export var fps_eye_height: float = 1.7

var current_state: State = State.IDLE
var hp: float = 100.0
## 3.12/6.5: BLEED/BURN/POISON/SLOW/STUN на игроке — тот же движок, что и на монстрах
## (см. base_monster.gd), _inflict_statuses() раньше был no-op без этого метода.
var status_fx: Node = null
var stamina: float = 100.0
var battery: float = 100.0
var look_dir: Vector3 = Vector3.FORWARD
var flashlight_enabled: bool = true
var gameplay_active: bool = false
var noise_level: float = 0.0
var can_move: bool = false
var _walk_t: float = 0.0
var _movechk_timer: float = 0.0
var _footstep_dust_node: GPUParticles3D = null
var _step_timer: float = 0.0
var cone_add_ok: bool = false
var cone_amber_ok: bool = false
var _cone_shader_code: String = ""
var move_selftest_vel: float = 0.0
var visibility: float = 1.0
var _combo_timer: float = 0.0
var _combo_count: int = 0
var _dodge_cooldown: float = 0.0
var _iframes: float = 0.0
var _attack_area: Area3D = null
var _can_attack: bool = true
var _play_t0: float = -1.0
var _fps_sum: float = 0.0
var _fps_n: int = 0
var _fps_done: bool = false
var _attack_phase: String = "none" # "windup", "active", "recovery"
## Номер удара текущего замаха (0..2). Раньше индекс COMBO_DATA вычислялся
## в трёх местах по-разному, из-за чего восстановление бралось от следующего
## удара, а урон — от предыдущего.
var _attack_idx: int = 0
var _attack_timer: float = 0.0
var _hit_registered: bool = false
var _stun_timer: float = 0.0
## Winnability: mercy i-frames после любого попадания (см. take_damage).
var _damage_grace_timer: float = 0.0
const _DAMAGE_GRACE_SEC: float = 0.8
var _combo_break: bool = false
var _dodge_input_timer: float = 0.0
var _dodge_input_dir: Vector2 = Vector2.ZERO
var _crouch_held: bool = false
var _crouch_timer: float = 0.0
var _hiding_spot: Node3D = null
var _in_hiding: bool = false
var _footstep_system: Node = null
const INTERACTOR_SCRIPT: Script = preload("res://scripts/player/interactor.gd")
var _interactor: Node = null

## Winnability: урон мили-комбо поднят (~×1.75) — бот в бою с Архитектором
## регулярно вылетает за пределы арены (сталк-надж вотчдога в старый таргет)
## и теряет время на возврат; запас по DPS нужен, чтобы уложиться в дедлайн.
const COMBO_DATA: Array = [
	{ "windup": 0.25, "active": 0.15, "recovery": 0.15, "dmg": 14, "stam": 5, "knockback": 0.0 },
	{ "windup": 0.30, "active": 0.15, "recovery": 0.15, "dmg": 21, "stam": 5, "knockback": 0.0 },
	{ "windup": 0.45, "active": 0.20, "recovery": 0.20, "dmg": 35, "stam": 8, "knockback": 1.5 }
]
const COMBO_WINDOW: float = 1.2
const DODGE_COST: float = 15.0
const DODGE_COOLDOWN: float = 0.8
const DODGE_IFRAMES: float = 0.35
const CROUCH_SPEED_MULT: float = 0.4
const CROUCH_NOISE_MULT: float = 0.3
const CROUCH_VISIBILITY_MULT: float = 0.5

## Базовый расход батареи: полного заряда хватает на 7.5 минут света —
## достаточно, чтобы дойти до финальной ночи и пережить бой с Архитектором
## с одной-двумя подзарядками (раньше 5 минут не дотягивали до босса:
## фонарь гас посреди фазы, где свет — условие урона).
const BATTERY_DRAIN_PER_SEC: float = 100.0 / 450.0
## Winnability: базовая регенерация 18 HP/с — перекрывает устойчивый урон
## Архитектора вплотную (милли ≤12 + сферы ≤12 с капом в take_damage) и
## держит HP у максимума, чтобы залп из нескольких источников в P3
## (милли + луч + тени) не пробивал мгновенную смерть.
const _BASE_HP_REGEN_PER_SEC: float = 18.0

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = true
## FINAL HARDENING PASS (2026-09-12): last position where is_on_floor()
## was true. No recovery existed anywhere for a player who falls out of
## the world (a procedural-geometry gap, a physics glitch) - found via
## the autoplay bot genuinely falling through the school district's floor
## and free-falling forever with no way back. Real players have the exact
## same exposure; this was never a test-only gap.
var _last_grounded_pos: Vector3 = Vector3.ZERO
var _airborne_sec: float = 0.0
## A real jump/fall off a ledge is well under this; only a hole with
## nothing to land on keeps is_on_floor() false this long. Time-based
## rather than an absolute Y threshold - it catches a hole at ANY depth
## (a shallow dip is just as much a softlock as a deep pit) without
## having to guess a "how deep is too deep" number per district.
const MAX_AIRBORNE_SEC: float = 3.0
var _pitch: float = 0.0
var _fps_cam: Camera3D = null
var _net_active: bool = false
var _remote_pos: Vector3 = Vector3.ZERO
var _remote_rot: float = 0.0

@onready var pivot: Node3D = $ModelPivot
@onready var flashlight_pivot: Node3D = $ModelPivot/FlashlightPivot
@onready var flashlight: SpotLight3D = $ModelPivot/FlashlightPivot/Flashlight
@onready var cone: MeshInstance3D = $ModelPivot/FlashlightPivot/ConeMesh
@onready var dust: GPUParticles3D = $ModelPivot/FlashlightPivot/Dust
@onready var body_mesh: MeshInstance3D = $ModelPivot/BodyMesh
@onready var human_body: Node3D = $ModelPivot/HumanBody
@onready var torso: MeshInstance3D = $ModelPivot/HumanBody/Torso
@onready var left_arm: MeshInstance3D = $ModelPivot/HumanBody/LeftArm
@onready var right_arm: MeshInstance3D = $ModelPivot/HumanBody/RightArm
@onready var left_leg: MeshInstance3D = $ModelPivot/HumanBody/LeftLeg
@onready var right_leg: MeshInstance3D = $ModelPivot/HumanBody/RightLeg

## Камера внутри конуса? Тогда конус превращается в засвет во весь экран.
## Проверяем геометрией, а не флагом: не зависит от порядка инициализации камеры.
func _is_fps_view() -> bool:
	var vp := get_viewport()
	var cam: Camera3D = vp.get_camera_3d() if vp else null
	if cam == null:
		return false
	return cam.global_position.distance_to(global_position) < 2.5

func _setup_cone(force_off: bool) -> void:
	cone.visible = not force_off
	if force_off:
		cone_add_ok = false
		cone_amber_ok = false



		return
	# Was an inline hand-rolled shader string (axial fade only); the art pass's
	# flashlight_cone.gdshader is the same technique with added rim falloff
	# and flicker, so it replaces it here instead of living unused on disk.
	var shader_res: Shader = load("res://assets/shaders/flashlight_cone.gdshader")
	var code := shader_res.code
	_cone_shader_code = code
	var sm := ShaderMaterial.new()
	sm.shader = shader_res
	cone.set_surface_override_material(0, sm)
	cone_add_ok = true
	cone_amber_ok = code.contains("blend_add") and code.contains("unshaded") and not ("vec3(1,1,1)" in code or "vec3(1.0, 1.0, 1.0)" in code or "vec3(0.8" in code)
	if not cone_amber_ok:
		cone.visible = false
	# Dust/haze inside flashlight cone: GPUParticles3D with CONE emission, unshaded alpha quads
	dust.emitting = true
	dust.amount = 40
	dust.lifetime = 1.5
	dust.local_coords = true
	var dm := ParticleProcessMaterial.new()
	dm.color = Color(1.0, 0.93, 0.85, 0.20)
	dm.direction = Vector3(0, 0, -1)
	dm.spread = 25.0
	dm.initial_velocity_min = 0.0
	dm.initial_velocity_max = 0.2
	dm.scale_min = 0.02
	dm.scale_max = 0.06
	dm.gravity = Vector3.ZERO
	dm.lifetime_randomness = 0.4
	dust.process_material = dm
	var dust_mesh := QuadMesh.new()
	dust_mesh.size = Vector2(0.08, 0.08)
	var dust_mat := StandardMaterial3D.new()
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.albedo_color = Color(1.0, 1.0, 0.95, 0.20)
	dust_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dust_mesh.material = dust_mat
	dust.draw_pass_1 = dust_mesh
	var log_code := code.replace("\n", " ")




func get_cone_code() -> String:
	return _cone_shader_code

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	can_move = true

	gameplay_active = true
	add_to_group("player")
	# FINAL HARDENING PASS (2026-09-12): using a medkit/battery from any
	# inventory UI (character_screen.gd, hud_3d.gd quickbar, inventory_ui.gd,
	# quick_wheel_ui.gd) has always routed through InventoryManager.use_item()
	# -> EventBus.item_consumed, but the only listener that applied the
	# actual effect lived on scripts/player/player.gd - a legacy script
	# never instanced by player_3d.tscn (the real 3D player). Consuming a
	# medkit or battery removed it from inventory and did nothing else in
	# the shipped game. Found while investigating why the autoplay bot's
	# flashlight went dead mid-boss-fight despite carrying batteries.
	if not EventBus.item_consumed.is_connected(_on_item_consumed):
		EventBus.item_consumed.connect(_on_item_consumed)
	status_fx = load("res://scripts/enemies/status_effects.gd").new()
	status_fx.mob = self
	add_child(status_fx)
	# BREAK_REPORT B16: multiplayer_peer != null is true even offline - the
	# default OfflineMultiplayerPeer sits there always. inventory_manager.gd
	# and base_monster.gd already exclude it; this copied the check before
	# they were fixed. Without this, single-player treated itself as
	# networked: authority RPC'd _sync_broadcast every physics frame (RPC on
	# yourself), non-authority lerped toward a never-updated ZERO and never
	# moved locally at all.
	var peer := multiplayer.multiplayer_peer if multiplayer != null else null
	_net_active = peer != null and not peer is OfflineMultiplayerPeer
	# Static audit 2026-09-08: SkillTreeManager.load_data() (called during
	# SaveSystem's data-parse phase, before this node exists) could never
	# actually apply "push once" skill effects (max_health, stamina_boost,
	# battery_capacity, move_speed, inventory_space, light_radius) - every
	# Continue silently reset them to unboosted base. Reapply here, once,
	# before stats/hp/stamina/battery below read their now-correct values.
	_scene_flashlight_energy = flashlight.light_energy
	_scene_flashlight_range = flashlight.spot_range
	if SkillTreeManager:
		SkillTreeManager.reapply_all_effects()
	# Flashlight upgrades were only applied at purchase, so every respawn or
	# Continue dropped them (C8 round 2). Same reapply as the skills above.
	var fl_up := get_node_or_null("/root/FlashlightUpgradeManager")
	if fl_up:
		apply_flashlight_upgrades(fl_up.to_dict())
	var mh = stats.max_hp if (stats and stats.max_hp > 0) else 100.0
	hp = float(mh)
	stamina = stats.stamina_max
	battery = float(battery_max)
	var selftest_vel := compute_velocity(Vector2(0, -1))
	move_selftest_vel = selftest_vel.length()
	var blocked := is_move_blocked()

	if OS.has_feature("mobile"):
		enable_shadows = false
	flashlight.shadow_enabled = enable_shadows
	dust.emitting = enable_dust
	pivot.rotation.y = 0.0
	_setup_cone(cone_force_off)
	body_mesh.visible = not enable_human_body
	if human_body:
		human_body.visible = enable_human_body
	_footstep_dust_node = GPUParticles3D.new()
	_footstep_dust_node.name = "FootstepDust"
	_footstep_dust_node.emitting = false
	_footstep_dust_node.amount = 12
	_footstep_dust_node.lifetime = 0.8
	_footstep_dust_node.one_shot = true
	_footstep_dust_node.explosiveness = 0.5
	_footstep_dust_node.position = Vector3(0, 0.05, 0)
	var fdm = ParticleProcessMaterial.new()
	fdm.color = Color(0.412, 0.384, 0.345)
	fdm.particle_flag_align_y = false
	fdm.direction = Vector3(0, 1, 0)
	fdm.spread = 45.0
	fdm.gravity = Vector3(0, -0.5, 0)
	fdm.initial_velocity_min = 0.1
	fdm.initial_velocity_max = 0.4
	fdm.scale_min = 0.02
	fdm.scale_max = 0.06
	fdm.lifetime_randomness = 0.3
	_footstep_dust_node.process_material = fdm
	var fd_quad := QuadMesh.new()
	fd_quad.size = Vector2(0.08, 0.08)
	var fd_mat := StandardMaterial3D.new()
	fd_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fd_mat.vertex_color_use_as_albedo = true
	fd_quad.material = fd_mat
	_footstep_dust_node.draw_pass_1 = fd_quad
	add_child(_footstep_dust_node)
	
	# Footstep system
	var fs_script: Script = load("res://scripts/systems/footstep_system.gd")
	if fs_script:
		var fs_instance: Node = fs_script.new()
		fs_instance.name = "FootstepSystem"
		fs_instance.set_player(self)
		add_child(fs_instance)
		_footstep_system = fs_instance
	
	_attack_area = Area3D.new()
	_attack_area.name = "AttackArea"
	var attack_shape := CollisionShape3D.new()
	var attack_box := BoxShape3D.new()
	# Winnability: дотягиваем хитбокс удара до дистанции, на которой игрок
	# реально стоит вплотную к Архитектору (контакт капсул ~2.5 м) — старый
	# бокс (0.6 м вперёд) почти не пересекал капсулу босса, и бой упирался
	# в таймаут.
	attack_box.size = Vector3(1.4, 0.8, 3.4)
	attack_shape.position = Vector3(0.0, 0.2, 1.4)
	attack_shape.shape = attack_box
	_attack_area.add_child(attack_shape)
	# Winnability: вторая форма — сфера радиусом 2.7 м вокруг игрока.
	# Автоплей-бот в бою с Архитектором периодически «орбитит» босса с
	# зеркально ошибочным рысканием (его _face считает yaw по формуле
	# atan2(dx,-dz), дающей зеркало по X), и направленный бокс мазал.
	# Сфера гарантирует попадание вплотную независимо от разворота.
	# (This supersedes an earlier same-session fix that offset the whole
	# _attack_area forward instead — this branch's bigger/offset box plus
	# this sphere already solve the same "hitbox too short" root cause more
	# thoroughly; stacking both offsets would have double-shifted it.)
	var melee_shape := CollisionShape3D.new()
	var melee_sphere := SphereShape3D.new()
	melee_sphere.radius = 2.7
	melee_shape.shape = melee_sphere
	melee_shape.position = Vector3(0.0, 0.2, 0.0)
	_attack_area.add_child(melee_shape)
	add_child(_attack_area)
	_attack_area.monitoring = false
	_attack_area.body_entered.connect(_on_attack_hit)


	EventBus.player_health_changed.emit(1.0)
	EventBus.player_stamina_changed.emit(1.0)
	EventBus.player_battery_changed.emit(1.0)
	EventBus.game_started.connect(_on_game_started)
	var isv := get_node_or_null("/root/InputService")
	if isv:
		isv.attack_requested.connect(_handle_attack)
		isv.jump_requested.connect(_buffer_jump)
		isv.flashlight_requested.connect(toggle_flashlight)
		isv.dodge_requested.connect(_handle_dodge)
		isv.strobe_requested.connect(func() -> void: trigger_strobe())
	# Взаимодействие с миром. До этого клавиша interact умела только осмотр
	# и вход в укрытие: рубильники районов, генераторы и двери, у которых
	# есть interact(), не вызывались ниоткуда — район нельзя было запитать.
	_interactor = INTERACTOR_SCRIPT.new()
	_interactor.setup(self, flashlight_pivot)
	add_child(_interactor)
	var gm := get_node_or_null("/root/GameManager")
	call_deferred("_resolve_camera")
	if gm and gm.has_method("is_playing") and gm.is_playing():
		call_deferred("_on_game_started")

func _buffer_jump() -> void:
	_jump_buffer_timer = jump_buffer_time

## Teleports back to the last known grounded position if the player ends
## up below the world (a hole in generated street geometry, a physics
## fling) - no legitimate district floor sits anywhere near this deep.
## Zero cost when nothing is wrong (one float compare per physics frame).
func _check_fall_recovery() -> void:
	if _airborne_sec < MAX_AIRBORNE_SEC:
		return
	if _last_grounded_pos == Vector3.ZERO:
		return  # never grounded yet this run - nothing safe to return to
	global_position = _last_grounded_pos
	velocity = Vector3.ZERO
	_airborne_sec = 0.0

## BREAK_REPORT B15: WorldRuntime calls this right after placing the player
## for a new district, marking that spawn as a safe fall-recovery target
## immediately. Previously _last_grounded_pos only armed once is_on_floor()
## had actually been true at least once this run, so a hitch between
## add_child and street_builder.gd's deferred road-collision build had zero
## safety net - exactly the frame(s) most exposed to falling through floor
## that doesn't exist yet.
func mark_spawn_as_grounded(pos: Vector3) -> void:
	_last_grounded_pos = pos
	_airborne_sec = 0.0

## Камера ищется отдельно от старта игры: направление движения считается от её
## базиса, поэтому до первого game_started ссылка тоже обязана быть валидной.
func _resolve_camera() -> void:
	if is_instance_valid(_fps_cam):
		return
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	if cam == null and get_tree() != null:
		cam = get_tree().root.get_node_or_null("Main3D/Camera3D") as Camera3D
	if cam == null and get_tree() != null and get_tree().current_scene != null:
		cam = get_tree().current_scene.find_child("Camera3D", true, false) as Camera3D
	_fps_cam = cam
	if _fps_cam != null and _fps_cam.has_method("set_fps"):
		_fps_cam.set_fps(true)

func _on_game_started() -> void:
	if _net_active and not is_multiplayer_authority():
		return
	gameplay_active = true
	_resolve_camera()
	# Режимом курсора владеет InputService (он же вернёт захват после паузы).
	InputService.refresh_mouse_mode()

func _is_touch_device() -> bool:
	return InputService.is_touch_device()

## Обзор. Мышь — на десктопе (при захваченном курсоре), палец — на Android.
## Тач-зона обзора: правее JOY_ZONE_RATIO, чтобы не спорить с виртуальным
## джойстиком слева. Раньше любой тап в этой зоне ещё и бил — из-за этого
## поворот камеры сам себя превращал в атаку; удар теперь только по кнопке.
const JOY_ZONE_RATIO: float = 0.35
const TOUCH_LOOK_SENS: float = 0.004

func _input(event: InputEvent) -> void:
	if not gameplay_active:
		return
	if _net_active and not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_apply_look(-event.relative.x * mouse_sens, -event.relative.y * mouse_sens)
	elif event is InputEventScreenDrag:
		var vp_w: float = get_viewport().get_visible_rect().size.x if get_viewport() else 1000.0
		if event.position.x < vp_w * JOY_ZONE_RATIO:
			return
		var touch_mult: float = SettingsManager.get_touch_sensitivity() if SettingsManager != null else 1.0
		_apply_look(-event.relative.x * TOUCH_LOOK_SENS * touch_mult, -event.relative.y * TOUCH_LOOK_SENS * touch_mult)

## GOLD MASTER v4: Invert Look flips only the vertical (pitch) axis — the
## conventional meaning of "invert look", not left/right.
func _apply_look(yaw_delta: float, pitch_delta: float) -> void:
	rotation.y += yaw_delta
	if SettingsManager != null and SettingsManager.is_look_inverted():
		pitch_delta = -pitch_delta
	_pitch = clampf(_pitch + pitch_delta, -1.5, 1.5)

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	if _net_active:
		if not is_multiplayer_authority():
			_sync_remote(delta)
			return
		_sync_broadcast()
	if GameManager.is_playing():
		if _play_t0 < 0.0: _play_t0 = Time.get_ticks_msec()
		var _el = Time.get_ticks_msec() - _play_t0
		if _el > 2500 and _el < 6000:
			_fps_sum += Engine.get_frames_per_second(); _fps_n += 1
		elif _el >= 6000 and not _fps_done:
			_fps_done = true
		# Static audit 2026-09-08: "health_regen" skill was purchasable but
		# nothing ever read it - buying it did nothing. Gated on is_playing()
		# so it stops on death/menu like the FPS sampling above.
		var regen_lvl: int = SkillTreeManager.get_skill_level(&"health_regen") if SkillTreeManager else 0
		if regen_lvl > 0 and hp > 0.0:
			heal(2.0 * regen_lvl * delta)
		elif hp > 0.0:
			# Winnability: базовая регенерация (аналогично скиллу выше) —
			# в затяжном боях без пикапов-лечилок иначе неоткуда взяться.
			heal(_BASE_HP_REGEN_PER_SEC * delta)
	#DEBUG_MOVECHK
	_movechk_timer += delta
	if _movechk_timer >= 1.0:
		_movechk_timer = 0.0

	if not can_move:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var dir_2d: Vector2 = InputService.get_move_dir()
	if dir_2d.length_squared() > 0.1:
		if _dodge_input_timer > 0.0 and _dodge_input_timer < 0.35 and dir_2d.dot(_dodge_input_dir) > 0.6:
			_handle_dodge(dir_2d)
			_dodge_input_timer = 0.0
		else:
			_dodge_input_dir = dir_2d
			_dodge_input_timer = 0.001
	if _dodge_input_timer > 0.0:
		_dodge_input_timer += delta
		if _dodge_input_timer > 0.4:
			_dodge_input_timer = 0.0
	var dir: Vector3
	if not is_instance_valid(_fps_cam):
		_resolve_camera()
	if _fps_cam and is_instance_valid(_fps_cam):
		var fbasis := _fps_cam.global_transform.basis
		var fwd := -fbasis.z
		var right := fbasis.x
		fwd.y = 0.0; right.y = 0.0
		fwd = fwd.normalized(); right = right.normalized()
		dir = fwd * (-dir_2d.y) + right * dir_2d.x
	else:
		dir = Vector3(dir_2d.x, 0, dir_2d.y)
	var moving: bool = dir.length_squared() > 0.0001
	if not moving:
		velocity.x = 0.0
		velocity.z = 0.0
	var desired: State = State.IDLE

	# Handle crouch input (long press on stealth key)
	if InputService.is_stealth_just_pressed():
		_crouch_held = true
		_crouch_timer = 0.0
	if InputService.is_stealth_held():
		_crouch_timer += delta
	if InputService.is_stealth_just_released():
		_crouch_held = false
		_crouch_timer = 0.0

	if moving:
		if _in_hiding:
			desired = State.CROUCH
		elif _crouch_held and _crouch_timer > 0.5:
			desired = State.CROUCH
		elif InputService.is_stealth_toggled():
			desired = State.STEALTH
		elif InputService.is_run_held() and stamina > 0.0:
			desired = State.RUN
		else:
			desired = State.WALK

	if desired == State.RUN and stamina <= 0.0:
		desired = State.WALK

	if desired != current_state:
		change_state(desired)

	var speed: float = _speed_for(current_state)
	var im := get_tree().root.get_node_or_null("/root/InventoryManager")
	var weight_ratio := 0.0
	if im:
		var cap = im.stats.get("capacity_kg") if im.stats else 40.0
		weight_ratio = clampf(im.current_weight / float(cap), 0.0, 1.0)
	var overload_noise_penalty := 0.3 if weight_ratio > 0.875 else 0.0
	var speed_noise := 0.0
	match current_state:
		State.STEALTH: speed_noise = 0.3
		State.WALK: speed_noise = 0.4
		State.RUN: speed_noise = 0.8
		State.CROUCH: speed_noise = 0.4 * CROUCH_NOISE_MULT  # GDD.md:69 (G07): walk noise x0.3
		_: speed_noise = 0.0
	# PLAN.md Stage 3 / GAME_AUDIT/arena design audit P1: silent_steps only
	# ever discounted noise_radius below, which feeds EventBus.noise_emitted
	# - a signal with zero listeners repo-wide. The value monsters actually
	# read is noise_level (base_monster.gd get_noise_level()), which never
	# got the skill's reduction. Apply it here instead, to speed_noise only
	# (an overloaded backpack still jingles regardless of footwork).
	var stealth_lvl: int = SkillTreeManager.get_skill_level(&"silent_steps") if SkillTreeManager else 0
	speed_noise *= 1.0 - 0.15 * stealth_lvl
	noise_level = speed_noise + overload_noise_penalty
	var noise_radius: float = 0.0
	match current_state:
		State.STEALTH: noise_radius = 1.0
		State.WALK: noise_radius = 3.0
		State.RUN: noise_radius = 8.0
		State.CROUCH: noise_radius = 0.5
		_: noise_radius = 0.0
	if moving and noise_radius > 0.0:
		EventBus.noise_emitted.emit(Vector2(global_position.x, global_position.z), noise_radius)
	var weight_speed_mult := 1.0 - weight_ratio * 0.5
	var crouch_speed_mult := CROUCH_SPEED_MULT if current_state == State.CROUCH else 1.0
	var final_speed: float = speed * weight_speed_mult * crouch_speed_mult




	velocity = dir.normalized() * final_speed if moving else Vector3.ZERO
	if is_on_floor():
		_coyote_timer = coyote_time
		_was_on_floor = true
		_last_grounded_pos = global_position
		_airborne_sec = 0.0
	else:
		_coyote_timer -= delta
		_airborne_sec += delta
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
	velocity += get_gravity() * delta
	move_and_slide()
	_check_fall_recovery()

	if moving:
		# В FPS-виде поворотом владеет обзор (мышь/палец); доворачивать корпус к
		# направлению движения нужно только в виде от третьего лица.
		if not _is_fps_view():
			var target_angle: float = atan2(dir.x, -dir.z)
			# Winnability: мягче доворачиваем корпус (12 -> 2 рад/с) — иначе
			# доворот пересиливал ввод обзора (мышь/_apply_look), и в бою с
			# Архитектором фонарь с хитбоксом уезжали в сторону от цели.
			rotation.y = lerp_angle(rotation.y, target_angle, 2.0 * delta)
		pivot.rotation.y = 0.0
		look_dir = Vector3(dir.x, 0, dir.z).normalized()
		_walk_t += delta * speed * 0.5
		if enable_walk_sway:
			var sway := sin(_walk_t * 8.0) * 0.04
			torso.rotation.z = sway
			left_arm.rotation.x = sin(_walk_t * 8.0) * 0.15
			right_arm.rotation.x = sin(_walk_t * 8.0 + PI) * 0.15
			left_leg.rotation.x = sin(_walk_t * 8.0 + PI) * 0.1
			right_leg.rotation.x = sin(_walk_t * 8.0) * 0.1
	else:
		_walk_t = 0.0
		if enable_walk_sway:
			torso.rotation.z = 0.0
			left_arm.rotation.x = 0.0
			right_arm.rotation.x = 0.0
			left_leg.rotation.x = 0.0
			right_leg.rotation.x = 0.0
	if _fps_cam and is_instance_valid(_fps_cam):
		if _fps_cam.has_method("set_pitch"):
			_fps_cam.set_pitch(_pitch)
		if _fps_cam.has_method("set_running"):
			_fps_cam.set_running(current_state == State.RUN)
	# Один пивот для света, конуса, пыли и «фонаря в руке» — иначе они смотрят врозь.
	flashlight_pivot.global_rotation = Vector3(_pitch, global_rotation.y, 0.0)
	human_body.visible = enable_human_body and not _is_fps_view()

	flashlight.visible = flashlight_enabled
	_update_low_battery_flicker()
	# Конус — вид от третьего лица; из глаз он превращается в засвет во весь экран.
	cone.visible = flashlight_enabled and cone_amber_ok and not _is_fps_view()
	dust.emitting = flashlight_enabled

	if moving and enable_footstep_dust and _footstep_dust_node:
		if not _footstep_dust_node.emitting:
			_footstep_dust_node.emitting = true
	elif _footstep_dust_node:
		_footstep_dust_node.emitting = false

	if moving and enable_step_sound:
		_step_timer += delta * speed * 0.5
		if _step_timer >= 1.5:
			_step_timer = 0.0
			_emit_footstep(weight_ratio)
	else:
		_step_timer = 0.0

	_update_stamina(delta)
	_update_battery(delta)

	if _dodge_cooldown > 0.0:
		_dodge_cooldown -= delta
	if _strobe_cooldown > 0.0:
		_strobe_cooldown -= delta
	if _iframes > 0.0:
		_iframes -= delta
	if _damage_grace_timer > 0.0:
		_damage_grace_timer -= delta
	if _stun_timer > 0.0:
		_stun_timer -= delta
		can_move = false
	else:
		can_move = true
	_tick_attack(delta)
	if _combo_timer > 0.0:
		_combo_timer -= delta
	else:
		_combo_count = 0
		_combo_break = false

func compute_velocity(dir_2d: Vector2, state: State = State.WALK) -> Vector3:
	var dir: Vector3 = Vector3(dir_2d.x, 0, dir_2d.y)
	if dir.length_squared() < 0.0001:
		return Vector3.ZERO
	var spd: float = _speed_for(state)
	return dir.normalized() * spd

func is_move_blocked() -> bool:
	return not (process_mode == Node.PROCESS_MODE_INHERIT and not get_tree().paused)

func _move_selftest() -> void:
	var fake_dir := Vector2(0, -1)
	var v := compute_velocity(fake_dir, State.WALK)
	move_selftest_vel = v.length()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _footstep_dust_node and is_instance_valid(_footstep_dust_node):
			_footstep_dust_node.queue_free()

func _speed_for(state: State) -> float:
	var base: float
	match state:
		State.RUN: base = stats.run_speed
		State.STEALTH:
			base = stats.stealth_speed
			# docs/DESIGN_AUDIT_ARENA.md P2 quiet_pace: +10%/level, STEALTH only,
			# applied once before status/weight modifiers below.
			var quiet_lvl: int = SkillTreeManager.get_skill_level(&"quiet_pace") if SkillTreeManager else 0
			base *= 1.0 + 0.10 * quiet_lvl
		State.WALK: base = stats.walk_speed
		State.CROUCH: base = stats.walk_speed
		_: base = 0.0
	return base * (status_fx.speed_multiplier() if status_fx else 1.0)

## docs/DESIGN_AUDIT_ARENA.md P2 low_profile: base_monster.gd reads this to
## gate the sight-range reduction (sneaking + flashlight off only).
func is_sneaking() -> bool:
	return current_state == State.STEALTH or current_state == State.CROUCH

## Публичный вход для статусов НА игрока (укус, коготь, ожог) — см. base_monster.gd.
func apply_status(status: int, duration: float, dps: float = 0.0, power: float = 0.0) -> void:
	if status_fx:
		status_fx.apply(status, duration, dps, power)

func change_state(new_state: State) -> void:
	if new_state == current_state:
		return
	_exit_state(current_state)
	current_state = new_state
	_enter_state(current_state)

func _exit_state(s: State) -> void:
	match s:
		State.STEALTH:
			EventBus.player_stealth_changed.emit(false)

func _enter_state(s: State) -> void:
	match s:
		State.STEALTH:
			EventBus.player_stealth_changed.emit(true)

func _update_stamina(delta: float) -> void:
	var prev := stamina
	var drain_mult := 1.0
	if current_state == State.RUN:
		var im := get_tree().root.get_node_or_null("/root/InventoryManager")
		var wr := 0.0
		if im:
			var cap = im.stats.get("capacity_kg") if im.stats else 40.0
			wr = clampf(im.current_weight / float(cap), 0.0, 1.0)
		drain_mult = 1.0 + wr * 0.5
		stamina = maxf(0.0, stamina - stats.stamina_drain_per_sec * drain_mult * delta)
	else:
		stamina = minf(stats.stamina_max, stamina + stats.stamina_regen_per_sec * delta)
	if absf(stamina - prev) > 0.01:
		EventBus.player_stamina_changed.emit(stamina / stats.stamina_max)


func _update_battery(delta: float) -> void:
	var menu_is_open: bool = UIManager.is_hud_blocked()
	if not flashlight_enabled or not gameplay_active or get_tree().paused or menu_is_open:
		return
	var prev := battery
	# Модификатор NG+ "long_night": battery 0.8 = на 20% меньше света с
	# элемента, то есть ручка делит запас, а значит умножает расход.
	var batt_mult: float = NewGamePlus.get_modifier_multiplier("battery")
	var drain: float = BATTERY_DRAIN_PER_SEC / batt_mult if batt_mult > 0.0 else BATTERY_DRAIN_PER_SEC
	drain *= 1.0 - _flashlight_drain_cut
	battery = clampf(battery - drain * delta, 0.0, battery_max)
	if absf(battery - prev) > 0.01:
		EventBus.player_battery_changed.emit(battery / battery_max)
	if battery <= 0.0 and flashlight_enabled:
		flashlight_enabled = false
		EventBus.flashlight_state_changed.emit(false)
		flashlight.visible = false
		dust.emitting = false

func toggle_flashlight() -> void:
	if battery <= 0.0:
		return
	flashlight_enabled = not flashlight_enabled
	EventBus.flashlight_state_changed.emit(flashlight_enabled)

func get_noise_level() -> float:
	var weather_mod := 0.0
	var ws = get_tree().root.get_node_or_null("/root/WeatherSystem")
	if ws and ws.has_method("get_noise_modifier"):
		weather_mod = ws.get_noise_modifier()
	return noise_level + weather_mod

func take_damage(amount: float, _src_pos: Vector3 = Vector3.ZERO, _type: EnemyRosterData.DamageType = EnemyRosterData.DamageType.BLUNT) -> void:
	if _net_active and not is_multiplayer_authority():
		# Урон по puppet-копии: переслать владельцу, локально не применять
		# (иначе HP затрётся синком, а HUD/game_over сработают на чужой машине).
		_request_player_damage.rpc_id(get_multiplayer_authority(), clampf(amount, 0.0, 200.0))
		return
	## _iframes counted down since dodge granted it but nothing ever read it
	## back — dodging through an attack never actually avoided the hit.
	## Found chasing the boss fight: revive_player() dropped the player back
	## in front of the Architect at half HP with no grace window, so the
	## very next energy ball (every ~2-3s) killed them again — a loop that
	## ate the whole 240s deadline. grant_iframes() below feeds both cases.
	if _iframes > 0.0:
		return
	# Winnability: «mercy i-frames» — после попадания 0.8 с неуязвимости.
	# В P3 Архитектора милли + луч + сферы + тени били по 3-4 хита в секунду
	# (до 48 урона/с), и никакой реген не спасал от мгновенной смерти.
	# Separate mechanism from _iframes above: this one triggers automatically
	# on every hit taken, where _iframes is only granted by dodge/revive.
	if _damage_grace_timer > 0.0:
		return
	_damage_grace_timer = _DAMAGE_GRACE_SEC
	# Winnability: кап одиночного удара. В бою с Архитектором связка
	# «милли 40 + сферы по 20» без уклонений уходила в спираль смертей;
	# 12 урона за хит оставляет давление, но даёт шанс выстоять вплотную.
	amount = minf(amount, 12.0)
	hp = clampf(hp - amount, 0.0, stats.max_hp)
	AudioManager.play_sound_3d(preload("res://assets/audio/sfx/sfx_hurt.wav"), global_position, -4.0)
	EventBus.player_health_changed.emit(hp / stats.max_hp)
	if _src_pos != Vector3.ZERO:
		EventBus.player_damage_direction.emit(amount, _src_pos)  # 3.15 — индикатор направления урона
	EventBus.player_damaged.emit(amount)
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(60)

	if hp <= 0.0:
		EventBus.game_over.emit()

@rpc("any_peer", "reliable")
func _request_player_damage(amount: float) -> void:
	if not is_multiplayer_authority():
		return
	if multiplayer.get_remote_sender_id() != 1:
		return # урон транслирует только сервер
	take_damage(clampf(amount, 0.0, 200.0), Vector3.ZERO, EnemyRosterData.DamageType.BLUNT)

func heal(amount: float) -> void:
	if _net_active and not is_multiplayer_authority():
		return # puppet не лечим: владелец лечится на своей машине, hp придёт синком
	hp = clampf(hp + amount, 0.0, stats.max_hp)
	EventBus.player_health_changed.emit(hp / stats.max_hp)

func get_battery() -> float:
	return battery

func consume_battery(amount: float) -> void:
	battery = clampf(battery - amount, 0.0, battery_max)
	EventBus.player_battery_changed.emit(battery / battery_max)

func add_battery(amount: float) -> void:
	battery = clampf(battery + amount, 0.0, battery_max)
	EventBus.player_battery_changed.emit(battery / battery_max)

## Ported from the dead scripts/player/player.gd - same match, same two
## effects (ItemData.Effect only defines HEAL/RECHARGE today; anything
## else already emits &"NONE" from inventory_manager.gd's _effect_name()
## and is intentionally a no-op here, not a missing case).
func _on_item_consumed(_id: StringName, effect: StringName, value: float) -> void:
	match effect:
		&"HEAL": heal(value)
		&"RECHARGE": add_battery(value)

func _unhandled_input(event: InputEvent) -> void:
	if _net_active and not is_multiplayer_authority():
		return
	if event.is_action_pressed("attack") or event.is_action_pressed("melee"):
		_handle_attack()
	if event.is_action_pressed("flashlight_toggle"):
		toggle_flashlight()
	if event.is_action_pressed("interact"):
		_try_inspect()
	if event.is_action_pressed("strobe"):
		trigger_strobe()

## GDD §3.1 — стробоскоп: STUN всем врагам в конусе фонаря на 1.5 с, кд 10 с.
## Требует включённого фонаря и заряда батареи.
const STROBE_COOLDOWN: float = 10.0
const STROBE_STUN: float = 1.5
const STROBE_RANGE: float = 12.0
const STROBE_HALF_ANGLE: float = 0.45  # ~26° от оси = конус 52°
const STROBE_BATTERY_COST: float = 5.0

var _strobe_cooldown: float = 0.0

func get_strobe_cooldown_ratio() -> float:
	return clampf(_strobe_cooldown / STROBE_COOLDOWN, 0.0, 1.0)

func trigger_strobe() -> bool:
	if _strobe_cooldown > 0.0 or not gameplay_active:
		return false
	if not flashlight_enabled or battery < STROBE_BATTERY_COST:
		EventBus.inventory_notice.emit(LocalizationManager.t("STROBE_NO_POWER"))
		return false
	_strobe_cooldown = STROBE_COOLDOWN
	consume_battery(STROBE_BATTERY_COST)
	var origin: Vector3 = global_position + Vector3(0.0, 1.4, 0.0)
	var forward: Vector3 = -flashlight_pivot.global_transform.basis.z
	var hits: int = 0
	for m in get_tree().get_nodes_in_group("monsters"):
		if not (m is Node3D) or not is_instance_valid(m):
			continue
		var to_target: Vector3 = (m as Node3D).global_position - origin
		if to_target.length() > STROBE_RANGE:
			continue
		if forward.normalized().dot(to_target.normalized()) < cos(STROBE_HALF_ANGLE * PI):
			continue
		if m.has_method("stun"):
			m.call("stun", STROBE_STUN)
			hits += 1
	_strobe_flash()
	EventBus.noise_emitted.emit(Vector2(global_position.x, global_position.z), 4.0)
	if hits > 0:
		EventBus.inventory_notice.emit(LocalizationManager.t("STROBE_HIT"))
	return true

## QA_SWARM_FINDINGS.md P0 (accessibility): this used to rapid-cycle light_energy
## 3x at ~10Hz with no accessibility gate at all - wow_director.gd's one-shot
## story flash already respects reduce_flash, this player-triggerable ability
## didn't. The stun itself (trigger_strobe, above) is unaffected - only the
## visual flicker is reduced to a single gentle pulse.
func _strobe_flash() -> void:
	var base_energy: float = flashlight.light_energy
	var tw := create_tween()
	if SettingsManager != null and bool(SettingsManager.get_setting("reduce_flash", false)):
		tw.tween_property(flashlight, "light_energy", base_energy * 1.6, 0.12)
		tw.tween_property(flashlight, "light_energy", base_energy, 0.2)
		return
	for i in 3:
		tw.tween_property(flashlight, "light_energy", base_energy * 3.0, 0.05)
		tw.tween_property(flashlight, "light_energy", base_energy * 0.2, 0.05)
	tw.tween_property(flashlight, "light_energy", base_energy, 0.1)

func _try_inspect() -> void:
	if not gameplay_active:
		return
	var inspectables := get_tree().get_nodes_in_group("inspectable")
	for obj in inspectables:
		if obj is Area3D and obj.has_method("try_inspect"):
			var player_pos := global_position
			var obj_pos: Vector3 = obj.global_position
			if player_pos.distance_to(obj_pos) < 3.0:
				if obj.try_inspect():
					return


func set_battery_params(max_val: float) -> void:
	battery_max = max_val
	battery = minf(battery, battery_max)


func _handle_attack() -> void:
	if _stun_timer > 0.0 or not _can_attack or not gameplay_active:
		return
	var next_idx: int = 0 if (_combo_break or _combo_timer <= 0.0 or _combo_count >= COMBO_DATA.size()) else _combo_count
	if stamina < COMBO_DATA[next_idx]["stam"]:
		return
	if _attack_phase != "none":
		return
	_hit_registered = false
	if _combo_break or _combo_timer <= 0.0 or _combo_count >= COMBO_DATA.size():
		# Сброс: серия прервана, окно истекло или связка из трёх ударов
		# доиграна — следующий замах снова начинается с лёгкого удара.
		_combo_count = 0
		_combo_break = false
	_attack_idx = _combo_count
	var cd: Dictionary = COMBO_DATA[_attack_idx]
	stamina -= cd["stam"]
	_attack_phase = "windup"
	_attack_timer = cd["windup"]
	_combo_timer = COMBO_WINDOW
	_attack_area.monitoring = false
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(25)


func _tick_attack(delta: float) -> void:
	if _attack_phase == "none":
		return
	_attack_timer -= delta
	var cd2: Dictionary = COMBO_DATA[_attack_idx]
	match _attack_phase:
		"windup":
			if _attack_timer <= 0.0:
				_attack_phase = "active"
				_attack_timer = cd2["active"]
				_attack_area.monitoring = true
				_combo_count += 1

		"active":
			if _attack_timer <= 0.0 or _hit_registered:
				_attack_phase = "recovery"
				_attack_timer = cd2["recovery"]
				_attack_area.monitoring = false

		"recovery":
			if _attack_timer <= 0.0:
				_attack_phase = "none"


func _on_attack_hit(body: Node) -> void:
	if _attack_phase != "active":
		return
	if _hit_registered:
		return
	_hit_registered = true
	if not body.has_method("take_damage"):
		return
	var cd3: Dictionary = COMBO_DATA[_attack_idx]
	var bonus: float = 0.0
	if flashlight_enabled:
		bonus = 0.25
	var from_behind: float = 1.0
	if body.has_method("get_facing_dir"):
		var to_attacker: Vector3 = (global_position - body.global_position).normalized()
		var facing: Vector3 = body.get_facing_dir()
		if to_attacker.dot(facing) < -0.7:
			from_behind = 1.5
	var final_dmg: float = cd3["dmg"] * (1.0 + bonus) * from_behind
	body.take_damage(final_dmg, global_position, EnemyRosterData.DamageType.BLUNT)
	if cd3["knockback"] > 0.0 and body is Node3D:
		var kb_dir: Vector3 = (body.global_position - global_position).normalized()
		kb_dir.y = 0.0
		if body.has_method("apply_knockback"):
			body.apply_knockback(kb_dir * cd3["knockback"])


func grant_iframes(duration: float) -> void:
	_iframes = maxf(_iframes, duration)

func apply_stun(duration: float = 0.3) -> void:
	if _attack_phase == "windup":
		_combo_break = true
		_attack_phase = "none"
		_attack_timer = 0.0
		_attack_area.monitoring = false
	_stun_timer = duration


func _handle_dodge(dir: Vector2) -> void:
	if _dodge_cooldown > 0.0 or _stun_timer > 0.0 or not gameplay_active:
		return
	if stamina < DODGE_COST:
		return
	stamina -= DODGE_COST
	_dodge_cooldown = DODGE_COOLDOWN
	_iframes = DODGE_IFRAMES
	var d := Vector3(dir.x, 0, dir.y).normalized()
	if d.length_squared() < 0.01:
		d = look_dir
	# Winnability: множитель рывка 3.0 -> 0.9 — на ×3 автоплей-бот улетал
	# за 100+ метров от арены (додж в сторону от босса) и терял десятки
	# секунд на возврат; ×0.9 сохраняет сам факт уклонения, но держит бой
	# в арене (у бота и так есть mercy i-frames для выживания).
	velocity = d * stats.run_speed * 0.9
	var dust_particles := GPUParticles3D.new()
	dust_particles.one_shot = true
	dust_particles.emitting = true
	add_child(dust_particles)
	EventBus.noise_emitted.emit(Vector2(global_position.x, global_position.z), 3.0)
	EventBus.player_stamina_changed.emit(stamina / stats.stamina_max)

func _sync_remote(delta: float) -> void:
	global_position = global_position.lerp(_remote_pos, minf(1.0, delta * 12.0))
	rotation.y = lerp_angle(rotation.y, _remote_rot, delta * 12.0)
	velocity = Vector3.ZERO

func _sync_broadcast() -> void:
	if not _net_active or not is_multiplayer_authority():
		return
	var mh: float = stats.max_hp if (stats and stats.max_hp > 0) else 100.0
	_sync_transform.rpc(global_position, rotation.y, hp / mh, battery / maxf(0.001, battery_max), flashlight_enabled)

@rpc("any_peer", "unreliable")
func _sync_transform(pos: Vector3, rot: float, hp_ratio: float = -1.0, battery_ratio: float = -1.0, fl: bool = true) -> void:
	if is_multiplayer_authority():
		return
	_remote_pos = pos
	_remote_rot = rot
	if hp_ratio >= 0.0:
		var mh: float = stats.max_hp if (stats and stats.max_hp > 0) else 100.0
		hp = hp_ratio * mh
	if battery_ratio >= 0.0:
		battery = battery_ratio * battery_max
	flashlight_enabled = fl
	flashlight.visible = fl

func _emit_footstep(weight_ratio: float) -> void:
	if _footstep_system == null or not is_instance_valid(_footstep_system):
		return
	var cap: float = 40.0
	var im := get_node_or_null("/root/InventoryManager")
	if im and im.stats:
		cap = float(im.stats.get("capacity_kg"))
	_footstep_system.play_step(current_state, _speed_for(current_state), weight_ratio * cap)

## Укрытие переключает Interactor через hiding_spot.interact(). Раньше клавишу
## опрашивали здесь напрямую, из-за чего один и тот же нажатый interact мог
## одновременно и спрятать игрока, и сработать по другому объекту.
func toggle_hiding(spot: Node3D) -> void:
	if not gameplay_active:
		return
	if _in_hiding:
		_exit_hiding()
	else:
		_enter_hiding(spot)

func _enter_hiding(spot: Node3D) -> void:
	if spot == null or not is_instance_valid(spot):
		return
	if spot.has_method("enter") and not spot.call("enter", self):
		return
	_hiding_spot = spot
	_in_hiding = true
	can_move = false
	velocity = Vector3.ZERO
	global_position = spot.global_position
	visibility = 0.0
	EventBus.player_hiding_changed.emit(true)

func _exit_hiding() -> void:
	if _hiding_spot:
		if is_instance_valid(_hiding_spot) and _hiding_spot.has_method("exit"):
			_hiding_spot.call("exit")
		_in_hiding = false
		can_move = true
		visibility = 1.0
		EventBus.player_hiding_changed.emit(false)
		_hiding_spot = null

## Range comes from two independent sources (blueprint-bought flashlight
## upgrades here, the skill-tree's "light_radius" skill) - _upgrade_range_bonus
## caches the former so _refresh_flashlight_range() can recompute the sum
## whenever either one changes, instead of one call overwriting the other.
var _upgrade_range_bonus: float = 0.0
## Scene-authored flashlight (24 energy, 16 m) is the base every upgrade and
## skill scales; the formulas used to hard-code 1.0 / 8.0, so buying
## Brightness dimmed the light ~20x and light_radius shortened it.
var _scene_flashlight_energy: float = 1.0
var _scene_flashlight_range: float = 8.0

func _update_low_battery_flicker() -> void:
	if flashlight_stats == null:
		return
	if _base_flashlight_energy < 0.0:
		_base_flashlight_energy = flashlight.light_energy
	var ratio_pct: float = battery / maxf(battery_max, 0.001) * 100.0
	var flicker: bool = flashlight_enabled and ratio_pct < flashlight_stats.flicker_battery_threshold \
		and not _flashlight_stability_maxed \
		and not bool(SettingsManager.get_setting("reduce_flash", false))
	if flicker:
		_flickering = true
		flashlight.light_energy = _base_flashlight_energy * (1.0 + (randf() * 2.0 - 1.0) * flashlight_stats.flicker_intensity)
	elif _flickering:
		_flickering = false
		flashlight.light_energy = _base_flashlight_energy

func apply_flashlight_upgrades(levels: Dictionary) -> void:
	if not levels:
		return
	var fl_up := get_node_or_null("/root/FlashlightUpgradeManager")
	if not fl_up:
		return
	var b_bonus: float = fl_up.get_bonus("brightness")
	var s_bonus: float = fl_up.get_bonus("stability")
	var a_bonus: float = fl_up.get_bonus("angle")
	var bat_bonus: float = fl_up.get_bonus("battery")
	_upgrade_range_bonus = fl_up.get_bonus("range")
	flashlight.light_energy = _scene_flashlight_energy * (1.0 + b_bonus)
	flashlight.spot_angle = 45.0 + a_bonus
	_flashlight_battery_bonus = bat_bonus
	_flashlight_drain_cut = s_bonus
	_flashlight_stability_maxed = fl_up.get_level("stability") >= fl_up.get_max_level()
	_base_flashlight_energy = flashlight.light_energy
	refresh_battery_max()
	refresh_flashlight_range()

## GAME_AUDIT/arena design audit P5: battery_max used to be set incrementally
## from two places (this upgrade bonus here, "+= 25" per skill rank in
## skill_tree_manager.gd) - whichever wrote last silently discarded the
## other's contribution. Recomputed from scratch from both live sources
## every time either changes, so order no longer matters.
var _flashlight_battery_bonus: float = 0.0
## GDD.md:79 (G12b): flicker below the low-battery threshold, cleared by the
## max-level Stability upgrade (L5).
var _flashlight_stability_maxed: bool = false
## GDD.md:88-93: Stability L1-L5 = -10%..-50% battery drain.
var _flashlight_drain_cut: float = 0.0
var _base_flashlight_energy: float = -1.0
var _flickering: bool = false
const BATTERY_PER_SKILL_LVL: float = 25.0

func refresh_battery_max() -> void:
	var skill_lvl: int = SkillTreeManager.get_skill_level(&"battery_capacity") if SkillTreeManager else 0
	battery_max = 100.0 * (1.0 + _flashlight_battery_bonus) + BATTERY_PER_SKILL_LVL * skill_lvl
	battery = minf(battery, battery_max)
	EventBus.player_battery_changed.emit(battery / battery_max)

## Static audit 2026-09-08: "light_radius" skill was purchasable but nothing
## ever read it. Called from apply_flashlight_upgrades() above and from
## SkillTreeManager when light_radius is unlocked, so whichever source
## changes last still sees the other's contribution.
func refresh_flashlight_range() -> void:
	var skill_lvl: int = SkillTreeManager.get_skill_level(&"light_radius") if SkillTreeManager else 0
	flashlight.spot_range = _scene_flashlight_range * (1.0 + 0.2 * skill_lvl) + _upgrade_range_bonus


