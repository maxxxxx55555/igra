extends RefCounted
## Session 29 (the v1.0.0-ship pass, .qa_logs/WORKQUEUE.tsv). A block, the procedural body of the monsters (scripts/enemies/monster_rig.gd, monster_looks.gd):
## ANIM1 each of the 12 monster scenes builds the rig (Torso, BodyMesh, HeadMesh, _update_anim) and has a look and a gait row, and no row is missing for a data/monsters id (A1, A3, C7);
## ANIM2 the legs swing with the speed, the two sides in opposite phase, and stand still at rest (A2); ANIM3 twenty kills count twenty, a second hit on a falling body counts nothing and every body
## lies down (A6); ANIM4 the windup of an attack draws the arm back for 0.4 s, strikes and recovers (A4); ANIM5 the head follows an aware monster's player within 0.7 rad at 6 rad/s or less and
## faces forward in a chase (A7); ANIM6 a hit pushes the body back by 0.08 m or less and it returns, a heavy hit delays the next attack (A5); ANIM7 the feet of every monster stand on the floor
## of its capsule (A2); ANIM8 the arachnophobia mode swaps the crawler for its blob (C7). Wired into _closeout_check_runner.gd as `await Rc29.run(self)`; CLOSEOUT_ONLY=s29 runs it alone.

const _Looks := preload("res://scripts/enemies/monster_looks.gd")
const _Rig := preload("res://scripts/enemies/monster_rig.gd")
const State := BaseMonster.State
const _FAR := Vector3(-600.0, 0.0, 600.0)
const _SCENES: Array[String] = ["rotter_3d", "crawler_3d", "hound_3d", "hunter_3d", "brute_3d", "shadow_3d", "watcher_3d", "burner_3d", "sharpshooter_3d", "tvar_3d", "destroyer_3d", "boss_architect_3d"]

static func run(r: Node) -> void:
	r._playing()
	UIManager.close_all_blocking()
	if _built(r):
		_gait(r)
		_kills(r)
		_windup(r)
		_head(r)
		_flinch(r)
		_feet(r)
		_arachnophobia(r)
	else:
		for id: String in ["ANIM2", "ANIM3", "ANIM4", "ANIM5", "ANIM6", "ANIM7", "ANIM8"]:
			r._ok(false, "%s there is no rig to test (ANIM1 failed)" % id)
	r._playing()

static func _spot(i: int, z: float = 0.0) -> Vector3:
	return _FAR + Vector3(float(i % 6) * 12.0, 0.0, z + float(i / 6) * 12.0)

static func _step(m: Node3D, frames: int, dt: float) -> void:
	for _i in frames:
		m.call("_update_anim", dt)

static func _built(r: Node) -> bool:
	var missing: Array[String] = []
	for i in _SCENES.size():
		var m: Node3D = r._monster(_SCENES[i], _spot(i))
		var id: StringName = m.get("monster_id")
		var parts: bool = m.get_node_or_null("VisualRoot/Torso/BodyMesh") != null and m.get_node_or_null("VisualRoot/Torso/HeadMesh") != null
		if not (m.has_method("_update_anim") and parts and _Looks.LOOKS.has(id)):
			missing.append(String(id))
		m.queue_free()
	r._ok(missing.is_empty(), "ANIM1 the 12 monster scenes build the rig and have a look (missing: %s)" % [missing])
	var no_row: Array[String] = []
	var rows: int = 0
	for file in DirAccess.get_files_at("res://data/monsters"):
		if file.ends_with(".tres"):
			rows += 1
			var data: Resource = load("res://data/monsters/" + file)
			if not _Looks.LOOKS.has(data.get("id")):
				no_row.append(file)
	r._ok(rows == 12 and no_row.is_empty(), "ANIM1 every id of data/monsters (%d) has a gait row (without: %s)" % [rows, no_row])
	return missing.is_empty() and no_row.is_empty()

static func _gait(r: Node) -> void:
	var m: Node3D = r._monster("rotter_3d", _spot(0, 40.0))
	var l0: Node3D = m.get_node("VisualRoot/Leg0")
	var l1: Node3D = m.get_node("VisualRoot/Leg1")
	m.set("velocity", Vector3(0.0, 0.0, -2.0))
	var swung: float = 0.0
	var opposite: bool = true
	for _i in 60:
		m.call("_update_anim", 0.05)
		swung = maxf(swung, absf(l0.rotation.x))
		if absf(l0.rotation.x) > 0.1 and l0.rotation.x * l1.rotation.x > 0.0:
			opposite = false
	r._ok(swung > 0.15 and opposite, "ANIM2 the legs swing with the speed (%.2f rad at most), the two sides in opposite phase" % swung)
	m.set("velocity", Vector3.ZERO)
	_step(m, 60, 0.05)
	var rest: float = absf(l0.rotation.x) + absf(l1.rotation.x)
	r._ok(rest < 0.05, "ANIM2 the legs stand still at rest (%.3f rad)" % rest)
	m.queue_free()

