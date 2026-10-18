extends "res://scripts/tools/_density_frames_runner.gd"
## Retention hooks (Session 28, W1; tools/qa_sim/retention_frames <label> <hash>): every hook that brings a player back is driven from inside the engine the way the game drives it (the entry points the game's own
## signals call, the buttons' own `pressed`, UIManager), judged by what it leaves behind, and shot once. A line each, `[retention] HOOK <id> PASS|FAIL <detail>`, then `[retention] DONE hooks=<passed>/<all>`:
##   daily_card     the card of the menu: its lines are filled, follow the language, and say "completed" with the streak after the claim
##   daily_claim    today's challenge completed: the reward is in the wallet once and equals the template's, the notice names it, a replay of the claim pays nothing
##   streak_reward  the seventh day in a row: the milestone fires once and the bonus is in the reward the notice names
##   achievement    an unlock pays its coins once, shows its notice, and its row in the Codex is ticked
##   collection     a found document fills the card of its district in the Codex at once, and its entry stands in the journal
##   journal_stats  the statistics tab shows the coins of now and not the coins of its first look
##   ng_plus_pick   the pick screen: Activate raises the level and a modifier button picks one, both through the buttons
## Frames -> docs/stills/retention/<state>_after_<hash>_<UTC>.jpg (the label "after": they show the code that ships). The profile is the owner's: the shell wrapper snapshots it and puts it back.

const HOOKS: int = 7
const COINS_PROBE: int = 777
var _passed: int = 0
var _failed: Array[String] = []
var _heard: Array[String] = []

func _hook(id: String, ok: bool, detail: String) -> void:
	print("[retention] HOOK %s %s %s" % [id, "PASS" if ok else "FAIL", detail])
	if ok:
		_passed += 1
	else:
		_failed.append(id)

func _snap(state: String, _kind: String = "") -> void:
	out_dir = "res://docs/stills/retention/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var file_name := "%s_after_%s_%s" % [state, _hash, _utc()]
	await _shot(file_name)
	print("[retention] frame %s.jpg" % file_name)

func _listen(message: String) -> void:
	_heard.append(message)

## The three lines of the menu's daily card, or {} when the menu has none.
func _card() -> Dictionary:
	var scene: Node = get_tree().current_scene
	var column: Node = scene.get_node_or_null("VBox") if scene != null else null
	var card: Node = column.get_node_or_null("DailyCard") if column != null else null
	if card == null:
		return {}
	return {"shown": (card as CanvasItem).visible, "title": (card.get_node("Title") as Label).text, "body": (card.get_node("Body") as Label).text, "streak": (card.get_node("Streak") as Label).text}

func _card_open() -> bool:
	var en: Dictionary = _card()
	LocalizationManager.set_language("ru")
	await get_tree().create_timer(0.4).timeout
	var ru: Dictionary = _card()
	LocalizationManager.set_language("en")
	await get_tree().create_timer(0.4).timeout
	await _snap("01_menu_daily")
	print("[retention] card en=%s ru=%s" % [en, ru])
	var ok: bool = not en.is_empty() and not ru.is_empty() and bool(en["shown"]) and String(en["title"]) != "" and String(en["body"]).contains("/") and String(en["streak"]) != ""
	return ok and String(ru["title"]) != String(en["title"]) and String(ru["streak"]) != String(en["streak"])

## Today is not claimed, the streak stands at `streak` and the last claim was `days_ago` days ago (0: never).
func _reset_day(streak: int, days_ago: int) -> void:
	DailyChallengeManager.set("_completed_today", false)
	DailyChallengeManager.set("_last_completed_day", -1)
	DailyChallengeManager.set("_progress", 0)
	SaveSystem.set("_daily_streak", streak)
	SaveSystem.set("_last_daily_time", 0 if days_ago <= 0 else int(Time.get_unix_time_from_system()) - 86400 * days_ago)

