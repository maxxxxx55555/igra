extends RefCounted
## Session 26 (S1, S4): ACHSIG, the handlers of the achievements that had no check of their own; ACHRUN, the run marks of Quiet as a Mouse and Without a Scratch start empty in a New Game; ACH15, Darkness is the Dark ending and a Survivor
## death does not pay it; DAILY2, the daily selector does not offer a template one run cannot pay (docs/ACHIEVEMENT_REACHABILITY.md, docs/DAILY_SIM.md).
## Wired into _closeout_check_runner.gd as `Rc26.run(self)`; CLOSEOUT_ONLY=s26 runs it alone, which tools/qa_sim/af2_both_ways.py uses on the pre-fix runtime.

static func run(r: Node) -> void:
	_handlers(r)
	_darkness(r)
	_run_marks(r)
	_daily_selector(r)

## The achievements that had no check of their own (docs/ACHIEVEMENT_REACHABILITY.md): the handler each signal reaches, called the way the check of ach_06 calls it.
static func _handlers(r: Node) -> void:
	var grid_before: Dictionary = PowerGrid.to_dict()
	var docs_before: Dictionary = ProgressTracker._docs.duplicate()
	var ids: Array = ["ach_01", "ach_02", "ach_03", "ach_04", "ach_05", "ach_district_hospital", "ach_district_power_station"]
	for id: String in ids:
		AchievementManager._unlocked.erase(id)
	AchievementManager._progress.clear()
	PowerGrid.reset()
	AchievementManager._on_streetlight_activated(&"suburbs")
	r._ok(AchievementManager.is_unlocked(&"ach_01"), "ACHSIG1 the first lit streetlight unlocks First Light")
	AchievementManager._on_district_restored(&"hospital", DistrictData.Stage.FULL)
	r._ok(AchievementManager.is_unlocked(&"ach_02") and AchievementManager.is_unlocked(&"ach_district_hospital") and not AchievementManager.is_unlocked(&"ach_03"),
		"ACHSIG2 one district FULL unlocks Electrician and its own district achievement, not Beacon")
	for district in PowerGrid.all_districts():
		district.stage = DistrictData.Stage.FULL
	AchievementManager._on_district_restored(&"power_station", DistrictData.Stage.FULL)
	r._ok(AchievementManager.is_unlocked(&"ach_03") and AchievementManager.is_unlocked(&"ach_district_power_station"), "ACHSIG3 every district FULL unlocks Beacon")
	for n in 49:
		AchievementManager._on_enemy_killed(&"shadow")
	var before_50: bool = AchievementManager.is_unlocked(&"ach_05")
	AchievementManager._on_enemy_killed(&"shadow")
	r._ok(not before_50 and AchievementManager.is_unlocked(&"ach_05"), "ACHSIG4 the 50th Shadow unlocks Shadow Hunter, the 49th does not")
	for i in Endings.get_total_documents():
		ProgressTracker._docs["closeout_doc_%d" % i] = true
	AchievementManager._on_document_unlocked(&"closeout_doc_0")
	r._ok(AchievementManager.is_unlocked(&"ach_04"), "ACHSIG5 the last document unlocks Librarian")
	ProgressTracker._docs = docs_before
	for id: String in ids:
		AchievementManager._unlocked.erase(id)
	AchievementManager._progress.clear()
	AchievementManager._save()
	PowerGrid.from_dict(grid_before)

## A death with the grid unfinished is the Dark ending and pays Darkness; a death with only the power station lit is Survivor and does not.
static func _darkness(r: Node) -> void:
	var grid_before: Dictionary = PowerGrid.to_dict()
	PowerGrid.reset()
	AchievementManager._unlocked.erase("ach_15")
	EndingsManager.evaluate_death_ending()
	var dark: StringName = EndingsManager.get_ending()
	AchievementManager._on_player_died()
	r._ok(dark == &"dark" and AchievementManager.is_unlocked(&"ach_15"), "ACH15 a death with the grid unfinished is the Dark ending and unlocks Darkness (ending %s)" % dark)
	AchievementManager._unlocked.erase("ach_15")
	PowerGrid.get_district(&"power_station").stage = DistrictData.Stage.FULL
	EndingsManager.evaluate_death_ending()
	var survivor: StringName = EndingsManager.get_ending()
	AchievementManager._on_player_died()
	r._ok(survivor == &"survivor" and not AchievementManager.is_unlocked(&"ach_15"), "ACH15 a death with only the power station lit is Survivor and does not unlock Darkness (ending %s)" % survivor)
	PowerGrid.from_dict(grid_before)

## The marks of the last run must not survive reset_all() (a New Game); the profile's counters and what is unlocked stay.
static func _run_marks(r: Node) -> void:
	AchievementManager._progress.clear()
	AchievementManager._progress["seen_park"] = 1
	AchievementManager._progress["hurt_school"] = 1
	AchievementManager._progress["ach_05"] = 7
	AchievementManager._unlocked["ach_01"] = true
	SaveSystem.reset_all()
	var p: Dictionary = AchievementManager._progress
	r._ok(not p.has("seen_park") and not p.has("hurt_school"), "ACHRUN1 a New Game starts the marks of Quiet as a Mouse and Without a Scratch empty (seen_park %s, hurt_school %s)" % [p.has("seen_park"), p.has("hurt_school")])
	r._ok(int(p.get("ach_05", 0)) == 7 and AchievementManager.is_unlocked(&"ach_01"), "ACHRUN2 it keeps the profile's counters and what is unlocked (Shadow Hunter %s, First Light %s)" % [p.get("ach_05", 0), AchievementManager.is_unlocked(&"ach_01")])
	AchievementManager._unlocked.erase("ach_01")
	AchievementManager._progress.clear()
	AchievementManager._save()

## A template over the districts of a once-per-district type is walked past; a type with no per-run cap keeps its target.
static func _daily_selector(r: Node) -> void:
	var m: Node = DailyChallengeManager
	var fields: Array[String] = ["_templates", "_day", "_completed_today", "_progress", "_play_seconds", "_today_id", "_today"]
	var kept: Dictionary = {}
	for f in fields:
		kept[f] = m.get(f)
	var cap: int = DistrictManager.DISTRICTS.size()
	m._templates = [
		{"id": "over", "type": "light_streets", "target": cap + 1, "reward": 1},
		{"id": "fits", "type": "light_streets", "target": cap, "reward": 1},
		{"id": "kills", "type": "kill_enemies", "target": 999, "reward": 1},
	]
	m._roll_for_day(0)
	var first: String = m._today_id
	m._roll_for_day(2)
	var kills: String = m._today_id
	m._roll_for_day(3)
	var again: String = m._today_id
	for f in fields:
		m.set(f, kept[f])
	r._ok(first == "fits" and again == "fits" and kills == "kills", "DAILY2 the daily selector walks past a template over the %d districts (day 0 %s, day 3 %s) and keeps one with no per-run cap (day 2 %s)" % [cap, first, again, kills])
