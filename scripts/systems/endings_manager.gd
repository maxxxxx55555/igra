extends Node

signal ending_reached(ending_id: StringName)

enum Ending { LIGHT, HOPE, SURVIVOR, DARK, TRUTH }

const ENDING_DATA: Dictionary = {
	"light": {
		"title": "Свет",
		"description": "Все 11 районов восстановлены. Все документы собраны. Реактор запущен, город озаряется. По радио доносится: «Спасибо».",
		"color": Color(1.0, 0.85, 0.4)
	},
	"hope": {
		"title": "Надежда",
		"description": "Все районы восстановлены, но правда не раскрыта. Титры на фоне рассвета над городом.",
		"color": Color(0.6, 0.8, 1.0)
	},
	"survivor": {
		"title": "Выживший",
		"description": "Только электростанция восстановлена. Остальной город погружен во тьму. Игрок уходит в неизвестность.",
		"color": Color(0.8, 0.6, 0.6)
	},
	"dark": {
		"title": "Тьма",
		"description": "Игрок погиб или не восстановил сеть. Город погружается в вечную тьму. Игрок становится одним из монстров.",
		"color": Color(0.2, 0.1, 0.2)
	},
	"truth": {
		"title": "Истина",
		"description": "Все документы + аудио-логи + фото + бункер в районе 11. Катастрофа была преднамеренной.",
		"color": Color(1.0, 0.5, 0.2)
	}
}

var _achieved_ending: StringName = ""
var _ending_data: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.game_won.connect(_evaluate_ending)

func _evaluate_ending() -> void:
	var dm: Node = get_node_or_null("/root/DistrictManager")
	var pt: Node = get_node_or_null("/root/ProgressTracker")
	var dm_districts: int = 0
	var dm_full: int = 0
	var docs_total: int = 0
	var docs_found: int = 0
	var has_bunker: bool = false
	var has_all_docs: bool = false
	var has_all_audio: bool = false
	var has_all_photos: bool = false
	
	if dm:
		dm_districts = dm.get_district_count() if dm.has_method("get_district_count") else 11
		dm_full = 0
		for i in range(dm_districts):
			var did = dm.get_district_id(i) if dm.has_method("get_district_id") else StringName("district_" + str(i))
			if dm.get_stage(did) >= 3:
				dm_full += 1
	
	if pt:
		docs_total = pt.get_total_documents() if pt.has_method("get_total_documents") else 0
		docs_found = pt.get_found_documents() if pt.has_method("get_found_documents") else 0
		has_all_docs = docs_found >= docs_total and docs_total > 0
		has_all_audio = pt.has_all_audio_logs() if pt.has_method("has_all_audio_logs") else false
		has_all_photos = pt.has_all_photos() if pt.has_method("has_all_photos") else false
		has_bunker = pt.is_bunker_accessed() if pt.has_method("is_bunker_accessed") else false
	
	var ending: StringName = _determine_ending(dm_full, dm_districts, has_all_docs, has_bunker, has_all_audio, has_all_photos)
	_achieved_ending = ending
	_ending_data = ENDING_DATA.get(String(ending), {})
	ending_reached.emit(ending)

func _determine_ending(full: int, total: int, all_docs: bool, bunker: bool, all_audio: bool, all_photos: bool) -> StringName:
	# Truth: all docs + audio + photos + bunker
	if all_docs and bunker and all_audio and all_photos:
		return &"truth"
	# Light: all districts full + all docs
	if full >= total and all_docs:
		return &"light"
	# Hope: all districts full but missing docs
	if full >= total:
		return &"hope"
	# Survivor: only powerplant (district 11) full
	if full == 1:
		return &"survivor"
	# Dark: died or no districts
	return &"dark"

func get_ending() -> StringName:
	return _achieved_ending

func get_ending_data(ending_id: StringName = "") -> Dictionary:
	var id: StringName = ending_id if ending_id else _achieved_ending
	return ENDING_DATA.get(String(id), {})

func get_all_endings() -> Dictionary:
	return ENDING_DATA.duplicate()

func force_ending(ending_id: StringName) -> void:
	_achieved_ending = ending_id
	_ending_data = ENDING_DATA.get(String(ending_id), {})
	ending_reached.emit(ending_id)