## Completes today's challenge through the entry that every signal of the game ends in (the time types have no other), shoots the notice, and says what came of it.
func _claim(state: String) -> Dictionary:
	var rewards: Array[int] = []
	var miles: Array[int] = []
	var on_done := func(reward: int) -> void: rewards.append(reward)
	var on_mile := func(days: int) -> void: miles.append(days)
	DailyChallengeManager.completed.connect(on_done)
	DailyChallengeManager.streak_milestone.connect(on_mile)
	_heard.clear()
	EventBus.inventory_notice.connect(_listen)
	var coins0: int = CoinWallet.get_coins()
	var today: Dictionary = DailyChallengeManager.get_today()
	DailyChallengeManager.call("_tick", String(today.get("type", "")), int(today.get("target", 1)))
	await get_tree().create_timer(0.35).timeout
	await _snap(state)
	var out: Dictionary = {"rewards": rewards.duplicate(), "miles": miles.duplicate(), "delta": CoinWallet.get_coins() - coins0, "heard": _heard.duplicate(), "streak": SaveSystem.get_daily_streak(), "base": int(today.get("reward", 0))}
	DailyChallengeManager.completed.disconnect(on_done)
	DailyChallengeManager.streak_milestone.disconnect(on_mile)
	EventBus.inventory_notice.disconnect(_listen)
	return out

func _daily_claim() -> void:
	_reset_day(0, 0)
	var first: Dictionary = await _claim("02_daily_notice")
	var rewards: Array = first["rewards"]
	var notice: String = LocalizationManager.tf("DAILY_DONE_NOTICE", [rewards[0]]) if rewards.size() == 1 else ""
	var ok: bool = rewards.size() == 1 and int(first["delta"]) == int(rewards[0]) and int(rewards[0]) == int(first["base"]) and int(first["streak"]) == 1 and (first["heard"] as Array).has(notice)
	var coins1: int = CoinWallet.get_coins()
	DailyChallengeManager.call("_complete")
	var replay: int = CoinWallet.get_coins() - coins1
	_hook("daily_claim", ok and replay == 0, "rewards %s base %s wallet +%s streak %s notice [%s] heard %s replay +%d" % [rewards, first["base"], first["delta"], first["streak"], notice, first["heard"], replay])

func _streak_reward() -> void:
	_reset_day(6, 1)
	var seventh: Dictionary = await _claim("03_streak_notice")
	var rewards: Array = seventh["rewards"]
	var miles: Array = seventh["miles"]
	var notice: String = LocalizationManager.tf("DAILY_DONE_NOTICE", [rewards[0]]) if rewards.size() == 1 else ""
	var ok: bool = rewards.size() == 1 and miles.size() == 1 and int(miles[0]) == 7 and int(seventh["streak"]) == 7 and int(rewards[0]) >= 150 and int(seventh["delta"]) == int(rewards[0]) and (seventh["heard"] as Array).has(notice)
	_hook("streak_reward", ok, "rewards %s milestones %s streak %s wallet +%s notice [%s] heard %s" % [rewards, miles, seventh["streak"], seventh["delta"], notice, seventh["heard"]])

## The visible labels of a page (the pages of the Codex that are not shown are not visible in the tree).
func _labels(root: Node) -> Array[String]:
	var out: Array[String] = []
	if root == null:
		return out
	for node: Node in root.find_children("*", "Label", true, false):
		var label := node as Label
		if label != null and label.is_visible_in_tree():
			out.append(label.text)
	return out

func _codex() -> Control:
	return (UIManager.get("_cache") as Dictionary).get(&"codex", null) as Control

func _open_tab(tab: StringName) -> Array[String]:
	UIManager.open_codex(tab)
	await get_tree().create_timer(0.7).timeout
	return _labels(_codex())

func _close_codex() -> void:
	UIManager.close(&"codex")
	await get_tree().create_timer(0.4).timeout

