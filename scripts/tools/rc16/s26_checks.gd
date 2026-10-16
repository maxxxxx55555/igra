extends RefCounted
## Session 26 (S1, S4): ACHSIG, the handlers of the achievements that had no check of their own; ACHRUN, the run marks of Quiet as a Mouse and Without a Scratch start empty in a New Game; ACH15, Darkness is the Dark ending and a Survivor
## death does not pay it, and GameManager hears game_over before AchievementManager (ACH15M, the mechanism); DAILY2, the daily selector does not offer a template one run cannot pay;
## DAILY3, two days that select the same template do not share progress (docs/ACHIEVEMENT_REACHABILITY.md, docs/DAILY_SIM.md); AUD6, the Music bus ends in a limiter.
## Wired into _closeout_check_runner.gd as `Rc26.run(self)`; CLOSEOUT_ONLY=s26 runs it alone, which tools/qa_sim/af2_both_ways.py uses on the pre-fix runtime.

## What DAILY2 and DAILY3 roll on the live daily manager and put back, `_progress_day` and `_last_completed_day` included.
const DAILY_FIELDS: Array[String] = ["_templates", "_day", "_completed_today", "_progress", "_play_seconds", "_today_id", "_today", "_last_completed_day", "_progress_day"]

static func run(r: Node) -> void:
	_handlers(r)
	_darkness(r)
	_run_marks(r)
	_daily_selector(r)
	_daily_days(r)
	_music_limiter(r)

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
	var heard: Array[Object] = []
	for c: Dictionary in EventBus.game_over.get_connections():
		heard.append((c["callable"] as Callable).get_object())
	var slot_gm: int = heard.find(GameManager)
	var slot_ach: int = heard.find(AchievementManager)
	r._ok(slot_gm != -1 and slot_ach != -1 and slot_gm < slot_ach, "ACH15M GameManager hears game_over before AchievementManager, so the ending is resolved when Darkness is asked (slots %d and %d)" % [slot_gm, slot_ach])
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
	var kept: Dictionary = {}
	for f in DAILY_FIELDS:
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
	for f in DAILY_FIELDS:
		m.set(f, kept[f])
	r._ok(first == "fits" and again == "fits" and kills == "kills", "DAILY2 the daily selector walks past a template over the %d districts (day 0 %s, day 3 %s) and keeps one with no per-run cap (day 2 %s)" % [cap, first, again, kills])

## Two days can select the same template (the selector walks past an unwinnable one into the next day's own): progress carries within one day and not across the day line.
## A saved 7 of 7 of the day before opened the next day at 7 of 7, and one event paid it again.
static func _daily_days(r: Node) -> void:
	var m: Node = DailyChallengeManager
	var kept: Dictionary = {}
	for f in DAILY_FIELDS:
		kept[f] = m.get(f)
	var cap: int = DistrictManager.DISTRICTS.size()
	m._templates = [
		{"id": "over", "type": "light_streets", "target": cap + 1, "reward": 1},
		{"id": "fits", "type": "restore_districts", "target": 3, "reward": 1},
	]
	m._last_completed_day = -1
	m._today_id = ""
	m.set("_progress_day", -1)
	m._roll_for_day(0)
	m._progress = 2
	m._roll_for_day(0)
	var same_day: int = m._progress
	m._roll_for_day(1)
	var next_day: int = m._progress
	for f in DAILY_FIELDS:
		m.set(f, kept[f])
	r._ok(same_day == 2 and next_day == 0, "DAILY3 two days that select the same template do not share progress: the same day keeps it (%d of 2), the next day starts empty (%d)" % [same_day, next_day])

## The windowed audio truth gate read the Music bus at +1.3 and +1.9 dB on two runs in a row, in a peak that is bimodal on one code tree (docs/CORRECTION_LOG.md 114 and 276): the layers and the action sting of a battle can sum past the
## -1.5 dB ceiling. The layout ends the bus in a hard limiter below that ceiling; only the ducker's Amplify (scripts/systems/audio_ducker.gd) may come after it, a cut and never a boost.
static func _music_limiter(r: Node) -> void:
	var bus: int = AudioServer.get_bus_index(&"Music")
	var limiter: AudioEffectHardLimiter = null
	var slot: int = -1
	for i in AudioServer.get_bus_effect_count(bus):
		var effect: AudioEffect = AudioServer.get_bus_effect(bus, i)
		if effect is AudioEffectHardLimiter:
			limiter = effect as AudioEffectHardLimiter
			slot = i
	var tail_ok: bool = true
	for j in range(slot + 1, AudioServer.get_bus_effect_count(bus)):
		tail_ok = tail_ok and AudioServer.get_bus_effect(bus, j) is AudioEffectAmplify
	var limited: bool = limiter != null and AudioServer.is_bus_effect_enabled(bus, slot) and limiter.ceiling_db <= -1.5 and tail_ok
	r._ok(limited, "AUD6 the Music bus ends in an enabled limiter under the -1.5 dB ceiling of the audio truth gate (slot %d of %d, ceiling %s)" % [slot, AudioServer.get_bus_effect_count(bus), "none" if limiter == null else str(limiter.ceiling_db)])
