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
var _districts_looted: Dictionary = {}
const DOC_ON_DISTRICT := "doc_engineer_log"
const DOC_ON_SECRET := "doc_family_letter"
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.secret_found.connect(_on_secret_found)
	EventBus.enemy_killed.connect(_on_kill)
	EventBus.puzzle_solved.connect(func(_a, _b): puzzles += 1; _post())
	EventBus.district_restored.connect(func(_a, _b): _unlock_doc(DOC_ON_DISTRICT); _post())
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
	_unlock_doc(DOC_ON_SECRET)
	_post()

func is_secret_found(id: String) -> bool:
	return _secrets_found.get(id, false)

func is_district_looted(id: String) -> bool:
	return _districts_looted.get(id, false)

func mark_district_looted(id: String) -> void:
	_districts_looted[id] = true

func found_secret_ids() -> Array:
	return _secrets_found.keys()

func _on_kill(id: StringName) -> void:
	kills += 1
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

## Бункер в 11-м районе = электростанция восстановлена полностью.
func is_bunker_accessed() -> bool:
	var pg := get_node_or_null("/root/PowerGrid")
	if pg == null:
		return false
	return pg.get_stage(&"power_station") >= DistrictData.Stage.FULL

func get_stats() -> Dictionary:
	return {"secrets": secrets, "kills": kills, "puzzles": puzzles, "time_played": time_played, "districts": _districts_restored()}
func to_dict() -> Dictionary:
	return {"secrets": secrets, "kills": kills, "shadow_kills": shadow_kills, "puzzles": puzzles, "time_played": time_played,
		"ach": _ach_done.keys().map(func(k): return String(k)),
		"docs": _docs.keys().filter(func(k): return _docs[k]).map(func(k): return String(k)),
		"secret_ids": _secrets_found.keys().map(func(k): return String(k)),
		"looted_districts": _districts_looted.keys().map(func(k): return String(k))}
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
	_districts_looted.clear()
	for k in d.get("looted_districts", []):
		_districts_looted[String(k)] = true