extends RefCounted
## Session 23 (docs/AI_STEALTH.md): the thrown distraction, the group alert, the search at the last place the player was, the difficulty hooks of the AI and the
## glide of the HUD's noise and visibility bars. Wired into _closeout_check_runner.gd as `await Rc23Ai.run(self)`; CLOSEOUT_ONLY=s23 runs it with the others.
## The monsters stand in the far corner of the world with their own AI stopped (runner `_monster`): the handlers of the signals they hear still run.

const _Bomb := preload("res://scripts/gameplay/noise_bomb.gd")
const _Hud := preload("res://scripts/ui/hud_3d.gd")
const State := BaseMonster.State
const FLOOR_SIZE: float = 80.0

static func run(r: Node) -> void:
	r._playing()
	UIManager.close_all_blocking()
	await _noise_bomb(r)
	_group_alert(r)
	_last_seen(r)
	_difficulty_hooks(r)
	await _bars_glide(r)
	SettingsManager.set_difficulty(1)
	r._playing()

## AI1: a thrown bomb pops where it lands and sends the monsters in earshot that have not seen the player to the spot; those beyond it stay.
static func _noise_bomb(r: Node) -> void:
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(FLOOR_SIZE, 0.2, FLOOR_SIZE)
	floor_shape.shape = box
	floor_body.add_child(floor_shape)
	r.add_child(floor_body)
	var origin: Vector3 = Vector3(-500.0, -0.1, -500.0)
	floor_body.global_position = origin
	var ear: Node3D = r._monster("crawler_3d", origin + Vector3(14.0, 0.1, 0.0))
	var far: Node3D = r._monster("crawler_3d", origin + Vector3(36.0, 0.1, 0.0))
	for monster: Node3D in [ear, far]:
		monster.call("_change_state", State.IDLE)
	var bomb: RigidBody3D = _Bomb.new()
	r.add_child(bomb)
	bomb.call("launch", origin + Vector3(0.0, 1.5, 0.0), Vector3(0.0, -0.3, 0.0))
	for i in 90:
		await r.get_tree().physics_frame
	var popped: bool = not is_instance_valid(bomb)
	var heard: bool = int(ear.get("ai_state")) == State.INVESTIGATE and (ear.get("_investigate_point") as Vector3).distance_to(origin) < 3.0
	var stayed: bool = int(far.get("ai_state")) == State.IDLE
	for node: Node in [ear, far, floor_body]:
		node.queue_free()
	r._ok(popped and heard and stayed, "AI1 noise bomb: it popped on landing (%s), the monster 14 m away goes to look at the spot (%s), the one 36 m away, beyond the radius of %.0f m, stays (%s)" % [popped, heard, _Bomb.NOISE_RADIUS, stayed])

## AI2: a monster that sees the player calls the neighbours within 8 m (a hound within 15 m); one already chasing and one beyond the range do not move.
static func _group_alert(r: Node) -> void:
	var origin: Vector3 = Vector3(-300.0, 0.0, 300.0)
	var caller: Node3D = r._monster("crawler_3d", origin)
	var near: Node3D = r._monster("crawler_3d", origin + Vector3(6.0, 0.0, 0.0))
	var far: Node3D = r._monster("crawler_3d", origin + Vector3(30.0, 0.0, 0.0))
	var chasing: Node3D = r._monster("crawler_3d", origin + Vector3(4.0, 0.0, 4.0))
	for monster: Node3D in [caller, near, far, chasing]:
		monster.call("_change_state", State.IDLE)
	chasing.call("_change_state", State.CHASE)
	near.call("_change_state", State.IDLE)
	far.call("_change_state", State.IDLE)
	caller.call("_change_state", State.CHASE)
	var neighbours: bool = int(near.get("ai_state")) == State.INVESTIGATE
	var beyond: bool = int(far.get("ai_state")) == State.IDLE
	var held: bool = int(chasing.get("ai_state")) == State.CHASE
	var hound: Node3D = r._monster("hound_3d", origin + Vector3(0.0, 0.0, 100.0))
	var pack: Node3D = r._monster("crawler_3d", origin + Vector3(0.0, 0.0, 112.0))
	for monster: Node3D in [hound, pack]:
		monster.call("_change_state", State.IDLE)
	hound.call("_change_state", State.CHASE)
	var pack_call: bool = int(pack.get("ai_state")) == State.INVESTIGATE  # 12 m: a hound calls 15 m, a crawler would not
	for node: Node in [caller, near, far, chasing, hound, pack]:
		node.queue_free()
	r._ok(neighbours and beyond and held and pack_call, "AI2 group alert: the neighbour 6 m away goes to look (%s), the one 30 m away stays (%s), one already chasing keeps chasing (%s), a hound's call reaches 12 m (%s)" % [neighbours, beyond, held, pack_call])

