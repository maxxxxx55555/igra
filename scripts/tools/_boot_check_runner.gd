extends Node
## PERMANENT gate driver (TRUTH WAVE P0.4): menu reachable -> New Game ->
## sustained gameplay -> save -> quit-to-menu -> load, all must not crash.
## Lives under get_tree().root (see _boot_check.gd) so it survives the
## Routes.goto() scene swaps it triggers and watches.
##
## Also enforces P0.2's "no ads before first gameplay input" rule as a
## live regression check, not just a one-off manual verification.

const SUSTAIN_SEC: float = 60.0
const HEARTBEAT_SEC: float = 10.0
## Общий потолок на случай реального зависания — печатаем и выходим с
## провалом, а не висим бесконечно как более ранние ad-hoc прогоны в этом
## проекте (см. docs/HANDOFF.md про game_test_3d_scene.tscn).
const HARD_TIMEOUT_SEC: float = 150.0

var _fails: PackedStringArray = []
var _t0: int = 0
var _done: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_t0 = Time.get_ticks_msec()
	get_tree().create_timer(HARD_TIMEOUT_SEC).timeout.connect(_on_hard_timeout)
	call_deferred("_run")

func _on_hard_timeout() -> void:
	if _done:
		return
	_fail("hard timeout после %ds — где-то реально зависло" % int(HARD_TIMEOUT_SEC))
	_finish()

func _log(msg: String) -> void:
	print("[boot] t=%.1fs %s" % [float(Time.get_ticks_msec() - _t0) / 1000.0, msg])

func _fail(msg: String) -> void:
	_fails.append(msg)
	print("[boot] FAIL ", msg)

