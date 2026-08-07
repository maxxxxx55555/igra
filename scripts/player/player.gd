extends CharacterBody2D
enum State { IDLE, WALK, RUN, STEALTH }
@export var stats: PlayerStats
@onready var visual: Node2D = $PlayerVisual
@onready var interact_zone: Area2D = $InteractZone
var current_state: State = State.IDLE
var stamina: float = 0.0
var hp: float = 0.0
var battery: float = 100.0
var look_dir: Vector2 = Vector2.DOWN
var _weight_ratio: float = 0.0
var _weight_speed_mult: float = 1.0
var _weight_noise_mult: float = 1.0
var _noise_timer: float = 0.0
var _interact_target: Node = null
func _ready() -> void:
    if stats == null:
        # push_error("Player: не назначен PlayerStats (data/balance/player_stats.tres)")
        return
    stamina = stats.stamina_max
    hp = stats.max_hp
    battery = 100.0
    add_to_group("player")
    InputService.interact_requested.connect(_on_interact_requested)
    EventBus.inventory_weight_changed.connect(_on_weight_changed)
    EventBus.item_consumed.connect(_on_item_consumed)
    EventBus.light_disrupted.connect(_on_light_disrupted)
    EventBus.player_health_changed.emit(hp / stats.max_hp)
    EventBus.player_stamina_changed.emit(stamina / stats.stamina_max)
    EventBus.player_battery_changed.emit(battery / 100.0)
    EventBus.player_stealth_changed.emit(false)
    _emit_state()
func _physics_process(delta: float) -> void:
    if stats == null:
        return
    var dir: Vector2 = InputService.get_move_dir()
    var moving: bool = dir.length_squared() > 0.0001
    var desired: State
    if InputService.is_stealth_toggled() and moving:
        desired = State.STEALTH
    elif InputService.is_run_held() and moving and stamina > 0.0:
        desired = State.RUN
    elif moving:
        desired = State.WALK
    else:
        desired = State.IDLE
    if desired == State.RUN and stamina <= 0.0:
        desired = State.WALK
    if desired != current_state:
        current_state = desired
        _emit_state()
    var speed: float = _speed_for(current_state) * stats.weight_speed_mult * _weight_speed_mult
    velocity = dir.normalized() * speed if moving else Vector2.ZERO
    move_and_slide()
    if moving:
        look_dir = look_dir.lerp(dir.normalized(), 12.0 * delta).normalized()
        visual.look_dir = look_dir
        visual.queue_redraw()
    _update_stamina(delta)
    _update_noise(delta, moving)
func _speed_for(state: State) -> float:
    match state:
        State.RUN: return stats.run_speed
        State.STEALTH: return stats.stealth_speed
        State.WALK: return stats.walk_speed
        _: return 0.0
func _update_stamina(delta: float) -> void:
    var prev := stamina
    if current_state == State.RUN:
        stamina = maxf(0.0, stamina - stats.stamina_drain_per_sec * delta)
    else:
        stamina = minf(stats.stamina_max, stamina + stats.stamina_regen_per_sec * delta)
    if absf(stamina - prev) > 0.01:
        EventBus.player_stamina_changed.emit(stamina / stats.stamina_max)
func _update_noise(delta: float, moving: bool) -> void:
    var radius: float = 0.0
    if moving:
        match current_state:
            State.RUN: radius = stats.noise_run
            State.WALK: radius = stats.noise_walk
            State.STEALTH: radius = stats.noise_stealth
        radius *= _weight_noise_mult
    _noise_timer += delta
    if radius > 0.0 and _noise_timer >= stats.noise_emit_interval:
        _noise_timer = 0.0
        EventBus.noise_emitted.emit(global_position, radius)
func _emit_state() -> void:
    EventBus.player_state_changed.emit(int(current_state))
    EventBus.player_stealth_changed.emit(current_state == State.STEALTH)
func _on_interact_requested() -> void:
    if is_instance_valid(_interact_target) and _interact_target.has_method("interact"):
        _interact_target.interact(self)
func set_interact_target(target: Node) -> void:
    _interact_target = target
    EventBus.player_interact_available.emit(is_instance_valid(target))
func _on_weight_changed(ratio: float) -> void:
    _weight_ratio = ratio
    var soft: float = 0.5
    _weight_speed_mult = 1.0 - 0.5 * smoothstep(soft, 1.0, ratio)
    _weight_noise_mult = 1.0 + ratio
func _on_item_consumed(_id: StringName, effect: StringName, value: float) -> void:
    match effect:
        &"HEAL": heal(value)
        &"RECHARGE": add_battery(value)
func _on_light_disrupted() -> void:
    var fl := get_node_or_null("Flashlight")
    if fl and fl.has_method("set_enabled"):
        fl.set_enabled(false)
func take_damage(amount: float) -> void:
    if stats == null:
        return
    hp = clampf(hp - amount, 0.0, stats.max_hp)
    EventBus.player_health_changed.emit(hp / stats.max_hp)
    if hp <= 0.0:
        GameManager.trigger_death()
func heal(amount: float) -> void:
    if stats == null:
        return
    hp = clampf(hp + amount, 0.0, stats.max_hp)
    EventBus.player_health_changed.emit(hp / stats.max_hp)
func get_battery() -> float:
    return battery
func consume_battery(amount: float) -> void:
    if amount <= 0.0:
        return
    var prev := battery
    battery = clampf(battery - amount, 0.0, 100.0)
    if absf(battery - prev) > 0.01:
        EventBus.player_battery_changed.emit(battery / 100.0)
    if battery <= 0.0 and prev > 0.0:
        EventBus.flashlight_depleted.emit()
func add_battery(amount: float) -> void:
    if amount <= 0.0:
        return
    var prev := battery
    battery = clampf(battery + amount, 0.0, 100.0)
    if absf(battery - prev) > 0.01:
        EventBus.player_battery_changed.emit(battery / 100.0)