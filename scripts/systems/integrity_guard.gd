extends Node

const MAX_COINS: int = 9999999
const ECONOMY_INTERVAL: float = 5.0
const WATCHDOG_INTERVAL: float = 1.0

var _economy_timer: float = ECONOMY_INTERVAL
var _watchdog_timer: float = WATCHDOG_INTERVAL
var _last_coins: int = 0
var _last_position: Vector3 = Vector3.ZERO
var _last_hp: float = 100.0
var _last_battery: float = 100.0
var _last_stamina: float = 100.0
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

func _process(delta: float) -> void:
	_economy_timer -= delta
	_watchdog_timer -= delta
	if _economy_timer <= 0.0:
		_economy_timer = ECONOMY_INTERVAL
		_check_economy()
	if _watchdog_timer <= 0.0:
		_watchdog_timer = WATCHDOG_INTERVAL
		_watchdog()

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
		CoinWallet.from_dict({"coins": current})
		push_warning("IntegrityGuard: economy value clamped")
	if current != _last_coins:
		_last_coins = current

func _watchdog() -> void:
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
	_validate_float(player, "hp", 0.0, 1000.0, _last_hp)
	_validate_float(player, "battery", 0.0, 1000.0, _last_battery)
	_validate_float(player, "stamina", 0.0, 1000.0, _last_stamina)
	_capture_snapshot()

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
	target.set(property_name, clampf(number, minimum, maximum))