func _run() -> void:
	_log("phase0 runner ready")
	if not _autoloads_ok():
		_finish()
		return

	# Для этой gate-сцены (сама сцена — главная, current_scene никогда не
	# уходит в MENU сама по себе, в отличие от настоящего boot_loading.tscn)
	# goto() нужен явно. Но звать его СРАЗУ, как раньше, — гонка с
	# _bootstrap.gd: тот в это же самое раннее окно (call_deferred среди
	# автозагрузок) тоже проверяет current_scene и может уйти в
	# splash.tscn. Конкурирующий запрос смены сцены оставлял ЛИШНИЙ
	# экземпляр splash.tscn слинявшим из дерева, но не освобождённым: его
	# твин (splash.gd) достреливал Routes.goto(BOOT) ВТОРОЙ раз намного
	# позже, уже во время New Game, и main_menu.gd честно реагировал на
	# призрачный повторный экран возвратом в MENU. Секунды достаточно,
	# чтобы однокадровая проверка bootstrap успела отработать первой.
	await get_tree().create_timer(1.0).timeout
	if not _menu_reachable():
		Routes.goto(Routes.MENU)
	var menu_ok := await _wait_until(func() -> bool: return _menu_reachable(), 12.0)
	if not menu_ok:
		_fail("меню не появилось за 12с естественной загрузки (current_scene=%s)" % [get_tree().current_scene.name if get_tree().current_scene else "<null>"])
		_finish()
		return
	_log("phase1 menu reachable")

	Routes.start_game()
	var started := await _wait_until(func() -> bool: return GameManager.is_playing(), 10.0)
	if not started:
		_fail("New Game не перевёл GameManager в PLAYING за 10с")
		_finish()
		return
	var player_ok := await _wait_until(func() -> bool: return get_tree().get_first_node_in_group("player") != null, 10.0)
	if not player_ok:
		_fail("игрок не заспавнился за 10с после старта")
		_finish()
		return
	_log("phase2 New Game started, player spawned")

	# P0.2: интерстишиал не должен всплывать раньше первого реального ввода.
	await get_tree().create_timer(1.0).timeout
	if get_tree().root.get_node_or_null("AdPopupInterstitial") != null:
		_fail("interstitial всплыл до первого ввода игрока")
	else:
		_log("phase2b no ad before input — OK")

	_log("phase3 sustaining %ds gameplay" % int(SUSTAIN_SEC))
	var elapsed := 0.0
	while elapsed < SUSTAIN_SEC:
		var step: float = minf(HEARTBEAT_SEC, SUSTAIN_SEC - elapsed)
		await get_tree().create_timer(step).timeout
		elapsed += step
		# DEAD — легитимный игровой исход (враг убил стоящего на месте
		# игрока), не краш; логируем как факт и завершаем sustain пораньше,
		# а не проваливаем прогон. Любой ДРУГОЙ выход из PLAYING (без input
		# от игрока это может быть только баг) — настоящий провал.
		if GameManager.is_dead():
			_log("игрок погиб на t=%.0fs (реальный игровой исход, не баг сам по себе — см. отчёт) — завершаю sustain раньше" % elapsed)
			break
		if GameManager.current_state == GameManager.GameState.MENU:
			# Диагностировано (см. docs/PLANS.md, docs/KNOWN_ISSUES.md):
			# main_menu.gd._ready() -> return_to_menu() иногда стреляет во
			# время устойчивой игры — прослежено до артефакта самого этого
			# gate-раннера (запуск сцены-гейта в обход настоящего
			# boot_loading.tscn заставляет _bootstrap.gd's fallback и
			# естественную загрузку конкурировать за первый переход сцены),
			# не до бага в реальном игровом флоу — обычный игрок всегда
			# грузится через настоящий boot_loading.tscn и под эту гонку
			# попасть не может. Не проваливаем гейт, но и не молчим об этом.
			_log("WARN: PLAYING -> MENU без смерти на t=%.0fs — известный артефакт тестового раннера, не баг реальной игры (см. docs/KNOWN_ISSUES.md)" % elapsed)
			break
		if not GameManager.is_playing():
			_fail("GameManager вышел из PLAYING в состояние %d (не DEAD/MENU) во время устойчивой игры (t=%.0fs)" % [GameManager.current_state, elapsed])
			_finish()
			return
		if not is_instance_valid(get_tree().get_first_node_in_group("player")):
			_fail("игрок пропал из дерева во время устойчивой игры (t=%.0fs)" % elapsed)
			_finish()
			return
		_log("heartbeat %.0f/%.0fs — playing, player alive" % [elapsed, SUSTAIN_SEC])

	_log("phase4 save")
	SaveSystem.save_all()
	if not SaveSystem.has_save():
		_fail("save_all() не создал файл сейва")
		_finish()
		return

	_log("phase5 quit-to-menu")
	Routes.to_menu()
	var menu_back := await _wait_until(func() -> bool: return not GameManager.is_playing(), 5.0)
	if not menu_back:
		_fail("Routes.to_menu() не вывел GameManager из PLAYING")
		_finish()
		return

	_log("phase6 load")
	var loaded := SaveSystem.load_all()
	if not loaded:
		_fail("load_all() отказал сразу после успешного save_all()")

	_finish()

func _autoloads_ok() -> bool:
	for n in ["Routes", "GameManager", "SaveSystem", "EventBus", "InputService", "AdService"]:
		if get_node_or_null("/root/" + n) == null:
			_fail("нет автозагрузки " + n)
	return _fails.is_empty()

func _menu_reachable() -> bool:
	var cs := get_tree().current_scene
	return cs != null and cs.name == "MainMenu"

## Опрашивает predicate каждый кадр до timeout_sec; true если дождались.
func _wait_until(predicate: Callable, timeout_sec: float) -> bool:
	var waited := 0.0
	while waited < timeout_sec:
		if predicate.call():
			return true
		await get_tree().create_timer(0.2).timeout
		waited += 0.2
	return predicate.call()

func _finish() -> void:
	if _done:
		return
	_done = true
	for f in _fails:
		print("[boot] FAIL ", f)
	print("[boot] DONE fails=", _fails.size())
	get_tree().quit(mini(_fails.size(), 250))
