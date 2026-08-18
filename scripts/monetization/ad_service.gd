extends Node
## Реклама за вознаграждение, независимо от поставщика.
##
## Игровой код знает только про этот сервис. Поставщик подставляется в
## `_provider` и обязан уметь три вещи: initialize(), is_ready(), show(id).
## По умолчанию стоит заглушка — «ролик» на 3 секунды, чтобы весь поток
## можно было прогнать без SDK и без устройства.
##
## Мобильный SDK подключается отдельным файлом (см. ..\refs\godot-admob и
## ..\refs\AppLovin-MAX-Godot), игровой код при этом не меняется.

signal reward_granted(reward_id: StringName, amount: int)
signal ad_failed(reason: String)

## Что игрок получает за просмотр. Суммы держим здесь, чтобы баланс правился
## в одном месте, а не по четырём точкам вызова.
const REWARDS: Dictionary = {
	&"double_xp": 0,        # множитель, а не количество: обрабатывает XpManager
	&"revive": 1,
	&"extra_battery": 1,
	&"bonus_coins": 100,
	&"hint_reveal": 1,
}

const COOLDOWN_SEC: float = 900.0  ## 15 минут между роликами

@export var enabled: bool = true   ## рубильник: выключает рекламу целиком

var _provider: Object = null
var _last_shown_ms: int = -1
var _in_flight: bool = false

const CrazyGamesStub := preload("res://scripts/monetization/stub_crazy_games.gd")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # ролик показывается и на паузе
	set_provider(_default_provider())

## В вебе настоящего SDK нет — ставим заглушку, которая честно говорит
## «роликов нет» и не роняет сборку. Везде остальное — отладочная заглушка.
func _default_provider() -> Object:
	if OS.has_feature("web"):
		return CrazyGamesStub.new(self)
	return StubAdProvider.new(self)

## Подмена поставщика: сюда придёт настоящий SDK, отсюда же его берут тесты.
func set_provider(provider: Object) -> void:
	_provider = provider
	if _provider != null:
		_provider.initialize()

## Готов ли ролик к показу прямо сейчас. Причина отказа не возвращается —
## вызывающему достаточно знать, показывать ли кнопку.
func is_rewarded_ready() -> bool:
	return enabled and not _in_flight and _cooldown_left() <= 0.0 and _provider != null and _provider.is_ready()

## Сколько секунд осталось до следующего доступного ролика.
func cooldown_left() -> float:
	return _cooldown_left()

func show_rewarded(reward_id: StringName) -> void:
	if not REWARDS.has(reward_id):
		_fail("неизвестная награда: " + String(reward_id))
		return
	if not is_rewarded_ready():
		_fail("ролик не готов")
		return
	_in_flight = true
	_provider.show(reward_id)

## Поставщик зовёт это, когда игрок досмотрел ролик.
func _on_provider_reward(reward_id: StringName) -> void:
	_in_flight = false
	_last_shown_ms = Time.get_ticks_msec()
	reward_granted.emit(reward_id, int(REWARDS.get(reward_id, 0)))

## Поставщик зовёт это при любой осечке. Кулдаун не трогаем: неудачный показ
## не должен запирать игрока на 15 минут.
func _on_provider_failed(reason: String) -> void:
	_in_flight = false
	_fail(reason)

func _fail(reason: String) -> void:
	ad_failed.emit(reason)

func _cooldown_left() -> float:
	if _last_shown_ms < 0:
		return 0.0
	var passed := float(Time.get_ticks_msec() - _last_shown_ms) / 1000.0
	return maxf(0.0, COOLDOWN_SEC - passed)


## Заглушка: показывает окно с отсчётом и кнопкой. Ничего не грузит из сети,
## поэтому годится и для автопилота, и для отладки в редакторе.
class StubAdProvider:
	const POPUP := preload("res://scripts/monetization/ad_popup.gd")

	var _service: Node

	func _init(service: Node) -> void:
		_service = service

	func initialize() -> void:
		pass

	func is_ready() -> bool:
		return true

	func show(reward_id: StringName) -> void:
		var popup := POPUP.new()
		popup.name = "AdPopup"  # по этому имени окно находит автопилот
		popup.claimed.connect(func() -> void: _service._on_provider_reward(reward_id))
		popup.dismissed.connect(func() -> void: _service._on_provider_failed("игрок закрыл ролик"))
		# Показ могут запросить из _ready другого узла, когда root ещё занят
		# расстановкой детей — прямой add_child() там молча проваливается.
		_service.get_tree().root.add_child.call_deferred(popup)
