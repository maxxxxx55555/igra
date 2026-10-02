extends Node
## rc16 O2: gameplay quantities measured in SIMULATED time (the sum of the process deltas and the physics tick count), run three
## times with `--fixed-fps 30`, `60` and `120` (tools/qa_sim/timing_equiv). One line per quantity: "[timing] fps=<N> <key>=<value>";
## tools/qa_sim/timing_compare.py judges the three runs against each other (same boss time, damage, pickup reach within tolerance).

const FAR := Vector3(500.0, 0.0, 500.0)
const WARMUP_SEC: float = 3.0
const WALK_SEC: float = 2.0
const FIRE_SEC: float = 6.0
const MELEE_SEC: float = 8.0
const BATTERY_SEC: float = 8.0
const MONSTER_SEC: float = 12.0
const BOSS_DEADLINE_SEC: float = 90.0
const PICKUP_OFFSETS: Array[float] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5]
const PICKUP_WALK_SEC: float = 2.0
const FLOOR_HALF_SIZE: float = 100.0
const ROTTER := "res://scenes/enemies/rotter_3d.tscn"
const BOSS := "res://scenes/enemies/boss_architect_3d.tscn"
const PICKUP := "res://scenes/pickups/item_pickup_3d.tscn"

var _fps: int = 60
var _t: float = 0.0
var _frames: int = 0
var _ticks: int = 0
var _main: Node = null
var _player: Node3D = null
var _shots: int = 0
var _first_shot_t: float = -1.0
var _last_shot_t: float = -1.0
var _hits: int = 0
var _hit_total: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _process(delta: float) -> void:
	_t += delta
	_frames += 1

func _physics_process(_delta: float) -> void:
	_ticks += 1

func _report(key: String, value: float) -> void:
	print("[timing] fps=%d %s=%.5f" % [_fps, key, value])

func _note(key: String, text: String) -> void:
	print("[timing] fps=%d %s=ERROR %s" % [_fps, key, text])

func _wait(seconds: float) -> void:
	var until := _t + seconds
	while _t < until:
		await get_tree().process_frame

func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)

func _on_fired() -> void:
	_shots += 1
	if _first_shot_t < 0.0:
		_first_shot_t = _t
	_last_shot_t = _t

func _on_player_damaged(amount: float) -> void:
	_hits += 1
	_hit_total += amount

func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--tfps="):
			_fps = int(String(a).substr(7))
	SaveSystem.mark_onboard_done()
	GameManager._change_state(GameManager.GameState.PLAYING)
	_main = (load("res://scenes/main_3d.tscn") as PackedScene).instantiate()
	add_child(_main)
	await _wait(WARMUP_SEC)
	_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player == null:
		_note("setup", "no player")
		_finish()
		return
	_build_floor()
	_place_player()
	await _wait(1.0)
	await _measure_clocks()
	await _measure_walk_and_sprint()
	await _measure_battery()
	var weapons := _player.get_node_or_null("WeaponManager") as WeaponManager
	if weapons == null:
		_note("weapons", "no WeaponManager")
	else:
		await _measure_weapon(weapons, &"rifle")
		await _measure_reload(weapons)
		await _measure_weapon(weapons, &"pistol")
		weapons.holster()
		await _measure_melee()
		await _measure_monster()
		await _measure_pickups()
		await _measure_boss(weapons)
	_finish()

func _finish() -> void:
	_report("delta_mean", _t / float(maxi(_frames, 1)))
	_report("physics_ticks_per_sim_s", float(_ticks) / maxf(_t, 0.001))
	print("[timing] DONE fps=%d frames=%d sim_s=%.3f physics_ticks=%d" % [_fps, _frames, _t, _ticks])
	get_tree().quit(0)

func _build_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "TimingFloor"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(FLOOR_HALF_SIZE * 2.0, 1.0, FLOOR_HALF_SIZE * 2.0)
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	body.global_position = FAR + Vector3(0.0, -0.5, 0.0)

