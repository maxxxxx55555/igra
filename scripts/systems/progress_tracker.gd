extends Node
var secrets: int = 0
var kills: int = 0
var shadow_kills: int = 0
var puzzles: int = 0
var time_played: float = 0.0
var _ach_done: Dictionary = {}
var _docs: Dictionary = {}
## Какие именно секреты найдены. Счётчика `secrets` хватало достижениям, но
## не экрану коллекции: чтобы показать найденный секрет текстом, нужен id.
var _secrets_found: Dictionary = {}
## QA_SWARM_FINDINGS.md P1 (cheater): district_loot.gd's populate() had no
## gate at all, unlike secrets below - leaving and re-entering a district
## (which rebuilds the scene, world_runtime.gd) restocked every common item
## and repair part for free, indefinitely. One flag per district, same
## idempotent-dict shape as _secrets_found.
## Loot keys picked up ("district:index"); DistrictLoot spawns the others again on every rebuild.
var _loot_taken: Dictionary = {}
## G25 (GDD §18): firearms found in the world and the one ammo reserve they share.
const WEAPON_IDS: Array[String] = ["pistol", "rifle", "shotgun"]
const MAX_AMMO_RESERVE: int = 240
var ammo: int = 0
var _weapons: Dictionary = {}
## G21 (GDD §9): workbench blueprints learned (the pickup is spent on learning) and what was crafted from them.
const BLUEPRINT_IDS: Array[String] = ["enhanced_battery", "uv_flashlight", "strobe_flashlight", "portable_workbench", "battery_l2"]
const BLUEPRINT_ITEM_PREFIX: String = "blueprint_"
## Flashlight capacity from the workbench batteries: 0.2 enhanced, 0.4 level 2, the larger counts.
const MAX_BATTERY_BONUS: float = 0.4
var battery_bonus: float = 0.0
var _blueprints: Dictionary = {}
var _crafted: Dictionary = {}
## G26 (GDD §24.2): the album gets a photo of the moment for every document and audio log, secret, quest, first
## kill of a monster kind, artifact, and for each district entered, lit and saved: photo_total() >= 200 in all.
const PHOTO_DIR: String = "user://photos/"
const PHOTO_SIZE := Vector2i(128, 72)
const CREATURE_IDS: Array[String] = ["shadow", "crawler", "watcher", "hunter", "destroyer", "sharpshooter", "brute", "burner", "rotter", "hound", "boss"]
const ARTIFACT_ITEMS: Array[String] = ["ancient_key", "scope_lens", "serum", "radio_part"]
const PHOTO_MILESTONES: Dictionary = {50: "ach_09", 100: "ach_10", 200: "ach_17"}
## GDD 24.6, the statistics screen: counters beside kills and time. Saved with the run.
var deaths: int = 0
var shots: int = 0
var jumps: int = 0
var distance: float = 0.0
var items_picked: int = 0
var crafted: int = 0
var damage_taken: float = 0.0
var kills_by: Dictionary = {}
## The monster that landed the last hit on the player (the death screen's cause); cleared when a run starts.
var last_hit_by: StringName = &""
const DOC_ON_DISTRICT := "doc_engineer_log"
const DOC_ON_SECRET := "doc_family_letter"
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.secret_found.connect(_on_secret_found)
	EventBus.enemy_killed.connect(_on_kill)
	EventBus.puzzle_solved.connect(func(_a, _b): puzzles += 1; _post())
	EventBus.district_restored.connect(func(_a, _b): _unlock_doc(DOC_ON_DISTRICT); _post())
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.game_over.connect(func() -> void: deaths += 1)
	EventBus.game_started.connect(func() -> void: last_hit_by = &"")
	EventBus.player_damaged.connect(func(amount: float) -> void: damage_taken += amount)
	EventBus.quest_completed.connect(func(id: String) -> void: _add_photo("quest_" + id))
	EventBus.district_entered.connect(func(id: StringName) -> void: _add_photo("district_%s_entered" % id))
	EventBus.district_stage_changed.connect(_on_stage_photo)
