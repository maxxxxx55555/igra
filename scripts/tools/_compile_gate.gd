extends Node

## Compile gate этапа 4: все .gd компилируются, все сцены грузятся,
## инстанцируются и не имеют битых зависимостей, все ресурсы читаются.
## Запускать как главную сцену (в режиме -s автозагрузки недоступны
## и дают ложные ошибки компиляции).

const SKIP_DIRS: PackedStringArray = [".godot", ".backup", ".git", "build", "_BACKUPS", "android"]

var _scripts: PackedStringArray = []
var _scenes: PackedStringArray = []
var _res: PackedStringArray = []
var _fails: PackedStringArray = []

func _ready() -> void:
	_scan("res://")
	print("GATE scan: gd=", _scripts.size(), " tscn=", _scenes.size(), " tres/res=", _res.size())
	_check_scripts()
	_check_resources()
	_check_scenes()
	for f in _fails:
		print("GATE FAIL ", f)
	print("COMPILE_GATE bad=", _fails.size())
	get_tree().quit(mini(_fails.size(), 250))

func _scan(dir_path: String) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		var full: String = dir_path.path_join(f) if dir_path != "res://" else "res://" + f
		if d.current_is_dir():
			if not f.begins_with(".") and not SKIP_DIRS.has(f):
				_scan(full)
		else:
			match f.get_extension().to_lower():
				"gd":
					_scripts.append(full)
				"tscn":
					_scenes.append(full)
				"tres", "res":
					_res.append(full)
		f = d.get_next()
	d.list_dir_end()

## Загрузка .gd уже компилирует его: null => ошибка парсинга.
func _check_scripts() -> void:
	for p in _scripts:
		if load(p) as Script == null:
			_fails.append("SCRIPT " + p)

func _check_resources() -> void:
	for p in _res:
		if ResourceLoader.load(p) == null:
			_fails.append("RES " + p)
		else:
			_check_deps(p)

## Битые [ext_resource] Godot не превращает в null-загрузку (ставит заглушку),
## поэтому зависимости проверяем отдельно.
func _check_deps(p: String) -> void:
	for dep in ResourceLoader.get_dependencies(p):
		var path: String = dep.get_slice("::", 2) if dep.count("::") >= 2 else dep
		if path.is_empty():
			continue
		if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
			_fails.append("DEP " + p + " -> " + path)

func _check_scenes() -> void:
	for p in _scenes:
		var ps: PackedScene = load(p) as PackedScene
		if ps == null:
			_fails.append("SCENE " + p)
			continue
		_check_deps(p)
		print("GATE inst ", p)
		var n: Node = ps.instantiate()
		if n == null:
			_fails.append("INST " + p)
			continue
		n.free()