func _achievement() -> void:
	var manager: Node = get_node_or_null("/root/AchievementManager")
	var pick: StringName = &""
	if manager != null:
		for entry: Dictionary in (manager.call("get_all") as Array):
			if not bool(entry.get("unlocked", false)):
				pick = StringName(entry.get("id", &""))
				break
	if pick == &"":
		_hook("achievement", false, "nothing left to unlock (manager %s)" % [manager != null])
		return
	_heard.clear()
	EventBus.inventory_notice.connect(_listen)
	var coins0: int = CoinWallet.get_coins()
	manager.call("_unlock", pick)
	await get_tree().create_timer(0.2).timeout
	var paid: int = CoinWallet.get_coins() - coins0
	EventBus.achievement_unlocked.emit(pick)
	await get_tree().create_timer(0.1).timeout
	var replay: int = CoinWallet.get_coins() - coins0 - paid
	EventBus.inventory_notice.disconnect(_listen)
	var labels: Array[String] = await _open_tab(&"achievements")
	var ticked: int = 0
	for text: String in labels:
		ticked += 1 if text.begins_with("[+]") else 0
	await _snap("04_codex_achievements")
	await _close_codex()
	var notice: String = LocalizationManager.tf("REWARD_ACHIEVEMENT", [paid])
	_hook("achievement", paid > 0 and replay == 0 and _heard.has(notice) and ticked >= 1, "%s paid +%d replay +%d notice [%s] heard %s ticked rows %d" % [pick, paid, replay, notice, _heard, ticked])

## The sum of the "found / total" counts of the album's cards.
func _found(labels: Array[String]) -> int:
	var count := RegEx.create_from_string("^(\\d+) / (\\d+)$")
	var found: int = 0
	for text: String in labels:
		var hit := count.search(text)
		found += int(hit.get_string(1)) if hit != null else 0
	return found

func _a_document_not_yet_found() -> String:
	var ids: Array[String] = []
	for district: Variant in DistrictLoot.DOCUMENTS:
		ids.append(String(DistrictLoot.DOCUMENTS[district]))
	for district: Variant in DistrictLoot.LORE_DOCS:
		for id: Variant in (DistrictLoot.LORE_DOCS[district] as Array):
			ids.append(String(id))
	for id: String in ids:
		if not ProgressTracker.is_doc_unlocked(id):
			return id
	return ""

func _collection() -> void:
	var doc: String = _a_document_not_yet_found()
	if doc == "":
		_hook("collection", false, "every document is found already")
		return
	var album0: int = _found(await _open_tab(&"collection"))
	await _close_codex()
	await _open_tab(&"journal")
	var entries0: int = _buttons()
	await _close_codex()
	ProgressTracker.unlock_doc(doc)
	var album1: int = _found(await _open_tab(&"collection"))
	await _snap("05_codex_collection")
	await _close_codex()
	await _open_tab(&"journal")
	var entries1: int = _buttons()
	await _close_codex()
	_hook("collection", album1 == album0 + 1 and entries1 == entries0 + 1, "%s found: album %d -> %d, journal entries %d -> %d" % [doc, album0, album1, entries0, entries1])

## The visible buttons with a text on the open page of the Codex (the entries of the journal).
func _buttons() -> int:
	var count: int = 0
	for node: Node in _codex().find_children("*", "Button", true, false):
		var button := node as Button
		count += 1 if button != null and button.is_visible_in_tree() and button.text != "" else 0
	return count

func _journal_stats() -> void:
	var first: String = "%d" % CoinWallet.get_coins()
	var labels0: Array[String] = await _open_tab(&"stats")
	await _close_codex()
	CoinWallet.add(COINS_PROBE)
	var second: String = "%d" % CoinWallet.get_coins()
	var labels1: Array[String] = await _open_tab(&"stats")
	await _snap("06_codex_stats")
	await _close_codex()
	_hook("journal_stats", labels0.has(first) and labels1.has(second) and first != second, "coins %s on the first look (%s), %s after +%d (%s)" % [first, labels0.has(first), second, COINS_PROBE, labels1.has(second)])

