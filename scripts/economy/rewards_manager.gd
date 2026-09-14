extends Node
const REWARD_SECRET: int = 50
const REWARD_DISTRICT_RESTORED: int = 200
const REWARD_ACHIEVEMENT: int = 100
func _ready() -> void:
	EventBus.secret_found.connect(_on_secret)
	EventBus.district_restored.connect(_on_district)
	EventBus.achievement_unlocked.connect(_on_achievement)
func _reward(base: int) -> int:
	return int(base * NewGamePlus.get_modifier_multiplier("rewards"))
func _on_secret(_secret_id: StringName) -> void:
	var amount := _reward(REWARD_SECRET)
	CoinWallet.add(amount)
	EventBus.inventory_notice.emit(LocalizationManager.tf("REWARD_SECRET", [amount]))
func _on_district(_district_id: StringName, _stage: int) -> void:
	var amount := _reward(REWARD_DISTRICT_RESTORED)
	CoinWallet.add(amount)
	EventBus.inventory_notice.emit(LocalizationManager.tf("REWARD_DISTRICT", [amount]))
func _on_achievement(_achievement_id: StringName) -> void:
	var amount := _reward(REWARD_ACHIEVEMENT)
	CoinWallet.add(amount)
	EventBus.inventory_notice.emit(LocalizationManager.tf("REWARD_ACHIEVEMENT", [amount]))