extends RefCounted
## Session 28 (S1, the masterpiece pass): the attack cases the earlier passes did not have, run by attack_sim.gd after its own (`_S28.run(self)`). Each case prints one line `[attack-sim] OK|FAIL <ID> ...`
## and has a mutation in tools/qa_sim/s26_mutations.py (the sets of the group "attack"): the game code of its fix put back, the case must fail.
##   SPD1  a game speed above 1 (Engine.time_scale injected) is put back and logged in a release build; the dip of a hit-stop is left alone
##   VIT1  a vital over its own maximum is clamped and logged as a memory edit (a few percent over is a rounding and only clamped)
##   ECO1  a wallet outside 0..999,999 is clamped and logged     NGB1  a New Game+ level or a modifier list over what a run earns is corrected and logged
##   SAV2  a validly signed save with absurd experience, skill points, vitals and coins loads clamped
##   DLY4  a restored tls_daily.json cannot pay the day's reward or raise the streak twice     DLY5  a deleted one cannot reopen the day
##   ACH2  an achievement unlocked again (a restored achievements.cfg) pays its coins once   CFG1  a hostile settings.cfg leaves the difficulty, Hardcore and the volumes in range
##   OVL1  no shipped script loads a resource pack, runs a process or compiles a string, and the file scan names a repackaged data file
## Honest limits (docs/SECURITY_THREAT_MODEL.md): all of it holds against a file edit and a restored file, none of it against a player who holds the signing key or edits memory between two ticks of the watchdog.

const _Log := preload("res://scripts/security/security_log.gd")
const _Scan := preload("res://scripts/security/integrity_scan.gd")
const MAIN_PATH: String = "user://tls_savegame.save"
const SUFFIXES: Array[String] = ["", ".bak", ".bak2", ".bak3"]

## A stand-in for the player's vitals: the watchdog reads and writes three properties and nothing else.
class _Vitals extends Node:
	var hp: float = 100.0
	var battery: float = 100.0
	var stamina: float = 100.0

static func run(sim: Node) -> void:
	var guard: Node = sim.get_node_or_null("/root/IntegrityGuard")
	sim._ok(guard != null, "SPD0 the watchdog is a live autoload for the cases of Session 28")
	if guard == null:
		return
	var tampered0: bool = guard.tampered
	_speed(sim, guard)
	_vitals(sim, guard)
	_economy(sim, guard)
	_new_game_plus(sim, guard)
	guard.tampered = tampered0
	_absurd_save(sim)
	_daily_replay(sim)
	_achievement_replay(sim)
	_config_tamper(sim)
	_export_overlay(sim)

static func _last_kind() -> String:
	var entries: Array = _Log.read()
	return String((entries.back() as Dictionary).get("kind", "")) if not entries.is_empty() else ""

static func _read_all(paths: Array[String]) -> Dictionary:
	var saved: Dictionary = {}
	for path: String in paths:
		if FileAccess.file_exists(path):
			saved[path] = FileAccess.get_file_as_bytes(path)
	return saved

static func _put_back(paths: Array[String], saved: Dictionary) -> void:
	for path: String in paths:
		if saved.has(path):
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_buffer(saved[path] as PackedByteArray)
				file.close()
		elif FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

static func _speed(sim: Node, guard: Node) -> void:
	var scale0: float = Engine.time_scale
	guard.tampered = false
	Engine.time_scale = 4.0
	guard._watch_time_scale(true)
	var kind: String = _last_kind()
	sim._ok(is_equal_approx(Engine.time_scale, 1.0) and guard.tampered and kind == "speed",
		"SPD1 a game speed of 4 injected into a release build is put back to %.2f and logged as '%s' (tampered %s)" % [Engine.time_scale, kind, guard.tampered])
	Engine.time_scale = 0.4
	guard.tampered = false
	guard._watch_time_scale(true)
	sim._ok(is_equal_approx(Engine.time_scale, 0.4) and not guard.tampered, "SPD1 the slow motion of a hit-stop (0.4) is not a speed hack")
	Engine.time_scale = scale0

