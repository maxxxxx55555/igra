extends Node

const LOCALES: PackedStringArray = ["en","ru","es","fr","de","it","pt","ja","ko","zh","ar","tr","pl"]

var _current: StringName = &""

func _ready() -> void:
	_load_all()
	_apply()

func _unquote(s: String) -> String:
	var t := s.strip_edges()
	if t.length() >= 2 and t.begins_with('"') and t.ends_with('"'):
		t = t.substr(1, t.length() - 2)
	return t.replace("\\n", "\n")

func _godot_loc(code: String) -> String:
	if code == "zh":
		return "zh_CN"
	if code == "pt":
		return "pt_BR"
	if code == "en":
		return "en_US"
	return code

func _load_all() -> void:
	for loc in LOCALES:
		var path := "res://locale/%s.po" % loc
		if not FileAccess.file_exists(path):
			continue
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var tr_res := Translation.new()
		tr_res.locale = _godot_loc(loc)
		var msgid := ""
		while not f.eof_reached():
			var line: String = f.get_line().strip_edges()
			if line.begins_with("msgid "):
				msgid = _unquote(line.substr(6))
			elif line.begins_with("msgstr ") and msgid != "":
				tr_res.add_message(msgid, _unquote(line.substr(7)))
		f.close()
		TranslationServer.add_translation(tr_res)

func _apply() -> void:
	var lang := OS.get_locale().substr(0, 2).to_lower()
	if LOCALES.has(lang):
		_current = StringName(lang)
	else:
		_current = &"en"
	TranslationServer.set_locale(_godot_loc(String(_current)))

func set_locale(loc: StringName) -> void:
	_current = loc
	TranslationServer.set_locale(_godot_loc(String(loc)))

func current() -> StringName:
	return _current

func t(key: StringName) -> String:
	return tr(String(key))