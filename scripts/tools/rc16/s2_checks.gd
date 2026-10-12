extends RefCounted
## Session 23 (S2): SAVEMIG, what SaveSystem does with a save of each generation and with each way a file can be wrong, run against the real loader (docs/SAVE_MIGRATION_MATRIX.md);
## NGP1, New Game+ raises the player's damage by 10 % a level (docs/NGPLUS_TABLE.md); DAILY1, the daily file the game reads (docs/DAILY_SIM.md).
## Wired into _closeout_check_runner.gd as `await Rc23S2.run(self)`; CLOSEOUT_ONLY=s23 runs it with the others. Every case prints one `[savemig]` line that
## tools/qa_sim/save_migration_sim.py reads back and holds against its own expectation table (the same rows, written a second time).

const DIR := "user://s23_savemig/"
const GOOD_COINS := 7
const FAR := Vector3(500.0, 0.0, 500.0)

## [id, title, expected loaded, expected source, expected progress kept]
const CASES: Array = [
	["g0", "no version key", true, "main", true],
	["g1", "version 1", true, "main", true],
	["g2", "version 2", true, "main", true],
	["g3", "version 3, the current one", true, "main", true],
	["g4", "version 4, newer than the build", false, "none", false],
	["f1", "no hmac", false, "none", false],
	["f2", "wrong hmac", false, "none", false],
	["f3", "plain checksum, the pre-hmac format", false, "none", false],
	["f4", "not JSON", false, "none", false],
	["f5", "empty data_json", false, "none", false],
	["p1", "no progress_hmac", true, "main", false],
	["p2", "wrong progress_hmac", true, "main", false],
	["b1", "main wrong, .bak good", true, "bak", true],
	["b2", "main and .bak wrong, .bak2 and .bak3 good", true, "bak2", true],
	["b3", "main, .bak and .bak2 wrong, .bak3 good", true, "bak3", true],
	["b4", "all four wrong", false, "none", false],
	["b5", "main good, .bak good", true, "main", true],
	["b6", "main newer than the build, .bak good", true, "bak", true],
]

static func run(r: Node) -> void:
	_save_matrix(r)
	_daily_source(r)
	await _ngp_damage(r)

static func _save_matrix(r: Node) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var bad: Array[String] = []
	for row: Array in CASES:
		var got: Dictionary = _case(String(row[0]))
		print("[savemig] case=%s | %s | loaded=%s source=%s progress_kept=%s version=%s quarantined=%s" % [row[0], row[1], got["loaded"], got["source"], got["kept"], got["version"], got["quarantined"]])
		if got["loaded"] != row[2] or got["source"] != row[3] or got["kept"] != row[4] or (row[2] and int(got["version"]) != SaveSystem.SAVE_VERSION):
			bad.append(String(row[0]))
	_clean()
	DirAccess.remove_absolute(DIR)
	r._ok(bad.is_empty(), "SAVEMIG the loader against %d save generations and faults: %s" % [CASES.size(), "all as the matrix says" if bad.is_empty() else "differs in " + ", ".join(bad)])

## The save of a case on disk, then what _read_validated makes of it.
static func _case(id: String) -> Dictionary:
	_clean()
	DirAccess.make_dir_recursive_absolute(DIR)
	var path: String = DIR + "slot.save"
	match id:
		"g0":
			_put(path, _payload(-1))
		"g1":
			_put(path, _payload(1))
		"g2":
			_put(path, _payload(2))
		"g3":
			_put(path, _payload(3))
		"g4":
			_put(path, _payload(4))
		"f1":
			_put(path, _payload(3), "none")
		"f2":
			_put(path, _payload(3), "wrong")
		"f3":
			_put(path, _payload(3), "checksum")
		"f4":
			_raw(path, "this is not a save")
		"f5":
			_raw(path, JSON.stringify({"hmac": "x", "data_json": ""}))
		"p1":
			_put(path, _payload(3, "none"))
		"p2":
			_put(path, _payload(3, "wrong"))
		"b1":
			_put(path, _payload(3), "wrong")
			_put(path + ".bak", _payload(3, "good", 11))
		"b2":
			_put(path, _payload(3), "wrong")
			_put(path + ".bak", _payload(3), "wrong")
			_put(path + ".bak2", _payload(3, "good", 22))
			_put(path + ".bak3", _payload(3, "good", 33))
		"b3":
			_put(path, _payload(3), "wrong")
			_put(path + ".bak", _payload(3), "wrong")
			_put(path + ".bak2", _payload(3), "wrong")
			_put(path + ".bak3", _payload(3, "good", 33))
		"b4":
			for suffix: String in ["", ".bak", ".bak2", ".bak3"]:
				_put(path + suffix, _payload(3), "wrong")
		"b5":
			_put(path, _payload(3, "good", 1))
			_put(path + ".bak", _payload(3, "good", 2))
		"b6":
			_put(path, _payload(4))
			_put(path + ".bak", _payload(3, "good", 11))
	var data: Dictionary = SaveSystem._read_validated(path)
	var coins: int = int(data.get("coins", -1))
	var source: String = "none"
	if not data.is_empty():
		source = "main"
		for pair: Array in [["bak", 11], ["bak2", 22], ["bak3", 33]]:
			if coins == pair[1] and id.begins_with("b") and id != "b5":
				source = String(pair[0])
	var quarantined: bool = false
	for file_name in DirAccess.get_files_at(DIR):
		quarantined = quarantined or file_name.contains(".corrupt-")
	return {
		"loaded": not data.is_empty(), "source": source, "version": data.get("version", 0), "quarantined": quarantined,
		"kept": not data.is_empty() and not (data.get("progress", {}) as Dictionary).is_empty(),
	}

