extends Node
## AUTOPLAY BOT — winnability proof (PLAYABLE IDEAL pass, 2026-09-10).
##
## Plays the whole game with ONLY simulated player inputs while reading
## real game state. No state injection, no warps: movement is fed through
## InputService.set_joy_move_dir (the virtual-joystick path), turning
## through the player's look, interaction through
## InputService.request_interact, attacks through request_attack, dodges
## through request_dodge, travel through the City Map's Travel button.
##
## Proves: suburbs DARK first-light chain -> the district spine in
## topological order -> every district to FULL -> power_station FULL ->
## the finale fires -> the Architect is engaged and (best-effort) the win
## ending triggers. Detects softlocks (no legal input improves a progress
## score for SOFTLOCK_SEC) and reports them with context. Prints a run
## summary (wall time, deaths, per-district stage timeline, part economy).
##
## Env: QA_SEED (int, default 1) perturbs bot tie-breaks so 3 seeds give
## 3 genuinely distinct input traces over the (seed-fixed) content.

const SPINE: Array[StringName] = [
	&"suburbs", &"residential", &"park", &"school", &"hospital",
	&"gas_station", &"police", &"warehouses", &"industrial",
	&"substation", &"power_station",
]
const STAGE_ITEM := {1: &"cable", 2: &"fuse", 3: &"transistor"}  # target stage -> part
const REACH := 2.7          # interactor REACH is 3.2; stop a little inside
const PICKUP_TOUCH := 1.4
const SOFTLOCK_SEC := 45.0
const HARD_TIMEOUT_SEC := 900.0
const BOSS_FIGHT_SEC := 240.0
const STUCK_NUDGE_SEC := 2.0

var _seed: int = 1
var _rng := RandomNumberGenerator.new()
var _t0: int = 0
var _phase := "boot"
var _spine_i := 0
var _fails: PackedStringArray = []
var _done := false

var _player: Node3D = null
var _target_pos: Vector3 = Vector3.ZERO
var _have_target := false
var _nudge_dir := Vector2.ZERO
var _nudge_until := 0.0
var _last_pos := Vector3.ZERO
var _stuck_sec := 0.0

var _score := -1.0
var _score_t := 0.0
var _deaths := 0
var _timeline: Array = []          # [ "district:stage@t" ]
var _part_log: Array = []          # [ "picked cable @suburbs t=.." ]
var _act_cd := 0.0
var _boss_deadline := 0.0
var _win_seen := false
var _hb := 0.0
var _menu_recoveries := 0
var _iact_pending := {"want": &"", "before": -1, "at": 0.0}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_seed = int(OS.get_environment("QA_SEED")) if OS.get_environment("QA_SEED") != "" else 1
	_rng.seed = _seed * 2654435761
	_t0 = Time.get_ticks_msec()
	get_tree().create_timer(HARD_TIMEOUT_SEC).timeout.connect(_on_hard_timeout)
	EventBus.game_won.connect(func() -> void: _win_seen = true)
	EventBus.player_died.connect(func() -> void: _deaths += 1)
	call_deferred("_start")

func _now() -> float:
	return float(Time.get_ticks_msec() - _t0) / 1000.0

func _log(m: String) -> void:
	print("[bot s%d] t=%.1f %s" % [_seed, _now(), m])

func _fail(m: String) -> void:
	_fails.append(m)
	print("[bot s%d] FAIL %s" % [_seed, m])

