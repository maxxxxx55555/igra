extends RefCounted
## Session 28 (the masterpiece pass, docs/DIFFICULTY_INTENT.md). D1: TEL1 to TEL7, every attack that can hurt the player is announced by a cue (a flash and a sound) 0.35 s or more before the hit lands, from the Shadow
## and the Watcher that struck at once to the windups of the Crawler, the Hunter and the Brute and the third phase of the Architect (its melee and its falling beams), and no monster reaches further than it sees;
## DIF1 to DIF3, the most one hit takes follows the difficulty and the New Game+ level (12 at Normal, 15 at Hard, the enemy damage bonus of a level scales it: the 15 % a level had been cut away by the cap), and a
## monster's hit points and damage follow the difficulty, so Hard takes longer to kill and kills in fewer hits; ESC1, no spawn point of any district lies within 12 m of the arrival crossroads and each has a streetlight
## pole within 20 m; RET1, a respawn never leaves the flashlight below one battery. Wired into _closeout_check_runner.gd as `await Rc28.run(self)`; CLOSEOUT_ONLY=s28 runs it alone, which
## tools/qa_sim/s26_mutations.py uses (its fifth set, one mutation per check).

const _Density := preload("res://scripts/tools/rc16/density_checks.gd")
const _WorldRuntime := preload("res://scripts/world/world_runtime.gd")
const State := BaseMonster.State
const _FAR := Vector3(-600.0, 0.0, 600.0)
const MIN_CUE_MS: int = 350
const MIN_WINDUP: float = 0.4
const MIN_FALL_SEC: float = 0.7
const ARRIVAL_CLEAR: float = 12.0
const LAMP_REACH: float = 20.0
const WARNED: Array[String] = ["shadow_3d", "watcher_3d", "destroyer_3d", "rotter_3d", "hound_3d", "burner_3d", "sharpshooter_3d"]
## A stand-in for the player that notes the first hit it takes: the monsters ask for take_damage and nothing else.
const _VICTIM_SRC: String = "extends Node3D\nvar hit_msec: int = -1\nfunc take_damage(_amount: float = 0.0, _from: Vector3 = Vector3.ZERO) -> void:\n\tif hit_msec < 0:\n\t\thit_msec = Time.get_ticks_msec()\n"
const _GEAR_SRC: String = "extends Node3D\nvar hp: float = 100.0\nvar battery: float = 100.0\nvar battery_max: float = 100.0\nvar stats: Resource = null\n"

static func run(r: Node) -> void:
	r._playing()
	UIManager.close_all_blocking()
	await _telegraphs(r)
	_hit_cap(r)
	_monster_scale(r)
	await _escape(r)
	_respawn(r)
	r._playing()

static func _stand_in(r: Node, source: String, at: Vector3) -> Node3D:
	var script := GDScript.new()
	script.source_code = source
	script.reload()
	var node := Node3D.new()
	node.set_script(script)
	r.add_child(node)
	node.global_position = at
	return node

## A monster of a kind and a stand-in victim a step from it. The monster is kept awake: the Hunter, the Watcher and the Destroyer switch themselves off out of the camera's view and beyond
## wake_m of the player (scripts/components/visibility_enabler.gd, TZ_DECISIONS VIS-enabler), and these sit in the far corner of the world, so their enabler is taken off (WAKE1 holds it).
static func _pair(r: Node, kind: String, at: Vector3, step: float) -> Array[Node3D]:
	var monster: Node3D = r._monster(kind, at)
	var victim: Node3D = _stand_in(r, _VICTIM_SRC, at + Vector3(step, 0.0, 0.0))
	var enabler: Node = monster.get_node_or_null("VisibilityEnabler")
	if enabler != null:
		enabler.free()
	monster.process_mode = Node.PROCESS_MODE_INHERIT
	monster.set("player_ref", victim)
	monster.set("attack_timer", 0.0)
	var pair: Array[Node3D] = [monster, victim]
	return pair

