extends RefCounted
## Session 29 (the v10.0.0-ship pass), G-PLAY2 and G-PLAY3.
## END5: the five endings reached through the real paths of the game, not through the evaluator alone. Dark and Survivor are ACH15 (s26_checks.gd: GameManager.trigger_death with the state a death leaves), Hope is WIN2 and Truth is ach_14
## (the closeout runner: GameManager.trigger_win with every district FULL and the documents and secrets of the case); END5 is the one that had no run of its own, Light (a win with every district FULL and every document, the bunker not opened).
## DODGE1: a telegraph is a thing a player can read and use. Each of the seven attacks that go through a cue (TEL1) is started, the stand-in player steps out of its reach as soon as the cue has gone off, and nothing hits it: an attack that
## still lands on a player who has left would make the cue a lie. Wired into _closeout_check_runner.gd.

const _S28 := preload("res://scripts/tools/rc16/s28_checks.gd")

static func run(r: Node) -> void:
	await _dodge(r)
	await _light(r)

static func _dodge(r: Node) -> void:
	var monsters: Array[Node3D] = []
	var victims: Array[Node3D] = []
	for i: int in _S28.WARNED.size():
		var kind: String = _S28.WARNED[i]
		var pair: Array[Node3D] = _S28._pair(r, kind, _S28._FAR + Vector3(float(i) * 40.0, 0.0, 240.0), 8.0 if kind == "sharpshooter_3d" else 0.8)
		monsters.append(pair[0])
		victims.append(pair[1])
	for _settle in 3:
		await r.get_tree().process_frame
	for monster: Node3D in monsters:
		monster.call("_state_attack", 0.0)
	# the cue has gone off (TEL1 reads the gap to the hit): the player reads it and leaves, far out of any reach
	for victim: Node3D in victims:
		victim.global_position += Vector3(0.0, 0.0, 60.0)
	await r.get_tree().create_timer(0.8).timeout
	var hit: Array[String] = []
	var cued: int = 0
	for i: int in monsters.size():
		cued += 1 if int((monsters[i].get("_telegraph") as Node).get("last_cue_msec")) >= 0 else 0
		if int(victims[i].get("hit_msec")) >= 0:
			hit.append(_S28.WARNED[i])
	for node: Node3D in monsters + victims:
		node.queue_free()
	await r.get_tree().process_frame
	r._ok(cued == _S28.WARNED.size() and hit.is_empty(), "DODGE1 %d of %d attacks sent their cue and none hit a player who stepped out of reach after it (hit anyway: %s)" % [cued, _S28.WARNED.size(), hit])

static func _light(r: Node) -> void:
	r.call("_playing")
	var grid_before: Dictionary = PowerGrid.to_dict()
	for district in PowerGrid.all_districts():
		district.stage = DistrictData.Stage.FULL
	var docs_before: Dictionary = ProgressTracker._docs.duplicate()
	var secrets_before: int = ProgressTracker.secrets
	for i: int in Endings.get_total_documents():
		ProgressTracker._docs["end5_doc_%d" % i] = true
	ProgressTracker.secrets = 0
	EndingsManager.force_ending(&"dark")  # what an earlier run (or a death) left behind
	GameManager.trigger_win()
	await r.get_tree().process_frame
	var got: StringName = EndingsManager.get_ending()
	ProgressTracker._docs = docs_before
	ProgressTracker.secrets = secrets_before
	GameManager._change_state(GameManager.GameState.PLAYING)
	UIManager.close(&"win")
	PowerGrid.from_dict(grid_before)
	r._player.set("gameplay_active", true)
	r._ok(got == &"light", "END5 a win with every district FULL and every document, the bunker not opened, is the Light ending (%s)" % got)
