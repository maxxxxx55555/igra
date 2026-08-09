class_name EnemyBase
extends CharacterBody2D
enum State { IDLE, PATROL, CHASE, FLEE, STUN, DEAD }
@export var monster_id: StringName = &""
@export var patrol_points: Array[Vector2] = []
var data: MonsterData
var state: State = State.IDLE
var hp: float = 0.0
var _player: Node = null
var _player_stealth: bool = false
var _path_timer: float = 0.0
var _lose_timer: float = 0.0
var _patrol_idx: int = 0
var _noise_pos: Vector2 = Vector2.INF
var _noise_timer: float = 0.0
var _spotted: bool = false
var _facing: Vector2 = Vector2.DOWN
var _t: float = 0.0
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var detect_area: Area2D = $DetectArea
@onready var detect_shape: CollisionShape2D = $DetectArea/DetectShape
@onready var body_shape: CollisionShape2D = $CollisionShape2D
func _react_to_light(_in_light: bool, _delta: float) -> void:
    pass
func _tick_special(_delta: float) -> void:
    pass
func _on_lost_player() -> void:
    pass
func _ready() -> void:
    data = _load_data(monster_id)
    hp = data.max_hp
    add_to_group("enemies")
    (detect_shape.shape as CircleShape2D).radius = data.detect_radius
    (body_shape.shape as CircleShape2D).radius = data.collision_radius
    nav.path_desired_distance = 6.0
    nav.target_desired_distance = 8.0
    detect_area.body_entered.connect(_on_detect_entered)
    detect_area.body_exited.connect(_on_detect_exited)
    EventBus.noise_emitted.connect(_on_noise)
    EventBus.player_stealth_changed.connect(_on_player_stealth)
    if patrol_points.is_empty():
        state = State.IDLE
    else:
        state = State.PATROL
    queue_redraw()
func _physics_process(delta: float) -> void:
    if not GameManager.is_playing():
        return
    _t += delta
    if state == State.DEAD or data == null:
        return
    var in_light := _is_in_light()
    _react_to_light(in_light, delta)
    _tick_special(delta)
    if state == State.DEAD:
        return
    match state:
        State.IDLE:
            _try_acquire_target()
        State.PATROL:
            _do_patrol(delta)
            _try_acquire_target()
        State.CHASE:
            _do_chase(delta)
        State.FLEE:
            _do_flee(delta)
        State.STUN:
            velocity = Vector2.ZERO
            move_and_slide()
    _try_melee()
    queue_redraw()
func _effective_detect_radius() -> float:
    return data.detect_radius * (0.4 if _player_stealth else 1.0)
func _can_see_player() -> bool:
    if not is_instance_valid(_player):
        return false
    var to_player: Vector2 = _player.global_position - global_position
    var dist: float = to_player.length()
    if dist > minf(data.vision_range, _effective_detect_radius()):
        return false
    if data.vision_cone_deg >= 360.0:
        return true
    var ang := absf(wrapf(to_player.angle_to(_facing), -PI, PI))
    return ang <= deg_to_rad(data.vision_cone_deg * 0.5)
func _try_acquire_target() -> void:
    if _can_see_player() or _noise_timer > 0.0:
        _enter_chase()
func _enter_chase() -> void:
    if state == State.DEAD or state == State.STUN:
        return
    state = State.CHASE
    _lose_timer = data.lose_time
    _path_timer = 0.0
    if not _spotted:
        _spotted = true
        EventBus.monster_spotted.emit(monster_id)
    queue_redraw()
func _do_patrol(_delta: float) -> void:
    if patrol_points.is_empty():
        return
    var target := patrol_points[_patrol_idx]
    _steering_move(target, data.move_speed)
    if global_position.distance_to(target) < 10.0:
        _patrol_idx = (_patrol_idx + 1) % patrol_points.size()
