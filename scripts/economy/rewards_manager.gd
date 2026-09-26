extends Node
const REWARD_SECRET: int = 50
const REWARD_DISTRICT_RESTORED: int = 200
## GDD.md:229 coin curve "0-200 at D1 -> 8000+ by D11": the n-th district in
## DistrictManager.DISTRICTS order pays 200 + 100*(n-1) (D1 200 ... D11 1200,
## 7700 in all). The old flat 200 measured 3439 coins at the end of a winning
## bot run (C8 rc12, seed 2): under half the curve.
const REWARD_DISTRICT_STEP: int = 100
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
func _on_district(district_id: StringName, _stage: int) -> void:
	var index := maxi(DistrictManager.DISTRICTS.find(String(district_id)), 0)
	var amount := _reward(REWARD_DISTRICT_RESTORED + REWARD_DISTRICT_STEP * index)
	CoinWallet.add(amount)
	EventBus.inventory_notice.emit(LocalizationManager.tf("REWARD_DISTRICT", [amount]))
func _on_achievement(_achievement_id: StringName) -> void:
	var amount := _reward(REWARD_ACHIEVEMENT)
	CoinWallet.add(amount)
	EventBus.inventory_notice.emit(LocalizationManager.tf("REWARD_ACHIEVEMENT", [amount]))