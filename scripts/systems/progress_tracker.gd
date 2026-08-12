extends Node
var secrets: int = 0
var kills: int = 0
var shadow_kills: int = 0
var puzzles: int = 0
var time_played: float = 0.0
var _ach_done: Dictionary = {}
var _docs: Dictionary = {}
const DOC_ON_DISTRICT := "doc_engineer_log"
const DOC_ON_SECRET := "doc_family_letter"
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.secret_found.connect(func(_id): secrets += 1; _unlock_doc(DOC_ON_SECRET); _post())
	EventBus.enemy_killed.connect(_on_kill)
	EventBus.puzzle_solved.connect(func(_a, _b): puzzles += 1; _post())
	EventBus.district_restored.connect(func(_a, _b): _unlock_doc(DOC_ON_DISTRICT); _post())
func _process(delta: float) -> void:
	if GameManager.is_playing():
		time_played += delta
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
func _grant(id: String) -> void:
	_ach_done[id] = true
	EventBus.achievement_unlocked.emit(StringName(id))
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
	return Endings.TOTAL_DOCUMENTS

func get_found_documents() -> int:
	return count_docs()

## Аудиологи и фото — часть коллекции документов: отдельных счётчиков
## в игре нет, поэтому «все аудиологи» = все документы найдены.
func has_all_audio_logs() -> bool:
	return count_docs() >= Endings.TOTAL_DOCUMENTS

func has_all_photos() -> bool:
	return count_docs() >= Endings.TOTAL_DOCUMENTS

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
		"docs": _docs.keys().filter(func(k): return _docs[k]).map(func(k): return String(k))}
func from_dict(d: Dictionary) -> void:
	secrets = int(d.get("secrets", 0))
	kills = int(d.get("kills", 0))
	shadow_kills = int(d.get("shadow_kills", 0))
	puzzles = int(d.get("puzzles", 0))
	time_played = float(d.get("time_played", 0.0))
	_ach_done.clear()
	for k in d.get("ach", []):
		_ach_done[String(k)] = true
	_docs.clear()
	for k in d.get("docs", []):
		_docs[String(k)] = true