func _do_chase(delta: float) -> void:
    var target: Vector2
    if is_instance_valid(_player):
        target = _player.global_position
    elif _noise_pos != Vector2.INF:
        target = _noise_pos
    else:
        _on_lost_player()
        state = State.PATROL
        queue_redraw()
        return
    _path_timer -= delta
    if _path_timer <= 0.0 or nav.target_position.distance_to(target) > 24.0:
        _path_timer = 0.2
        nav.target_position = target
    _steering_move(nav.get_next_path_position(), data.chase_speed)
    if is_instance_valid(_player) and global_position.distance_to(_player.global_position) > data.detect_radius * 1.4:
        _lose_timer -= delta
        if _lose_timer <= 0.0:
            _on_lost_player()
            state = State.PATROL
            queue_redraw()
func _do_flee(delta: float) -> void:
    var away := Vector2.RIGHT
    if is_instance_valid(_player):
        away = (global_position - _player.global_position).normalized()
    _facing = away
    velocity = away * data.chase_speed
    move_and_slide()
    if not _is_in_light():
        _lose_timer -= delta
        if _lose_timer <= 0.0:
            state = State.PATROL if not patrol_points.is_empty() else State.IDLE
            queue_redraw()
func _steering_move(target: Vector2, speed: float) -> void:
    var dir := (target - global_position)
    if dir.length() > 1.0:
        _facing = dir.normalized()
    velocity = _facing * speed
    move_and_slide()
func _is_in_light() -> bool:
    for fl in get_tree().get_nodes_in_group("flashlight"):
        if fl.has_method("is_point_lit") and fl.is_point_lit(global_position):
            return true
    return false
func _try_melee() -> void:
    if not is_instance_valid(_player):
        return
    if global_position.distance_to(_player.global_position) <= data.melee_range:
        if _player.has_method("take_damage"):
            _player.take_damage(data.melee_damage * get_physics_process_delta_time())
func _on_detect_entered(body: Node) -> void:
    if body.is_in_group("player"):
        _player = body
func _on_detect_exited(body: Node) -> void:
    if body == _player:
        _player = null
func _on_noise(pos: Vector2, radius: float) -> void:
    var d := global_position.distance_to(pos)
    if d <= radius * data.noise_sensitivity:
        _noise_pos = pos
        _noise_timer = 0.5
        if state == State.IDLE or state == State.PATROL:
            _enter_chase()
func _on_player_stealth(stealth: bool) -> void:
    _player_stealth = stealth
func take_damage(amount: float) -> void:
    if state == State.DEAD:
        return
    hp -= amount
    if hp <= 0.0:
        _die()

func _die() -> void:
    state = State.DEAD
    velocity = Vector2.ZERO
    EventBus.enemy_killed.emit(monster_id)
    if multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
        rpc_id(1, "_server_kill", monster_id)
    call_deferred("queue_free")

@rpc("any_peer", "reliable")
func _server_kill(monster_id: StringName) -> void:
    if is_multiplayer_authority():
        EventBus.enemy_killed.emit(monster_id)
func _load_data(id: StringName) -> MonsterData:
    match id:
        &"shadow": return preload("res://data/monsters/monster_shadow.tres")
        &"crawler": return preload("res://data/monsters/monster_crawler.tres")
        &"watcher": return preload("res://data/monsters/monster_watcher.tres")
        &"hunter": return preload("res://data/monsters/monster_hunter.tres")
        &"destroyer": return preload("res://data/monsters/monster_destroyer.tres")
        &"boss": return preload("res://data/monsters/monster_boss.tres")
    if id != &"":
        push_error("EnemyBase: неизвестный monster_id = %s" % id)
    var fallback := MonsterData.new()
    fallback.id = id
    return fallback
func _draw() -> void:
    if data == null:
        return
    VisualStyle.draw_monster(self, monster_id, _facing, data.body_color, _t)
    if data.vision_cone_deg < 360.0:
        var half := deg_to_rad(data.vision_cone_deg * 0.5)
        var base_ang := _facing.angle()
        draw_arc(Vector2.ZERO, 28.0, base_ang - half, base_ang + half, 12, Color(1, 0.4, 0.3, 0.4), 2.0, true)
    var sc := Color.WHITE
    match state:
        State.CHASE: sc = Color.RED
        State.FLEE: sc = Color.CYAN
        State.PATROL: sc = Color.YELLOW
    draw_circle(Vector2(0, -16), 3.0, sc)