## AI3: a monster that loses the chased player (it leaves the detect area) searches the place it was last, for the search time, and goes back to the patrol after it.
static func _last_seen(r: Node) -> void:
	var player: Node3D = r._player
	var monster: Node3D = r._monster("crawler_3d", Vector3(-300.0, 0.0, -300.0))
	monster.call("_change_state", State.CHASE)
	monster.call("_on_detect_body_exited", player)
	var searching: bool = int(monster.get("ai_state")) == State.INVESTIGATE
	var point_ok: bool = (monster.get("_investigate_point") as Vector3).distance_to(player.global_position) < 0.01
	var time_ok: bool = absf(float(monster.get("_investigate_timer")) - float(BaseMonster.SEARCH_TIME)) < 0.01
	monster.queue_free()
	r._ok(searching and point_ok and time_ok, "AI3 last known place: leaving the detect area while chased starts a search (%s) at the player's last place (%s) for %.0f s (%s)" % [searching, point_ok, BaseMonster.SEARCH_TIME, time_ok])

## AI4: the difficulty hooks: the search lasts 7, 10 and 13 s; on Easy a monster stands 0.5 s noticing before it chases (not on Normal or Hard), and does not move meanwhile.
static func _difficulty_hooks(r: Node) -> void:
	var searches: Array[float] = []
	var reacts: Array[float] = []
	var held: bool = false
	for level: int in 3:
		SettingsManager.set_difficulty(level)
		var monster: Node3D = r._monster("crawler_3d", Vector3(-300.0, 0.0, -400.0))
		monster.call("_change_state", State.IDLE)
		monster.call("_change_state", State.CHASE)
		reacts.append(float(monster.get("_react_timer")))
		if level == 0:
			monster.set("velocity", Vector3(3.0, 0.0, 0.0))
			monster.call("_state_chase", 0.1)
			held = (monster.get("velocity") as Vector3) == Vector3.ZERO and is_equal_approx(float(monster.get("_react_timer")), 0.4)
		monster.call("_change_state", State.IDLE)
		monster.call("_enter_investigate_at", Vector3(-300.0, 0.0, -400.0))
		searches.append(float(monster.get("_investigate_timer")))
		monster.queue_free()
	SettingsManager.set_difficulty(1)
	var cold: bool = searches.size() == 3 and is_equal_approx(searches[0], 7.0) and is_equal_approx(searches[1], 10.0) and is_equal_approx(searches[2], 13.0)
	var react: bool = reacts == [0.5, 0.0, 0.0]
	r._ok(cold and react and held, "AI4 difficulty hooks: the search lasts %s s (7, 10, 13), the reaction time is %s s (0.5, 0, 0), an Easy monster stands still while it notices (%s)" % [searches, reacts, held])

## AI5: the noise and visibility bars glide to what the player's state asks for and shade between the colours: a jump of the state moves the bar 0.15 per poll,
## and a middle value has a middle colour.
static func _bars_glide(r: Node) -> void:
	var hud: Node = r._main.get_node("HUD")
	var player: Node3D = r._player
	var noise_fill := hud.get("noise_fill") as ColorRect
	var width: float = _Hud.BAR_W
	hud.set("_noise_shown", 0.0)
	var noise0: Variant = player.get("noise_level")
	player.set("noise_level", 0.8)
	var steps: Array[float] = []
	for i in 6:
		hud.call("_poll_noise_visibility")
		steps.append(noise_fill.offset_right / width)
	player.set("noise_level", noise0)
	var glides: bool = is_equal_approx(steps[0], 0.15) and steps[2] > steps[1] and steps[1] > steps[0]
	var middle: Color = hud.call("_pick_noise_color", 0.25)
	var calm: Color = hud.call("_pick_noise_color", 0.0)
	var warn: Color = hud.call("_pick_noise_color", 0.5)
	var shaded: bool = not middle.is_equal_approx(calm) and not middle.is_equal_approx(warn) and middle.g > calm.g - 0.001
	hud.set("_noise_shown", 0.0)
	r._ok(glides and shaded, "AI5 detection gradient: after a jump of the player's noise to 0.8 the bar is at %s of its width on the first six polls (it glides by 0.15), a value of 0.25 has a colour of its own %s between green and brass (%s)" % [steps, middle, shaded])
