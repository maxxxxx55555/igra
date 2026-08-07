extends Node
## Гейт автолоадов. Сцена: scenes/tools/autoload_api_check_scene.tscn
##
## Статически проверяет, что каждое обращение вида `Autoload.member` в коде
## действительно существует — как метод, свойство, сигнал или константу.
## Поводом стали 20 несуществующих методов SettingsManager (apply_graphics,
## set_fps_cap, set_shadow_quality...), из-за которых экран настроек падал
## на каждом ползунке: компилятор такие вызовы не ловит, они разрешаются
## в рантайме.

const SCAN_DIRS: Array = ["res://scripts", "res://scenes"]
const SKIP_DIRS: Array = [".godot", ".git", "_BACKUPS"]

## Обращения, которые не должны существовать на автолоаде: это встроенные
## методы Object/Node либо синтаксис, который regex не различает.
const BUILTIN_OK: Array = [
	"new", "call", "call_deferred", "callv", "get", "set", "free", "queue_free",
	"connect", "disconnect", "emit_signal", "has_method", "has_signal", "get_script",
	"is_inside_tree", "get_node", "get_node_or_null", "get_tree", "add_child",
	"remove_child", "get_children", "get_parent", "notification", "duplicate",
	"get_instance_id", "is_queued_for_deletion", "set_process", "set_physics_process",
	"get_class", "is_class", "propertize", "resource_path", "name", "owner"]

var _autoloads: Dictionary = {}
var _bad: Array = []
var _checked: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_collect_autoloads()
	print("[api] autoloads: ", _autoloads.size())
	var re := RegEx.new()
	# Ровно одно обращение: имя автолоада, точка, идентификатор.
	re.compile("(?<![A-Za-z0-9_.])(%s)\\.([A-Za-z_][A-Za-z0-9_]*)" % "|".join(_autoloads.keys()))
	for d in SCAN_DIRS:
		_scan(d, re)
	print("[api] references checked: ", _checked)
	if _bad.is_empty():
		print("[api] DONE fails=0")
	else:
		for b in _bad:
			print("[api] [FAIL] ", b)
		print("[api] DONE fails=", _bad.size())
	get_tree().quit(0 if _bad.is_empty() else 1)

func _collect_autoloads() -> void:
	for child in get_tree().root.get_children():
		if child == self or child == get_parent():
			continue
		# Автолоады — прямые дети root, добавленные до текущей сцены.
		if child is Window:
			continue
		_autoloads[child.name] = child

func _scan(dir: String, re: RegEx) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		if sub in SKIP_DIRS:
			continue
		_scan(dir + "/" + sub, re)
	for f in d.get_files():
		if f.ends_with(".gd"):
			_scan_file(dir + "/" + f, re)

func _scan_file(path: String, re: RegEx) -> void:
	var src := FileAccess.get_file_as_string(path)
	if src.is_empty():
		return
	for m in re.search_all(src):
		var owner_name: String = m.get_string(1)
		var member: String = m.get_string(2)
		if member in BUILTIN_OK:
			continue
		_checked += 1
		var node: Node = _autoloads[owner_name]
		if _has_member(node, member):
			continue
		var line: int = src.substr(0, m.get_start()).count("\n") + 1
		_bad.append("%s:%d  %s.%s does not exist" % [path, line, owner_name, member])

func _has_member(node: Node, member: String) -> bool:
	if node.has_method(member) or node.has_signal(member):
		return true
	for p in node.get_property_list():
		if p.name == member:
			return true
	var scr := node.get_script() as GDScript
	while scr != null:
		if scr.get_script_constant_map().has(member):
			return true
		scr = scr.get_base_script() as GDScript
	return false
