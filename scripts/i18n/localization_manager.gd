

extends Node

## LocalizationManager - 13 jazykov, system font fallback, RTL
signal language_changed(lang: String)

const LANG_DIR: String = "res://data/i18n/"

const SUPPORTED: Array = ["ru","en","es","de","fr","it","pt_BR","tr","ja","ko","zh","zh_TW","ar"]

## Эндонимы: язык подписан на самом себе, как ждёт игрок в списке языков.
## Раньше здесь была латинская транслитерация ("Nihongo", "Zhongwen(Jian)") —
## обходной путь вокруг отсутствия глифов. Теперь fallback-шрифт настроен
## в _setup_system_font(), и подписи можно писать родным письмом.
const LANG_NAMES: Dictionary = {
	"ru": "Русский", "en": "English", "es": "Español", "de": "Deutsch",
	"fr": "Français", "it": "Italiano", "pt_BR": "Português (BR)", "tr": "Türkçe",
	"ja": "日本語", "ko": "한국어", "zh": "简体中文", "zh_TW": "繁體中文",
	"ar": "العربية"}

const RTL_LANGS: Array = ["ar"]

## Основной шрифт игры (латиница/кириллица). В нём нет иероглифов и арабской
## вязи, поэтому к нему цепляется системный шрифт как fallback.
const UI_FONT_PATH: String = "res://assets/fonts/Rajdhani-Regular.ttf"

## Системные шрифты с покрытием CJK/арабского — берётся первый доступный в ОС.
const FALLBACK_FONT_NAMES: Array = [
	"Segoe UI", "Yu Gothic UI", "Malgun Gothic", "Microsoft YaHei",
	"Microsoft JhengHei", "Noto Sans", "Noto Sans CJK", "Noto Sans Arabic",
	"Arial", "Tahoma", "DejaVu Sans"]

var current_lang: String = "ru"

var _strings: Dictionary = {}

var _last_trans: Translation = null

func _ready() -> void:
	_setup_system_font()
	var saved = _load_pref()
	if saved == "" :
		saved = _detect_system_lang()
	if saved in SUPPORTED:
		current_lang = saved
	else:
		current_lang = "en"
	_load_language(current_lang)

## Раньше здесь создавались SystemFont и Theme, которые тут же выбрасывались —
## заявленный fallback для CJK/арабского не работал вообще. Теперь шрифт
## реально прописывается в ThemeDB (движковый дефолт для любого Control)
## и в тему проекта, если она задана.
func _setup_system_font() -> void:
	var sf := SystemFont.new()
	sf.allow_system_fallback = true
	sf.multichannel_signed_distance_field = false
	sf.font_names = PackedStringArray(FALLBACK_FONT_NAMES)

	var base: Font = sf
	if ResourceLoader.exists(UI_FONT_PATH):
		var game_font := ResourceLoader.load(UI_FONT_PATH) as FontFile
		if game_font != null:
			# Дубликат, чтобы не мутировать общий кэшированный ресурс.
			game_font = game_font.duplicate() as FontFile
			var fb: Array[Font] = [sf]
			game_font.fallbacks = fb
			base = game_font

	ThemeDB.fallback_font = base
	_apply_font_to_theme(get_tree().root.theme, base)

func _apply_font_to_theme(theme: Theme, font: Font) -> void:
	if theme == null:
		return
	if theme.default_font == null:
		theme.default_font = font
	elif not theme.default_font.fallbacks.has(font):
		var fb: Array[Font] = theme.default_font.fallbacks.duplicate()
		fb.append(font)
		theme.default_font.fallbacks = fb

func _detect_system_lang() -> String:
	var loc = OS.get_locale()
	if loc.begins_with("zh_TW") or loc.begins_with("zh-Hant"): return "zh_TW"
	if loc.begins_with("zh"): return "zh"
	if loc.begins_with("pt_BR"): return "pt_BR"
	var short = loc.substr(0, 2)
	if short in SUPPORTED: return short
	return "en"

func _load_language(lang: String) -> void:
	var path = LANG_DIR + lang + ".json"
	if not ResourceLoader.exists(path):
		path = LANG_DIR + "en.json"
		lang = "en"
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		_strings = {}
		return
	var parsed = JSON.parse_string(f.get_as_text())
	_strings = parsed if parsed is Dictionary else {}
	current_lang = lang
	_sync_translation_server(lang)
	_save_pref(lang)
	language_changed.emit(lang)

func _sync_translation_server(lang: String) -> void:
	if _last_trans != null:
		TranslationServer.remove_translation(_last_trans)
	_last_trans = Translation.new()
	_last_trans.locale = lang
	for key in _strings:
		_last_trans.add_message(str(key), str(_strings[key]))
	TranslationServer.add_translation(_last_trans)
	TranslationServer.set_locale(lang)

func set_language(lang: String) -> void:
	if lang in SUPPORTED:
		_load_language(lang)

func t(key: String) -> String:
	return _strings.get(key, key)

func cycle_language() -> void:
	var idx = SUPPORTED.find(current_lang)
	var next = SUPPORTED[(idx + 1) % SUPPORTED.size()]
	set_language(next)

func is_rtl(lang: String = current_lang) -> bool:
	return lang in RTL_LANGS

func _pref_path() -> String:
	return "user://lang.cfg"

func _save_pref(lang: String) -> void:
	var f = FileAccess.open(_pref_path(), FileAccess.WRITE)
	if f: f.store_string(lang)

func _load_pref() -> String:
	if not FileAccess.file_exists(_pref_path()): return ""
	var f = FileAccess.open(_pref_path(), FileAccess.READ)
	return f.get_as_text().strip_edges()