func _ng_plus_pick() -> void:
	NewGamePlus.set("_current_ng_plus", 0)
	NewGamePlus.set("_active_modifiers", [])
	NewGamePlus.set("_banked_runs", [])
	UIManager.open(&"new_game_plus")
	await get_tree().create_timer(0.7).timeout
	var screen: Control = (UIManager.get("_cache") as Dictionary).get(&"new_game_plus", null) as Control
	var activate: Button = screen.find_child("ActivateButton", true, false) as Button if screen != null else null
	if activate == null or activate.disabled:
		_hook("ng_plus_pick", false, "no enabled Activate button (screen %s)" % [screen != null])
		return
	activate.pressed.emit()
	await get_tree().create_timer(0.5).timeout
	var level: int = NewGamePlus.get_current_ng_plus()
	var pick: Button = null
	for node: Node in screen.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.is_visible_in_tree() and not button.disabled and button != activate and button.text.contains(" — "):
			pick = button
			break
	if pick != null:
		pick.pressed.emit()
		await get_tree().create_timer(0.5).timeout
	var active: Array = NewGamePlus.get_active_modifiers()
	await _snap("07_ng_plus_pick")
	UIManager.close(&"new_game_plus")
	_hook("ng_plus_pick", level == 1 and pick != null and active.size() == 1, "level %d, a modifier button %s, picked %s" % [level, pick != null, active])

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("[retention] SKIP headless - frames need a real display")
		get_tree().quit(3)
		return
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("--thash="):
			_hash = s.substr(8)
	var ads := get_node_or_null("/root/AdService")
	if ads:
		ads.enabled = false
	var menu_up := func() -> bool:
		var cs := get_tree().current_scene
		return cs != null and cs.scene_file_path == Routes.MENU
	if not await _wait_until(menu_up, 15.0):
		Routes.goto(Routes.MENU)
		if not await _wait_until(menu_up, 10.0):
			_fail("main menu never came up")
			return
	get_window().size = WINDOW_SIZE
	LocalizationManager.set_language("en")
	await get_tree().create_timer(1.0).timeout
	var card_ok: bool = await _card_open()
	SaveSystem.mark_onboard_done()
	Routes.start_game()
	var playing := func() -> bool: return GameManager.is_playing() and get_tree().get_first_node_in_group("player") != null
	if not await _wait_until(playing, 20.0):
		_fail("never reached gameplay")
		return
	SettingsManager.set_setting("trailer_mode", false)
	TutorialSystem.call("_skip_tutorial")
	NewGamePlus.set("_active_modifiers", [])  # a Ghost run of the profile unlocks nothing, and the hooks are judged on the rules of the base game
	await get_tree().create_timer(3.0).timeout
	print("[retention] start hash=%s %s" % [_hash, _mem()])
	await _daily_claim()
	await _streak_reward()
	await _achievement()
	await _collection()
	await _journal_stats()
	await _ng_plus_pick()
	GameManager.return_to_menu()
	Routes.goto(Routes.MENU)
	if not await _wait_until(menu_up, 15.0):
		_fail("the menu never came back")
		return
	await get_tree().create_timer(1.5).timeout
	var card: Dictionary = _card()
	await _snap("08_menu_daily_done")
	var done: bool = not card.is_empty() and String(card["body"]).contains(LocalizationManager.t("DAILY_COMPLETED_LABEL")) and String(card["streak"]).contains("7")
	_hook("daily_card", card_ok and done, "open card ok %s, after the claim %s" % [card_ok, card])
	print("[retention] DONE hooks=%d/%d failed=%s hash=%s" % [_passed, HOOKS, _failed, _hash])
	get_tree().quit(0 if _failed.is_empty() else 1)