static func _vitals(sim: Node, guard: Node) -> void:
	var vitals := _Vitals.new()
	vitals.hp = 9999.0
	guard.tampered = false
	guard._validate_float(vitals, "hp", 0.0, 100.0, 100.0)
	var kind: String = _last_kind()
	sim._ok(is_equal_approx(vitals.hp, 100.0) and guard.tampered and kind == "vitals", "VIT1 a health of 9999 against a maximum of 100 is clamped to %.0f and logged as '%s'" % [vitals.hp, kind])
	vitals.hp = 104.0
	guard.tampered = false
	guard._validate_float(vitals, "hp", 0.0, 100.0, 100.0)
	sim._ok(is_equal_approx(vitals.hp, 100.0) and not guard.tampered, "VIT1 a health 4 %% over its maximum is a rounding: clamped, not flagged (%.0f)" % vitals.hp)
	vitals.free()

static func _economy(sim: Node, guard: Node) -> void:
	var wallet0: Dictionary = CoinWallet.to_dict()
	guard.tampered = false
	CoinWallet.coins = 123456789
	guard._check_economy()
	var kind: String = _last_kind()
	sim._ok(CoinWallet.get_coins() == guard.MAX_COINS and guard.tampered and kind == "economy", "ECO1 a wallet of 123,456,789 is clamped to %d and logged as '%s'" % [CoinWallet.get_coins(), kind])
	guard.tampered = false
	CoinWallet.coins = -50
	guard._check_economy()
	sim._ok(CoinWallet.get_coins() == 0 and guard.tampered, "ECO1 a negative wallet is clamped to %d and flagged" % CoinWallet.get_coins())
	CoinWallet.from_dict(wallet0)

static func _new_game_plus(sim: Node, guard: Node) -> void:
	var level0: int = NewGamePlus.get_current_ng_plus()
	var modifiers0: Array = NewGamePlus.get_active_modifiers()
	NewGamePlus.set("_current_ng_plus", 99)
	NewGamePlus.set("_active_modifiers", ["a", "b", "c", "d", "e"])
	guard.tampered = false
	guard._check_economy()
	var kind: String = _last_kind()
	sim._ok(NewGamePlus.get_current_ng_plus() == NewGamePlus.MAX_NG_PLUS and NewGamePlus.get_active_modifiers().size() <= NewGamePlus.MAX_NG_PLUS and guard.tampered and kind == "ngplus",
		"NGB1 a New Game+ level of 99 with five modifiers is corrected to level %d with %d and logged as '%s'" % [NewGamePlus.get_current_ng_plus(), NewGamePlus.get_active_modifiers().size(), kind])
	NewGamePlus.set("_current_ng_plus", level0)
	NewGamePlus.set("_active_modifiers", modifiers0)