func _on_item_picked_up(item_id: StringName) -> void:
	items_picked += 1
	var id := String(item_id)
	if ARTIFACT_ITEMS.has(id):
		_add_photo("artifact_" + id)
	if not id.begins_with(BLUEPRINT_ITEM_PREFIX) or not learn_blueprint(id.substr(BLUEPRINT_ITEM_PREFIX.length())):
		return
	InventoryManager.remove(item_id)
	EventBus.inventory_notice.emit(LocalizationManager.tf("BLUEPRINT_LEARNED", [LocalizationManager.name_for("ITEM_", item_id)]))

func _on_stage_photo(id: StringName, stage: int) -> void:
	if stage == DistrictData.Stage.STREETS:
		_add_photo("district_%s_lit" % id)
	elif stage == DistrictData.Stage.FULL:
		_add_photo("district_%s_saved" % id)

## One photo per id: stored in the save (SaveSystem.get_photos), its thumbnail beside it as a 128x72 snapshot of
## the view. A photo that counts towards a milestone unlocks the achievement (Photographer 50, Seeker 100,
## Collector 200).
func _add_photo(id: String) -> void:
	if not SaveSystem.add_photo(id):
		return
	_snap_thumbnail(id)
	var total: int = SaveSystem.get_photo_count()
	EventBus.photo_added.emit(total)
	EventBus.inventory_notice.emit(LocalizationManager.tf("PHOTO_ADDED", [total]))
	if PHOTO_MILESTONES.has(total):
		AchievementManager.unlock(String(PHOTO_MILESTONES[total]))

