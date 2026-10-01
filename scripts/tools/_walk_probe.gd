extends Node
## Walking-pace probe: the player walks at the first objective's bearing in the first district; once a second it
## prints where it is, how fast it goes, what it slides on and what blocks it. Headless:
##   godot --headless --path . res://scenes/tools/walk_probe_scene.tscn

const TARGET := Vector3(8.0, 0.0, 8.0)
const SECONDS := 24.0

var _player: CharacterBody3D = null
var _t: float = 0.0
var _log_t: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _run() -> void:
	GameManager._change_state(GameManager.GameState.PLAYING)
	var main := (load("res://scenes/main_3d.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(main)
	await get_tree().create_timer(3.0).timeout
	_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	print("[probe] player at %s speed stats %.2f/%.2f/%.2f" % [_player.global_position, _player.stats.walk_speed, _player.stats.run_speed, _player.stats.stealth_speed])
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _player == null:
		return
	_t += delta
	var to := TARGET - _player.global_position
	to.y = 0.0
	var cam := get_viewport().get_camera_3d()
	var basis := cam.global_transform.basis if cam != null else _player.global_transform.basis
	var fwd := -basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right := basis.x
	right.y = 0.0
	right = right.normalized()
	var wdir := to.normalized()
	InputService.set_joy_active(true)
	InputService.set_joy_move_dir(Vector2(wdir.dot(right), -wdir.dot(fwd)).limit_length(1.0))
	_log_t += delta
	if _log_t >= 1.0:
		_log_t = 0.0
		var hits: PackedStringArray = []
		for i in _player.get_slide_collision_count():
			var c := _player.get_slide_collision(i)
			hits.append("%s@%s" % [c.get_collider().name if c.get_collider() != null else "?", c.get_position()])
		print("[probe] t=%.1f pos=%s vel=%s floor=%s to_target=%.1f cam_valid=%s slides=%s" % [_t, _player.global_position, _player.velocity, _player.is_on_floor(), to.length(), cam != null, ", ".join(hits)])
	if _t >= SECONDS:
		InputService.set_joy_active(false)
		get_tree().quit(0)