## TEL1: the attacks that go through the telegraph (the Shadow, the Watcher and the Destroyer used to hit at once) wait 0.35 s or more between the cue and the hit. TEL2: the windups of the Crawler, the Hunter and
## the Brute carry the cue at their start and last 0.4 s or more. TEL3 to TEL6: the third phase of the Architect swings after a cue and then cools down, sends a cue with every beam, marks the place a beam lands with a
## ring of ember, and lets the beam fall for 0.7 s or more. TEL7: the attack range of every monster is inside its sight (the Watcher struck from 18 m and saw 12).
static func _telegraphs(r: Node) -> void:
	var monsters: Array[Node3D] = []
	var victims: Array[Node3D] = []
	for i in WARNED.size():
		var pair: Array[Node3D] = _pair(r, WARNED[i], _FAR + Vector3(float(i) * 40.0, 0.0, 0.0), 8.0 if WARNED[i] == "sharpshooter_3d" else 0.8)
		monsters.append(pair[0])
		victims.append(pair[1])
	var windups: Array[Node3D] = []
	for kind: String in ["crawler_3d", "hunter_3d", "brute_3d"]:
		windups.append(_pair(r, kind, _FAR + Vector3(float(windups.size()) * 40.0, 0.0, 80.0), 0.8)[0])
	var boss_pair: Array[Node3D] = _pair(r, "boss_architect_3d", _FAR + Vector3(0.0, 0.0, 160.0), 0.8)
	var boss: Node3D = boss_pair[0]
	var boss_victim: Node3D = boss_pair[1]
	var boss_telegraph: Node = boss.get("_telegraph")
	boss.set("_music_started", true)
	boss.set("phase", 2)
	# The tween of a cue is credited the whole frame it starts in: the attacks begin after the frames that built the scenes are over.
	for _settle in 3:
		await r.get_tree().process_frame
	for monster: Node3D in monsters:
		monster.call("_state_attack", 0.0)
	for monster: Node3D in windups:
		monster.call("_change_state", State.CHASE)
		monster.call("_tick_ai" if monster.get("monster_id") == &"crawler" else "_state_chase", 0.016)
	boss.call("_tick_p3", 0.016)
	var cooling: bool = float(boss.get("attack_timer")) > 0.0
	var melee_cue: int = int(boss_telegraph.get("last_cue_msec"))
	boss_telegraph.set("last_cue_msec", -1)
	boss.call("_spawn_falling_beam")
	var beam_cue: int = int(boss_telegraph.get("last_cue_msec"))
	await r.get_tree().create_timer(0.8).timeout
	var gaps: Array[int] = []
	var announced: int = 0
	for i in monsters.size():
		var cue_msec: int = int((monsters[i].get("_telegraph") as Node).get("last_cue_msec"))
		var hit_msec: int = int(victims[i].get("hit_msec"))
		var gap: int = hit_msec - cue_msec if cue_msec >= 0 and hit_msec >= 0 else -1
		gaps.append(gap)
		announced += 1 if gap >= MIN_CUE_MS else 0
	var windup_times: Array[float] = [float(windups[0].get("_leap_windup")), float(windups[1].get("_charge_windup")), float(windups[2].get("_windup_timer"))]
	var windup_cues: int = 0
	for monster: Node3D in windups:
		windup_cues += 1 if int((monster.get("_telegraph") as Node).get("last_cue_msec")) >= 0 else 0
	var melee_hit: int = int(boss_victim.get("hit_msec"))
	var melee_gap: int = melee_hit - melee_cue if melee_cue >= 0 and melee_hit >= 0 else -1
	var rings: int = 0
	for node: Node in r.get_tree().current_scene.get_children():
		var ring := node as MeshInstance3D
		if ring != null and ring.mesh is CylinderMesh and is_equal_approx((ring.mesh as CylinderMesh).height, 0.02):
			rings += 1
	var fall_sec: float = 11.2 / BossMonster.BEAM_FALL_SPEED
	var blind: Array[String] = []
	for monster: Node3D in monsters + windups:
		var sight: float = maxf(float(monster.get("vision_range")), float(monster.get("detect_range")))
		if float(monster.get("attack_range")) > sight:
			blind.append("%s %.0f of %.0f m" % [monster.get("monster_id"), float(monster.get("attack_range")), sight])
	for node: Node in r.get_tree().get_nodes_in_group("boss_hazard"):
		node.queue_free()
	for group: Array[Node3D] in [monsters, windups]:
		for node: Node3D in group:
			node.queue_free()
	boss.queue_free()
	await r.get_tree().process_frame
	r._ok(announced == WARNED.size(), "TEL1 telegraphs: %d of %d attacks wait %d ms or more after the cue (gaps %s ms)" % [announced, WARNED.size(), MIN_CUE_MS, gaps])
	r._ok(windup_cues == 3 and windup_times.min() >= MIN_WINDUP, "TEL2 windups: %d of 3 (Crawler, Hunter, Brute) carry the cue at their start and last %s s (%.1f s at least)" % [windup_cues, windup_times, MIN_WINDUP])
	r._ok(melee_gap >= MIN_CUE_MS and cooling, "TEL3 architect melee: the swing waits %d ms after its cue (%d ms at least) and starts a cooldown (%s)" % [melee_gap, MIN_CUE_MS, cooling])
	r._ok(rings == 1, "TEL4 beam ring: %d ring of ember marks the place a falling beam lands for as long as it falls (1 wanted)" % rings)
	r._ok(beam_cue >= 0, "TEL5 beam cue: the Architect's flash and sound go off when a beam is sent (%s)" % [beam_cue >= 0])
	r._ok(fall_sec >= MIN_FALL_SEC, "TEL6 beam fall: a beam takes %.2f s to land (%.1f s at least)" % [fall_sec, MIN_FALL_SEC])
	r._ok(blind.is_empty(), "TEL7 reach: no monster attacks from further than it sees; out of bounds: %s" % [blind])