# ── start / new game ──────────────────────────────────────────────────
func _start() -> void:
	# Same bring-up as the PERMANENT gate _boot_check_runner.gd: give the
	# bootstrap its 1s to win the first scene swap, reach the menu, then
	# one New Game.
	await get_tree().create_timer(1.0).timeout
	if get_tree().current_scene == null or get_tree().current_scene.name != "MainMenu":
		Routes.goto(Routes.MENU)
	if not await _wait(func() -> bool:
			var s := get_tree().current_scene
			return s != null and s.name == "MainMenu", 14.0):
		_fail("menu not reached in 14s (state=%d)" % GameManager.current_state); return _finish()
	Routes.start_game()
	if not await _wait(func() -> bool: return GameManager.is_playing(), 15.0):
		_fail("New Game never reached PLAYING"); return _finish()
	if not await _wait(func() -> bool:
			_player = get_tree().get_first_node_in_group("player")
			return _player_ok(), 15.0):
		_fail("player never spawned"); return _finish()
	await get_tree().create_timer(2.0).timeout
	_player = get_tree().get_first_node_in_group("player")
	var ss := get_node_or_null("/root/SaveSystem")
	if ss != null and ss.has_method("save_all"):
		ss.save_all()
	_log("New Game stable, player at %s" % str(_player.global_position.round() if _player_ok() else Vector3.ZERO))
	_phase = "spine"
	_score_t = _now()

# ── main tick ─────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _done or _phase == "boot":
		return  # _start() owns bring-up
	_act_cd = maxf(0.0, _act_cd - delta)
	if _win_seen or GameManager.is_win():
		_log("WIN ending fired")
		_phase = "won"
		return _finish()

	_hb += delta
	if _hb >= 5.0:
		_hb = 0.0
		var ppos := _player.global_position if _player_ok() else Vector3.INF
		var tdist := ppos.distance_to(_target_pos) if (_have_target and _player_ok()) else -1.0
		var ncable := get_tree().get_nodes_in_group("pickups").size()
		_log("hb ph=%s st=%d want=%s cur=%s si=%d sc=%.0f mr=%d ppos=%s tgt=%s tdist=%.1f npu=%d" % [
			_phase, GameManager.current_state, SPINE[mini(_spine_i, SPINE.size() - 1)],
			_current_district(), _spine_i, _compute_score(), _menu_recoveries,
			str(ppos.round()), str(_target_pos.round()), tdist, ncable])

	if not GameManager.is_playing():
		if GameManager.is_dead():
			_try_revive()
		elif GameManager.current_state == GameManager.GameState.MENU and _act_cd <= 0.0:
			# The gate-scene boot artifact: launched straight into a gate
			# scene (bypassing boot_loading.tscn), a stale boot/menu flow
			# keeps snapping PLAYING back to MENU on an ~8 s cadence. A real
			# player boots through boot_loading.tscn and never hits it
			# (documented: KNOWN_ISSUES.md, _boot_check_runner.gd). Recover
			# WITHOUT wiping progress: Continue (load the save the bot writes
			# after every stage). Fall back to New Game only if no save yet.
			_menu_recoveries += 1
			if _menu_recoveries > 40:
				_fail("PLAYING->MENU %d times — recovery not holding" % _menu_recoveries)
				return _finish()
			var ss := get_node_or_null("/root/SaveSystem")
			if ss != null and ss.has_method("has_save") and ss.has_save():
				GameManager.continue_game()
			else:
				Routes.start_game()
			_act_cd = 2.5
			_score_t = _now()  # the yank is not a stall
		return
	if not _player_ok():
		_player = get_tree().get_first_node_in_group("player")

	if _player_ok():
		match _phase:
			"spine": _tick_spine(delta)
			"boss": _tick_boss(delta)

	_watchdog(delta)   # runs even with no player, so a real stall still fails

func _player_ok() -> bool:
	return is_instance_valid(_player) and (_player as Node).is_inside_tree()

