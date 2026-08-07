class_name ShopItem
extends Resource
enum Kind { COIN_PACK, UPGRADE, SKIN, BUNDLE }
@export var id: StringName
@export var kind: Kind
@export var display_name: String
@export var description: String = ""
@export var icon: Texture2D
@export var price_coins: int = 0
@export var discount_percent: int = 0
@export var coins_granted: int = 0
@export var bundle_contents: Array[StringName] = []
func final_price_coins() -> int:
    return int(round(price_coins * (1.0 - discount_percent / 100.0)))