## DIF1: one hit of 100 takes 8 HP at Easy (12 over the 1.5 of its health), 12 at Normal and 15 at Hard. DIF3: the enemy damage of New Game+ level 2 (x1.3) scales the cap, 15.6 at Normal.
static func _hit_cap(r: Node) -> void:
	var by_level: Array[float] = []
	for level in 3:
		by_level.append(_taken(r._player, level, 0))
	var new_game_plus: float = _taken(r._player, 1, 2)
	SettingsManager.set_difficulty(1)
	r._ok(by_level == [8.0, 12.0, 15.0], "DIF1 hit cap: a hit of 100 takes %s HP at Easy, Normal and Hard (8, 12 and 15 wanted)" % [by_level])
	r._ok(is_equal_approx(new_game_plus, 15.6), "DIF3 hit cap at New Game+: a hit of 100 takes %.2f HP at Normal and level 2 (15.6 wanted: the enemy damage bonus of the level scales the cap)" % new_game_plus)

static func _taken(player: Node3D, difficulty: int, ng_level: int) -> float:
	var saved_level: int = int(NewGamePlus.get("_current_ng_plus"))
	var saved_hp: float = float(player.get("hp"))
	var max_hp: float = float((player.get("stats") as Resource).get("max_hp"))
	SettingsManager.set_difficulty(difficulty)
	NewGamePlus.set("_current_ng_plus", ng_level)
	player.set("hp", max_hp)
	player.set("_damage_grace_timer", 0.0)
	player.set("_iframes", 0.0)
	player.call("take_damage", 100.0)
	var lost: float = snappedf(max_hp - float(player.get("hp")), 0.01)
	NewGamePlus.set("_current_ng_plus", saved_level)
	player.set("hp", saved_hp)
	player.set("_damage_grace_timer", 0.0)
	return lost

## DIF2: a Crawler has 0.7, 1 and 1.3 times its hit points and 0.75, 1 and 1.25 times its damage at Easy, Normal and Hard, so Hard takes longer to kill and kills in fewer hits (balance_sim section 8 holds the rest).
static func _monster_scale(r: Node) -> void:
	var hp_of: Array[float] = []
	var damage_of: Array[float] = []
	for level in 3:
		SettingsManager.set_difficulty(level)
		var monster: Node3D = r._monster("crawler_3d", _FAR + Vector3(0.0, 0.0, 240.0))
		hp_of.append(float(monster.get("max_hp")))
		damage_of.append(float(monster.get("attack_damage")))
		monster.queue_free()
	SettingsManager.set_difficulty(1)
	var scaled: bool = is_equal_approx(hp_of[0] / hp_of[1], 0.7) and is_equal_approx(hp_of[2] / hp_of[1], 1.3) and is_equal_approx(damage_of[0] / damage_of[1], 0.75) and is_equal_approx(damage_of[2] / damage_of[1], 1.25)
	r._ok(scaled, "DIF2 monster scale: a Crawler has %s hit points and hits for %s at Easy, Normal and Hard (0.7 and 1.3 times the hit points, 0.75 and 1.25 times the damage wanted)" % [hp_of, damage_of])

