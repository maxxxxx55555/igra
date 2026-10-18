extends RefCounted
## Session 28 (A1, the masterpiece pass): the music of the district follows how hunted the player is, and a district bed turns over. Run after the sweeps of s28_sweep_checks.gd (CLOSEOUT_ONLY=s28).
##   MUS5  a bed turns over every two loops and no turn starts where the one before it started: the point moves by the golden ratio of the length (a third of it at least between two turns, no two turns of a run alike) and the variants take turns
##   MUS6  the three states crossfade on the hunted level (the detection meter set by hand, no monster in range): at 0 only the bed plays, at 0.4 the tense stem is up and the combat stems are down,
##         at 1.0 the combat stems are up, the tense stem is down and the bed has given way; the stems settle at the volumes of the targets
## The windowed run of the same sweep, with the peak of the music bus at each level, is in tools/qa_sim/audio_truth_gate.gd (a launch of its own).

static func run(r: Node) -> void:
	r._playing()
	_bed_turns(r)
	_threat_stems(r)
	r._playing()

static func _bed_turns(r: Node) -> void:
	var worst_gap: float = 1.0
	var distinct: int = 0
	var cycles: bool = true
	for seed_value: int in [0, 12345, -77, 4294967295]:
		var seen: Dictionary = {}
		var previous: float = -1.0
		for turn in 8:
			var offset: float = float(MusicManager.bed_slot(turn, 3, seed_value)["offset"])
			if previous >= 0.0:
				var gap: float = absf(offset - previous)
				worst_gap = minf(worst_gap, minf(gap, 1.0 - gap))
			previous = offset
			seen[snappedf(offset, 0.001)] = true
		distinct = maxi(distinct, seen.size())
		var variants: Dictionary = {}
		for turn in 3:
			variants[int(MusicManager.bed_slot(turn, 3, seed_value)["variant"])] = true
		cycles = cycles and variants.size() == 3
	r._ok(worst_gap >= 0.33 and distinct == 8 and cycles, "MUS5 a bed turns over: the start moves by at least %.2f of its length between two turns, 8 turns start in %d places, three variants take turns (%s)" % [worst_gap, distinct, cycles])

static func _threat_stems(r: Node) -> void:
	var music: Node = MusicManager
	var layers: Dictionary = music.get("_layers")
	var hunters: Array[Node] = []
	for monster: Node in r.get_tree().get_nodes_in_group("enemies"):
		hunters.append(monster)
		monster.remove_from_group("enemies")
	var levels: Dictionary = {}
	for meter: float in [0.0, 0.4, 1.0]:
		for i in 240:
			music.set("_combat_hold", MusicManager.CALM_DELAY * meter)
			music.call("_tick_layers", 0.05)
		var bed: float = maxf((layers["ambient_dark"] as AudioStreamPlayer).volume_db, (layers["ambient_lit"] as AudioStreamPlayer).volume_db)
		levels[meter] = {"bed": bed, "low": (layers["threat_low"] as AudioStreamPlayer).volume_db, "high": (layers["threat_high"] as AudioStreamPlayer).volume_db}
	music.set("_combat_hold", 0.0)
	for monster: Node in hunters:
		monster.add_to_group("enemies")
	var calm: Dictionary = levels[0.0]
	var tense: Dictionary = levels[0.4]
	var combat: Dictionary = levels[1.0]
	var holds: bool = float(calm["bed"]) > -13.0 and float(calm["low"]) < -45.0 and float(calm["high"]) < -45.0
	holds = holds and float(tense["low"]) > -13.0 and float(tense["high"]) < -45.0
	holds = holds and float(combat["high"]) > -13.0 and float(combat["low"]) < -45.0 and float(combat["bed"]) < float(calm["bed"]) - 4.0
	r._ok(holds, "MUS6 the stems crossfade on the hunted level: calm %s, tense %s, combat %s (dB: the bed, the tense stem, the combat stem)" % [calm, tense, combat])
