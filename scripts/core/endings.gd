class_name Endings
## GDD S7.4: концовки зависят от % восстановленных районов и собранных документов.
## Вызывайте mark_ended() из GameManager.trigger_win/deat. reset() при новой игре.

const SPEEDRUN_SECONDS: float = 1800.0
const TOTAL_DISTRICTS: int = 11
const TOTAL_DOCUMENTS: int = 2  # doc_engineer_log + doc_family_letter

static var _ended: bool = false

static func mark_ended() -> void:
	_ended = true

static func reset() -> void:
	_ended = false

static func evaluate() -> Array:
	var out: Array = []
	if not _ended:
		return out
	var pt := _root().get_node_or_null("/root/ProgressTracker")
	var dm := _root().get_node_or_null("/root/DistrictManager")
	var gm := _root().get_node_or_null("/root/GameManager")
	if dm == null:
		return out

	var pct := _district_pct(dm)
	var docs := _count_docs(pt)
	var docs_pct := float(docs) / float(TOTAL_DOCUMENTS)
	var secrets: int = pt.secrets if pt else 0
	var powerplant_full: bool = dm.get_stage("powerplant") >= 3
	var all_districts: bool = dm.all_restored()

	# Истина (секретная) — все документы + аудио-логи + фото + бункер
	if pt and docs >= TOTAL_DOCUMENTS and all_districts and secrets >= 3:
		out.append({"id": "truth", "title": "END_TRUTH_TITLE", "desc": "END_TRUTH_DESC", "tier": "secret"})

	# Свет (хорошая) — все 11 районов FULL + все документы
	if all_districts and docs_pct >= 1.0:
		out.append({"id": "light", "title": "END_LIGHT_TITLE", "desc": "END_LIGHT_DESC", "tier": "good"})

	# Надежда (нейтральная) — все районы FULL, но < 50% документов
	if all_districts and docs_pct < 0.5:
		out.append({"id": "hope", "title": "END_HOPE_TITLE", "desc": "END_HOPE_DESC", "tier": "neutral"})

	# Выживший (средняя) — только District 11 (powerplant) восстановлен
	if powerplant_full and not all_districts:
		out.append({"id": "survivor", "title": "END_SURVIVOR_TITLE", "desc": "END_SURVIVOR_DESC", "tier": "medium"})

	# Тьма (плохая) — сеть не починена (не достигнута или не восстановлена ЭС)
	if pct < 1.0 and not powerplant_full:
		out.append({"id": "darkness", "title": "END_DARKNESS_TITLE", "desc": "END_DARKNESS_DESC", "tier": "bad"})

	# Спринтер (достижение) — быстрая победа
	if gm and gm.play_time > 0.0 and gm.play_time < SPEEDRUN_SECONDS:
		out.append({"id": "sprinter", "title": "END_SPRINTER_TITLE", "desc": LocalizationManager.tf("END_SPRINTER_DESC", [int(SPEEDRUN_SECONDS / 60.0)]), "tier": "achievement"})

	return out

static func _district_pct(dm: Node) -> float:
	var n := 0
	if dm.has_method("count_restored"):
		n = dm.count_restored()
	return float(n) / float(TOTAL_DISTRICTS)

static func _count_docs(pt: Node) -> int:
	if pt == null or not pt.has_method("count_docs"):
		return 0
	return pt.count_docs()

static func _root() -> Node:
	return Engine.get_main_loop().root