static func _absurd_save(sim: Node) -> void:
	var paths: Array[String] = []
	for suffix: String in SUFFIXES:
		paths.append(MAIN_PATH + suffix)
	var saved: Dictionary = _read_all(paths)
	SaveSystem._write_atomic(MAIN_PATH, {
		"version": SaveSystem.SAVE_VERSION,
		"xp": {"level": 9999, "current_xp": -5, "xp_to_next": 0, "total_skill_points": 9999},
		"skill_tree": {"skill_points": 99999999, "unlocked_skills": {"move_speed": 50, "not_a_skill": 3}},
		"vitals": {"hp": 1e30, "stamina": -4.0, "battery": 1e30},
		"wallet": {"coins": 1e15, "paid": "x"},
	})
	SaveSystem.load_all()
	var vitals: Dictionary = SaveSystem._pending_vitals
	var vitals_ok: bool = not vitals.is_empty()
	for key: String in ["hp", "stamina", "battery"]:
		vitals_ok = vitals_ok and float(vitals.get(key, -1.0)) >= 0.0 and float(vitals.get(key, 1e30)) <= SaveSystem.MAX_VITAL
	var level: int = XpManager.get_level()
	var paid: Variant = CoinWallet.to_dict().get("paid", null)
	var skill_cap: int = SkillTreeManager._max_level_for(&"move_speed")
	sim._ok(level <= XpManager.MAX_LEVEL and XpManager.get_total_skill_points() <= level - 1 and CoinWallet.get_coins() <= CoinWallet.MAX_COINS and paid is Array and (paid as Array).is_empty()
			and SkillTreeManager.get_skill_level(&"move_speed") <= skill_cap and SkillTreeManager.get_skill_level(&"not_a_skill") == 0 and SkillTreeManager.get_skill_points() <= 9999 and vitals_ok,
		"SAV2 a signed save with level 9999, 9999 skill points, 1e30 vitals and 1e15 coins loads clamped: level %d (cap %d), points %d, coins %d, move_speed %d of %d, vitals %s" % [
			level, XpManager.MAX_LEVEL, XpManager.get_total_skill_points(), CoinWallet.get_coins(), SkillTreeManager.get_skill_level(&"move_speed"), skill_cap, vitals])
	_put_back(paths, saved)
	XpManager.reset()
	SkillTreeManager.reset()
	CoinWallet.from_dict({})
	SaveSystem._pending_vitals = {}
	SaveSystem.load_all()

static func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()

static func _reset_daily_state(daily: Node, day: int) -> void:
	daily._last_completed_day = -1
	daily._completed_today = false
	daily._today_id = ""
	daily._progress = 0
	daily._load_state()
	daily._roll_for_day(day)

## DLY4 and DLY5: the claim of a day is counted in the profile (the main save) as well as in tls_daily.json, so a copy of the file from before the claim cannot pay the reward or raise the streak
## a second time, and a deleted file cannot reopen the day. Every file and field the case touches is put back.
static func _daily_replay(sim: Node) -> void:
	var daily: Node = DailyChallengeManager
	var path: String = daily.SAVE_PATH
	var paths: Array[String] = [path]
	var saved: Dictionary = _read_all(paths)
	var fields0: Array = [daily._today_id, daily._progress, daily._completed_today, daily._last_completed_day, daily._progress_day]
	var streak0: int = SaveSystem._daily_streak
	var time0: int = SaveSystem._last_daily_time
	var wallet0: Dictionary = CoinWallet.to_dict()
	var today: int = daily._today_index()
	SaveSystem._last_daily_time = 0
	SaveSystem._daily_streak = 0
	DirAccess.remove_absolute(path)
	_reset_daily_state(daily, today)
	daily._save_state()
	var unclaimed: String = FileAccess.get_file_as_string(path)
	var coins0: int = CoinWallet.get_coins()
	daily._complete()
	var paid: int = CoinWallet.get_coins() - coins0
	var streak1: int = SaveSystem.get_daily_streak()
	_write_text(path, unclaimed)
	_reset_daily_state(daily, today)
	daily._completed_today = false
	daily._complete()
	var paid_again: int = CoinWallet.get_coins() - coins0 - paid
	sim._ok(paid > 0 and paid_again == 0 and SaveSystem.get_daily_streak() == streak1,
		"DLY4 a restored daily file pays nothing twice: the claim paid %d, the replay %d more, the streak %d then %d" % [paid, paid_again, streak1, SaveSystem.get_daily_streak()])
	DirAccess.remove_absolute(path)
	_reset_daily_state(daily, today)
	sim._ok(daily.is_completed_today(), "DLY5 a deleted daily file does not reopen the day that was claimed (completed today: %s)" % daily.is_completed_today())
	_put_back(paths, saved)
	daily._today_id = fields0[0]
	daily._progress = fields0[1]
	daily._completed_today = fields0[2]
	daily._last_completed_day = fields0[3]
	daily._progress_day = fields0[4]
	SaveSystem._daily_streak = streak0
	SaveSystem._last_daily_time = time0
	CoinWallet.from_dict(wallet0)

