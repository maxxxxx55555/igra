extends Node

signal ending_reached(ending_id: StringName)

enum Ending { LIGHT, HOPE, SURVIVOR, DARK, TRUTH }

## Тексты концовок были захардкожены по-русски прямо в словаре: на любом
## из 13 языков игрок видел русский. Здесь лежат ключи, а строки берутся
## из локализации в get_ending_data().
const ENDING_DATA: Dictionary = {
	"light":    {"title": "ENDING_LIGHT_TITLE",    "desc": "ENDING_LIGHT_DESC",    "color": Color(1.0, 0.85, 0.4)},
	"hope":     {"title": "ENDING_HOPE_TITLE",     "desc": "ENDING_HOPE_DESC",     "color": Color(0.6, 0.8, 1.0)},
	"survivor": {"title": "ENDING_SURVIVOR_TITLE", "desc": "ENDING_SURVIVOR_DESC", "color": Color(0.8, 0.6, 0.6)},
	"dark":     {"title": "ENDING_DARK_TITLE",     "desc": "ENDING_DARK_DESC",     "color": Color(0.2, 0.1, 0.2)},
	"truth":    {"title": "ENDING_TRUTH_TITLE",    "desc": "ENDING_TRUTH_DESC",    "color": Color(1.0, 0.5, 0.2)},
}

## P2 (FINAL INTEGRATION wave): GAMEFEEL V2 delivered one sting per ending
## (assets/audio/jingles/ending_*_sting.ogg) but nothing anywhere connected
## to ending_reached - grepped the whole project for ".connect(" on this
## signal before writing this, zero matches. Only "full" tracks were asked
## for in the brief (ending_light_full.ogg / ending_dark_full.ogg for two
## of the five endings specifically); those don't exist on disk under that
## name or any other - checked assets/audio/ and the delivery reports.
## Wiring the real, delivered stings for all 5 endings is a strict superset
## of "something plays for light/dark" using what's actually here, rather
## than leaving genuinely finished audio silent because the fuller ask
## can't be met.
const _STING_PATH: Dictionary = {
	"light": "res://assets/audio/jingles/ending_light_sting.ogg",
	"hope": "res://assets/audio/jingles/ending_hope_sting.ogg",
	"survivor": "res://assets/audio/jingles/ending_survivor_sting.ogg",
	"dark": "res://assets/audio/jingles/ending_dark_sting.ogg",
	"truth": "res://assets/audio/jingles/ending_truth_sting.ogg",
}
var _sting_player: AudioStreamPlayer

var _achieved_ending: StringName = ""
var _ending_data: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sting_player = AudioStreamPlayer.new()
	_sting_player.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
	add_child(_sting_player)
	EventBus.game_won.connect(_evaluate_ending)
	ending_reached.connect(_play_sting)

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

## Возвращает уже переведённые title/description — вызывающему коду
## (экран победы, экран концовок) не нужно знать про ключи.
func get_ending_data(ending_id: StringName = "") -> Dictionary:
	var id: StringName = ending_id if ending_id else _achieved_ending
	return _localized(ENDING_DATA.get(String(id), {}))

func get_all_endings() -> Dictionary:
	var out: Dictionary = {}
	for id in ENDING_DATA:
		out[id] = _localized(ENDING_DATA[id])
	return out

func _localized(entry: Dictionary) -> Dictionary:
	if entry.is_empty():
		return {}
	return {
		"title": LocalizationManager.t(String(entry.get("title", ""))),
		"description": LocalizationManager.t(String(entry.get("desc", ""))),
		"color": entry.get("color", Color.WHITE),
	}

func force_ending(ending_id: StringName) -> void:
	_achieved_ending = ending_id
	_ending_data = ENDING_DATA.get(String(ending_id), {})
	ending_reached.emit(ending_id)

func _play_sting(ending_id: StringName) -> void:
	var path: String = _STING_PATH.get(String(ending_id), "")
	if path == "" or not ResourceLoader.exists(path):
		return
	_sting_player.stream = load(path)
	_sting_player.play()