extends RefCounted
## rc16 closeout checks of sec: wired by the orchestrator into _closeout_check_runner.gd as `await <Preload>.run(self)`

const NGP_FILE: String = "user://ng_plus_data.json"
const KEPT_FIELDS: Array[String] = ["_current_ng_plus", "_is_ng_plus_active", "_active_modifiers", "_banked_runs"]
const OTHER_RUN: String = "0123456789abcdef"
const NOTICE_KEY: String = "NGP_RUN_ALREADY_COUNTED"
const LEDGER_CAP: int = 64
const FORGED_VALID: int = 450
const FORGED_TOTAL: int = 500
const LONG_ENTRY: int = 5000

## The profile's New Game+ file and the in-memory state are put back at the end, whatever the checks did to them.
static func run(r: Node) -> void:
	await r.get_tree().process_frame
	var had_file: bool = FileAccess.file_exists(NGP_FILE)
	var fields: Dictionary = {}
	for field in KEPT_FIELDS:
		var value: Variant = NewGamePlus.get(field)
		if value != null:
			var copy: Variant = value.duplicate() if value is Array else value
			fields[field] = copy
	var kept: Dictionary = {"had_file": had_file, "file": FileAccess.get_file_as_string(NGP_FILE) if had_file else "", "run": SaveSystem.get("_run_id"), "fields": fields}
	NewGamePlus.reset_for_new_game()
	_names_and_banks(r)
	_second_win(r)
	_forged_ledger(r)
	_restore(kept)

static func _ledger() -> Variant:
	return NewGamePlus.call("get_banked_runs") if NewGamePlus.has_method("get_banked_runs") else null

## E1A: a run has a name, the name rides in the save and a Continue or a Retry (both go through load_all) loads the same one back,
## and winning banks the run once. The old code has no run name and no ledger.
static func _names_and_banks(r: Node) -> void:
	if not SaveSystem.has_method("get_run_id") or not NewGamePlus.has_method("get_banked_runs"):
		r._ok(false, "E1A the game names no run and keeps no ledger of banked runs (SaveSystem.get_run_id, NewGamePlus.get_banked_runs)")
		return
	var run_id: String = String(SaveSystem.call("get_run_id"))
	r._ok(not run_id.is_empty() and String(SaveSystem.call("clean_run_id", run_id)) == run_id, "E1A a fresh game has a well-formed run name (%s)" % run_id)
	SaveSystem.save_all()
	var written: Dictionary = SaveSystem._read_envelope(SaveSystem.SAVE_PATH)
	SaveSystem.set("_run_id", OTHER_RUN)
	SaveSystem.load_all()
	SaveSystem.consume_pending_player_pos()
	SaveSystem.apply_pending_vitals(r._player)
	var loaded: String = String(SaveSystem.call("get_run_id"))
	r._ok(String(written.get("run_id", "")) == run_id and loaded == run_id,
		"E1A the name is in the signed save and a Continue or a Retry brings the same one back (file %s, loaded %s)" % [written.get("run_id", ""), loaded])
	var level: int = NewGamePlus.get_current_ng_plus()
	var accepted: bool = NewGamePlus.activate_ng_plus()
	r._ok(accepted and NewGamePlus.get_current_ng_plus() == level + 1 and _ledger() == [run_id],
		"E1A winning banks the run once: one level more and its name in the ledger (level %d of %d, ledger %s)" % [NewGamePlus.get_current_ng_plus(), level + 1, _ledger()])

## E1B: the same run winning again leaves the level where it was and says why, once; another run still banks its own level.
## The old code advances a level on every win, so the level check fails there whatever the ledger API is.
static func _second_win(r: Node) -> void:
	var seen: Array = []
	var on_notice := func(message: String) -> void: seen.append(message)
	EventBus.inventory_notice.connect(on_notice)
	var level: int = NewGamePlus.get_current_ng_plus()
	var accepted: bool = NewGamePlus.activate_ng_plus()
	EventBus.inventory_notice.disconnect(on_notice)
	var ledger: Variant = _ledger()
	r._ok(not accepted and NewGamePlus.get_current_ng_plus() == level and ledger is Array and ledger.size() == 1,
		"E1B the same run winning again banks nothing (accepted %s, level %d of %d, ledger %s)" % [accepted, NewGamePlus.get_current_ng_plus(), level, ledger])
	r._ok(seen.size() == 1 and seen[0] == LocalizationManager.t(NOTICE_KEY) and LocalizationManager.has_key(NOTICE_KEY),
		"E1B and the player is told once, in words (%s)" % [seen])
	SaveSystem.set("_run_id", OTHER_RUN)
	r._ok(NewGamePlus.activate_ng_plus() and NewGamePlus.get_current_ng_plus() == level + 1, "E1B a different run still banks its level (level %d)" % NewGamePlus.get_current_ng_plus())

## E1C: a forged ledger (5000-character strings, a dictionary, numbers, 500 entries) loads as well-formed names only, the newest
## LEDGER_CAP of them. The old code has no ledger to load.
static func _forged_ledger(r: Node) -> void:
	var forged: Array = []
	for i in FORGED_VALID:
		forged.append("%016x" % (i + 1))
	forged.append({"nested": {"deep": [1, 2, 3]}})
	forged.append(7)
	forged.append(3.5)
	forged.append(null)
	forged.append("ABCDEF0123456789")
	forged.append("a".repeat(LONG_ENTRY))
	while forged.size() < FORGED_TOTAL:
		forged.append("z".repeat(LONG_ENTRY))
	SaveSystem.write_signed(NGP_FILE, {"ng_plus": 0, "active": false, "modifiers": [], "banked_runs": forged})
	NewGamePlus.call("_load_save")
	var ledger: Variant = _ledger()
	var sane: bool = ledger is Array and ledger.size() > 0 and ledger.size() <= LEDGER_CAP
	if sane:
		for entry in ledger:
			sane = sane and entry is String and String(SaveSystem.call("clean_run_id", entry)) == entry
		sane = sane and ledger[ledger.size() - 1] == "%016x" % FORGED_VALID
	r._ok(sane, "E1C a forged ledger of %d entries loads as at most %d well-formed names, the newest kept (%s)" % [FORGED_TOTAL, LEDGER_CAP, str(ledger.size()) if ledger is Array else "no ledger"])

static func _restore(kept: Dictionary) -> void:
	var fields: Dictionary = kept["fields"]
	for field in fields:
		NewGamePlus.set(field, fields[field])
	if kept["run"] is String:
		SaveSystem.set("_run_id", kept["run"])
	if kept["had_file"]:
		var f := FileAccess.open(NGP_FILE, FileAccess.WRITE)
		if f != null:
			f.store_string(String(kept["file"]))
			f.close()
	elif FileAccess.file_exists(NGP_FILE):
		DirAccess.remove_absolute(NGP_FILE)
