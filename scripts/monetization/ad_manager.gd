extends Node

## Ad/monetization system for THE LAST STREETLIGHT.
## Delegates to an AdProvider (Simulated by default; Admob on real device build).
## Handles rewarded ads, interstitial ads, and ad reward callbacks.

signal ad_started(ad_type: String)
signal ad_finished(ad_type: String, reward_type: String, amount: int)
signal ad_failed(ad_type: String, error: String)
signal ads_removed()

enum AdType { REWARDED, INTERSTITIAL, BANNER }

const _SIMULATED := "simulated"
const _ADMOB := "admob"
const _SimulatedScript := preload("res://scripts/monetization/simulated_ad_provider.gd")
const _AdmobScript := preload("res://scripts/monetization/admob_provider.gd")

## Выбор провайдера: "simulated" (по умолчанию) или "admob".
@export var provider_mode: String = _SIMULATED

var _ads_enabled: bool = true
var _rewarded_cooldown: float = 3600.0
var _last_rewarded_time: float = -9999.0
var _interstitial_cooldown: float = 1800.0
var _last_interstitial_time: float = -9999.0
var _session_impressions: int = 0
var _provider: AdProvider = null

func _ready() -> void:
	_ads_enabled = not SettingsManager.get_setting("ads_removed", false)
	_provider = _create_provider()
	_provider.ads_enabled = _ads_enabled
	add_child(_provider)
	_provider.ad_finished.connect(_on_provider_finished)
	_provider.ad_failed.connect(func(ad_type: String, error: String) -> void: ad_failed.emit(ad_type, error))

func _create_provider() -> AdProvider:
	match provider_mode:
		_ADMOB:
			return _AdmobScript.new()
		_:
			return _SimulatedScript.new()

## Показать rewarded-рекламу. Возвращает true, если ad показан.
func show_rewarded_ad(reward_type: String = "coins", amount: int = 100) -> bool:
	if not _ads_enabled:
		_emit_reward_from_provider(reward_type, amount)  # логика удалённых реклам — без показа
		return false
	if Time.get_unix_time_from_system() - _last_rewarded_time < _rewarded_cooldown:
		ad_failed.emit("rewarded", "cooldown")
		return false
	_last_rewarded_time = Time.get_unix_time_from_system()
	_session_impressions += 1
	ad_started.emit("rewarded")
	return _provider.show_rewarded_ad(reward_type, amount)

func _emit_reward_from_provider(reward_type: String, amount: int) -> void:
	# Паттерн: провайдер сигналит ad_finished → _on_provider_finished → награда.
	# Здесь — мгновенная награда при ads_removed (без рекламы).
	_provider.ad_finished.emit("rewarded", reward_type, amount)

func show_interstitial() -> bool:
	if not _ads_enabled:
		return false
	if Time.get_unix_time_from_system() - _last_interstitial_time < _interstitial_cooldown:
		return false
	_last_interstitial_time = Time.get_unix_time_from_system()
	_session_impressions += 1
	ad_started.emit("interstitial")
	return _provider.show_interstitial()

## Убрать рекламу (premium-покупка)
func remove_ads() -> void:
	_ads_enabled = false
	_settings_remove()
	ads_removed.emit()

func has_ads() -> bool:
	return _ads_enabled

func has_rewarded_available() -> bool:
	return _ads_enabled and Time.get_unix_time_from_system() - _last_rewarded_time >= _rewarded_cooldown

func get_session_impressions() -> int:
	return _session_impressions

func _settings_remove() -> void:
	SettingsManager.set_setting("ads_removed", true)

func _on_provider_finished(ad_type: String, reward_type: String, amount: int) -> void:
	match reward_type:
		"coins":
			CoinWallet.add_coins(amount)
		"battery":
			EventBus.item_picked_up.emit(&"battery")
		"health":
			EventBus.player_healed.emit(amount)
	ad_finished.emit(ad_type, reward_type, amount)