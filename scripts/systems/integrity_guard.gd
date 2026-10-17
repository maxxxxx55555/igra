extends Node

const _Log := preload("res://scripts/security/security_log.gd")
const _Scan := preload("res://scripts/security/integrity_scan.gd")
## The wallet's own cap (coin_wallet.gd): about 80 times what a winning run earns (the bot's wins earn 11,000).
const MAX_COINS: int = 999999
## Two clocks that run in real time, the engine's monotonic ticks and the system's wall clock, keep step; a hooked timer (a speed hack) moves one of
## them. A window of CLOCK_WINDOW_SEC is off when they differ by more than CLOCK_TOLERANCE of it; CLOCK_OFF_WINDOWS in a row are a speed hack (a wall
## clock set once, or a phone that slept, is one window).
const CLOCK_WINDOW_SEC: float = 10.0
const CLOCK_TOLERANCE: float = 0.25
const CLOCK_OFF_WINDOWS: int = 2
const EMULATOR_MARKS: Array[String] = ["sdk_gphone", "emulator", "android sdk built for", "genymotion", "ranchu", "vbox"]
const ECONOMY_INTERVAL: float = 5.0
const WATCHDOG_INTERVAL: float = 1.0
## The game never runs faster than real time (the hit-stop and the slow motion of wow_director.gd only go below 1.0): a release build puts the speed back and says so.
const MAX_TIME_SCALE: float = 1.05
## A vital over its own maximum by more than this share is a memory edit and not a rounding.
const VITALS_SLACK: float = 1.05

var _economy_timer: float = ECONOMY_INTERVAL
var _watchdog_timer: float = WATCHDOG_INTERVAL
var _last_coins: int = 0
var _last_position: Vector3 = Vector3.ZERO
var _last_hp: float = 100.0
var _last_battery: float = 100.0
var _last_stamina: float = 100.0
## Set by a violation that says the build or the clock was tampered with (a changed data file, a speed hack, a debugger on a release build): the
## leaderboard stops recording runs. An emulator is logged and does not set it: many players run the game on one.
var tampered: bool = false
var _window_ticks: int = 0
var _window_wall: float = 0.0
var _off_windows: int = 0
## TRUTH WAVE P1: один пропущенный тик ватчдога (1с) достаточно наивно
## считался "игрок пропал навсегда" и бросал в меню — а игрок на деле мог
## быть просто посреди обычной смерти/перехода (переродждение узла,
## смена сцены), пока GameManager ещё не успел сам выставить DEAD. Гонка
## воспроизводилась на boot_check_scene.tscn: watchdog форсил MENU раньше,
## чем реальная логика смерти успевала отработать. Требуем несколько
## подряд неудачных тиков, прежде чем считать это настоящей поломкой.
const MISSING_PLAYER_GRACE_TICKS: int = 3
var _missing_player_ticks: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if is_instance_valid(EventBus):
		if EventBus.has_signal("game_started"):
			EventBus.game_started.connect(_capture_snapshot)
	_capture_snapshot()
	_window_ticks = Time.get_ticks_usec()
	_window_wall = Time.get_unix_time_from_system()
	call_deferred("_scan_resources")
	call_deferred("_android_checks")

func _process(delta: float) -> void:
	_economy_timer -= delta
	_watchdog_timer -= delta
	if _economy_timer <= 0.0:
		_economy_timer = ECONOMY_INTERVAL
		_check_economy()
	if _watchdog_timer <= 0.0:
		_watchdog_timer = WATCHDOG_INTERVAL
		_watchdog()
	_watch_clocks()

## One violation: a line in the encrypted log (scripts/security/security_log.gd) and, unless `taints` is false, the tampered flag.
func flag(kind: String, detail: String, taints: bool = true) -> void:
	_Log.record(kind, detail)
	push_warning("IntegrityGuard: %s (%s)" % [kind, detail])
	if taints:
		tampered = true

static func window_is_off(ticks_sec: float, wall_sec: float) -> bool:
	return absf(ticks_sec - wall_sec) > CLOCK_TOLERANCE * ticks_sec

func _watch_clocks() -> void:
	var ticks_sec: float = float(Time.get_ticks_usec() - _window_ticks) / 1000000.0
	if ticks_sec < CLOCK_WINDOW_SEC:
		return
	var wall_sec: float = Time.get_unix_time_from_system() - _window_wall
	_off_windows = _off_windows + 1 if window_is_off(ticks_sec, wall_sec) else 0
	_window_ticks = Time.get_ticks_usec()
	_window_wall = Time.get_unix_time_from_system()
	if _off_windows >= CLOCK_OFF_WINDOWS:
		_off_windows = 0
		flag("speed", "monotonic %.1f s against wall %.1f s" % [ticks_sec, wall_sec])

