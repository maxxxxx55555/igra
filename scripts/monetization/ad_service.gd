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
signal interstitial_shown
signal interstitial_failed(reason: String)

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
## interstitial на смене района: не чаще раза в 3 минуты, никогда в бою.
const INTERSTITIAL_COOLDOWN_SEC: float = 180.0
## revive/extra_battery — по одному разу за сессию каждый (не общий лимит
## на оба), остальные награды подчиняются только 15-минутному кулдауну.
const SESSION_LIMITED: Array[StringName] = [&"revive", &"extra_battery"]
var _used_this_session: Dictionary = {}

@export var enabled: bool = true   ## рубильник: выключает рекламу целиком

var _provider: Object = null
var _last_shown_ms: int = -1
var _in_flight: bool = false
var _last_interstitial_ms: int = -1
var _interstitial_in_flight: bool = false

const CrazyGamesStub := preload("res://scripts/monetization/stub_crazy_games.gd")
const AppLovinProvider := preload("res://scripts/monetization/applovin_provider.gd")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # ролик показывается и на паузе
	set_provider(_default_provider())
	EventBus.district_entered.connect(func(_id: StringName) -> void: show_interstitial())

## SDK-ключ берём из project settings (monetization/applovin_sdk_key,
## пусто по умолчанию) — так подстановка реального ключа перед релизом
## не требует правки кода, см. docs/store/HUMAN_CHECKLIST.md.
## Пусто/веб/ключ не задан -> отладочная заглушка, игровой код не знает разницы.
func _default_provider() -> Object:
	if OS.has_feature("web"):
		return CrazyGamesStub.new(self)
	var sdk_key: String = str(ProjectSettings.get_setting("monetization/applovin_sdk_key", ""))
	if OS.has_feature("mobile") and not sdk_key.is_empty():
		return AppLovinProvider.new(self, sdk_key)
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

## reward_id-специфичная проверка: как is_rewarded_ready(), плюс лимит раз-в-
## сессию для revive/extra_battery (см. SESSION_LIMITED).
func can_show_reward(reward_id: StringName) -> bool:
	if reward_id in SESSION_LIMITED and _used_this_session.get(reward_id, false):
		return false
	return is_rewarded_ready()

## Сколько секунд осталось до следующего доступного ролика.
func cooldown_left() -> float:
	return _cooldown_left()

func show_rewarded(reward_id: StringName) -> void:
	if not REWARDS.has(reward_id):
		_fail("неизвестная награда: " + String(reward_id))
		return
	if not can_show_reward(reward_id):
		_fail("ролик не готов")
		return
	_in_flight = true
	_provider.show(reward_id)

## Поставщик зовёт это, когда игрок досмотрел ролик.
func _on_provider_reward(reward_id: StringName) -> void:
	_in_flight = false
	_last_shown_ms = Time.get_ticks_msec()
	if reward_id in SESSION_LIMITED:
		_used_this_session[reward_id] = true
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

## interstitial при смене района. "Никогда в бою" — читаем у MusicManager
## тот же _combat_hold, которым он уже держит боевую музыку, вместо
## отдельного трекера боя. TRUTH WAVE P0.2: "ads never before first
## gameplay input" — вход в первый район сам по себе не в счёт, ждём
## InputService.has_player_acted() (сбрасывается на новую игру).
func is_interstitial_ready() -> bool:
	if not (_provider != null and _provider.has_method("is_interstitial_ready")):
		return false
	var input_ok: bool = not (InputService and InputService.has_method("has_player_acted")) \
		or InputService.has_player_acted()
	return enabled and input_ok and not _interstitial_in_flight and _interstitial_cooldown_left() <= 0.0 \
		and not MusicManager.is_in_combat() and _provider.is_interstitial_ready()

func interstitial_cooldown_left() -> float:
	return _interstitial_cooldown_left()

func show_interstitial() -> void:
	if not is_interstitial_ready():
		return
	_interstitial_in_flight = true
	_provider.show_interstitial()

func _on_provider_interstitial_shown() -> void:
	_interstitial_in_flight = false
	_last_interstitial_ms = Time.get_ticks_msec()
	interstitial_shown.emit()

func _on_provider_interstitial_failed(reason: String) -> void:
	_interstitial_in_flight = false
	interstitial_failed.emit(reason)

func _interstitial_cooldown_left() -> float:
	if _last_interstitial_ms < 0:
		return 0.0
	var passed := float(Time.get_ticks_msec() - _last_interstitial_ms) / 1000.0
	return maxf(0.0, INTERSTITIAL_COOLDOWN_SEC - passed)


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

	func is_interstitial_ready() -> bool:
		return true

	func show_interstitial() -> void:
		var popup := POPUP.new()
		popup.name = "AdPopupInterstitial"
		popup.title_key = "AD_TITLE_INTERSTITIAL"
		popup.claimed.connect(func() -> void: _service._on_provider_interstitial_shown())
		popup.dismissed.connect(func() -> void: _service._on_provider_interstitial_shown())
		_service.get_tree().root.add_child.call_deferred(popup)
