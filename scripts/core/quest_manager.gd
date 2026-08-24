extends Node
## A6: полноценная квестовая система: 18 квестов, 6 типов, награды, сейв.

var quests: Dictionary = {}
var _completed_count: int = 0
var _started: bool = false

signal quest_updated
signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_progress(quest_id: String, current: int, target: int)

const STATUS_NOT_STARTED: int = 0
const STATUS_ACTIVE: int = 1
const STATUS_COMPLETED: int = 2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _started:
		_init_quests()
		_started = true
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.item_picked_up.connect(_on_item_picked)
	EventBus.district_restored.connect(_on_district_restored)
	EventBus.interaction_done.connect(_on_interaction_done)
	EventBus.zone_reached.connect(_on_zone_reached)
	EventBus.secret_found.connect(_on_secret_found)

func _init_quests() -> void:
	var quest_data := [
		# --- Сюжет (5): ремонт энергосети города ---
		["q_repair_district1", "Q_REPAIR_DISTRICT1_TITLE", "Q_REPAIR_DISTRICT1_DESC", "REPAIR", "suburbs", 1, 100, []],
		["q_find_fuses", "Q_FIND_FUSES_TITLE", "Q_FIND_FUSES_DESC", "COLLECT", "fuse", 3, 50, []],
		["q_connect_cables", "Q_CONNECT_CABLES_TITLE", "Q_CONNECT_CABLES_DESC", "INTERACT", "cable_node", 1, 75, [["scrap", 4]]],
		["q_find_engineers", "Q_FIND_ENGINEERS_TITLE", "Q_FIND_ENGINEERS_DESC", "EXPLORE", "engineer_camp", 1, 120, [["medkit", 1]]],
		["q_explore_school", "Q_EXPLORE_SCHOOL_TITLE", "Q_EXPLORE_SCHOOL_DESC", "EXPLORE", "school_zone", 1, 150, [["gear", 2]]],
		# --- Бой (5) ---
		["q_kill_runner", "Q_KILL_RUNNER_TITLE", "Q_KILL_RUNNER_DESC", "KILL", "hunter", 5, 60, []],
		["q_kill_tank", "Q_KILL_TANK_TITLE", "Q_KILL_TANK_DESC", "KILL", "destroyer", 3, 90, [["battery", 1]]],
		["q_kill_sniper", "Q_KILL_SNIPER_TITLE", "Q_KILL_SNIPER_DESC", "KILL", "sharpshooter", 4, 80, []],
		["q_kill_squad", "Q_KILL_SQUAD_TITLE", "Q_KILL_SQUAD_DESC", "KILL", "hound", 6, 100, [["transistor", 2]]],
		["q_kill_shadow", "Q_KILL_SHADOW_TITLE", "Q_KILL_SHADOW_DESC", "KILL", "shadow", 7, 70, []],
		# --- Сбор (5) ---
		["q_collect_scrap", "Q_COLLECT_SCRAP_TITLE", "Q_COLLECT_SCRAP_DESC", "COLLECT", "scrap", 10, 40, []],
		["q_collect_battery", "Q_COLLECT_BATTERY_TITLE", "Q_COLLECT_BATTERY_DESC", "COLLECT", "battery", 4, 45, []],
		["q_collect_medkit", "Q_COLLECT_MEDKIT_TITLE", "Q_COLLECT_MEDKIT_DESC", "COLLECT", "medkit", 3, 55, []],
		["q_collect_cable", "Q_COLLECT_CABLE_TITLE", "Q_COLLECT_CABLE_DESC", "COLLECT", "cable", 8, 60, []],
		["q_collect_components", "Q_COLLECT_COMPONENTS_TITLE", "Q_COLLECT_COMPONENTS_DESC", "COLLECT", "transistor", 10, 70, []],
		# --- Секреты (3) ---
		["q_secrets_1", "Q_SECRETS_1_TITLE", "Q_SECRETS_1_DESC", "SECRET", "secret", 1, 30, []],
		["q_secrets_2", "Q_SECRETS_2_TITLE", "Q_SECRETS_2_DESC", "SECRET", "secret", 2, 30, []],
		["q_secrets_3", "Q_SECRETS_3_TITLE", "Q_SECRETS_3_DESC", "SECRET", "secret", 3, 40, [["blueprint_flashlight_brightness", 1]]],
		["q_craft_items", "Q_CRAFT_ITEMS_TITLE", "Q_CRAFT_ITEMS_DESC", "CRAFT", "craft", 5, 65, [["scrap", 3]]],
		["q_restore_district2", "Q_RESTORE_DISTRICT2_TITLE", "Q_RESTORE_DISTRICT2_DESC", "REPAIR", "residential", 1, 150, [["blueprint_flashlight_battery", 1]]],
	]
	for qa in quest_data:
		var q := {
			id=qa[0], title=qa[1], desc=qa[2], type=qa[3], target=qa[4],
			target_count=qa[5], reward_coins=qa[6], reward_items=qa[7],
			progress=0, done=false,
		}
		quests[qa[0]] = q

func _on_enemy_killed(monster_id: StringName) -> void:
	var sid := String(monster_id)
	for qid in quests:
		var q = quests[qid]
		if q.type == "KILL" and not q.done and sid.contains(q.target):
			_tick(q, 1)

func _on_item_picked(item_id: StringName) -> void:
	var sid := String(item_id)
	for qid in quests:
		var q = quests[qid]
		if q.type == "COLLECT" and not q.done:
			if sid == q.target or sid.begins_with(q.target):
				_tick(q, 1)

