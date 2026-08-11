extends Node
const CATALOG: Array = [
	# IAP-паки монет (донат) исключены — донат и реклама отключены.
	preload("res://data/shop/upgrade_flashlight_brightness.tres"),
	preload("res://data/shop/upgrade_flashlight_battery.tres"),
	preload("res://data/shop/upgrade_backpack_capacity.tres"),
	preload("res://data/shop/upgrade_backpack_slots.tres"),
	preload("res://data/shop/skin_survivor_ashen.tres"),
	preload("res://data/shop/skin_survivor_rust.tres"),
	preload("res://data/shop/bundle_starter.tres"),
]
var _by_id: Dictionary = {}
var _owned: Dictionary = {}
func _ready() -> void:
	for it in CATALOG:
		if it is ShopItem:
			_by_id[(it as ShopItem).id] = it
func get_item(id: StringName) -> ShopItem:
	return _by_id.get(id, null)
func catalog_by_kind(kind: int) -> Array:
	var out: Array = []
	for it in _by_id.values():
		if (it as ShopItem).kind == kind:
			out.append(it)
	return out
func is_owned(id: StringName) -> bool:
	return _owned.get(id, false)
func buy(id: StringName) -> void:
	var item := get_item(id)
	if item == null:
		return
	if item.kind != ShopItem.Kind.COIN_PACK and is_owned(id):
		EventBus.inventory_notice.emit("Уже куплено")
		return
	match item.kind:
		ShopItem.Kind.COIN_PACK:
			EventBus.inventory_notice.emit("ДОНАТ ОТКЛЮЧЁН — МОНЕТЫ ТОЛЬКО В ИГРЕ")
		_:
			_spend_and_grant(item)
func _spend_and_grant(item: ShopItem) -> void:
	var price := item.final_price_coins()
	if not CoinWallet.try_spend(price):
		return
	_grant(item)
	EventBus.purchase_success.emit(item.id)
func _grant(item: ShopItem) -> void:
	_owned[item.id] = true
	match item.kind:
		ShopItem.Kind.UPGRADE:
			UpgradeSystem.apply(item.id)
			EventBus.inventory_notice.emit("Улучшение применено: %s" % item.display_name)
		ShopItem.Kind.SKIN:
			EventBus.skin_unlocked.emit(item.id)
			EventBus.inventory_notice.emit("Скин получен: %s" % item.display_name)
		ShopItem.Kind.BUNDLE:
			for content_id in item.bundle_contents:
				var c := get_item(content_id)
				if c != null:
					_grant(c)
			EventBus.inventory_notice.emit("Набор получен: %s" % item.display_name)
func to_dict() -> Dictionary:
	return {"owned": _owned.keys().map(func(k): return String(k))}
func from_dict(d: Dictionary) -> void:
	_owned.clear()
	for k in d.get("owned", []):
		_owned[StringName(k)] = true