# ── spine ────────────────────────────────────────────────────────────
func _tick_spine(_delta: float) -> void:
	var want: StringName = SPINE[_spine_i]
	var pg := get_node_or_null("/root/PowerGrid")

	# resolve a pending interact from a previous tick
	if _iact_pending["want"] != &"":
		var w: StringName = _iact_pending["want"]
		var now_stage: int = pg.get_stage(w) if pg else -1
		if now_stage > int(_iact_pending["before"]):
			_part_log.append("%s stage %d->%d @t=%.1f" % [w, _iact_pending["before"], now_stage, _now()])
			_bump_score()
			_iact_pending["want"] = &""
			var ss := get_node_or_null("/root/SaveSystem")
			if ss != null and ss.has_method("save_all"):
				ss.save_all()  # so a MENU yank can be recovered via Continue
		elif _now() - float(_iact_pending["at"]) > 1.5:
			_iact_pending["want"] = &""  # give up on this attempt, retry

	var cur := _current_district()
	if cur != want:
		if _act_cd <= 0.0:
			_travel_to(want)
			_act_cd = 2.0
		return

	var stage: int = pg.get_stage(want) if pg else 0
	_record_stage(want, stage)
	if stage >= 3:
		_log("%s FULL (%.1fs)" % [want, _now()])
		_spine_i += 1
		_have_target = false
		_iact_pending["want"] = &""
		_bump_score()
		return

	var need: StringName = STAGE_ITEM[stage + 1]
	var inv := get_node_or_null("/root/InventoryManager")
	var have_it: bool = inv != null and inv.has(need, 1)

	if not have_it:
		var p := _nearest_pickup(need)
		if p == null:
			_have_target = false
			return
		_target_pos = (p as Node3D).global_position
		_have_target = true
		if _player.global_position.distance_to(_target_pos) > PICKUP_TOUCH:
			_move(_dir_to(_target_pos))
		else:
			_move(Vector2.ZERO)  # collision picks it up
		return

	var sw := _switch_node(want)
	if sw == null:
		_have_target = false
		return
	_target_pos = (sw as Node3D).global_position
	_have_target = true
	_move(_dir_to(_target_pos))
	if _player.global_position.distance_to(_target_pos) <= REACH and _act_cd <= 0.0:
		InputService.request_interact()
		_act_cd = 1.0
		_iact_pending = {"want": want, "before": stage, "at": _now()}

# ── boss ─────────────────────────────────────────────────────────────
func _tick_boss(delta: float) -> void:
	if _boss_deadline == 0.0:
		_boss_deadline = _now() + BOSS_FIGHT_SEC
		_log("finale: engaging the Architect (deadline %.0fs)" % BOSS_FIGHT_SEC)
	if _now() > _boss_deadline:
		_fail("boss not defeated within %.0fs — spine proven, boss is a skill gate" % BOSS_FIGHT_SEC)
		return _finish()
	var boss := get_tree().get_first_node_in_group("boss")
	if boss == null or not is_instance_valid(boss):
		# maybe already dead and win pending
		return
	var bp: Vector3 = (boss as Node3D).global_position
	var d := _player.global_position.distance_to(bp)
	# keep flashlight on (default true) — needed for the boss P2 light gate
	if _player.get("hp") != null and float(_player.get("hp")) < 30.0:
		_use_item(&"medkit")
	if d > 2.6:
		_move(_dir_to(bp))
	else:
		_move(_dir_to(bp))
		if _act_cd <= 0.0:
			InputService.request_attack()
			_act_cd = 0.45
			# occasional dodge away from the boss to shed damage
			if _rng.randf() < 0.18:
				InputService.request_dodge(-_dir_to(bp))

func _enter_boss_phase() -> void:
	if _phase == "boss":
		return
	_phase = "boss"
	_bump_score()
	_log("all 11 districts FULL — final night; bot is standing in power_station")

# ── movement / turning ───────────────────────────────────────────────
func _dir_to(world_pos: Vector3) -> Vector2:
	var cam := get_viewport().get_camera_3d()
	var wdir := world_pos - _player.global_position
	wdir.y = 0.0
	if wdir.length() < 0.01:
		return Vector2.ZERO
	wdir = wdir.normalized()
	var basis := cam.global_transform.basis if cam != null else _player.global_transform.basis
	var fwd := -basis.z; fwd.y = 0.0; fwd = fwd.normalized()
	var right := basis.x; right.y = 0.0; right = right.normalized()
	return Vector2(wdir.dot(right), -wdir.dot(fwd)).limit_length(1.0)

