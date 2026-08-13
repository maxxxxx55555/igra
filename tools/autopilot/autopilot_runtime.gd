extends RefCounted
## Каркас автопилота: регистрация тестов, вотчдог, отчёт и скриншоты.
##
## Тест — это Callable, который получает ссылку на этот объект и пользуется
## check()/fail(). Любой тест обязан завершиться: за временем следит вотчдог
## в autopilot_main.gd, поэтому зависание превращается в [FAIL], а не в
## бесконечно висящий процесс на машине владельца.

const REPORT_DIR: String = "res://tools/autopilot_report"
const SHOTS_DIR: String = "res://tools/autopilot_report/shots"

var _lines: PackedStringArray = []
var _passed: int = 0
var _failed: int = 0
var _current: String = ""
var _current_failed: bool = false
var _shots: int = 0

## Сообщения текущего теста: копятся, чтобы печатать их под именем теста.
var _notes: PackedStringArray = []

func begin(test_name: String) -> void:
	_current = test_name
	_current_failed = false
	_notes = []

## Утверждение. Первое падение внутри теста делает весь тест [FAIL],
## но остальные проверки всё равно выполняются — так в отчёте видно
## сразу все симптомы, а не только первый.
func check(condition: bool, message: String) -> bool:
	if condition:
		return true
	_current_failed = true
	_notes.append("      ! " + message)
	return false

func note(message: String) -> void:
	_notes.append("      · " + message)

func fail(message: String) -> void:
	_current_failed = true
	_notes.append("      ! " + message)

## Упал ли последний завершённый тест — для строки прогресса в консоли.
var _last_failed: bool = false

func last_test_failed() -> bool:
	return _last_failed

func end() -> void:
	if _current == "":
		return
	_last_failed = _current_failed
	if _current_failed:
		_failed += 1
		_lines.append("[FAIL] " + _current)
	else:
		_passed += 1
		_lines.append("[PASS] " + _current)
	for n in _notes:
		_lines.append(n)
	_current = ""
	_notes = []

## Тест, который невозможно выполнить (нет предусловий), — это FAIL:
## молча пропущенная проверка создаёт ложное ощущение зелёного прогона.
func unavailable(reason: String) -> void:
	fail("не удалось выполнить: " + reason)

func failed_count() -> int:
	return _failed

func passed_count() -> int:
	return _passed

func shot_count() -> int:
	return _shots

## Скриншот текущего кадра.
##
## Обязательно ждём RenderingServer.frame_post_draw: get_image() без этого
## возвращает содержимое ещё не отрисованного кадра, и на диск ложится
## пустая картинка. Путь глобализуем — при запуске через --script res://
## указывает на папку проекта, но save_png надёжнее работает с абсолютным.
func screenshot(tree: SceneTree, shot_name: String) -> void:
	var vp := tree.root.get_viewport()
	if vp == null:
		note("скриншот " + shot_name + ": нет вьюпорта")
		return
	await RenderingServer.frame_post_draw
	var tex := vp.get_texture()
	if tex == null:
		note("скриншот " + shot_name + ": вьюпорт без текстуры (нет окна?)")
		return
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		note("скриншот " + shot_name + ": пустой кадр")
		return
	var dir := ProjectSettings.globalize_path(SHOTS_DIR)
	DirAccess.make_dir_recursive_absolute(dir)
	if img.save_png(dir.path_join(shot_name + ".png")) == OK:
		_shots += 1
	else:
		note("скриншот " + shot_name + ": не сохранился")

func write_report(seconds: float) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	var head: PackedStringArray = []
	head.append("THE LAST STREETLIGHT — автоматический прогон")
	head.append("дата: " + Time.get_datetime_string_from_system())
	head.append("Godot: " + Engine.get_version_info().get("string", "?"))
	head.append("")
	var body := "\n".join(head) + "\n" + "\n".join(_lines) + "\n"
	var total := _passed + _failed
	var tail: PackedStringArray = []
	tail.append("")
	tail.append("──────────────────────────────────────────")
	tail.append("всего тестов: %d   успешно: %d   провалено: %d" % [total, _passed, _failed])
	tail.append("скриншотов: %d" % _shots)
	tail.append("время: %.1f с" % seconds)
	if _failed == 0:
		tail.append("ИТОГ: всё зелёное")
	else:
		tail.append("ИТОГ: есть падения — смотри строки [FAIL] выше")
	var text := body + "\n".join(tail) + "\n"
	var f := FileAccess.open(REPORT_DIR + "/report.txt", FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()
	return text
