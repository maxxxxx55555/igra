class_name AdmobProvider
extends AdProvider
## AdmobProvider — заглушка для Google AdMob через Godot AdMob plugin.
## Полная интеграция требует: сборку с плагином, App ID в export, test unit ids.
## До этого — падает на false (без наград), UI подсказывает «Реклама недоступна».

func show_rewarded_ad(_reward_type: String, _amount: int) -> bool:
	# TODO: подключить GodotAdMobPlugin после сборки с плагином.
	ad_failed.emit("rewarded", "admob_not_integrated")
	return false

func show_interstitial() -> bool:
	ad_failed.emit("interstitial", "admob_not_integrated")
	return false

func is_available(_ad_type: String) -> bool:
	return false