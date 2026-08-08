class_name SimulatedAdProvider
extends AdProvider
## SimulatedAdProvider — симуляция рекламы (PC / Android без AdMob SDK).
## Начисляет награду по таймеру «просмотра».

const SIMULATED_DELAY := 1.5

func _ready() -> void:
	ads_enabled = true

func show_rewarded_ad(reward_type: String, amount: int) -> bool:
	if not ads_enabled:
		return false
	ad_started.emit("rewarded")
	await get_tree().create_timer(SIMULATED_DELAY).timeout
	ad_finished.emit("rewarded", reward_type, amount)
	return true

func show_interstitial() -> bool:
	if not ads_enabled:
		return false
	ad_started.emit("interstitial")
	await get_tree().create_timer(1.0).timeout
	ad_finished.emit("interstitial", "", 0)
	return true

func is_available(_ad_type: String) -> bool:
	return ads_enabled