extends Resource

class_name SaveData

@export var player_position: Vector3
@export var player_hp: float = 100.0
@export var player_stamina: float = 100.0
@export var player_battery: float = 100.0

@export var current_scene: String = ""

@export var inventory_items: Array[String]
@export var inventory_dict: Dictionary

@export var abilities: Array[String]

@export var quests_state: Dictionary

@export var wallet: Dictionary
@export var shop: Dictionary
@export var upgrades: Dictionary
@export var encyclopedia: Dictionary
@export var power_grid: Dictionary
@export var coins: Dictionary
@export var achievements: Dictionary
@export var progress: Dictionary

@export var settings: Dictionary

@export var timestamp: int = 0
@export var version: int = 2