## A save body: `signature` is "good", "none" or "wrong" for its progress_hmac; `version` -1 leaves the key out.
static func _payload(version: int, signature: String = "good", coins: int = GOOD_COINS) -> Dictionary:
	var power: Dictionary = {"suburbs": 3}
	var progress: Dictionary = {"coins_found": 2}
	var body: Dictionary = {"power": power, "progress": progress, "coins": coins}
	if version >= 0:
		body["version"] = version
	if signature == "good":
		body["progress_hmac"] = SaveSystem._sign_progress(power, progress)
	elif signature == "wrong":
		body["progress_hmac"] = "0".repeat(64)
	return body

## The envelope on disk: `mode` is "good", "none" (no hmac), "wrong" (a wrong hmac) or "checksum" (the plain hash of the old format).
static func _put(path: String, payload: Dictionary, mode: String = "good") -> void:
	var text: String = JSON.stringify(payload)
	var envelope: Dictionary = {"data_json": text}
	match mode:
		"good":
			envelope["hmac"] = SaveSystem._sign(text)
		"wrong":
			envelope["hmac"] = "0".repeat(64)
		"checksum":
			envelope["checksum"] = text.sha256_text()
	_raw(path, JSON.stringify(envelope))

static func _raw(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

static func _clean() -> void:
	for file_name in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR + file_name)

## NGP1: at New Game+ level 2 a bullet and a melee hit do 1.2 times what they do at level 0 (GDD 12.5: +10 % a level); level 0 changes nothing.
static func _ngp_damage(r: Node) -> void:
	var player: Node3D = r._player
	var monster: Node3D = r._monster("crawler_3d", FAR)
	var level0: Variant = NewGamePlus.get("_current_ng_plus")
	var weapon := load("res://scenes/weapons/weapon_pistol.tscn").instantiate() as WeaponBase
	r.add_child(weapon)
	weapon.set_shooter(player)
	var phase0: Variant = player.get("_attack_phase")
	var gun: Array[float] = []
	var melee: Array[float] = []
	for level: int in [0, 2]:
		NewGamePlus.set("_current_ng_plus", level)
		gun.append(weapon._effective_damage())
		player.set("_attack_phase", "active")
		player.set("_hit_registered", false)
		player.set("_attack_idx", 0)
		player.set("_chain_landed", false)
		monster.set("hp", 1000.0)
		monster.set("ai_state", BaseMonster.State.IDLE)
		player.call("_on_attack_hit", monster)
		melee.append(1000.0 - float(monster.get("hp")))
		await r.get_tree().create_timer(0.3).timeout
	NewGamePlus.set("_current_ng_plus", level0)
	player.set("_attack_phase", phase0)
	player.set("_chain_landed", false)
	var base_damage: float = weapon.damage
	weapon.queue_free()
	monster.queue_free()
	var gun_ratio: float = gun[1] / gun[0]
	var melee_ratio: float = melee[1] / maxf(melee[0], 0.001)
	r._ok(is_equal_approx(gun[0], base_damage) and absf(gun_ratio - 1.2) < 0.001 and melee[0] > 0.0 and absf(melee_ratio - 1.2) < 0.01, "NGP1 New Game+ player damage: a bullet %.1f at level 0 and %.1f at level 2 (x%.2f), a melee hit %.1f then %.1f (x%.2f)" % [gun[0], gun[1], gun_ratio, melee[0], melee[1], melee_ratio])

## DAILY1: the manager reads content/daily_challenges.json (60 templates) and not the 30 of the older data/ file: ResourceLoader sees the file and the manager holds 60.
static func _daily_source(r: Node) -> void:
	var seen: bool = ResourceLoader.exists("res://content/daily_challenges.json")
	var held: int = (DailyChallengeManager.get("_templates") as Array).size()
	r._ok(seen and held == 60, "DAILY1 the daily file: ResourceLoader sees content/daily_challenges.json (%s) and the manager holds %d templates (60 expected)" % [seen, held])
