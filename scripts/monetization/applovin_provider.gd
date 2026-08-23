## Wraps addons/applovin_max/AppLovinMAX.gd behind the same interface
## ad_service.gd's StubAdProvider already implements (initialize/is_ready/
## show, plus is_interstitial_ready/show_interstitial) — see ad_service.gd's
## own doc comment: "поставщик подставляется... игровой код не меняется."
##
## Ad unit IDs are read from project settings (monetization/applovin_*_unit_id,
## empty by default) rather than hardcoded — real IDs come from the
## AppLovin dashboard per app, see docs/store/HUMAN_CHECKLIST.md.
extends RefCounted

var _service: Node
var _sdk_key: String
var _rewarded_unit: String
var _interstitial_unit: String
var _sdk_ready: bool = false
var _pending_reward_id: StringName = &""

func _init(service: Node, sdk_key: String) -> void:
	_service = service
	_sdk_key = sdk_key
	_rewarded_unit = str(ProjectSettings.get_setting("monetization/applovin_rewarded_unit_id", ""))
	_interstitial_unit = str(ProjectSettings.get_setting("monetization/applovin_interstitial_unit_id", ""))

func initialize() -> void:
	var rewarded_listener := AppLovinMAX.RewardedAdEventListener.new()
	rewarded_listener.on_ad_display_failed = func(_id: String, _err, _info) -> void:
		_service._on_provider_failed("ad display failed")
	rewarded_listener.on_ad_hidden = func(_id: String, _info) -> void:
		if not _rewarded_unit.is_empty():
			AppLovinMAX.load_rewarded_ad(_rewarded_unit)
	rewarded_listener.on_ad_received_reward = func(_id: String, _reward, _info) -> void:
		_service._on_provider_reward(_pending_reward_id)
	AppLovinMAX.set_rewarded_ad_listener(rewarded_listener)

	var interstitial_listener := AppLovinMAX.InterstitialAdEventListener.new()
	interstitial_listener.on_ad_display_failed = func(_id: String, _err, _info) -> void:
		_service._on_provider_interstitial_failed("ad display failed")
	interstitial_listener.on_ad_hidden = func(_id: String, _info) -> void:
		_service._on_provider_interstitial_shown()
		if not _interstitial_unit.is_empty():
			AppLovinMAX.load_interstitial(_interstitial_unit)
	AppLovinMAX.set_interstitial_ad_listener(interstitial_listener)

	var init_listener := AppLovinMAX.InitializationListener.new()
	init_listener.on_sdk_initialized = func(_config) -> void:
		_sdk_ready = true
		if not _rewarded_unit.is_empty():
			AppLovinMAX.load_rewarded_ad(_rewarded_unit)
		if not _interstitial_unit.is_empty():
			AppLovinMAX.load_interstitial(_interstitial_unit)
	AppLovinMAX.initialize(_sdk_key, init_listener)

func is_ready() -> bool:
	return _sdk_ready and not _rewarded_unit.is_empty() and AppLovinMAX.is_rewarded_ad_ready(_rewarded_unit)

func show(reward_id: StringName) -> void:
	_pending_reward_id = reward_id
	AppLovinMAX.show_rewarded_ad(_rewarded_unit)

func is_interstitial_ready() -> bool:
	return _sdk_ready and not _interstitial_unit.is_empty() and AppLovinMAX.is_interstitial_ready(_interstitial_unit)

func show_interstitial() -> void:
	AppLovinMAX.show_interstitial(_interstitial_unit)
