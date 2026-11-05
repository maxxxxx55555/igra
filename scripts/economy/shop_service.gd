extends Node
## The two survivor skins and the starter bundle left the catalog on 2026-11-05: they tinted only the 2D player_visual.gd, which the first-person game never shows.
const CATALOG: Array = [
	# IAP-паки монет (донат) исключены — донат и реклама отключены.
	preload("res://data/shop/upgrade_flashlight_brightness.tres"),
	preload("res://data/shop/upgrade_flashlight_battery.tres"),
	preload("res://data/shop/upgrade_backpack_capacity.tres"),
	preload("res://data/shop/upgrade_backpack_slots.tres"),
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
	return _owned.get(id, false) or UpgradeSystem.is_applied(id)
func buy(id: StringName) -> void:
	var item := get_item(id)
	if item == null:
		return
	if item.kind != ShopItem.Kind.COIN_PACK and (is_owned(id) or (item.kind == ShopItem.Kind.BUNDLE and item.bundle_contents.all(is_owned))):
		EventBus.inventory_notice.emit(LocalizationManager.t("SHOP_ALREADY_OWNED"))
		return
	match item.kind:
		ShopItem.Kind.COIN_PACK:
			EventBus.inventory_notice.emit(LocalizationManager.t("SHOP_NO_IAP"))
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
			EventBus.inventory_notice.emit(LocalizationManager.tf("SHOP_UPGRADE_APPLIED", [LocalizationManager.name_for("SHOP_ITEM_", item.id, item.display_name)]))
		ShopItem.Kind.SKIN:
			EventBus.skin_unlocked.emit(item.id)
			EventBus.inventory_notice.emit(LocalizationManager.tf("SHOP_SKIN_GRANTED", [LocalizationManager.name_for("SHOP_ITEM_", item.id, item.display_name)]))
		ShopItem.Kind.BUNDLE:
			for content_id in item.bundle_contents:
				var c := get_item(content_id)
				if c != null and not is_owned(content_id):
					_grant(c)
			EventBus.inventory_notice.emit(LocalizationManager.tf("SHOP_BUNDLE_GRANTED", [LocalizationManager.name_for("SHOP_ITEM_", item.id, item.display_name)]))
func to_dict() -> Dictionary:
	return {"owned": _owned.keys().map(func(k): return String(k))}
func from_dict(d: Dictionary) -> void:
	_owned.clear()
	for k in d.get("owned", []):
		_owned[StringName(k)] = true