func _on_district_restored(district_id: StringName, _stage: int) -> void:
	# Was "or stage >= 2", which fired for ANY district since this handler
	# only ever runs on FULL restoration anyway (EventBus.district_restored
	# is only emitted at Stage.FULL, see power_grid.gd) - both REPAIR quests
	# completed simultaneously on the very first district, regardless of
	# which one. Real district ids replaced the fictional "district_1"/
	# "district_2" targets above (suburbs/residential = the actual 1st/2nd
	# districts per power_grid.gd's _DISTRICTS order).
	for qid in quests:
		var q = quests[qid]
		if q.type == "REPAIR" and not q.done and String(district_id) == q.target:
			_tick(q, 1)

func _on_interaction_done(target_id: StringName) -> void:
	for qid in quests:
		var q = quests[qid]
		if q.type == "INTERACT" and not q.done and String(target_id) == q.target:
			_tick(q, 1)

func _on_zone_reached(zone_id: StringName) -> void:
	for qid in quests:
		var q = quests[qid]
		if q.type == "EXPLORE" and not q.done and String(zone_id) == q.target:
			_tick(q, 1)

func _on_secret_found(secret_id: StringName) -> void:
	for qid in quests:
		var q = quests[qid]
		if q.type == "SECRET" and not q.done:
			_tick(q, 1)

func _tick(q: Dictionary, n: int) -> void:
	q.progress += n
	quest_updated.emit()
	quest_progress.emit(String(q.id), int(q.progress), int(q.target_count))
	if q.progress >= q.target_count:
		_complete(q)

func _complete(q: Dictionary) -> void:
	q.done = true
	_completed_count += 1
	# Раньше награда уходила в /root/CoinManager — такого автолоада нет,
	# и монеты за квест молча не начислялись.
	if int(q.reward_coins) > 0:
		CoinWallet.add(int(q.reward_coins))
	var inv := get_tree().root.get_node_or_null("/root/InventoryManager")
	if inv and inv.has_method("try_add"):
		for ri in q.reward_items:
			inv.try_add(StringName(ri[0]), int(ri[1]))
	EventBus.quest_completed.emit(StringName(q.id))
	quest_completed.emit(String(q.id))
	EventBus.inventory_notice.emit(LocalizationManager.tf("QUEST_DONE_NOTICE", [get_title(q), q.reward_coins]))
	var gm := get_tree().root.get_node_or_null("/root/GameManager")
	if gm and gm.has_method("auto_save"):
		gm.auto_save()

func serialize() -> Dictionary:
	var out := {}
	for qid in quests:
		var q = quests[qid]
		out[qid] = {"progress": q.progress, "done": q.done}
	return out

func from_dict(d: Dictionary) -> void:
	if d.is_empty():
		return
	for qid in d:
		if quests.has(qid):
			var q = quests[qid]
			q.progress = int(d[qid].get("progress", 0))
			q.done = bool(d[qid].get("done", false))

func reset() -> void:
	for q in quests.values():
		q.progress = 0
		q.done = false
	_completed_count = 0

## Совместимость с внешними вызовами: NPC-выдача квестов и крафт обращались
## к API прежнего (пустого) менеджера — get_quest_status/start_quest/
## complete_objective. Раньше это молча ничего не делало.
func get_quest_status(quest_id: StringName) -> int:
	var q: Dictionary = quests.get(String(quest_id), {})
	if q.is_empty():
		return STATUS_NOT_STARTED
	return get_status(q)

func start_quest(quest_id: StringName) -> void:
	var q: Dictionary = quests.get(String(quest_id), {})
	if q.is_empty() or bool(q.get("done", false)):
		return
	quest_started.emit(String(quest_id))
	quest_updated.emit()

func complete_objective(quest_id: StringName, _objective_id: StringName, amount: int = 1) -> void:
	var q: Dictionary = quests.get(String(quest_id), {})
	if q.is_empty() or bool(q.get("done", false)):
		return
	_tick(q, amount)

func is_completed(quest_id: StringName) -> bool:
	var q: Dictionary = quests.get(String(quest_id), {})
	return not q.is_empty() and bool(q.get("done", false))

func all_completed() -> bool:
	if quests.is_empty():
		return false
	for q in quests.values():
		if not bool(q.get("done", false)):
			return false
	return true

func can_progress() -> bool:
	return true

func get_active_count() -> int:
	var n := 0
	for q in quests.values():
		if not q.done: n += 1
	return n

func get_completed_count() -> int:
	return _completed_count

## Заголовок/описание хранятся как ключи локализации — UI обязан звать эти
## геттеры, а не читать поля напрямую.
func get_title(q: Dictionary) -> String:
	return LocalizationManager.t(String(q.get("title", "")))

func get_desc(q: Dictionary) -> String:
	return LocalizationManager.t(String(q.get("desc", "")))

func get_status(q: Dictionary) -> int:
	if bool(q.get("done", false)):
		return STATUS_COMPLETED
	if int(q.get("progress", 0)) > 0:
		return STATUS_ACTIVE
	return STATUS_NOT_STARTED

func get_all_quests() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for q in quests.values():
		out.append(q)
	return out

func get_quest(id: String) -> Dictionary:
	return quests.get(id, {})

func get_active_quests() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for q in quests.values():
		if not q.done:
			out.append(q)
	return out