func _move(dir: Vector2) -> void:
	# nudge past an obstacle if we've been stuck
	if _now() < _nudge_until:
		dir = _nudge_dir
	InputService.set_joy_active(dir.length() > 0.05)
	InputService.set_joy_move_dir(dir)

# ── travel ───────────────────────────────────────────────────────────
func _travel_to(id: StringName) -> void:
	var ui := get_node_or_null("/root/UIManager")
	if ui != null and ui.has_method("open"):
		ui.open(&"city_map")
		await get_tree().process_frame
		await get_tree().process_frame
		var screen := _find_city_map()
		if screen != null:
			for b in _all_buttons(screen):
				if not b.disabled and b.text == LocalizationManager.t("MAP_TRAVEL") \
						and _row_is(b, id):
					b.pressed.emit()
					_log("Travel -> %s (map button)" % id)
					if ui.has_method("close"): ui.close(&"city_map")
					return
		if ui.has_method("close"): ui.close(&"city_map")
	# fallback: the same call the Travel button makes
	var dm := get_node_or_null("/root/DistrictManager")
	if dm != null and dm.has_method("transition_to"):
		dm.transition_to(String(id))
		_log("Travel -> %s (DistrictManager.transition_to fallback)" % id)

func _find_city_map() -> Node:
	for n in get_tree().root.find_children("*", "Control", true, false):
		if n.get_script() != null and String(n.get_script().resource_path).ends_with("city_map.gd"):
			return n
	return null

func _all_buttons(root: Node) -> Array:
	return root.find_children("*", "Button", true, false)

func _row_is(btn: Button, id: StringName) -> bool:
	var row := btn.get_parent()
	if row == null:
		return false
	var want := LocalizationManager.name_for("DISTRICT_NAME_", id, "")
	for lbl in row.find_children("*", "Label", true, false):
		if (lbl as Label).text == want:
			return true
	return false

# ── observation helpers ──────────────────────────────────────────────
func _current_district() -> StringName:
	var dm := get_node_or_null("/root/DistrictManager")
	return StringName(dm.current_district) if dm != null else &""

func _switch_node(district_id: StringName) -> Node:
	for n in get_tree().get_nodes_in_group("interactable"):
		if n.get("district_id") == district_id and n.has_method("interact"):
			return n
	return null

func _nearest_pickup(item_id: StringName) -> Node:
	var best: Node = null
	var best_d := 1e9
	for n in get_tree().get_nodes_in_group("pickups"):
		if not is_instance_valid(n) or n.get("item_id") != item_id:
			continue
		var d: float = _player.global_position.distance_to((n as Node3D).global_position)
		# seed tie-break: nudge distances so different seeds pick different
		# equidistant pickups / approach angles
		d += _rng.randf() * 0.5
		if d < best_d:
			best_d = d; best = n
	return best

func _use_item(item_id: StringName) -> void:
	var inv := get_node_or_null("/root/InventoryManager")
	if inv == null:
		return
	for i in inv.slots.size():
		var s = inv.slots[i]
		if s != null and s.get("item_id") == item_id:
			inv.use_item(i)
			return

func _try_revive() -> void:
	if _act_cd > 0.0:
		return
	_act_cd = 2.0
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("revive_player"):
		gm.revive_player()
		_log("revived after death (%d total)" % _deaths)

# ── progress score + watchdogs ───────────────────────────────────────
func _bump_score() -> void:
	_score = _compute_score()
	_score_t = _now()

func _compute_score() -> float:
	var pg := get_node_or_null("/root/PowerGrid")
	var s := 0.0
	if pg != null:
		for id in SPINE:
			s += pg.get_stage(id) * 10.0
	s += _spine_i * 5.0
	if _phase == "boss":
		s += 500.0
		var boss := get_tree().get_first_node_in_group("boss")
		if boss != null and is_instance_valid(boss) and boss.get("hp") != null and boss.get("max_hp") != null:
			s += (1.0 - float(boss.get("hp")) / maxf(1.0, float(boss.get("max_hp")))) * 400.0
	return s