func _scan_resources() -> void:
	var bad: Array[String] = _Scan.mismatches()
	if not bad.is_empty():
		flag("resources", ", ".join(PackedStringArray(bad.slice(0, 5))))

static func looks_like_emulator(model: String) -> bool:
	var lower := model.to_lower()
	for mark: String in EMULATOR_MARKS:
		if lower.contains(mark):
			return true
	return false

## Android only (the Java wrapper is not in other builds): an emulator is logged; a debugger attached to a release build is a tamper and ends the run.
func _android_checks() -> void:
	if OS.get_name() != "Android":
		return
	if looks_like_emulator(OS.get_model_name()):
		flag("emulator", OS.get_model_name(), false)
	if not Engine.has_singleton("JavaClassWrapper"):
		return
	var debug: Object = (Engine.get_singleton("JavaClassWrapper") as Object).call("wrap", "android.os.Debug")
	if debug != null and bool(debug.call("isDebuggerConnected")):
		flag("debugger", "a debugger is attached")
		if not OS.is_debug_build():
			get_tree().quit()

func _capture_snapshot() -> void:
	if is_instance_valid(CoinWallet):
		_last_coins = clampi(CoinWallet.get_coins(), 0, MAX_COINS)
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	_last_position = player.global_position
	_last_hp = _read_float(player, "hp", _last_hp)
	_last_battery = _read_float(player, "battery", _last_battery)
	_last_stamina = _read_float(player, "stamina", _last_stamina)

func _check_economy() -> void:
	if not is_instance_valid(CoinWallet):
		return
	var current: int = clampi(CoinWallet.get_coins(), 0, MAX_COINS)
	if current != CoinWallet.get_coins():
		flag("economy", "wallet %d outside 0..%d" % [CoinWallet.get_coins(), MAX_COINS])
		CoinWallet.from_dict({"coins": current})
	if is_instance_valid(NewGamePlus) and NewGamePlus.enforce_bounds():
		flag("ngplus", "the level or the modifiers were over what a run earns")
	if current != _last_coins:
		_last_coins = current

func _watchdog() -> void:
	_watch_time_scale()
	if not is_instance_valid(GameManager):
		return
	if not GameManager.is_playing():
		_missing_player_ticks = 0
		return
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		_missing_player_ticks += 1
		if _missing_player_ticks < MISSING_PLAYER_GRACE_TICKS:
			return
		# GameManager уже мог легитимно уйти из PLAYING (смерть/пауза/т.д.)
		# в течение периода ожидания — тогда это не поломка, а обычный переход.
		if not GameManager.is_playing():
			_missing_player_ticks = 0
			return
		push_warning("IntegrityGuard: player missing")
		if GameManager.has_method("_change_state"):
			GameManager._change_state(GameManager.GameState.MENU)
		return
	_missing_player_ticks = 0
	if not player.global_position.is_finite() or player.global_position.y <= -50.0:
		player.global_position = _last_position
		push_warning("IntegrityGuard: player position restored")
	else:
		_last_position = player.global_position
	var stats: Object = player.get("stats")
	_validate_float(player, "hp", 0.0, _read_float(stats, "max_hp", 1000.0) if stats != null else 1000.0, _last_hp)
	_validate_float(player, "battery", 0.0, _read_float(player, "battery_max", 1000.0), _last_battery)
	_validate_float(player, "stamina", 0.0, _read_float(stats, "stamina_max", 1000.0) if stats != null else 1000.0, _last_stamina)
	_capture_snapshot()

func _watch_time_scale(enforce: bool = not OS.is_debug_build()) -> void:
	if enforce and Engine.time_scale > MAX_TIME_SCALE:
		flag("speed", "time scale %.2f" % Engine.time_scale)
		Engine.time_scale = 1.0

func _read_float(target: Object, property_name: String, fallback: float) -> float:
	var value: Variant = target.get(property_name)
	if value == null or not is_finite(float(value)):
		return fallback
	return float(value)

func _validate_float(target: Object, property_name: String, minimum: float, maximum: float, fallback: float) -> void:
	var value: Variant = target.get(property_name)
	if value == null:
		return
	var number: float = float(value)
	if not is_finite(number):
		target.set(property_name, fallback)
		return
	if number > maximum * VITALS_SLACK:
		flag("vitals", "%s %.0f over its maximum %.0f" % [property_name, number, maximum])
	target.set(property_name, clampf(number, minimum, maximum))
