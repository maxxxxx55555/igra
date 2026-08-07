extends Node

## Гейт компиляции: грузит каждый .gd и проверяет, что он реально распарсился.
## Раньше проверялось только `res == null`, а Godot на битом скрипте отдаёт
## непустой объект из кэша — гейт печатал OK при живой Parse Error.

const SKIP_DIRS: Array = [".godot", ".git", "_BACKUPS", "addons/.import"]

var _files: Array[String] = []
var _idx: int = 0
var _bad: Array[String] = []

func _ready() -> void:
	_collect("res://")
	_files.sort()
	print("[compile-all] total scripts: ", _files.size())
	_next()

func _collect(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		var sub := dir.path_join(f)
		if d.current_is_dir():
			if not _is_skipped(f):
				_collect(sub)
		elif f.ends_with(".gd"):
			_files.append(sub)
		f = d.get_next()
	d.list_dir_end()

func _is_skipped(dir_name: String) -> bool:
	if dir_name.begins_with("."):
		return true
	return dir_name in SKIP_DIRS

func _next() -> void:
	if _idx >= _files.size():
		_finish()
		return
	var p := _files[_idx]
	_idx += 1
	_check(p)
	call_deferred("_next")

func _check(path: String) -> void:
	var res: Resource = ResourceLoader.load(path, "Script", ResourceLoader.CACHE_MODE_REUSE)
	if res == null:
		_bad.append("%s (load failed)" % path)
		return
	var scr := res as GDScript
	if scr == null:
		_bad.append("%s (not a GDScript)" % path)
		return
	# Ключевая проверка. Раньше гейт смотрел только `res == null`, но на битом
	# скрипте Godot отдаёт непустой объект — и гейт печатал OK при живой
	# Parse Error. У непарсящегося скрипта базовый тип пустой (Godot 4.7).
	if scr.get_instance_base_type() == "":
		_bad.append("%s (parse error)" % path)

func _finish() -> void:
	if _bad.is_empty():
		print("[compile-all] OK")
		get_tree().quit(0)
		return
	for b in _bad:
		print("[compile-all] BAD: ", b)
	print("[compile-all] FAILED: %d/%d" % [_bad.size(), _files.size()])
	get_tree().quit(1)
