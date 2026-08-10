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
var stamina: float = 100.0
var battery: float = 100.0
var look_dir: Vector3 = Vector3.FORWARD
var flashlight_enabled: bool = true
var gameplay_active: bool = false
var noise_level: float = 0.0
var detection_state: String = "HIDDEN"
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
var _attack_timer: float = 0.0
var _hit_registered: bool = false
var _stun_timer: float = 0.0
var _combo_break: bool = false
var _dodge_input_timer: float = 0.0
var _dodge_input_dir: Vector2 = Vector2.ZERO
var _crouch_held: bool = false
var _crouch_timer: float = 0.0
var _hiding_spot: Node3D = null
var _in_hiding: bool = false
var _footstep_system: Node = null

const COMBO_DATA: Array = [
    { "windup": 0.25, "active": 0.15, "recovery": 0.15, "dmg": 8, "stam": 5, "knockback": 0.0 },
    { "windup": 0.30, "active": 0.15, "recovery": 0.15, "dmg": 12, "stam": 5, "knockback": 0.0 },
    { "windup": 0.45, "active": 0.20, "recovery": 0.20, "dmg": 20, "stam": 8, "knockback": 1.5 }
]
const COMBO_WINDOW: float = 1.2
const DODGE_COST: float = 15.0
const DODGE_COOLDOWN: float = 0.8
const DODGE_IFRAMES: float = 0.35
const CROUCH_SPEED_MULT: float = 0.4
const CROUCH_NOISE_MULT: float = 0.3
const CROUCH_VISIBILITY_MULT: float = 0.5

const DEBUG_FLASHLIGHT: bool = true
const BATTERY_DRAIN_PER_SEC: float = 100.0 / 300.0

var _battery_log_timer: float = 0.0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = true
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
    var code := "shader_type spatial; render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled; void fragment(){ float a = clamp(1.0 - UV.y, 0.0, 1.0) * 0.85; vec3 amber = vec3(1.0, 0.55, 0.18); vec3 c = amber * 1.5 * a; ALBEDO = c; ALPHA = 1.0; }"
    _cone_shader_code = code
    var mat := Shader.new()
    mat.code = code
    var sm := ShaderMaterial.new()
    sm.shader = mat
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
    _net_active = multiplayer != null and multiplayer.multiplayer_peer != null
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
    attack_box.size = Vector3(0.6, 0.4, 1.2)
    attack_shape.shape = attack_box
    _attack_area.add_child(attack_shape)
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
    var gm := get_node_or_null("/root/GameManager")
    if gm and gm.has_method("is_playing") and gm.is_playing():
        call_deferred("_on_game_started")

func _buffer_jump() -> void:
    _jump_buffer_timer = jump_buffer_time

func _on_game_started() -> void:
    if _net_active and not is_multiplayer_authority():
        return
    gameplay_active = true
    if _fps_cam == null:
        var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
        if cam == null and get_tree():
            cam = get_tree().root.get_node_or_null("Main3D/Camera3D") as Camera3D
        _fps_cam = cam
    if _fps_cam and _fps_cam.has_method("set_fps"):
        _fps_cam.set_fps(true)
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
    if not gameplay_active:
        return
    if _net_active and not is_multiplayer_authority():
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotation.y -= event.relative.x * mouse_sens
        _pitch -= event.relative.y * mouse_sens
        _pitch = clampf(_pitch, -1.5, 1.5)
    if event is InputEventScreenDrag:
        var vp_w: float = get_viewport().get_visible_rect().size.x if get_viewport() else 1000.0
        if event.position.x < vp_w * 0.35:
            return
        rotation.y -= event.relative.x * mouse_sens
        _pitch = clampf(_pitch - event.relative.y * mouse_sens, -1.5, 1.5)
    if event is InputEventScreenTouch and event.pressed:
        var vp_w2: float = get_viewport().get_visible_rect().size.x if get_viewport() else 1000.0
        if event.position.x >= vp_w2 * 0.35:
            _handle_attack()

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
        State.CROUCH: speed_noise = 0.15
        _: speed_noise = 0.0
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
    else:
        _coyote_timer -= delta
    if Input.is_action_just_pressed("ui_accept"):
        _jump_buffer_timer = jump_buffer_time
    else:
        _jump_buffer_timer -= delta
    if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
        velocity.y = jump_velocity
        _coyote_timer = 0.0
        _jump_buffer_timer = 0.0
    velocity += get_gravity() * delta
    move_and_slide()

    if moving:
        if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
            var target_angle: float = atan2(dir.x, -dir.z)
            rotation.y = lerp_angle(rotation.y, target_angle, 12.0 * delta)
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
    # Один пивот для света, конуса, пыли и «фонаря в руке» — иначе они смотрят врозь.
    flashlight_pivot.global_rotation = Vector3(_pitch, global_rotation.y, 0.0)
    human_body.visible = enable_human_body and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED

    flashlight.visible = flashlight_enabled
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
    _update_hiding(delta)
    _battery_log_timer += delta
    if DEBUG_FLASHLIGHT and _battery_log_timer >= 1.0:
        _battery_log_timer = 0.0

    if _dodge_cooldown > 0.0:
        _dodge_cooldown -= delta
    if _iframes > 0.0:
        _iframes -= delta
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
    match state:
        State.RUN: return stats.run_speed
        State.STEALTH: return stats.stealth_speed
        State.WALK: return stats.walk_speed
        State.CROUCH: return stats.walk_speed
        _: return 0.0

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
    battery = clampf(battery - BATTERY_DRAIN_PER_SEC * delta, 0.0, 100.0)
    if absf(battery - prev) > 0.01:
        EventBus.player_battery_changed.emit(battery / 100.0)
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
    hp = clampf(hp - amount, 0.0, stats.max_hp)
    AudioManager.play_sound_3d(preload("res://assets/audio/sfx/sfx_hurt.wav"), global_position, -4.0)
    EventBus.player_health_changed.emit(hp / stats.max_hp)
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
    battery = clampf(battery - amount, 0.0, 100.0)
    EventBus.player_battery_changed.emit(battery / 100.0)

