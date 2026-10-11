extends RefCounted
## Session 20 (final window pass): the four P1 rows that were a few lines of code, docs/CORRECTION_LOG.md rows 168, 178, 179 and 180.
## Wired into _closeout_check_runner.gd as `await Rc20Window.run(self)`; CLOSEOUT_ONLY=s20 runs only these. Each id fails on the
## v8.0.0-final runtime and passes at HEAD (tools/qa_sim/af2_both_ways.py reads the pair). Every state a check touches is put back.

static func run(r: Node) -> void:
	r._playing()
	UIManager.close_all_blocking()
	_no_player_position(r)
	_streak_belongs_to_the_profile(r)
	_hardcore_death_screen(r)
	await _tutorial_hint_language(r)
	r._playing()

## EX1 (row 168): a save written while no player is in the tree (New Game and Continue set PLAYING before the world is built, and the
## 30 s autosave checks only that) held the position (0, 0, 0) and a load took it, where INF means "the district's spawn".
static func _no_player_position(r: Node) -> void:
	var player: Node = r._player
	player.remove_from_group("player")
	var written: Array = SaveSystem._read_player_pos()
	player.add_to_group("player")
	var loaded: Vector3 = SaveSystem._parse_player_pos(written)
	r._ok(not loaded.is_finite(), "EX1 a save with no player in the tree holds no position: written %s, a load takes %s (INF is the spawn)" % [written, loaded])

## STRK1 (row 179): the daily streak belongs to the profile like the day's claim in tls_daily.json. A New Game kept the claim and zeroed
## the streak, so the menu read "Completed!" over "Streak: 0". Reset progress (wipe_all_saves) still clears it.
static func _streak_belongs_to_the_profile(r: Node) -> void:
	var streak0: int = SaveSystem._daily_streak
	var last0: int = SaveSystem._last_daily_time
	var now: int = int(Time.get_unix_time_from_system())
	SaveSystem._daily_streak = 4
	SaveSystem._last_daily_time = now
	SaveSystem.reset_all()
	var kept: int = SaveSystem.get_daily_streak()
	var mark_kept: bool = SaveSystem._last_daily_time == now
	SaveSystem.wipe_all_saves()
	var wiped: int = SaveSystem.get_daily_streak()
	r._ok(kept == 4 and mark_kept and wiped == 0,
		"STRK1 a New Game keeps the daily streak (%d of 4, day mark kept %s) and Reset progress clears it (%d)" % [kept, mark_kept, wiped])
	SaveSystem._daily_streak = streak0
	SaveSystem._last_daily_time = last0

## HCD1 (row 178): a Hardcore death wiped the run (reset_all) before the state turned DEAD, so the death screen opened on the reset
## state: "Districts restored: 0 / 11" and "Documents found: 0 / 101" after a run that reached the boss. It shows the run it ends.
static func _hardcore_death_screen(r: Node) -> void:
	r._playing()
	var grid: Dictionary = PowerGrid.to_dict()
	var progress: Dictionary = ProgressTracker.to_dict()
	var hardcore0: bool = GameManager.run_hardcore
	var all: Array = PowerGrid.all_districts()
	for i: int in 3:
		(all[i] as DistrictData).stage = DistrictData.Stage.FULL
	ProgressTracker._docs[&"s20_probe_document"] = true
	var districts: int = ProgressTracker.get_stats()["districts"]
	var docs: int = ProgressTracker.count_docs()
	var want_districts: String = LocalizationManager.tf("DEATH_DISTRICTS", [districts, all.size(), 100 * districts / maxi(all.size(), 1)])
	var want_docs: String = LocalizationManager.tf("DEATH_DOCS", [docs, Endings.get_total_documents()])
	SaveSystem.save_all()
	UIManager.close(&"death")
	GameManager.run_hardcore = true
	GameManager.trigger_death()
	var screen := UIManager._get_screen(&"death") as Control
	var label: Label = screen.get("_d") as Label if screen != null else null
	var shown: String = label.text if label != null else ""
	var wiped: bool = not SaveSystem.has_save()
	r._ok(districts >= 3 and docs >= 1 and shown.contains(want_districts) and shown.contains(want_docs) and wiped,
		"HCD1 the death screen of a Hardcore run shows the run it ends (%d districts, %d documents; shows '%s'; the save is wiped %s)" % [
			districts, docs, shown.replace("\n", " | "), wiped])
	GameManager.run_hardcore = hardcore0
	r._playing()
	UIManager.close(&"death")
	PowerGrid.from_dict(grid)
	ProgressTracker.from_dict(progress)

## TUTL1 (row 180): the tutorial's hint follows a language switch. It was set once per step, so after a switch it stayed in the old
## language (Russian under an English pause menu) until the next step showed.
static func _tutorial_hint_language(r: Node) -> void:
	var tut := TutorialSystem
	var lang0: String = LocalizationManager.current_lang
	var done0: Variant = tut.get("_completed_steps")
	var step0: Variant = tut.get("_current_step")
	var active0: Variant = tut.get("_tutorial_active")
	var waiting0: Variant = tut.get("_waiting_for_action")
	var panel := tut.get("_hint_panel") as Control
	var shown0: bool = panel.visible
	tut.set("_tutorial_active", true)
	tut.set("_completed_steps", [])
	tut.set("_current_step", r._tutorial_index("crouch"))
	LocalizationManager.set_language("en")
	tut.call("_show_step")
	var label := tut.find_child("HintText", true, false) as Label
	var english: String = label.text
	LocalizationManager.set_language("de")
	await r.get_tree().process_frame
	var german: String = tut.tr("TUT_CROUCH")
	r._ok(english != german and label.text == german,
		"TUTL1 after a language switch the tutorial hint shows in the new language (en '%s', now '%s', de '%s')" % [english, label.text, german])
	LocalizationManager.set_language(lang0)
	tut.set("_completed_steps", done0)
	tut.set("_current_step", step0)
	tut.set("_tutorial_active", active0)
	tut.set("_waiting_for_action", waiting0)
	panel.visible = shown0