static func _kills(r: Node) -> void:
	var before: int = ProgressTracker.kills
	var dead: int = 0
	var lying: int = 0
	for i in 20:
		var m: Node3D = r._monster("rotter_3d", _spot(i, 80.0))
		m.call("take_damage", 99999.0)
		m.call("take_damage", 99999.0)
		_step(m, 12, 0.1)
		dead += 1 if int(m.get("ai_state")) == State.DEAD else 0
		lying += 1 if absf((m.get_node("VisualRoot") as Node3D).rotation.x) > 1.5 else 0
	var counted: int = ProgressTracker.kills - before
	r._ok(counted == 20 and dead == 20, "ANIM3 twenty kills count twenty, a second hit on a falling body counts nothing (counted %d, dead %d)" % [counted, dead])
	r._ok(lying == 20, "ANIM3 every one of the twenty bodies lies down (%d of 20)" % lying)

static func _windup(r: Node) -> void:
	var m: Node3D = r._monster("rotter_3d", _spot(0, 120.0))
	var arm: Node3D = m.get_node("VisualRoot/Torso/Arm0")
	(m.get("_telegraph") as Node).call("cue")
	var drawn: float = 0.0
	var thrown: float = 0.0
	for i in 50:
		m.call("_update_anim", 0.02)
		var t: float = float(i + 1) * 0.02
		if t <= _Rig.WINDUP:
			drawn = minf(drawn, arm.rotation.x)
		elif t <= _Rig.WINDUP + _Rig.STRIKE + 0.02:
			thrown = maxf(thrown, arm.rotation.x)
	_step(m, 40, 0.02)
	r._ok(_Rig.WINDUP >= 0.25 and drawn < -1.0 and thrown > 0.5 and absf(arm.rotation.x) < 0.15, "ANIM4 windup %.2f s draws the arm back (%.2f rad), the strike %.2f s throws it forward (%.2f), recover %.2f s" % [_Rig.WINDUP, drawn, _Rig.STRIKE, thrown, _Rig.RECOVER])
	m.queue_free()

static func _head(r: Node) -> void:
	var m: Node3D = r._monster("watcher_3d", _spot(0, 160.0))
	var near := Node3D.new()
	r.add_child(near)
	near.global_position = m.global_position + Vector3(-5.0, 0.0, 0.0)
	m.set("player_ref", near)
	m.set("ai_state", State.IDLE)
	var head: Node3D = m.get_node("VisualRoot/Torso/HeadMesh")
	m.call("_update_anim", 1.0 / 60.0)
	var first: float = absf(head.rotation.y)
	_step(m, 90, 1.0 / 60.0)
	var turned: float = head.rotation.y
	m.set("ai_state", State.CHASE)
	_step(m, 120, 1.0 / 60.0)
	r._ok(first <= 0.1001 and absf(turned) > 0.65 and absf(turned) <= 0.7001 and absf(head.rotation.y) < 0.05, "ANIM5 the head turns to the player at 6 rad/s or less (%.3f in one frame), stops at %.2f rad and faces forward in a chase (%.3f)" % [first, turned, head.rotation.y])
	near.queue_free()
	m.queue_free()

static func _flinch(r: Node) -> void:
	var m: Node3D = r._monster("hunter_3d", _spot(0, 200.0))
	var torso: Node3D = m.get_node("VisualRoot/Torso")
	m.set("attack_timer", 0.0)
	m.call("take_damage", float(m.get("max_hp")) * 0.6, m.global_position + Vector3(0.0, 0.0, -3.0))
	var push: float = 0.0
	for _i in 30:
		m.call("_update_anim", 0.01)
		push = maxf(push, torso.position.z)
	_step(m, 40, 0.01)
	r._ok(push > 0.02 and push <= 0.0801 and absf(torso.position.z) < 0.001, "ANIM6 a hit pushes the body back %.3f m (0.08 m at most) and it returns (%.4f)" % [push, torso.position.z])
	r._ok(float(m.get("attack_timer")) >= 0.24, "ANIM6 a heavy hit delays the next attack (attack_timer %.2f)" % float(m.get("attack_timer")))
	m.queue_free()

static func _feet(r: Node) -> void:
	var off: Array[String] = []
	for i in _SCENES.size():
		var m: Node3D = r._monster(_SCENES[i], _spot(i, 240.0))
		var id: StringName = m.get("monster_id")
		var legs: Array = _Looks.look(id)["legs"]
		var leg: Node3D = m.get_node_or_null("VisualRoot/Leg0") as Node3D
		if leg != null:
			var capsule: CapsuleShape3D = (m.get_node("CollisionShape3D") as CollisionShape3D).shape
			var floor_y: float = m.global_position.y - capsule.height * 0.5
			var tip: float = leg.global_position.y - float(legs[2])
			if absf(tip - floor_y) > 0.02:
				off.append("%s %.3f" % [id, tip - floor_y])
		m.queue_free()
	r._ok(off.is_empty(), "ANIM7 the feet of every monster stand on the floor of its capsule (off: %s)" % [off])

static func _arachnophobia(r: Node) -> void:
	var m: Node3D = r._monster("crawler_3d", _spot(0, 280.0))
	var alt: Node3D = m.get_node_or_null("AltMesh") as Node3D
	var body: Node3D = m.get_node("VisualRoot") as Node3D
	SettingsManager.set_arachnophobia(true)
	var swapped: bool = alt != null and alt.visible and not body.visible
	SettingsManager.set_arachnophobia(false)
	var back: bool = alt != null and not alt.visible and body.visible
	r._ok(swapped and back, "ANIM8 the arachnophobia mode swaps the crawler for its blob and back (swapped %s, back %s)" % [swapped, back])
	m.queue_free()
