class_name ItemData
extends Resource

## Rarity: GDD §V.5 9.13 — фильтры «обычные/редкие/эпические».
## Исходный набор расширен EPIC по требованию спеки.
enum Rarity { COMMON, UNCOMMON, RARE, EPIC }
enum Effect { NONE, HEAL, RECHARGE }
## GDD §V.5 9.5: слоты экипировки; NONE = не экипируется.
enum EquipSlot { NONE, HEAD, BODY, LEGS, HOLSTER, BACKPACK }

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
@export var equip_slot: EquipSlot = EquipSlot.NONE