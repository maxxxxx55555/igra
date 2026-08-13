extends SceneTree
## Автоматический прогон игры в настоящем Godot — без участия человека.
##
## Запуск (одной строкой, см. docs/ONE_COMMAND_TEST.md):
##   godot --path <проект> --script res://tools/autopilot/autopilot_main.gd
##
## Почему extends SceneTree: в режиме --script движок поднимает автозагрузки
## и рендерер, но НЕ запускает главную сцену. Значит, сцены можно поднимать
## по одной и проверять их изолированно, а не воевать с уже идущей игрой.
##
## Вотчдог: каждый тест ограничен по времени. Зависший тест снимается и
## отмечается [FAIL] — прогон на машине владельца обязан завершаться всегда.

const Runtime := preload("res://tools/autopilot/autopilot_runtime.gd")
const Suite := preload("res://tools/autopilot/autopilot_tests.gd")

## Сколько секунд отводится одному тесту. Взято с запасом: самый тяжёлый
## тест поднимает мир района целиком.
const TEST_BUDGET_SEC: float = 25.0

## Общий предел на весь прогон — страховка от зацикливания вне тестов.
const TOTAL_BUDGET_SEC: float = 600.0

var _rt: Runtime = null
var _started_usec: int = 0

func _initialize() -> void:
	_started_usec = Time.get_ticks_usec()
	_rt = Runtime.new()
	print("=== АВТОПИЛОТ: старт ===")
	# Тесты идут в собственной корутине, а _process продолжает крутить кадры:
	# без живого главного цикла не отрисуется ни один скриншот.
	_run_all()

## Защита от повторного завершения: _finish() зовут и обычный конец прогона,
## и аварийный лимит в _process. Без флага отчёт писался бы дважды, а quit()
## вызывался поверх уже идущего выхода.
var _finished: bool = false

## MainLoop._process возвращает bool: true завершает главный цикл.
## Поэтому здесь всегда false — выходом управляет только quit() в _finish().
func _process(_delta: float) -> bool:
	if _finished:
		return false
	if _elapsed() > TOTAL_BUDGET_SEC:
		# Сюда попадаем, только если тест навсегда завис на await: обычный
		# путь до этого места не доходит. Отчёт всё равно будет записан.
		_rt.fail("прогон прерван: превышен общий лимит %.0f с" % TOTAL_BUDGET_SEC)
		_rt.end()
		_finish()
	return false

func _elapsed() -> float:
	return float(Time.get_ticks_usec() - _started_usec) / 1_000_000.0

func _run_all() -> void:
	var suite := Suite.new()
	var tests: Array = suite.collect()
	# Тесты пишут в настоящий файл сохранения. Прячем прогресс владельца
	# до прогона и возвращаем после — автопроверка не должна ничего стереть.
	suite.backup_save()
	for entry in tests:
		var test_name: String = entry["name"]
		var fn: Callable = entry["fn"]
		# Изоляция: упавший тест мог оставить дерево на паузе или замедленным.
		# Следующий тест не должен расплачиваться за чужой мусор.
		paused = false
		Engine.time_scale = 1.0
		_rt.begin(test_name)
		var deadline := _elapsed() + TEST_BUDGET_SEC
		# Вотчдог: тест сам обязан вернуть управление. Если он уходит в
		# await и не возвращается, срабатывает общий лимит в _process.
		var ok: bool = await _guarded(fn, deadline)
		if not ok:
			_rt.fail("тест не уложился в %.0f с — считаем зависанием" % TEST_BUDGET_SEC)
		_rt.end()
		print(("  FAIL " if _rt.last_test_failed() else "  ok   ") + test_name)
		# Пишем отчёт после каждого теста. Если движок упадёт на следующем,
		# у владельца всё равно останется файл с уже пройденной частью.
		_rt.write_report(_elapsed())
	suite.restore_save()
	_finish()

## Запускает тест и следит, чтобы он не выбил бюджет. Callable может быть
## как обычным, так и корутиной — await корректно обрабатывает оба случая.
func _guarded(fn: Callable, deadline: float) -> bool:
	await fn.call(self, _rt)
	return _elapsed() <= deadline

func _finish() -> void:
	if _finished:
		return
	_finished = true
	var text := _rt.write_report(_elapsed())
	print(text)
	var code := _rt.failed_count()
	print("=== АВТОПИЛОТ: конец, провалов %d ===" % code)
	# Код возврата равен числу падений: удобно для CI и для владельца.
	quit(code)
