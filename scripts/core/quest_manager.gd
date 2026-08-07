extends Node
## A6: полноценная квестовая система: 18 квестов, 6 типов, награды, сейв.

var quests: Dictionary = {}
var _completed_count: int = 0
var _started: bool = false

signal quest_updated
signal quest_started(quest_id: String)

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
		["q_repair_district1", "Запустить подстанцию в жилых кварталах", "Найди распределительный щит и активируй питание района", "REPAIR", "district_1", 1, 100, []],
		["q_find_fuses", "Найти предохранители 2/3", "Обыщи окрестности, чтобы найти предохранители для щитка", "COLLECT", "fuse", 3, 50, []],
		["q_connect_cables", "Подключить кабели к трансформатору", "Соедини кабели на трансформаторной будке", "INTERACT", "cable_node", 1, 75, [["scrap", 4]]],
		["q_find_engineers", "Найти пропавшую группу инженеров", "Разыщи следы инженерной бригады в жилом секторе", "EXPLORE", "engineer_camp", 1, 120, [["medkit", 1]]],
		["q_explore_school", "Исследовать старую школу", "Проникни в здание школы и выясни, что там произошло", "EXPLORE", "school_zone", 1, 150, [["gear", 2]]],
		# --- Бой (5) ---
		["q_kill_runner", "Истребить бегунов 0/5", "Бегуны — самая наглая тварь этой ночи. Собери 5 скальпов.", "KILL", "runner", 5, 60, []],
		["q_kill_tank", "Свалить танков 0/3", "Бронированные уроды не дают пройти к центру. 3 туши.", "KILL", "tank", 3, 90, [["battery", 1]]],
		["q_kill_sniper", "Охотник на снайперов 0/4", "Снайперы держат крыши. Очисти 4 позиции.", "KILL", "sniper", 4, 80, []],
		["q_kill_squad", "Зачистить отряд 0/6", "Сгруппировавшаяся стая опаснее одиночек. 6 убийств.", "KILL", "squad", 6, 100, [["transistor", 2]]],
		["q_kill_shadow", "Тени не спасутся 0/7", "Теневые твари прячутся в темноте. 7 уничтожено.", "KILL", "shadow", 7, 70, []],
		# --- Сбор (5) ---
		["q_collect_scrap", "Металлолом 0/10", "Собери 10 единиц металлолома — пригодится для крафта.", "COLLECT", "scrap", 10, 40, []],
		["q_collect_battery", "Батареи 0/4", "Собери 4 батареи для фонаря.", "COLLECT", "battery", 4, 45, []],
		["q_collect_medkit", "Аптечки 0/3", "Собери 3 аптечки.", "COLLECT", "medkit", 3, 55, []],
		["q_collect_cable", "Кабели 0/8", "Собери 8 кабелей — медь на вес золота.", "COLLECT", "cable", 8, 60, []],
		["q_collect_components", "Компоненты 0/10", "Транзисторы и шестерни для станков. 10 штук.", "COLLECT", "transistor", 10, 70, []],
		# --- Секреты (3) ---
		["q_secrets_1", "Тайник 1/3", "Найди первый городской тайник.", "SECRET", "secret", 1, 30, []],
		["q_secrets_2", "Тайник 2/3", "Найди второй городской тайник.", "SECRET", "secret", 2, 30, []],
		["q_secrets_3", "Тайник 3/3", "Найди третий городской тайник.", "SECRET", "secret", 3, 40, [["blueprint_flashlight_brightness", 1]]],
		["q_restore_district2", "Запитать промзону", "Верни свет в промышленный район — без него не пройти к центру", "REPAIR", "district_2", 1, 150, [["blueprint_flashlight_battery", 1]]],
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

func _on_district_restored(district_id: StringName, stage: int) -> void:
	for qid in quests:
		var q = quests[qid]
		if q.type == "REPAIR" and not q.done:
			if String(district_id) == q.target or stage >= 2:
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
	if q.progress >= q.target_count:
		_complete(q)

func _complete(q: Dictionary) -> void:
	q.done = true
	_completed_count += 1
	var coins := get_tree().root.get_node_or_null("/root/CoinManager")
	if coins and coins.has_method("add_coins") and q.reward_coins > 0:
		coins.add_coins(q.reward_coins)
	var inv := get_tree().root.get_node_or_null("/root/InventoryManager")
	if inv and inv.has_method("try_add"):
		for ri in q.reward_items:
			inv.try_add(StringName(ri[0]), int(ri[1]))
	EventBus.quest_completed.emit(StringName(q.id))
	EventBus.inventory_notice.emit("ЗАДАНИЕ ВЫПОЛНЕНО: " + q.title + " (+" + str(q.reward_coins) + " монет)")
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

func get_active_count() -> int:
	var n := 0
	for q in quests.values():
		if not q.done: n += 1
	return n

func get_completed_count() -> int:
	return _completed_count

func get_quest(id: String) -> Dictionary:
	return quests.get(id, {})

func get_active_quests() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for q in quests.values():
		if not q.done:
			out.append(q)
	return out