func _place_player() -> void:
	if not GameManager.is_playing():
		GameManager._change_state(GameManager.GameState.PLAYING)
	_player.set("gameplay_active", true)
	_player.set("can_move", true)
	_player.global_position = FAR + Vector3(0.0, 1.2, 0.0)
	_player.rotation.y = 0.0
	_player.set("velocity", Vector3.ZERO)

# ── clocks: a timer and a tween of one second last one second of simulated time (one frame of slack) ──
func _measure_clocks() -> void:
	var t0 := _t
	await get_tree().create_timer(1.0).timeout
	_report("timer_1s", _t - t0)
	var probe := Node2D.new()
	add_child(probe)
	t0 = _t
	var tween := create_tween()
	tween.tween_property(probe, "position:x", 100.0, 1.0)
	await tween.finished
	_report("tween_1s", _t - t0)
	probe.queue_free()

# ── movement: metres per second of simulated time, and the stamina a sprint burns per second ──
func _measure_walk_and_sprint() -> void:
	InputService.set_joy_active(true)
	InputService.set_joy_move_dir(Vector2(0.0, -1.0))
	var start := _player.global_position
	var t0 := _t
	await _wait(WALK_SEC)
	_report("walk_mps", _flat(_player.global_position - start).length() / (_t - t0))
	InputService.set_joy_run_held(true)
	var stamina0: float = float(_player.get("stamina"))
	start = _player.global_position
	t0 = _t
	await _wait(WALK_SEC)
	_report("sprint_mps", _flat(_player.global_position - start).length() / (_t - t0))
	_report("stamina_drain_per_s", (stamina0 - float(_player.get("stamina"))) / (_t - t0))
	InputService.set_joy_run_held(false)
	InputService.set_joy_move_dir(Vector2.ZERO)
	InputService.set_joy_active(false)
	await _wait(0.5)
	_place_player()
	await _wait(0.5)

func _measure_battery() -> void:
	if not bool(_player.get("flashlight_enabled")):
		_player.call("toggle_flashlight")
	_player.set("battery", 100.0)
	var t0 := _t
	await _wait(BATTERY_SEC)
	_report("battery_drain_per_s", (100.0 - float(_player.get("battery"))) / (_t - t0))

# ── weapons: a held trigger (one fire attempt per physics tick, as the held attack key does) ──
func _measure_weapon(weapons: WeaponManager, id: StringName) -> void:
	if not weapons.is_unlocked(id):
		weapons.unlock(id)
	if not weapons.equip(id):
		_note(String(id) + "_shots_per_s", "equip failed")
		return
	var weapon := weapons.get_current_weapon()
	weapon.max_ammo = 100000
	weapon.current_ammo = 100000
	weapon.fired.connect(_on_fired)
	_shots = 0
	_first_shot_t = -1.0
	_last_shot_t = -1.0
	var from := _player.global_position + Vector3(0.0, 1.5, 0.0)
	var t0 := _t
	while _t < t0 + FIRE_SEC:
		await get_tree().physics_frame
		weapon.fire(from, Vector3(0.0, 0.0, -1.0))
	# the rate between the first and the last shot: the window's own edges do not count
	_report(String(id) + "_shots_per_s", float(_shots - 1) / maxf(_last_shot_t - _first_shot_t, 0.001))
	weapon.fired.disconnect(_on_fired)

func _measure_reload(weapons: WeaponManager) -> void:
	if not weapons.equip(&"rifle"):
		_note("rifle_reload_s", "equip failed")
		return
	var weapon := weapons.get_current_weapon()
	weapons.add_ammo(500)
	weapon.max_ammo = 30
	weapon.current_ammo = 0
	var t0 := _t
	if not weapon.try_reload():
		_note("rifle_reload_s", "try_reload refused")
		return
	while weapon.is_reloading() and _t < t0 + 10.0:
		await get_tree().process_frame
	_report("rifle_reload_s", _t - t0)

# ── melee: swings begun per second of simulated time, every swing restarted the tick the last one ends ──
func _measure_melee() -> void:
	var swings := 0
	var t0 := _t
	var smax: float = float((_player.get("stats") as Resource).get("stamina_max"))
	while _t < t0 + MELEE_SEC:
		await get_tree().physics_frame
		_player.set("stamina", smax)
		if String(_player.get("_attack_phase")) == "none":
			_player.call("_handle_attack")
			if String(_player.get("_attack_phase")) == "windup":
				swings += 1
	_report("melee_swings_per_s", float(swings) / (_t - t0))

