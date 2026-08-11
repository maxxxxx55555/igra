extends Resource
class_name LootTable

@export var entries: Array = []

func roll() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in entries:
		if randf() <= entry.chance:
			result.append({
				"item_id": entry.item_id,
				"quantity": entry.quantity,
				"rarity": entry.rarity,
			})
	return result

class LootEntry:
	var item_id: String
	var quantity: int
	var chance: float
	# Legacy string-based rarity — keeps loading old .tres without breakage.
	# New pipelines should use ItemData.Rarity enum directly; conversion lives in
	# item_database.gd / inventory. ponytail: string→enum bridge maps to COMMON/RARE only.
	var rarity: String
