extends Node
## Autoload "Shop". Coins-only purchases. CANON: no p2w, no real-money IAP.

signal purchased(item_id: StringName)
signal purchase_failed(item_id: StringName, reason: String)

const ITEMS := {
	"battery": {"price": 50,  "max": 3},
	"stamina": {"price": 100, "max": 2},
	"medkit":  {"price": 30,  "max": 5},
}

var _coins: int = 0
var _owned: Dictionary = {}

func add_coins(n: int) -> void:
	_coins += n

func coins() -> int:
	return _coins

func owned(item_id: StringName) -> int:
	return int(_owned.get(item_id, 0))

func can_buy(item_id: StringName) -> bool:
	var item: Variant = ITEMS.get(String(item_id))
	if item == null or not (item is Dictionary):
		return false
	var d: Dictionary = item
	return _coins >= int(d.get("price", 0)) and owned(item_id) < int(d.get("max", 0))

func buy(item_id: StringName) -> bool:
	if not can_buy(item_id):
		purchase_failed.emit(item_id, "insufficient")
		return false
	var item: Variant = ITEMS.get(String(item_id))
	var d: Dictionary = item
	_coins -= int(d.get("price", 0))
	_owned[item_id] = owned(item_id) + 1
	purchased.emit(item_id)
	UISFX.pickup()
	return true

func list_items() -> Array[StringName]:
	var out: Array[StringName] = []
	for k in ITEMS.keys():
		out.append(StringName(k))
	return out

func price_of(item_id: StringName) -> int:
	var item: Variant = ITEMS.get(String(item_id))
	if item == null or not (item is Dictionary):
		return 0
	return int((item as Dictionary).get("price", 0))