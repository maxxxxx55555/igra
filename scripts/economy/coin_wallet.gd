extends Node
signal coins_changed(new_amount: int)
signal purchase_failed(reason: String)
@export var start_coins: int = 0
var coins: int = 0
func _ready() -> void:
	SecurityVault.load_game()
	# The vault is the guarded mirror of the wallet. A vault written by an
	# earlier session wins; a fresh profile keeps the scene's start_coins.
	coins = clampi(SecurityVault.get_guarded_int(&"coins", start_coins), 0, MAX_COINS) if SecurityVault.last_load_error == OK else start_coins
	_guard()
	coins_changed.emit(coins)

func _guard() -> void:
	SecurityVault.set_guarded_int(&"coins", coins)
	SecurityVault.save_game()

func add(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	_guard()
	coins_changed.emit(coins)
func try_spend(amount: int) -> bool:
	if amount <= 0:
		return false
	if coins < amount:
		purchase_failed.emit("not_enough_coins")
		EventBus.inventory_notice.emit(LocalizationManager.t("NOT_ENOUGH_COINS"))
		return false
	coins -= amount
	_guard()
	coins_changed.emit(coins)
	return true
## The vault already committed this value with the matching bonus receipt.
func apply_saved_balance(balance: int) -> void:
	coins = balance
	coins_changed.emit(coins)

func spend_clamped(amount: int) -> void:
	if amount <= 0:
		return
	coins = maxi(0, coins - amount)
	_guard()
	coins_changed.emit(coins)

func get_coins() -> int:
	return coins
## One payment per key for the life of the profile: a replayed achievements file unlocks again, but the coins were paid. The keys are the achievement ids (25 at most); the cap bounds a file.
const MAX_PAID: int = 64
var _paid: Array[String] = []

func add_once(key: String, amount: int) -> bool:
	if amount <= 0 or _paid.has(key):
		return false
	_paid.append(key)
	add(amount)
	return true

func to_dict() -> Dictionary:
	return {"coins": coins, "paid": _paid.duplicate()}
## Anti-tamper sanity clamp (RELEASE CONVERGENCE, STEP 5): a hand-edited save
## used to set `coins` to any int with no bound — not a security hole per se
## (single-player, no leaderboard payout), but an easy path to display/economy
## nonsense (negative balance, overflow-scale numbers). 999999 is well above
## anything reachable by legitimate play (shop prices are 1500-4000), not a
## design cap.
const MAX_COINS: int = 999999

func from_dict(d: Dictionary) -> void:
	coins = clampi(int(d.get("coins", start_coins)), 0, MAX_COINS)
	_paid.clear()
	var raw: Variant = d.get("paid", [])
	if raw is Array:
		for key: Variant in (raw as Array).slice(0, MAX_PAID):
			if key is String and (key as String).length() <= 40:
				_paid.append(key)
	_guard()
	coins_changed.emit(coins)