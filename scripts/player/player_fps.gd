extends CharacterBody3D
## A8/A1: Igrok - crouch, shum, chekpoint-respawn

signal health_changed(new_health: int)
signal died

@export var speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

@onready var camera: Camera3D = $Camera3D
@onready var interact_ray: RayCast3D = $Camera3D/RayCast3D
@onready var flashlight: SpotLight3D = $Camera3D/SpotLight3D
@onready var health = $HealthComponent
@onready var attack = $AttackComponent
@onready var mesh: MeshInstance3D = $MeshInstance3D

var _coyote_timer: float = 0.0
var _jump_buffer: float = 0.0
const COYOTE_TIME: float = 0.1
const JUMP_BUFFER_TIME: float = 0.1
const STEP_INTERVAL: float = 0.4
var _step_timer: float = 0.0
var _flashlight_on: bool = true

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    if health:
        health.health_changed.connect(func(h): health_changed.emit(h))
        health.died.connect(_on_died)
    var gm = get_tree().root.get_node_or_null("GameManager")
    if gm:
        gm.player = self

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        camera.rotate_x(-event.relative.y * mouse_sensitivity)
        camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
    if event.is_action_pressed("flashlight_toggle"):
        _flashlight_on = !_flashlight_on
        if flashlight: flashlight.visible = _flashlight_on
    if event.is_action_pressed("ui_pause"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventKey and event.pressed:
        if event.is_action_pressed("quick_slot_1"): _use_slot(0)
        elif event.is_action_pressed("quick_slot_2"): _use_slot(1)
        elif event.is_action_pressed("quick_slot_3"): _use_slot(2)
        elif event.is_action_pressed("quick_slot_4"): _use_slot(3)
        elif event.is_action_pressed("quick_slot_5"): _use_slot(4)
        elif event.is_action_pressed("quick_slot_6"): _use_slot(5)

func _use_slot(index: int) -> void:
    var hud := get_tree().root.find_child("HUD3D", true, false)
    if hud and hud.has_method("_use_quick_slot"):
        hud._use_quick_slot(index)

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity += get_gravity() * delta
        _coyote_timer -= delta
    else:
        _coyote_timer = COYOTE_TIME
        if Input.is_action_just_pressed("jump"): _jump_buffer = JUMP_BUFFER_TIME
    if _jump_buffer > 0 and (_coyote_timer > 0 or is_on_floor()):
        velocity.y = jump_velocity; _jump_buffer = 0; _coyote_timer = 0
    var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    var current_speed := sprint_speed if Input.is_action_pressed("run") else speed
    if direction:
        velocity.x = direction.x * current_speed
        velocity.z = direction.z * current_speed
        if Input.is_action_pressed("sprint"):
            var ns := get_tree().root.get_node_or_null("NoiseSystem")
            if ns and ns.has_method("emit_noise"): ns.emit_noise(global_position, "sprint")
        _step_timer -= delta
        if _step_timer <= 0 and is_on_floor():
            var pm := get_tree().root.get_node_or_null("ParticleManager")
            if pm and pm.has_method("spawn"): pm.spawn("footstep_dust", global_position)
            var ns := get_tree().root.get_node_or_null("NoiseSystem")
            if ns and ns.has_method("emit_noise"): ns.emit_noise(global_position, "walk")
            _step_timer = STEP_INTERVAL
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        velocity.z = move_toward(velocity.z, 0, speed)
    move_and_slide()
    if Input.is_action_just_pressed("interact") and interact_ray and interact_ray.is_colliding():
        var collider = interact_ray.get_collider()
        if collider and collider.has_method("interact"):
            collider.interact(self)

func take_damage(amount: int, source: String = "") -> void:
    if health: health.take_damage(amount)
    var lm := get_tree().root.get_node_or_null("LevelManager")
    if lm and lm.has_method("add_damage"): lm.add_damage(amount)
    var pm := get_tree().root.get_node_or_null("ParticleManager")
    if pm and pm.has_method("spawn"): pm.spawn("blood_particles", global_position + Vector3.UP)
    if source != "":
        var ds := get_tree().root.get_node_or_null("/root/DeathScreen")
        if ds and ds.has_method("set_reason"):
            ds.set_reason(source)
    _play_hurt()

func _play_hurt() -> void:
    if not mesh: return
    var tw = create_tween()
    tw.tween_property(mesh, "modulate", Color(1, 0, 0), 0.1)
    tw.tween_property(mesh, "modulate", Color.WHITE, 0.1)

func _on_died() -> void:
    died.emit()
    var lm := get_tree().root.get_node_or_null("LevelManager")
    if lm:
        lm.respawn_or_reload()
    else:
        get_tree().reload_current_scene()
    var gm = get_tree().root.get_node_or_null("GameManager")
    if gm:
        gm.player = self