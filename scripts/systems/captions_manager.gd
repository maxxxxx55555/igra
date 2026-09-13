extends Node
## «Журнал Смотрителя» — 12 моментных подписей из content/captions.json.
##
## Подпись — это короткая реплика Смотрителя на уже существующее событие:
## достижение, концовка, старт NG+, найденный документ. Она ничего не меняет
## в правилах, поэтому и не заводит своих сущностей: слушает те же сигналы,
## что уже летают по игре, и запоминает, какие подписи игрок уже видел.
##
## Намеренно НЕ испускает document_unlocked: счётчик документов гейтит
## концовку «Истина» (ProgressTracker.count_docs() против Endings.
## get_total_documents()), и подмешивать туда подписи означало бы выдать
## «Истину» за чтение подписей.

signal caption_unlocked(caption_id: String)

const DATA_PATH: String = "res://content/captions.json"
const SAVE_PATH: String = "user://tls_captions.json"

var _moments: Array = []
var _gallery: Array = []
var _seen: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_data()
	_load_state()
	EventBus.achievement_unlocked.connect(func(id: String) -> void: _fire("achievement", String(id)))
	EventBus.document_unlocked.connect(func(id: String) -> void: _fire("lore_note", String(id)))
	NewGamePlus.ng_plus_activated.connect(func(_level: int) -> void: _fire("system", "ng_plus_activated"))
	EndingsManager.ending_reached.connect(func(id: StringName) -> void: _fire("ending", String(id)))

func _load_data() -> void:
	if not ResourceLoader.exists(DATA_PATH):
		return
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_moments = parsed.get("moments", [])
		_gallery = parsed.get("gallery", [])

## Подписи адресуются парой (kind, code_id): у достижений code_id — это
## "ach_09", а не короткое имя, у концовки «darkness» код зовётся "dark".
func _fire(kind: String, code_id: String) -> void:
	for row in _moments:
		var ref: Dictionary = row.get("ref", {})
		if String(ref.get("kind", "")) != kind:
			continue
		# Достижение прилетает и коротким именем ("first_light" из
		# ProgressTracker._grant), и кодовым ("ach_01" из AchievementManager),
		# поэтому сверяем обе формы, а не одну.
		if String(ref.get("code_id", "")) != code_id and String(ref.get("id", "")) != code_id:
			continue
		var id := String(row.get("id", ""))
		if id == "" or _seen.has(id):
			return
		_seen[id] = true
		_save_state()
		caption_unlocked.emit(id)
		EventBus.toast_requested.emit(LocalizationManager.t(String(row.get("i18n_key", ""))), "caption")
		return

func get_moments() -> Array:
	return _moments

func is_seen(caption_id: String) -> bool:
	return _seen.has(caption_id)

## Подпись к району для экрана коллекции (ref.kind == "district").
func gallery_caption_for(kind: String, ref_id: String) -> String:
	for row in _gallery:
		var ref: Dictionary = row.get("ref", {})
		if String(ref.get("kind", "")) == kind and String(ref.get("id", "")) == ref_id:
			return LocalizationManager.t(String(row.get("i18n_key", "")))
	return ""

func _save_state() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"seen": _seen.keys()}))

func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for k in parsed.get("seen", []):
			_seen[String(k)] = true
