extends Node
const REWARD_SECRET: int = 50
const REWARD_DISTRICT_RESTORED: int = 200
const REWARD_ACHIEVEMENT: int = 100
func _ready() -> void:
	EventBus.secret_found.connect(_on_secret)
	EventBus.district_restored.connect(_on_district)
	EventBus.achievement_unlocked.connect(_on_achievement)
func _on_secret(_secret_id: StringName) -> void:
	CoinWallet.add(REWARD_SECRET)
	EventBus.inventory_notice.emit(LocalizationManager.tf("REWARD_SECRET", [REWARD_SECRET]))
func _on_district(_district_id: StringName, _stage: int) -> void:
	CoinWallet.add(REWARD_DISTRICT_RESTORED)
	EventBus.inventory_notice.emit(LocalizationManager.tf("REWARD_DISTRICT", [REWARD_DISTRICT_RESTORED]))
func _on_achievement(_achievement_id: StringName) -> void:
	CoinWallet.add(REWARD_ACHIEVEMENT)
	EventBus.inventory_notice.emit(LocalizationManager.tf("REWARD_ACHIEVEMENT", [REWARD_ACHIEVEMENT]))