extends Node
## Статическая проверка арности подписок на сигналы автолоадов.
##
## В Godot 4 callable обязан принимать не меньше аргументов, чем эмитит сигнал.
## Компилятор это не ловит: подписка проходит сборку и падает в рантайме на
## КАЖДОМ emit — а обработчик молча не срабатывает. Именно так
## tutorial_system.gd подписался на 2-аргументный puzzle_solved однокарным
## методом, а трекер квестов — на 3-аргументный quest_progress безаргументным.
##
## Запуск: godot --headless --path . res://scenes/tools/signal_arity_check_scene.tscn

const ROOTS: Array[String] = ["res://scripts", "res://scenes"]

var _fails: int = 0
var _checked: int = 0
var _sig_args: Dictionary = {}   # "Autoload.signal" -> кол-во аргументов

func _ready() -> void:
	var names := _collect_signals()
	if names.is_empty():
		_fail("автолоады с сигналами не найдены")
		print("[sig] DONE fails=", _fails)
		get_tree().quit(1)
		return
	var re := RegEx.new()
	# <Autoload>.<signal>.connect(<Callable>) — берём автолоад, сигнал и аргумент.
	re.compile("(?<![A-Za-z0-9_.])(%s)\\.([A-Za-z_][A-Za-z0-9_]*)\\.connect\\(([^)]*)\\)"
		% "|".join(names))
	for root in ROOTS:
		_scan(root, re)
	print("[sig] signals: ", _sig_args.size(), "  connections checked: ", _checked)
	print("[sig] DONE fails=", _fails)
	get_tree().quit(1 if _fails > 0 else 0)

## Все автолоады, а не только EventBus: сигналы есть и у QuestManager,
## и у CoinWallet, и у XpManager — ошибки арности там ровно те же.
func _collect_signals() -> Array[String]:
	var names: Array[String] = []
	for child in get_node("/root").get_children():
		if child == self or child == get_parent():
			continue
		var has_own := false
		for s in child.get_signal_list():
			# Сигналы самого Node нам не интересны — только объявленные в скрипте.
			if (s.flags as int) & METHOD_FLAG_OBJECT_CORE:
				continue
			_sig_args["%s.%s" % [child.name, s.name]] = (s.args as Array).size()
			has_own = true
		if has_own:
			names.append(String(child.name))
	return names

func _scan(dir_path: String, re: RegEx) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with(".gd") or f.ends_with(".tscn"):
			_scan_file(dir_path.path_join(f), re)
	for sub in d.get_directories():
		_scan(dir_path.path_join(sub), re)

func _scan_file(path: String, re: RegEx) -> void:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return
	var lines := text.split("\n")
	for i in lines.size():
		for m in re.search_all(lines[i]):
			var key := "%s.%s" % [m.get_string(1), m.get_string(2)]
			var arg := m.get_string(3).strip_edges()
			if not _sig_args.has(key):
				continue  # несуществующие сигналы — забота autoload_api_check
			_checked += 1
			var handler := _handler_name(arg)
			if handler.is_empty():
				continue  # лямбда или bind() — арность разбирать не берёмся
			var declared := _method_arity(text, handler)
			if declared < 0:
				continue  # метод объявлен в другом файле/базовом классе
			var emitted: int = _sig_args[key]
			if declared < emitted:
				_fail("%s:%d  %s(%d args) -> %s(%d params)" % [
					path, i + 1, key, emitted, handler, declared])

## Из тела connect() достаём простое имя метода. Всё остальное (лямбды,
## Callable(...).bind(), self.method) пропускаем — ложные срабатывания хуже
## пропусков для гейта, который должен всегда быть зелёным.
func _handler_name(arg: String) -> String:
	if arg.is_empty() or arg.contains("func") or arg.contains("bind") or arg.contains("("):
		return ""
	if arg.begins_with("self."):
		arg = arg.substr(5)
	return arg if arg.is_valid_identifier() else ""

## Число параметров метода в том же файле; -1 если объявления здесь нет.
## Параметры со значением по умолчанию считаются: они не требуются от вызова.
func _method_arity(text: String, method: String) -> int:
	var re := RegEx.new()
	re.compile("(?m)^\\s*func\\s+%s\\s*\\(([^)]*)\\)" % method)
	var m := re.search(text)
	if m == null:
		return -1
	var params := m.get_string(1).strip_edges()
	return 0 if params.is_empty() else params.split(",").size()

func _fail(msg: String) -> void:
	_fails += 1
	print("[sig] [FAIL] ", msg)
