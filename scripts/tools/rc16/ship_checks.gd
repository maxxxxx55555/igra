extends RefCounted
## Session 21 (the shipping pass): the P1 rows that were a few lines of code, docs/CORRECTION_LOG.md rows 169, 172 and 174.
## Wired into _closeout_check_runner.gd as `await Rc21Ship.run(self)`; CLOSEOUT_ONLY=s21 runs only these. Each id fails on the
## v8.0.0-final runtime and passes at HEAD (tools/qa_sim/af2_both_ways.py reads the pair). A "guard" line holds a rule in both runs.
## Every state a check touches is put back; the restart check goes last because it reloads the district.

const FILLER: String = "ancient_key"
const PENDING_QUEST: String = "q_restore_district2"

static func run(r: Node) -> void:
	r._playing()
	UIManager.close_all_blocking()
	_remove_takes_all_or_nothing(r)
	_quest_pays_when_there_is_room(r)
	await _salvage_keeps_the_item(r)
	await _restart_goes_back_to_the_save(r)
	r._playing()

static func _full_pack(keep: Dictionary = {}) -> Dictionary:
	var slots: Array = []
	for i: int in InventoryManager.slots.size():
		slots.append({"item_id": FILLER, "count": 1})
	for i: int in keep:
		slots[i] = {"item_id": String(keep[i]), "count": 1}
	return {"slots": slots}

## RMV1 (row 174): remove() of more than the pack holds took what there was and answered false, so the caller that trusted the false
## (the LAN request has no count check of its own) lost the metal. It takes nothing now.
static func _remove_takes_all_or_nothing(r: Node) -> void:
	var pack: Dictionary = InventoryManager.to_dict()
	InventoryManager.from_dict({})
	InventoryManager.try_add(&"metal", 3, false)
	var weight: float = InventoryManager.current_weight
	var short: bool = InventoryManager.remove(&"metal", 5)
	var left: int = InventoryManager.count_of(&"metal")
	var left_kg: float = InventoryManager.current_weight
	var exact: bool = InventoryManager.remove(&"metal", 3)
	r._ok(not short and left == 3 and is_equal_approx(left_kg, weight) and exact and InventoryManager.count_of(&"metal") == 0,
		"RMV1 remove(5) of 3 metal takes nothing and answers false (answered %s, %d metal left at %.1f of %.1f kg); remove(3) takes them (%s)" % [short, left, left_kg, weight, exact])
	InventoryManager.from_dict(pack)

## QST1 (row 169): a quest whose item reward did not fit stayed open at its target until its event came again, and a REPAIR quest's
## event comes once per district: the Residential repair with a full pack kept q_restore_district2 (150 coins, a blueprint) open for
## good. It pays when the pack has room. QST2: not while the game is not playing (a load fills the pack before the world exists).
static func _quest_pays_when_there_is_room(r: Node) -> void:
	r._playing()
	var pack: Dictionary = InventoryManager.to_dict()
	var quests: Dictionary = QuestManager.serialize()
	var wallet: Dictionary = CoinWallet.to_dict()
	var completed: int = QuestManager._completed_count
	InventoryManager.from_dict(_full_pack())
	var quest: Dictionary = QuestManager.quests[PENDING_QUEST]
	var coins: int = CoinWallet.get_coins()
	quest.progress = quest.target_count
	QuestManager._complete(quest)
	var waits: bool = not quest.done
	GameManager._change_state(GameManager.GameState.PAUSED)
	InventoryManager.remove(StringName(FILLER), 1)
	var waits_out_a_load: bool = not quest.done
	r._ok(waits_out_a_load, "guard QST2 a pending quest does not pay while the game is not playing (done %s)" % quest.done)
	r._playing()
	InventoryManager.remove(StringName(FILLER), 1)
	var paid: bool = quest.done and CoinWallet.get_coins() == coins + int(quest.reward_coins) and InventoryManager.has(&"blueprint_flashlight_battery", 1)
	r._ok(waits and paid, "QST1 a quest that did not fit pays when the pack has room (waited %s; then done %s, coins %d of %d, blueprint %d)" % [
		waits, quest.done, CoinWallet.get_coins(), coins + int(quest.reward_coins), InventoryManager.count_of(&"blueprint_flashlight_battery")])
	QuestManager.from_dict(quests)
	QuestManager._completed_count = completed
	CoinWallet.from_dict(wallet)
	InventoryManager.from_dict(pack)

## SLV1 (row 169): the Salvage tab put the parts in, ignored the refusals and took the item out, so a full pack lost the parts. It keeps
## the item and takes nothing; a pack with room still gets the parts (I9.4).
static func _salvage_keeps_the_item(r: Node) -> void:
	r._playing()
	var pack: Dictionary = InventoryManager.to_dict()
	InventoryManager.from_dict(_full_pack({0: &"enhanced_battery"}))
	UIManager.open(&"workbench")
	await r.get_tree().process_frame
	var bench: Control = UIManager._get_screen(&"workbench")
	bench.call("_refresh_salvage")
	bench.call("_select_salvage", r._slot_of(&"enhanced_battery"))
	bench.call("_do_salvage")
	var kept: int = InventoryManager.count_of(&"enhanced_battery")
	var parts: int = InventoryManager.count_of(&"battery") + InventoryManager.count_of(&"cable")
	r._ok(kept == 1 and parts == 0, "SLV1 salvaging in a full pack keeps the item and gives nothing (enhanced battery %d of 1, parts %d of 0)" % [kept, parts])
	UIManager.close(&"workbench")
	InventoryManager.from_dict(pack)

## RST1 (row 172): Pause > Restart was a bare scene reload: no load, so the pack, the coins and the quests stayed as they were and the
## new player started at full health and charge, and the state stayed PAUSED. It goes back to the last save the way Continue does
## (GameManager.restart_from_save; the scene reload that follows is the pause menu's, which a check cannot run: it ends the run).
static func _restart_goes_back_to_the_save(r: Node) -> void:
	r._playing()
	var wallet: Dictionary = CoinWallet.to_dict()
	CoinWallet.from_dict({"coins": 700})
	SaveSystem.save_all()
	CoinWallet.from_dict({"coins": 1200})
	GameManager.pause_game()
	var back: bool = GameManager.has_method("restart_from_save") and bool(GameManager.call("restart_from_save"))
	await r.get_tree().process_frame
	await r.get_tree().process_frame
	r._ok(back and GameManager.is_playing() and not r.get_tree().paused and CoinWallet.get_coins() == 700,
		"RST1 Restart goes back to the last save and leaves the game playing (answered %s, state %d, tree paused %s, coins %d of 700, 1200 before)" % [
			back, GameManager.current_state, r.get_tree().paused, CoinWallet.get_coins()])
	var source: String = FileAccess.get_file_as_string("res://scripts/ui/pause_menu.gd")
	r._ok(source.contains("GameManager.restart_from_save()") and not source.contains("fade_to(func() -> void: Routes.restart_game())"),
		"RST1b the pause menu's Restart button goes through GameManager.restart_from_save (source of scripts/ui/pause_menu.gd)")
	SaveSystem.consume_pending_player_pos()
	CoinWallet.from_dict(wallet)
	r.get_tree().paused = false
	r._playing()
