extends Node
signal coins_changed(new_amount: int)
signal purchase_failed(reason: String)
@export var start_coins: int = 0
var coins: int = 0
func _ready() -> void:
	coins = start_coins
	coins_changed.emit(coins)
func add(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	coins_changed.emit(coins)
func try_spend(amount: int) -> bool:
	if amount <= 0:
		return false
	if coins < amount:
		purchase_failed.emit("not_enough_coins")
		EventBus.inventory_notice.emit(LocalizationManager.t("NOT_ENOUGH_COINS"))
		return false
	coins -= amount
	coins_changed.emit(coins)
	return true
func get_coins() -> int:
	return coins
func to_dict() -> Dictionary:
	return {"coins": coins}
func from_dict(d: Dictionary) -> void:
	coins = int(d.get("coins", start_coins))
	coins_changed.emit(coins)