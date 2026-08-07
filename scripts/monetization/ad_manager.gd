extends Node

## Ad/monetization system for THE LAST STREETLIGHT.
## Handles rewarded ads, interstitial ads, and ad reward callbacks.

signal ad_started(ad_type: String)
signal ad_finished(ad_type: String, reward_type: String, amount: int)
signal ad_failed(ad_type: String, error: String)
signal ads_removed()

enum AdType { REWARDED, INTERSTITIAL, BANNER }

var _ads_enabled: bool = true
var _rewarded_cooldown: float = 3600.0
var _last_rewarded_time: float = -9999.0
var _interstitial_cooldown: float = 1800.0
var _last_interstitial_time: float = -9999.0
var _session_impressions: int = 0

func _ready() -> void:
	_ads_enabled = not SettingsManager.get_setting("ads_removed", false)

## Show a rewarded ad. Returns true if ad was shown.
func show_rewarded_ad(reward_type: String = "coins", amount: int = 100) -> bool:
	if not _ads_enabled:
		_emit_reward(reward_type, amount)
		return false
	if Time.get_unix_time_from_system() - _last_rewarded_time < _rewarded_cooldown:
		ad_failed.emit("rewarded", "cooldown")
		return false
	_last_rewarded_time = Time.get_unix_time_from_system()
	_session_impressions += 1
	ad_started.emit("rewarded")
	# Simulate ad completion (replace with actual AdMob integration)
	await get_tree().create_timer(1.5).timeout
	_emit_reward(reward_type, amount)
	return true

func _emit_reward(reward_type: String, amount: int) -> void:
	match reward_type:
		"coins":
			CoinWallet.add_coins(amount)
		"battery":
			EventBus.item_picked_up.emit("battery", amount)
		"health":
			EventBus.player_healed.emit(amount)
	ad_finished.emit("rewarded", reward_type, amount)

func show_interstitial() -> bool:
	if not _ads_enabled:
		return false
	if Time.get_unix_time_from_system() - _last_interstitial_time < _interstitial_cooldown:
		return false
	_last_interstitial_time = Time.get_unix_time_from_system()
	_session_impressions += 1
	ad_started.emit("interstitial")
	await get_tree().create_timer(1.0).timeout
	ad_finished.emit("interstitial", "", 0)
	return true

## Remove ads (premium purchase)
func remove_ads() -> void:
	_ads_enabled = false
	SettingsManager.set_setting("ads_removed", true)
	ads_removed.emit()

func has_ads() -> bool:
	return _ads_enabled

func get_session_impressions() -> int:
	return _session_impressions