func add_battery(amount: float) -> void:
    battery = clampf(battery + amount, 0.0, 100.0)
    EventBus.player_battery_changed.emit(battery / 100.0)

func _unhandled_input(event: InputEvent) -> void:
    if _net_active and not is_multiplayer_authority():
        return
    if event.is_action_pressed("attack"):
        _handle_attack()
    if Input.is_action_just_pressed("flashlight_toggle"):
        toggle_flashlight()
    if event.is_action_pressed("interact"):
        _try_inspect()

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
    if stamina < COMBO_DATA[mini(_combo_count, 2)]["stam"]:
        return
    if _attack_phase != "none":
        return
    _hit_registered = false
    var hit_idx: int = mini(_combo_count, 2)
    if _combo_count > 0 and (_combo_break or _combo_timer <= 0.0):
        _combo_count = 0
        hit_idx = 0
    var cd: Dictionary = COMBO_DATA[hit_idx]
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
    var hit_idx_2: int = mini(_combo_count, 2)
    var cd2: Dictionary = COMBO_DATA[hit_idx_2]
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
    var hit_idx3: int = mini(_combo_count - 1, 2)
    if hit_idx3 < 0:
        return
    var cd3: Dictionary = COMBO_DATA[hit_idx3]
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
    velocity = d * stats.run_speed * 3.0
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

func _update_hiding(delta: float) -> void:
    if not gameplay_active:
        return
    if InputService.is_interact_just_pressed():
        if _in_hiding:
            _exit_hiding()
        else:
            _try_enter_hiding()

func _try_enter_hiding() -> void:
    var spots := get_tree().get_nodes_in_group("hiding_spot")
    for spot in spots:
        if spot.global_position.distance_to(global_position) < 2.0:
            _hiding_spot = spot as Node3D
            _in_hiding = true
            can_move = false
            velocity = Vector3.ZERO
            global_position = _hiding_spot.global_position
            visibility = 0.0
            EventBus.player_hiding_changed.emit(true)
            return

func _exit_hiding() -> void:
    if _hiding_spot:
        _in_hiding = false
        can_move = true
        EventBus.player_hiding_changed.emit(false)
        _hiding_spot = null

func apply_flashlight_upgrades(levels: Dictionary) -> void:
    if not levels:
        return
    var fl_up := get_node_or_null("/root/FlashlightUpgradeManager")
    if not fl_up:
        return
    var b_bonus: float = fl_up.get_bonus("brightness")
    var r_bonus: float = fl_up.get_bonus("range")
    var s_bonus: float = fl_up.get_bonus("stability")
    var a_bonus: float = fl_up.get_bonus("angle")
    var bat_bonus: float = fl_up.get_bonus("battery")
    flashlight.light_energy = 1.0 * (1.0 + b_bonus)
    flashlight.spot_range = 8.0 + r_bonus
    flashlight.spot_angle = 45.0 + a_bonus
    var sm := cone.material_override as ShaderMaterial
    if sm:
        sm.set_shader_parameter("softness", 0.3 * (1.0 - s_bonus))
    battery_max = 100.0 * (1.0 + bat_bonus)
    battery = minf(battery, battery_max)
    EventBus.player_battery_changed.emit(battery / battery_max)