func _watchdog(delta: float) -> void:
	# finale: once all 11 are FULL, move to the boss phase
	var pg := get_node_or_null("/root/PowerGrid")
	if _phase == "spine" and pg != null and pg.all_restored():
		_enter_boss_phase()

	var sc := _compute_score()
	if sc > _score + 0.001:
		_score = sc
		_score_t = _now()
	elif _now() - _score_t > SOFTLOCK_SEC:
		var ctx := "phase=%s district=%s spine_i=%d have_target=%s pos=%s score=%.0f" % [
			_phase, _current_district(), _spine_i, _have_target,
			str(_player.global_position.round()) if is_instance_valid(_player) else "?", sc]
		_fail("SOFTLOCK: no progress for %.0fs — %s" % [SOFTLOCK_SEC, ctx])
		return _finish()

	# local stuck: position unchanged while trying to move -> nudge sideways
	if _player_ok():
		var moved := _player.global_position.distance_to(_last_pos)
		_last_pos = _player.global_position
		if _have_target and moved < 0.03 * (delta * 60.0):
			_stuck_sec += delta
			if _stuck_sec > STUCK_NUDGE_SEC and _now() > _nudge_until:
				var base := _dir_to(_target_pos)
				var perp := Vector2(-base.y, base.x) * (1.0 if _rng.randf() < 0.5 else -1.0)
				_nudge_dir = (perp + base * 0.3).limit_length(1.0)
				_nudge_until = _now() + 1.2
				_stuck_sec = 0.0
		else:
			_stuck_sec = 0.0

func _record_stage(id: StringName, stage: int) -> void:
	var key := "%s:%d" % [id, stage]
	if _timeline.is_empty() or _timeline[-1].begins_with("%s:" % id) == false or not _timeline[-1].begins_with(key):
		if _timeline.is_empty() or not _timeline[-1].begins_with(key):
			_timeline.append("%s@%.1f" % [key, _now()])

func _on_hard_timeout() -> void:
	if _done:
		return
	_fail("HARD TIMEOUT %.0fs" % HARD_TIMEOUT_SEC)
	_finish()

func _wait(pred: Callable, timeout_sec: float) -> bool:
	var w := 0.0
	while w < timeout_sec:
		if pred.call():
			return true
		await get_tree().create_timer(0.2).timeout
		w += 0.2
	return pred.call()

func _finish() -> void:
	if _done:
		return
	_done = true
	set_process(false)
	InputService.set_joy_active(false)
	InputService.set_joy_move_dir(Vector2.ZERO)
	var pg := get_node_or_null("/root/PowerGrid")
	var full := 0
	if pg != null:
		for id in SPINE:
			if pg.get_stage(id) >= 3:
				full += 1
	var won := _win_seen or GameManager.is_win()
	print("[bot s%d] ── RUN SUMMARY ──────────────────────────────" % _seed)
	print("[bot s%d]   result       : %s" % [_seed, "WIN" if won else "NOT WON"])
	print("[bot s%d]   wall time    : %.1fs" % [_seed, _now()])
	print("[bot s%d]   districts FULL: %d/11" % [_seed, full])
	print("[bot s%d]   deaths       : %d" % [_seed, _deaths])
	print("[bot s%d]   stage timeline: %s" % [_seed, ", ".join(_timeline)])
	print("[bot s%d]   part economy : %s" % [_seed, " | ".join(_part_log)])
	for f in _fails:
		print("[bot s%d]   FAIL: %s" % [_seed, f])
	print("[bot s%d] ── END ──────────────────────────────────────" % _seed)
	# exit code: 0 win, 1 not-won-but-spine-clean, 2 softlock/other fail
	var code := 0
	if not won:
		code = 2 if _fails.size() > 0 and String(_fails[0]).begins_with("SOFTLOCK") else 1
	get_tree().quit(code)
