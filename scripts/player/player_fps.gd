extends CharacterBody3D
## FPS player controller: movement, interaction, flashlight and health wiring.
## + head bob (амплитуда 0.03), recoil, screen shake, footstep dust.

signal health_changed(new_health: int)
signal died

@export var speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

@onready var camera: Camera3D = $Camera3D
@onready var interact_ray: RayCast3D = $Camera3D/RayCast3D
@onready var flashlight: SpotLight3D = $Camera3D/SpotLight3D
@onready var health: Node = $HealthComponent
@onready var attack: Node3D = $AttackComponent
@onready var mesh: MeshInstance3D = $MeshInstance3D

const COYOTE_TIME: float = 0.1
const JUMP_BUFFER_TIME: float = 0.1
const STEP_INTERVAL: float = 0.4

# Head bob
const BOB_AMPLITUDE: float = 0.03
const BOB_FREQUENCY: float = 2.0
var _bob_time: float = 0.0
var _camera_base_y: float = 0.0

var _coyote_timer: float = 0.0
var _jump_buffer: float = 0.0
var _step_timer: float = 0.0
var _flashlight_on: bool = true

# Effects
var _recoil: Node = null
var _screen_shake: Node = null
var _footstep_dust: Node = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	var game_manager: Node = get_tree().root.get_node_or_null("GameManager")
	if game_manager != null:
		game_manager.set("player", self)
	_on_health_changed(int(health.get("health")))
	_camera_base_y = camera.position.y
	_setup_effects()

func _setup_effects() -> void:
	# Recoil
	var recoil_script: Script = load("res://scripts/effects/recoil.gd")
	if recoil_script:
		_recoil = Node.new()
		_recoil.set_script(recoil_script)
		_recoil.name = "Recoil"
		add_child(_recoil)
		_recoil.setup(camera)
	# Screen shake
	var shake_script: Script = load("res://scripts/effects/screen_shake.gd")
	if shake_script:
		_screen_shake = Node.new()
		_screen_shake.set_script(shake_script)
		_screen_shake.name = "ScreenShake"
		add_child(_screen_shake)
		_screen_shake.setup(camera)
	# Footstep dust
	var dust_script: Script = load("res://scripts/effects/footstep_dust.gd")
	if dust_script:
		_footstep_dust = Node3D.new()
		_footstep_dust.set_script(dust_script)
		_footstep_dust.name = "FootstepDust"
		add_child(_footstep_dust)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_event: InputEventMouseMotion = event as InputEventMouseMotion
		rotate_y(-mouse_event.relative.x * mouse_sensitivity)
		camera.rotate_x(-mouse_event.relative.y * mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x, -PI * 0.5, PI * 0.5)
	if event.is_action_pressed("flashlight_toggle"):
		_flashlight_on = not _flashlight_on
		flashlight.visible = _flashlight_on
		EventBus.flashlight_state_changed.emit(_flashlight_on)
	if event.is_action_pressed("ui_pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("quick_slot_1"):
			_use_slot(0)
		elif event.is_action_pressed("quick_slot_2"):
			_use_slot(1)
		elif event.is_action_pressed("quick_slot_3"):
			_use_slot(2)
		elif event.is_action_pressed("quick_slot_4"):
			_use_slot(3)
		elif event.is_action_pressed("quick_slot_5"):
			_use_slot(4)
		elif event.is_action_pressed("quick_slot_6"):
			_use_slot(5)

func _use_slot(index: int) -> void:
	var hud: Node = get_tree().root.find_child("HUD3D", true, false)
	if hud != null and hud.has_method("_use_quick_slot"):
		hud.call("_use_quick_slot", index)

## Вызывается из AttackComponent / Weapon при выстреле.
func on_shoot() -> void:
	if _recoil:
		_recoil.add_recoil()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		_coyote_timer -= delta
	else:
		_coyote_timer = COYOTE_TIME
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER_TIME
	else:
		_jump_buffer = maxf(0.0, _jump_buffer - delta)
	if _jump_buffer > 0.0 and (_coyote_timer > 0.0 or is_on_floor()):
		velocity.y = jump_velocity
		_jump_buffer = 0.0
		_coyote_timer = 0.0
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var sprinting: bool = Input.is_action_pressed("run") or Input.is_action_pressed("sprint")
	var current_speed: float = sprint_speed if sprinting else speed
	var is_moving: bool = not direction.is_zero_approx()
	if is_moving:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		_step_timer -= delta
		if _step_timer <= 0.0 and is_on_floor():
			_step_timer = STEP_INTERVAL
			_on_step()
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)
	# Head bob
	if is_moving and is_on_floor():
		_bob_time += delta * BOB_FREQUENCY * (sprint_speed / speed if sprinting else 1.0)
		camera.position.y = _camera_base_y + sin(_bob_time * TAU) * BOB_AMPLITUDE
	else:
		_bob_time = 0.0
		camera.position.y = move_toward(camera.position.y, _camera_base_y, delta * 4.0)
	_UpdateCrosshairAim()
	move_and_slide()
	if Input.is_action_just_pressed("interact") and interact_ray.is_colliding():
		var collider: Object = interact_ray.get_collider()
		if collider != null and collider.has_method("interact"):
			collider.call("interact", self)

## 3.6 Спека: прицел меняет цвет по наведению на врага.
## emits crosshair_state_changed (&"default" / &"enemy" / &"disabled").
func _UpdateCrosshairAim() -> void:
	if interact_ray == null:
		EventBus.crosshair_state_changed.emit(&"disabled")
		return
	if not interact_ray.is_colliding():
		EventBus.crosshair_state_changed.emit(&"default")
		return
	var collider := interact_ray.get_collider()
	if collider == null:
		EventBus.crosshair_state_changed.emit(&"disabled")
		return
	if collider.is_in_group("monster") or collider.is_in_group("enemy"):
		EventBus.crosshair_state_changed.emit(&"enemy")
	elif collider.has_method("interact"):
		EventBus.crosshair_state_changed.emit(&"default")
	else:
		EventBus.crosshair_state_changed.emit(&"disabled")

func _on_step() -> void:
	if _footstep_dust:
		var dust := _footstep_dust.duplicate()
		get_parent().add_child(dust)
		dust.puff(global_position)

func _on_health_changed(new_health: int) -> void:
	health_changed.emit(new_health)
	EventBus.player_health_changed.emit(float(health.call("get_health_ratio")))

func take_damage(amount: float, source: String = "", _type: EnemyRosterData.DamageType = EnemyRosterData.DamageType.BLUNT) -> void:
	health.call("take_damage", roundi(amount))
	if not source.is_empty():
		var death_screen: Node = get_tree().root.get_node_or_null("DeathScreen")
		if death_screen != null and death_screen.has_method("set_reason"):
			death_screen.call("set_reason", source)
	_play_hurt()

func _play_hurt() -> void:
	if mesh == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(mesh, "modulate", Color(1.0, 0.0, 0.0), 0.1)
	tween.tween_property(mesh, "modulate", Color.WHITE, 0.1)

func _on_died() -> void:
	died.emit()
	EventBus.player_died.emit()
	get_tree().reload_current_scene()