static func _achievement_replay(sim: Node) -> void:
	var wallet0: Dictionary = CoinWallet.to_dict()
	var before: int = CoinWallet.get_coins()
	EventBus.achievement_unlocked.emit("ach_s28_probe")
	var first: int = CoinWallet.get_coins() - before
	EventBus.achievement_unlocked.emit("ach_s28_probe")
	var second: int = CoinWallet.get_coins() - before - first
	sim._ok(first > 0 and second == 0, "ACH2 an achievement unlocked again (a restored achievements file) pays its coins once: %d the first time, %d the second" % [first, second])
	CoinWallet.from_dict(wallet0)

static func _config_tamper(sim: Node) -> void:
	var path: String = SettingsManager.CFG_PATH
	var paths: Array[String] = [path]
	var saved: Dictionary = _read_all(paths)
	var settings0: Dictionary = SettingsManager.to_dict()
	var ads0: bool = AdService.enabled
	var bad: Array[String] = []
	for hostile: Variant in [99, -3, "2", "abc", [1, 2], {"a": 1}, 1.7, "hard"]:
		var cfg := ConfigFile.new()
		cfg.set_value("game", "settings", {"difficulty": hostile, "hardcore": hostile, "ads_enabled": false, "revive": 99})
		cfg.set_value("audio", "volumes", {"Master": 9.0, "Music": -3.0})
		cfg.save(path)
		SettingsManager.load_from_cfg()
		var level: Variant = SettingsManager.get_setting("difficulty", -1)
		var scale: float = SettingsManager.difficulty_scale("monster_hp")
		var in_range: bool = level is int and int(level) >= 0 and int(level) <= 2 and is_finite(scale)
		var hardcore: Variant = SettingsManager.get_setting("hardcore", null)
		var rules_ok: bool = hardcore is bool and not hardcore and SettingsManager.get_volume("Master") <= 1.0 and SettingsManager.get_volume("Music") >= 0.0 and AdService.enabled == ads0
		if not (in_range and rules_ok):
			bad.append("%s -> %s" % [str(hostile), str(level)])
	sim._ok(bad.is_empty(), "CFG1 a hostile settings file (a number out of range, a word, a list, a dictionary in the difficulty and in Hardcore, volumes of 9 and -3, an ads flag) leaves the rules in range; wrong: %s" % [bad])
	_put_back(paths, saved)
	SettingsManager.from_dict(settings0)

static func _scripts(dir: String) -> Array[String]:
	var found: Array[String] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			found.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_scripts(dir.path_join(sub)))
	return found

static func _export_overlay(sim: Node) -> void:
	var needles: Array[String] = ["load_resource_pack", "OS.execute", "OS.create_process", "Expression.new", ".source_code", "GDScript.new", "load(\"user://", "load('user://"]
	var offenders: Array[String] = []
	for path: String in _scripts("res://scripts"):
		if path.begins_with("res://scripts/tools/") or path == "res://scripts/security/attack_sim.gd":
			continue
		var text: String = FileAccess.get_file_as_string(path)
		for needle: String in needles:
			if text.contains(needle):
				offenders.append("%s (%s)" % [path, needle])
	var changed: Array[String] = _Scan.mismatches({"files": {"res://data/districts.json": "0".repeat(64)}})
	var gone: Array[String] = _Scan.mismatches({"files": {"res://data/no_such_file.json": "0".repeat(64)}})
	sim._ok(offenders.is_empty() and changed == ["res://data/districts.json"] and gone == ["res://data/no_such_file.json"],
		"OVL1 no shipped script loads a resource pack, runs a process or compiles a string (%s) and the scan names a repackaged data file (%s) and a missing one (%s)" % [offenders, changed, gone])