# ── a monster put into CHASE next to the player (a free AI wanders by chance, and the global random numbers other scripts draw per
# frame differ between frame rates): hits it lands and the damage that arrives, per second ──
func _measure_monster() -> void:
	_place_player()
	await _wait(0.3)
	var monster := (load(ROTTER) as PackedScene).instantiate() as Node3D
	add_child(monster)
	monster.global_position = _player.global_position + Vector3(0.0, 0.0, -1.2)
	monster.set("player_ref", _player)
	monster.look_at(Vector3(_player.global_position.x, monster.global_position.y, _player.global_position.z), Vector3.UP)
	monster.call("_change_state", BaseMonster.State.CHASE)
	_hits = 0
	_hit_total = 0.0
	EventBus.player_damaged.connect(_on_player_damaged)
	var smax: float = float((_player.get("stats") as Resource).get("max_hp"))
	var t0 := _t
	var next_dbg := _t
	while _t < t0 + MONSTER_SEC:
		await get_tree().physics_frame
		_player.set("hp", smax)
		if _t >= next_dbg:
			next_dbg += 0.5
			print("[timing-dbg] fps=%d t=%.2f state=%s dist=%.2f hits=%d" % [_fps, _t - t0, str(monster.get("ai_state")), monster.global_position.distance_to(_player.global_position), _hits])
	_report("monster_hits_per_s", float(_hits) / (_t - t0))
	_report("monster_damage_per_s", _hit_total / (_t - t0))
	EventBus.player_damaged.disconnect(_on_player_damaged)
	monster.queue_free()
	await _wait(0.3)

# ── pickup reach: the widest lateral offset at which a player walking past still collects the item ──
func _measure_pickups() -> void:
	var reach: float = 0.0
	for offset in PICKUP_OFFSETS:
		_place_player()
		await _wait(0.4)
		var pickup := (load(PICKUP) as PackedScene).instantiate() as Node3D
		add_child(pickup)
		pickup.global_position = _player.global_position + Vector3(offset, 0.5, -3.0)
		pickup.call("set_item", &"scrap", 1)
		InputService.set_joy_active(true)
		InputService.set_joy_move_dir(Vector2(0.0, -1.0))
		await _wait(PICKUP_WALK_SEC)
		InputService.set_joy_move_dir(Vector2.ZERO)
		InputService.set_joy_active(false)
		if not is_instance_valid(pickup) or bool(pickup.get("_picked_up")):
			reach = offset
		if is_instance_valid(pickup):
			pickup.queue_free()
	_report("pickup_reach_m", reach)

# ── the Architect as a dummy (his own AI off): seconds of held rifle fire until he dies ──
func _measure_boss(weapons: WeaponManager) -> void:
	_place_player()
	await _wait(0.5)
	if not weapons.equip(&"rifle"):
		_note("boss_ttk_s", "equip failed")
		return
	var weapon := weapons.get_current_weapon()
	weapon.max_ammo = 100000
	weapon.current_ammo = 100000
	var boss := (load(BOSS) as PackedScene).instantiate() as Node3D
	add_child(boss)
	boss.global_position = _player.global_position + Vector3(0.0, 0.1, -12.0)
	boss.set("player_ref", _player)
	boss.set_process(false)
	boss.set_physics_process(false)
	await _wait(0.3)
	weapon.spread = 0.0
	var from := _player.global_position + Vector3(0.0, 1.5, 0.0)
	var aim := (boss.global_position + Vector3(0.0, 1.0, 0.0) - from).normalized()
	_report("boss_hp0", float(boss.get("hp")))
	var t0 := _t
	while is_instance_valid(boss) and float(boss.get("hp")) > 0.0 and _t < t0 + BOSS_DEADLINE_SEC:
		await get_tree().physics_frame
		weapon.fire(from, aim)
	_report("boss_ttk_s", _t - t0)