## ESC1: the 6 spawn points of an enemy pool lie 12 m or more from the arrival crossroads of every district (the first had stood 4.5 m from it) and each has a streetlight pole within 20 m (the poles of the
## batched node, as the density audit counts them).
static func _escape(r: Node) -> void:
	var arrival: Vector3 = _WorldRuntime.PLAYER_SPAWN_POS
	var nearest: float = INF
	var farthest: float = 0.0
	var short: Array[String] = []
	for id: StringName in DistrictSceneFactory.DISTRICTS:
		var root: Node3D = await _Density._build(r, id)
		var lamps: Array[Vector3] = _lamp_spots(root.get_node("Props"))
		for offset: Vector3 in EnemyPool.DEFAULT_SPAWN_OFFSETS:
			var from_arrival: float = Vector2(offset.x - arrival.x, offset.z - arrival.z).length()
			var to_lamp: float = INF
			for spot: Vector3 in lamps:
				to_lamp = minf(to_lamp, Vector2(offset.x - spot.x, offset.z - spot.z).length())
			nearest = minf(nearest, from_arrival)
			farthest = maxf(farthest, to_lamp)
			if from_arrival < ARRIVAL_CLEAR or to_lamp > LAMP_REACH:
				short.append("%s %s" % [id, offset])
		root.queue_free()
		await r.get_tree().process_frame
	r._ok(short.is_empty(), "ESC1 escape: the spawn points of all %d districts are %.1f m or more from the arrival crossroads (%d m wanted) and %.1f m or less from a streetlight pole (%d m wanted); out of bounds: %s" % [
		DistrictSceneFactory.DISTRICTS.size(), nearest, int(ARRIVAL_CLEAR), farthest, int(LAMP_REACH), short])

static func _lamp_spots(props: Node) -> Array[Vector3]:
	var spots: Array[Vector3] = []
	var poles := props.get_node_or_null("StreetlightPolesBatched") as MultiMeshInstance3D
	if poles == null:
		return spots
	for spot: Variant in poles.get_meta("spots", []):
		spots.append((spot as Transform3D).origin if spot is Transform3D else spot as Vector3)
	return spots

## RET1: a respawn gives half the health and a battery of at least 25 whatever the battery was at the death (0 and 10 come back as 25, 70 stays 70), and leaves a player that was not respawned alone.
static func _respawn(r: Node) -> void:
	var gear: Node3D = _stand_in(r, _GEAR_SRC, _FAR)
	var batteries: Array[float] = []
	for died_with: float in [0.0, 10.0, 70.0]:
		gear.set("hp", 100.0)
		gear.set("battery", 100.0)
		GameManager.set("_respawn_battery", died_with)
		GameManager.apply_pending_respawn(gear)
		batteries.append(float(gear.get("battery")))
	var half: bool = is_equal_approx(float(gear.get("hp")), 50.0)
	gear.set("hp", 100.0)
	gear.set("battery", 100.0)
	GameManager.set("_respawn_battery", -1.0)
	GameManager.apply_pending_respawn(gear)
	var untouched: bool = is_equal_approx(float(gear.get("hp")), 100.0) and is_equal_approx(float(gear.get("battery")), 100.0)
	gear.queue_free()
	r._ok(batteries == [25.0, 25.0, 70.0] and half and untouched, "RET1 respawn: the battery comes back as %s after a death with 0, 10 and 70 (25, 25 and 70 wanted), health %s, a player that was not respawned is untouched (%s)" % [batteries, half, untouched])
