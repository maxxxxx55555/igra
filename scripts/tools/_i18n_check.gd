extends Node
## Гейт локализации. Сцена: scenes/tools/i18n_check_scene.tscn
##
## Ловит три класса регрессий, которые иначе видно только на экране:
##   1) файл локали не парсится / это не словарь;
##   2) набор ключей разъехался с en.json — на экране появится сырой ID;
##   3) сломались плейсхолдеры %d/%s — format() выдаст мусор или ошибку.
## Ключи, реально запрошенные из кода, проверяет tools/i18n_audit.py.

const DIR: String = "res://data/i18n"
const BASE: String = "en"

var _fails: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var base: Dictionary = _load(BASE)
	_check(not base.is_empty(), "%s.json loaded: %d keys" % [BASE, base.size()])
	if base.is_empty():
		_finish()
		return
	for loc in _locales():
		if loc == BASE:
			continue
		_check_locale(loc, base)
	await _check_cached_map_captions()
	_finish()

## Cached maps must translate in place, including hidden screens, without resetting the remembered drawing or view.
func _check_cached_map_captions() -> void:
	var language0: String = LocalizationManager.current_lang
	var memory0: Dictionary = Cartography.to_dict().duplicate(true)
	var motion0: bool = bool(SettingsManager.get_setting("reduce_ui_motion", false))
	SettingsManager.set_setting("reduce_ui_motion", true)
	Cartography.from_dict({"rev": Cartography.LAYOUT_REV, "districts": {"suburbs": [-3, 2]}})
	var expected_memory: Dictionary = Cartography.to_dict().duplicate(true)
	LocalizationManager.set_language("en")
	UIManager.open(&"district_map")
	await get_tree().process_frame
	var map: Control = UIManager.call("_get_screen", &"district_map") as Control
	var labels: Array[Node] = map.find_children("*", "Label", true, false)
	var buttons: Array[Node] = map.find_children("*", "Button", true, false)
	map.set("_zoom", 2.0)
	map.set("_pan", Vector2(17.0, -11.0))
	LocalizationManager.set_language("ru")
	await get_tree().process_frame
	var keys: Array[String] = ["MAP_ZOOM_IN", "MAP_ZOOM_OUT", "MAP_RESET", "MAP_DISTRICTS", "BTN_CLOSE"]
	var captions_ok: bool = labels.size() >= 2 and buttons.size() == keys.size()
	if captions_ok:
		captions_ok = labels[0].get("text") == LocalizationManager.t("MAP_TITLE") and labels[1].get("text") == LocalizationManager.t("MAP_BLANK")
		for index: int in buttons.size():
			captions_ok = captions_ok and buttons[index].get("text") == LocalizationManager.t(keys[index])
	_check(captions_ok, "cached architectural map translates all seven captions EN to RU while open")
	_check(map.get("_zoom") == 2.0 and map.get("_pan") == Vector2(17.0, -11.0) and Cartography.to_dict() == expected_memory,
		"map language change preserves zoom, pan and charted memory")
	UIManager.close(&"district_map")
	LocalizationManager.set_language("en")
	UIManager.open(&"city_map")
	await get_tree().process_frame
	var travel: Control = UIManager.call("_get_screen", &"city_map") as Control
	var close_button: Button = null
	for node: Node in travel.find_children("*", "Button", true, false):
		if node.get("text") == LocalizationManager.t("BTN_CLOSE"):
			close_button = node as Button
	UIManager.close(&"city_map")
	LocalizationManager.set_language("ru")
	UIManager.open(&"city_map")
	await get_tree().process_frame
	_check(close_button != null and close_button.text == LocalizationManager.t("BTN_CLOSE"), "cached district travel Close translates after hidden EN to RU switch and reopen")
	LocalizationManager.set_language("en")
	await get_tree().process_frame
	_check(close_button != null and close_button.text == LocalizationManager.t("BTN_CLOSE") and labels[0].get("text") == LocalizationManager.t("MAP_TITLE"),
		"cached hidden map and open travel translate back to EN without replacement")
	UIManager.close(&"city_map")
	Cartography.from_dict(memory0)
	LocalizationManager.set_language(language0)
	SettingsManager.set_setting("reduce_ui_motion", motion0)

func _locales() -> Array:
	var out: Array = []
	var d := DirAccess.open(DIR)
	if d == null:
		_check(false, "cannot open " + DIR)
		return out
	for f in d.get_files():
		if f.ends_with(".json"):
			out.append(f.trim_suffix(".json"))
	out.sort()
	return out

func _load(loc: String) -> Dictionary:
	var path: String = "%s/%s.json" % [DIR, loc]
	var txt := FileAccess.get_file_as_string(path)
	if txt.is_empty():
		_check(false, "%s: unreadable" % loc)
		return {}
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		_check(false, "%s: not a JSON object" % loc)
		return {}
	return parsed

func _check_locale(loc: String, base: Dictionary) -> void:
	var data: Dictionary = _load(loc)
	if data.is_empty():
		return
	var missing: Array = []
	var bad_ph: Array = []
	for k in base:
		if not data.has(k):
			missing.append(k)
			continue
		var v := str(data[k])
		if v.strip_edges().is_empty():
			bad_ph.append("%s (empty)" % k)
			continue
		var b := str(base[k])
		# Число %d и %s должно совпадать — иначе format() на этой локали упадёт.
		if b.count("%d") != v.count("%d") or b.count("%s") != v.count("%s"):
			bad_ph.append("%s (placeholder)" % k)
	var extra: Array = []
	for k in data:
		if not base.has(k):
			extra.append(k)
	_check(missing.is_empty(), "%s: missing %d %s" % [loc, missing.size(), str(missing.slice(0, 5))])
	_check(extra.is_empty(), "%s: extra %d %s" % [loc, extra.size(), str(extra.slice(0, 5))])
	_check(bad_ph.is_empty(), "%s: bad values %d %s" % [loc, bad_ph.size(), str(bad_ph.slice(0, 5))])

func _check(cond: bool, label: String) -> void:
	print("[i18n] [", "OK" if cond else "FAIL", "] ", label)
	if not cond:
		_fails.append(label)

func _finish() -> void:
	print("[i18n] fails=", _fails.size())
	if not _fails.is_empty():
		print("[i18n] FAILED: ", str(_fails))
	get_tree().quit(0 if _fails.is_empty() else 1)
