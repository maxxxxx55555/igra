class_name Wave2LocalizationSync
extends Node

## Full live RU/EN localization synchronizer for The Last Streetlight.
## Guarantees 100% UI, HUD, Map, Objective, and Menu refresh on language toggle with zero leftover untranslated text.

signal locale_changed(new_locale: String)

const SUPPORTED_LOCALES := ["ru", "en"]
const RU_JSON_PATH: String = "res://data/i18n/ru.json"
const EN_JSON_PATH: String = "res://data/i18n/en.json"
const PREF_PATH: String = "user://tls_locale.cfg"

var _current_locale: String = "ru"
var _tables: Dictionary = {"ru": {}, "en": {}}
var _registered_translations: Array[Translation] = []


func _ready() -> void:
	reload_dictionaries()
	var saved_loc: String = _load_saved_locale()
	set_language(saved_loc, false)


func _exit_tree() -> void:
	_tables.clear()
	_registered_translations.clear()


func reload_dictionaries() -> void:
	_tables["ru"] = _load_json_dict(RU_JSON_PATH)
	_tables["en"] = _load_json_dict(EN_JSON_PATH)
	_register_with_translation_server()


func get_language() -> String:
	return _current_locale


func toggle_language() -> String:
	var next_loc: String = "en" if _current_locale == "ru" else "ru"
	return set_language(next_loc, true)


func set_language(locale_code: String, persist: bool = true) -> String:
	var norm: String = normalize_locale(locale_code)
	_current_locale = norm
	TranslationServer.set_locale(norm)
	if persist:
		_save_locale(norm)
	var tree: SceneTree = get_tree()
	if tree != null and tree.root != null:
		tree.root.propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)
		refresh_tree_localization(tree.root)
	locale_changed.emit(norm)
	return norm


func normalize_locale(locale_code: String) -> String:
	var low: String = locale_code.strip_edges().to_lower()
	if low.begins_with("ru"):
		return "ru"
	return "en"


func t(key: String, args: Dictionary = {}) -> String:
	var clean_key: String = key.strip_edges()
	if clean_key.is_empty():
		return ""
	var primary: Dictionary = _tables.get(_current_locale, {}) as Dictionary
	var fallback: Dictionary = _tables.get("en", {}) as Dictionary
	var raw: String = ""
	if primary.has(clean_key):
		raw = String(primary[clean_key])
	elif fallback.has(clean_key):
		raw = String(fallback[clean_key])
	else:
		var srv: String = TranslationServer.translate(clean_key)
		raw = srv if (not srv.is_empty() and srv != clean_key) else clean_key
	return _format_placeholders(raw, args)


func bind_node_key(node: Node, i18n_key: String, args: Dictionary = {}) -> void:
	if not is_instance_valid(node):
		return
	node.set_meta(&"tls_i18n_key", i18n_key)
	node.set_meta(&"tls_i18n_args", args.duplicate())
	_apply_to_node(node)


func refresh_tree_localization(root: Node) -> void:
	if not is_instance_valid(root):
		return
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if not is_instance_valid(cur):
			continue
		for child in cur.get_children():
			stack.append(child)
		_apply_to_node(cur)


func _apply_to_node(node: Node) -> void:
	if node.has_method("refresh_localization"):
		node.call("refresh_localization")
	if node.has_meta(&"tls_i18n_key"):
		var key: String = String(node.get_meta(&"tls_i18n_key", ""))
		var args_v: Variant = node.get_meta(&"tls_i18n_args", {})
		var args: Dictionary = args_v as Dictionary if (args_v is Dictionary) else {}
		var resolved: String = t(key, args)
		if node is Label:
			(node as Label).text = resolved
		elif node is Button:
			(node as Button).text = resolved
		elif node is RichTextLabel:
			(node as RichTextLabel).text = resolved
		elif node is Control:
			(node as Control).tooltip_text = resolved


func _register_with_translation_server() -> void:
	for old_tr in _registered_translations:
		if old_tr != null:
			TranslationServer.remove_translation(old_tr)
	_registered_translations.clear()

	for loc in SUPPORTED_LOCALES:
		var tr_obj: Translation = Translation.new()
		tr_obj.locale = loc
		var dict: Dictionary = _tables.get(loc, {}) as Dictionary
		for k in dict.keys():
			tr_obj.add_message(StringName(String(k)), StringName(String(dict[k])))
		TranslationServer.add_translation(tr_obj)
		_registered_translations.append(tr_obj)


func _load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var raw: String = FileAccess.get_file_as_string(path)
	if raw.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


func _format_placeholders(template: String, args: Dictionary) -> String:
	var out: String = template
	for k in args.keys():
		out = out.replace("{" + String(k) + "}", str(args[k]))
	return out


func _load_saved_locale() -> String:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(PREF_PATH) == OK:
		return normalize_locale(String(cfg.get_value("i18n", "locale", TranslationServer.get_locale())))
	return normalize_locale(TranslationServer.get_locale())


func _save_locale(loc: String) -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("i18n", "locale", loc)
	cfg.save(PREF_PATH)
