extends Node
class_name AdProvider
## AdProvider — интерфейс показа рекламы (T8).
## Реализации: SimulatedAdProvider (по умолчанию, без реальной рекламы),
## AdmobProvider (заглушка для AdMob через usher/plugin, требует сборки).

signal ad_started(ad_type: String)
signal ad_finished(ad_type: String, reward_type: String, amount: int)
signal ad_failed(ad_type: String, error: String)

var ads_enabled: bool = true

func _ready() -> void:
	pass

## Показать рекламу с наградой. Возвращает true, если показана (или мгновенно начислена).
func show_rewarded_ad(_reward_type: String, _amount: int) -> bool:
	return false

func show_interstitial() -> bool:
	return false

func is_available(_ad_type: String) -> bool:
	return false