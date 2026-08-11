extends Node
## A7: Kraft - 12 receptov

signal crafted(item_id: String)
signal craft_failed(reason: String)

var recipes: Dictionary = {}
var inventory: Dictionary = {}

func _ready() -> void:
	var f = FileAccess.open("res://data/recipes/recipes.json", FileAccess.READ)
	if f:
		recipes = JSON.parse_string(f.get_as_text())

func add_material(item_id: String, amount: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + amount

func can_craft(recipe_id: String) -> bool:
	if not recipes.has(recipe_id):
		return false
	var needs = recipes[recipe_id].needs
	for item in needs.keys():
		if inventory.get(item, 0) < needs[item]:
			return false
	return true

func craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		craft_failed.emit("Nedostatochno materialov")
		return false
	var needs = recipes[recipe_id].needs
	for item in needs.keys():
		inventory[item] -= needs[item]
		if inventory[item] <= 0:
			inventory.erase(item)
	var gives = recipes[recipe_id].gives
	inventory[gives] = inventory.get(gives, 0) + 1
	crafted.emit(gives)
	if QuestManager:
		QuestManager.complete_objective(&"side_10", &"craft_items", 1)
	return true

func get_recipe_count() -> int:
	return recipes.size()