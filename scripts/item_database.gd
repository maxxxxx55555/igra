extends RefCounted

enum ItemType { TOOL, CONSUMABLE, KEY, MATERIAL, DOCUMENT, WEAPON, EQUIPMENT, UPGRADE }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

static var items: Dictionary = {
	"flashlight":  {"name": "Flashlight",     "weight": 1.2,  "cost": 2500, "type": ItemType.TOOL,       "rarity": Rarity.COMMON,   "desc": "Primary light source."},
	"battery":     {"name": "Batteries",      "weight": 0.3,  "cost": 150,  "type": ItemType.CONSUMABLE, "rarity": Rarity.COMMON,   "desc": "Charge for flashlight."},
	"medkit":      {"name": "Medkit",         "weight": 0.8,  "cost": 800,  "type": ItemType.CONSUMABLE, "rarity": Rarity.UNCOMMON, "desc": "Restores 40 HP."},
	"key_red":     {"name": "Red Key",        "weight": 0.1,  "cost": 0,    "type": ItemType.KEY,        "rarity": Rarity.RARE,     "desc": "Opens substation door."},
	"key_blue":    {"name": "Blue Key",       "weight": 0.1,  "cost": 0,    "type": ItemType.KEY,        "rarity": Rarity.RARE,     "desc": "Opens warehouse."},
	"cable":       {"name": "Cable",          "weight": 2.5,  "cost": 300,  "type": ItemType.MATERIAL,   "rarity": Rarity.COMMON,   "desc": "For transformer connection."},
	"fuse":        {"name": "Fuse",           "weight": 0.4,  "cost": 200,  "type": ItemType.MATERIAL,   "rarity": Rarity.COMMON,   "desc": "Replace blown fuse."},
	"wrench":      {"name": "Wrench",         "weight": 1.8,  "cost": 1500, "type": ItemType.TOOL,       "rarity": Rarity.UNCOMMON, "desc": "Repair equipment."},
	"document":    {"name": "Document",       "weight": 0.05, "cost": 0,    "type": ItemType.DOCUMENT,   "rarity": Rarity.COMMON,   "desc": "Notes and reports."},
	"fuel":        {"name": "Fuel",           "weight": 5.0,  "cost": 500,  "type": ItemType.CONSUMABLE, "rarity": Rarity.UNCOMMON, "desc": "For generator."},
	"generator":   {"name": "Generator",      "weight": 15.0, "cost": 0,    "type": ItemType.EQUIPMENT,  "rarity": Rarity.RARE,     "desc": "Powers substation."},
	"transformer": {"name": "Transformer",    "weight": 25.0, "cost": 0,    "type": ItemType.EQUIPMENT,  "rarity": Rarity.EPIC,     "desc": "Converts voltage."},
	"backpack":    {"name": "Backpack",       "weight": 0.0,  "cost": 1200, "type": ItemType.UPGRADE,    "rarity": Rarity.UNCOMMON, "desc": "Increases capacity."},
	"noise_bomb":  {"name": "Noise Bomb",     "weight": 0.5,  "cost": 400,  "type": ItemType.CONSUMABLE, "rarity": Rarity.UNCOMMON, "desc": "Distracts monsters."},
	"lockpick":    {"name": "Lockpick",       "weight": 0.1,  "cost": 250,  "type": ItemType.TOOL,       "rarity": Rarity.COMMON,   "desc": "Opens locks."},
	"repair_kit":  {"name": "Repair Kit",     "weight": 1.0,  "cost": 600,  "type": ItemType.CONSUMABLE, "rarity": Rarity.UNCOMMON, "desc": "Repairs equipment."},
	"firework":    {"name": "Firework",       "weight": 0.3,  "cost": 100,  "type": ItemType.CONSUMABLE, "rarity": Rarity.COMMON,   "desc": "Distracts with light."},
	"molotov":     {"name": "Molotov",        "weight": 0.6,  "cost": 350,  "type": ItemType.WEAPON,     "rarity": Rarity.RARE,     "desc": "Fire trap."},
	"photo":       {"name": "Photo",          "weight": 0.02, "cost": 0,    "type": ItemType.DOCUMENT,   "rarity": Rarity.COMMON,   "desc": "Memorable snapshot."},
	"audio_log":   {"name": "Audio Log",      "weight": 0.05, "cost": 0,    "type": ItemType.DOCUMENT,   "rarity": Rarity.UNCOMMON, "desc": "Voice message."},
}

static func get_item(id: String) -> Dictionary:
	return items.get(id, {})

static func get_weight(id: String) -> float:
	var it: Dictionary = items.get(id, {})
	return it.get("weight", 0.0) if "weight" in it else 0.0

static func get_cost(id: String) -> int:
	var it: Dictionary = items.get(id, {})
	return it.get("cost", 0) if "cost" in it else 0

static func get_name(id: String) -> String:
	var it: Dictionary = items.get(id, {})
	return it.get("name", id) if "name" in it else id

static func get_desc(id: String) -> String:
	var it: Dictionary = items.get(id, {})
	return it.get("desc", "") if "desc" in it else ""

static func get_all_ids() -> Array:
	return items.keys()

static func get_count() -> int:
	return items.size()

static func rarity_name(r: int) -> String:
	match r:
		Rarity.COMMON: return "common"
		Rarity.UNCOMMON: return "uncommon"
		Rarity.RARE: return "rare"
		Rarity.EPIC: return "epic"
		Rarity.LEGENDARY: return "legendary"
	return "unknown"
