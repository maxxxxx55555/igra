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
	_finish()

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