func _snap_thumbnail(id: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var shot := get_viewport().get_texture().get_image()
	if shot == null or shot.is_empty():
		return
	shot.resize(PHOTO_SIZE.x, PHOTO_SIZE.y, Image.INTERPOLATE_BILINEAR)
	DirAccess.make_dir_recursive_absolute(PHOTO_DIR)
	shot.save_png(PHOTO_DIR + id + ".png")

## Every photo the game can give: its documents and audio logs, secrets, quests, monster kinds, artifacts
## (story items, weapons, blueprints) and three per district.
func photo_total() -> int:
	return Endings.get_total_documents() + MAX_SECRETS + QuestManager.get_all_quests().size() + CREATURE_IDS.size() \
		+ ARTIFACT_ITEMS.size() + WEAPON_IDS.size() + BLUEPRINT_IDS.size() + 3 * DistrictSceneFactory.DISTRICTS.size()

func unlock_weapon(id: String) -> bool:
	if not WEAPON_IDS.has(id) or _weapons.has(id):
		return false
	_weapons[id] = true
	_add_photo("artifact_weapon_" + id)
	return true

func has_weapon(id: String) -> bool:
	return _weapons.has(id)

func get_weapons() -> Array:
	return _weapons.keys()

func add_ammo(count: int) -> void:
	ammo = clampi(ammo + count, 0, MAX_AMMO_RESERVE)

func learn_blueprint(id: String) -> bool:
	if not BLUEPRINT_IDS.has(id) or _blueprints.has(id):
		return false
	_blueprints[id] = true
	_add_photo("artifact_blueprint_" + id)
	return true

func knows_blueprint(id: String) -> bool:
	return _blueprints.has(id)

func mark_crafted(id: String) -> void:
	if BLUEPRINT_IDS.has(id):
		_crafted[id] = true

func has_crafted(id: String) -> bool:
	return _crafted.has(id)

func blueprints_known() -> int:
	return _blueprints.size()

func raise_battery_bonus(bonus: float) -> void:
	battery_bonus = clampf(maxf(battery_bonus, bonus), 0.0, MAX_BATTERY_BONUS)

func _process(delta: float) -> void:
	if GameManager.is_playing():
		time_played += delta
## Один и тот же секрет не должен считаться дважды: он queue_free()-ится
## при взятии, но сохранение/загрузка в том же сеансе могла бы повторить id.
func _on_secret_found(id: StringName) -> void:
	var key := String(id)
	if key != "" and _secrets_found.has(key):
		return
	if key != "":
		_secrets_found[key] = true
	secrets += 1
	_add_photo("secret_" + key)
	_unlock_doc(DOC_ON_SECRET)
	_post()

func is_secret_found(id: String) -> bool:
	return _secrets_found.get(id, false)

func is_loot_taken(key: String) -> bool:
	return _loot_taken.get(key, false)

func mark_loot_taken(key: String) -> void:
	_loot_taken[key] = true

func found_secret_ids() -> Array:
	return _secrets_found.keys()

func _on_kill(id: StringName) -> void:
	kills += 1
	kills_by[String(id)] = int(kills_by.get(String(id), 0)) + 1
	if CREATURE_IDS.has(String(id)):
		_add_photo("creature_" + String(id))
	if id == &"shadow":
		shadow_kills += 1
	_post()
func _post() -> void:
	_check_achievements()
# Явные проверки (без лямбд в const — они не видят поля экземпляра в GDScript 4).
func _check_achievements() -> void:
	if not _ach_done.get("first_light", false) and puzzles >= 1:
		_grant("first_light")
	if not _ach_done.get("district_one", false) and _districts_restored() >= 1:
		_grant("district_one")
	if not _ach_done.get("shadow_slayer", false) and shadow_kills >= 1:
		_grant("shadow_slayer")
	if not _ach_done.get("secret_hunter", false) and secrets >= 3:
		_grant("secret_hunter")
## BREAK_REPORT B7: this used to emit EventBus.achievement_unlocked directly
## with these short ids ("first_light" etc.), bypassing AchievementManager
## entirely - the real ach_* row (ach_01 for "first_light") never actually
## unlocked or persisted (missing from the trophy list forever), while
## rewards_manager.gd's blanket "any achievement_unlocked emit pays
## REWARD_ACHIEVEMENT coins" handler paid out anyway, since it doesn't
## check which id fired. Other callers (photo_mode.gd, victory_screen.gd)
## already go through the real API for the exact same short-id ->
## ach_* mapping (achievements_manager.gd's own unlock()); this one just
## never had been wired the same way. _ach_done stays as this class's own
## "don't re-check the condition every frame" latch, separate from
## AchievementManager's real _unlocked state.
func _grant(id: String) -> void:
	_ach_done[id] = true
	AchievementManager.unlock(id)
func _unlock_doc(id: String) -> void:
	if _docs.get(id, false):
		return
	_docs[id] = true
	_add_photo("doc_" + id)
	EventBus.document_unlocked.emit(StringName(id))
## Публичная обёртка: документы поднимаются ещё и руками с земли,
## а не только выдаются за события.
func unlock_doc(id: String) -> void:
	_unlock_doc(id)

func is_doc_unlocked(id: String) -> bool:
	return _docs.get(id, false)

func count_docs() -> int:
	return _docs.size()
func _districts_restored() -> int:
	var n := 0
	for d in PowerGrid.all_districts():
		if d.stage >= DistrictData.Stage.FULL:
			n += 1
	return n
## Ниже — API, которое спрашивают EndingsManager и AchievementManager
## через has_method(). Этих методов здесь не было, поэтому проверки молча
## возвращали 0/false: концовка «Свет» (все документы) была недостижима,
## а «Истина» — тем более. Считаем по тем же 13 документам, что и Endings.
func get_total_documents() -> int:
	return Endings.get_total_documents()

func get_found_documents() -> int:
	return count_docs()

## Аудиологи и фото — часть коллекции документов: отдельных счётчиков
## в игре нет, поэтому «все аудиологи» = все документы найдены.
func has_all_audio_logs() -> bool:
	return count_docs() >= Endings.get_total_documents()

func has_all_photos() -> bool:
	return count_docs() >= Endings.get_total_documents()

## GDD.md:350 (G34) "бункер D11": the bunker is real content - secret
## secret_power_station_02 (content/secrets.json, zone z_bunker, spawned by
## DistrictLoot). It used to be aliased to "power station FULL", which every
## winning run already has, so the Truth ending never asked for the bunker.
const BUNKER_SECRET_ID: String = "secret_power_station_02"
func is_bunker_accessed() -> bool:
	return is_secret_found(BUNKER_SECRET_ID)

func get_stats() -> Dictionary:
	return {"secrets": secrets, "kills": kills, "puzzles": puzzles, "time_played": time_played, "districts": _districts_restored()}
func to_dict() -> Dictionary:
	return {"secrets": secrets, "kills": kills, "shadow_kills": shadow_kills, "puzzles": puzzles, "time_played": time_played,
		"ach": _ach_done.keys().map(func(k): return String(k)),
		"docs": _docs.keys().filter(func(k): return _docs[k]).map(func(k): return String(k)),
		"secret_ids": _secrets_found.keys().map(func(k): return String(k)),
		"loot_taken": _loot_taken.keys().map(func(k): return String(k)),
		"weapons": _weapons.keys(), "ammo": ammo, "blueprints": _blueprints.keys(), "crafted": _crafted.keys(),
		"battery_bonus": battery_bonus, "deaths": deaths, "shots": shots, "jumps": jumps, "distance": distance,
		"items_picked": items_picked, "crafted_items": crafted, "damage_taken": damage_taken, "kills_by": kills_by}
## content/secrets.json ships exactly 26 secrets (district_loot.gd/secret.gd
## both document this) - a real, fixed content total, unlike kills/puzzles
## below which have no such fixed roster in this project (kills accumulate
## indefinitely across a playthrough; inventing a puzzle total without a
## documented source would risk a wrong cap breaking a legitimate save).
const MAX_SECRETS: int = 26

func from_dict(d: Dictionary) -> void:
	# SECURITY_PATCH_SPEC P-07: every field here used to be trusted raw off
	# a signed-but-hand-editable save. secrets has a real fixed total to
	# clamp against; kills/puzzles don't (see MAX_SECRETS comment), but
	# negative counters and a nonsensical shadow_kills > kills are always
	# wrong regardless of any total, so those are still worth closing.
	secrets = clampi(int(d.get("secrets", 0)), 0, MAX_SECRETS)
	kills = maxi(0, int(d.get("kills", 0)))
	shadow_kills = clampi(int(d.get("shadow_kills", 0)), 0, kills)
	puzzles = maxi(0, int(d.get("puzzles", 0)))
	time_played = maxf(0.0, float(d.get("time_played", 0.0)))
	_ach_done.clear()
	for k in d.get("ach", []):
		_ach_done[String(k)] = true
	_docs.clear()
	for k in d.get("docs", []):
		_docs[String(k)] = true
	_secrets_found.clear()
	for k in d.get("secret_ids", []):
		_secrets_found[String(k)] = true
	_loot_taken.clear()
	for k in d.get("loot_taken", []):
		_loot_taken[String(k)] = true
	_weapons.clear()
	for k in d.get("weapons", []):
		if WEAPON_IDS.has(String(k)):
			_weapons[String(k)] = true
	ammo = clampi(int(d.get("ammo", 0)), 0, MAX_AMMO_RESERVE)
	_blueprints.clear()
	for k in d.get("blueprints", []):
		if BLUEPRINT_IDS.has(String(k)):
			_blueprints[String(k)] = true
	_crafted.clear()
	for k in d.get("crafted", []):
		if BLUEPRINT_IDS.has(String(k)):
			_crafted[String(k)] = true
	battery_bonus = clampf(float(d.get("battery_bonus", 0.0)), 0.0, MAX_BATTERY_BONUS)
	deaths = maxi(0, int(d.get("deaths", 0)))
	shots = maxi(0, int(d.get("shots", 0)))
	jumps = maxi(0, int(d.get("jumps", 0)))
	distance = maxf(0.0, float(d.get("distance", 0.0)))
	items_picked = maxi(0, int(d.get("items_picked", 0)))
	crafted = maxi(0, int(d.get("crafted_items", 0)))
	damage_taken = maxf(0.0, float(d.get("damage_taken", 0.0)))
	kills_by.clear()
	var by: Variant = d.get("kills_by", {})
	if by is Dictionary:
		for k in by:
			if String(k).length() <= 24 and int(by[k]) > 0:
				kills_by[String(k)] = int(by[k])
