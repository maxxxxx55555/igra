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
## Anti-tamper sanity clamp (RELEASE CONVERGENCE, STEP 5): a hand-edited save
## used to set `coins` to any int with no bound — not a security hole per se
## (single-player, no leaderboard payout), but an easy path to display/economy
## nonsense (negative balance, overflow-scale numbers). 999999 is well above
## anything reachable by legitimate play (shop prices are 30-100), not a
## design cap.
const MAX_COINS: int = 999999

func from_dict(d: Dictionary) -> void:
	coins = clampi(int(d.get("coins", start_coins)), 0, MAX_COINS)
	coins_changed.emit(coins)