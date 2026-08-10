extends Node
## A3: Konfigi vseh vragov (6-8 vidov)

const ENEMY_TYPES: Dictionary = {
    "watcher": {
        "name": "Nabljudatel", "hp": 60, "speed": 3.0, "damage": 10,
        "detection": 12.0, "attack_range": 1.5, "behavior": "patrol_chase",
        "xp": 25, "coins": 5, "color": [0.4, 0.4, 0.5]
    },
    "shadow": {
        "name": "Ten", "hp": 40, "speed": 5.0, "damage": 8,
        "detection": 8.0, "attack_range": 1.2, "behavior": "ambush",
        "xp": 30, "coins": 8, "color": [0.1, 0.1, 0.15]
    },
    "runner": {
        "name": "Begun", "hp": 25, "speed": 7.0, "damage": 12,
        "detection": 15.0, "attack_range": 1.0, "behavior": "zigzag_rush",
        "xp": 20, "coins": 4, "color": [0.6, 0.3, 0.2]
    },
    "tank": {
        "name": "Razrushitel", "hp": 200, "speed": 1.5, "damage": 40,
        "detection": 8.0, "attack_range": 2.0, "behavior": "slow_crush",
        "xp": 60, "coins": 20, "color": [0.5, 0.5, 0.5]
    },
    "sniper": {
        "name": "Snajper", "hp": 35, "speed": 0.0, "damage": 25,
        "detection": 25.0, "attack_range": 25.0, "behavior": "stationary_shoot",
        "xp": 35, "coins": 12, "color": [0.3, 0.5, 0.3]
    },
    "crawler": {
        "name": "Polzun", "hp": 30, "speed": 4.0, "damage": 15,
        "detection": 10.0, "attack_range": 1.0, "behavior": "low_crawl",
        "xp": 22, "coins": 6, "color": [0.4, 0.2, 0.3]
    },
    "phantom": {
        "name": "Fantom", "hp": 50, "speed": 4.5, "damage": 18,
        "detection": 14.0, "attack_range": 1.5, "behavior": "teleport_flank",
        "xp": 45, "coins": 15, "color": [0.5, 0.3, 0.6]
    },
    "swarm": {
        "name": "Roj", "hp": 10, "speed": 6.0, "damage": 5,
        "detection": 12.0, "attack_range": 0.8, "behavior": "swarm_surround",
        "xp": 8, "coins": 2, "color": [0.6, 0.6, 0.2]
    }
}

func get_config(type_id: String) -> Dictionary:
    return ENEMY_TYPES.get(type_id, ENEMY_TYPES["watcher"])

func get_all_types() -> Array:
    return ENEMY_TYPES.keys()