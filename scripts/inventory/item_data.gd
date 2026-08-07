class_name ItemData
extends Resource
enum Rarity { COMMON, UNCOMMON, RARE }
enum Effect { NONE, HEAL, RECHARGE }
@export var id: StringName
@export var display_name: String
@export var description: String
@export var rarity: Rarity = Rarity.COMMON
@export var weight: float = 0.5
@export var stackable: bool = true
@export var max_stack: int = 10
@export var consumable: bool = false
@export var effect: Effect = Effect.NONE
@export var effect_value: float = 0.0
@export var icon: Texture2D