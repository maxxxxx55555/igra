class_name EnemyRosterData
extends Resource

## Канон листов врагов. Поле damage_type_resistances — множитель входящего
## урона (0.0=иммун, 1.0=нейтрально, >1.0=слабость).
## Поведение — chase/cover/swarm/flee (один враг может иметь несколько).

enum Behavior { CHASE, COVER, SWARM, FLEE }
enum Status { BLEED, BURN, POISON, SLOW, STUN, FEAR }
enum DamageType { BULLET, SLASH, BLUNT, FIRE, ELECTRIC, POISON }

const AI_TO_ROSTER := {
	&"hunter": &"runner",
	&"destroyer": &"armored",
	&"watcher": &"sniper",
	&"crawler": &"dog",
	&"boss": &"beast",
}

@export var roster: Dictionary = {
	&"tramp": {
		"name": "ENEMY_WANDERER", "hp": 120, "damage": 12, "armor": 5,
		"weak_spot": "head", "behaviors": [Behavior.CHASE],
		"inflicts": [Status.BLEED],
		"resistances": {DamageType.BULLET: 1.0, DamageType.SLASH: 1.0, DamageType.BLUNT: 1.0, DamageType.FIRE: 1.0, DamageType.ELECTRIC: 1.0, DamageType.POISON: 1.0},
		"speed": 3.0, "attack_range": 1.6, "detect_range": 11.0,
	},
	&"cleaver": {
		"name": "ENEMY_SLASHER", "hp": 180, "damage": 18, "armor": 8,
		"weak_spot": "head", "behaviors": [Behavior.CHASE],
		"inflicts": [Status.BLEED],
		"resistances": {DamageType.BULLET: 0.9, DamageType.SLASH: 0.8, DamageType.BLUNT: 1.1, DamageType.FIRE: 1.0, DamageType.ELECTRIC: 1.0, DamageType.POISON: 1.0},
		"speed": 3.5, "attack_range": 1.8, "detect_range": 12.0,
	},
	&"runner": {
		"name": "ENEMY_RUNNER", "hp": 80, "damage": 8, "armor": 2,
		"weak_spot": "body", "behaviors": [Behavior.CHASE],
		"inflicts": [Status.BLEED],
		"resistances": {DamageType.BULLET: 1.1, DamageType.SLASH: 1.0, DamageType.BLUNT: 1.0, DamageType.FIRE: 1.0, DamageType.ELECTRIC: 1.0, DamageType.POISON: 1.0},
		"speed": 5.5, "attack_range": 1.4, "detect_range": 14.0,
	},
	&"rotter": {
		"name": "ENEMY_ROTTER", "hp": 350, "damage": 15, "armor": 20,
		"weak_spot": "legs", "behaviors": [Behavior.CHASE],
		"inflicts": [Status.POISON],
		"resistances": {DamageType.BULLET: 0.6, DamageType.SLASH: 0.8, DamageType.BLUNT: 0.7, DamageType.FIRE: 1.3, DamageType.ELECTRIC: 1.0, DamageType.POISON: 0.3},
		"speed": 1.8, "attack_range": 1.8, "detect_range": 9.0,
	},
	&"spitter": {
		"name": "ENEMY_SPITTER", "hp": 140, "damage": 10, "armor": 5,
		"weak_spot": "head", "behaviors": [Behavior.COVER],
		"inflicts": [Status.POISON],
		"resistances": {DamageType.BULLET: 1.0, DamageType.SLASH: 1.0, DamageType.BLUNT: 1.0, DamageType.FIRE: 1.2, DamageType.ELECTRIC: 1.0, DamageType.POISON: 0.5},
		"speed": 2.5, "attack_range": 9.0, "detect_range": 15.0, "ranged": true,
	},
	&"beast": {
		"name": "ENEMY_BEAST", "hp": 1200, "damage": 30, "armor": 25,
		"weak_spot": "head", "behaviors": [Behavior.CHASE],
		"inflicts": [Status.BLEED, Status.STUN],
		"resistances": {DamageType.BULLET: 0.5, DamageType.SLASH: 0.6, DamageType.BLUNT: 0.7, DamageType.FIRE: 0.8, DamageType.ELECTRIC: 0.9, DamageType.POISON: 0.4},
		"speed": 3.2, "attack_range": 3.0, "detect_range": 20.0, "mini_boss": true,
	},
	&"sniper": {
		"name": "ENEMY_SNIPER", "hp": 160, "damage": 25, "armor": 10,
		"weak_spot": "head", "behaviors": [Behavior.COVER],
		"inflicts": [Status.BLEED],
		"resistances": {DamageType.BULLET: 0.8, DamageType.SLASH: 1.1, DamageType.BLUNT: 1.0, DamageType.FIRE: 1.0, DamageType.ELECTRIC: 1.0, DamageType.POISON: 1.0},
		"speed": 2.8, "attack_range": 18.0, "detect_range": 25.0, "ranged": true,
	},
	&"armored": {
		"name": "ENEMY_ARMORED", "hp": 400, "damage": 20, "armor": 35,
		"weak_spot": "back", "behaviors": [Behavior.CHASE],
		"inflicts": [Status.STUN],
		"resistances": {DamageType.BULLET: 0.4, DamageType.SLASH: 0.5, DamageType.BLUNT: 0.6, DamageType.FIRE: 1.0, DamageType.ELECTRIC: 1.4, DamageType.POISON: 0.7},
		"speed": 2.0, "attack_range": 1.8, "detect_range": 10.0,
	},
	&"pyro": {
		"name": "ENEMY_ARSONIST", "hp": 200, "damage": 15, "armor": 5,
		"weak_spot": "head", "behaviors": [Behavior.CHASE],
		"inflicts": [Status.BURN],
		"resistances": {DamageType.BULLET: 1.0, DamageType.SLASH: 1.0, DamageType.BLUNT: 1.0, DamageType.FIRE: 0.2, DamageType.ELECTRIC: 1.0, DamageType.POISON: 1.0},
		"speed": 3.0, "attack_range": 2.5, "detect_range": 13.0,
	},
	&"larva": {
		"name": "ENEMY_WHELP", "hp": 60, "damage": 6, "armor": 2,
		"weak_spot": "body", "behaviors": [Behavior.SWARM],
		"inflicts": [Status.BLEED],
		"resistances": {DamageType.BULLET: 1.0, DamageType.SLASH: 1.0, DamageType.BLUNT: 1.0, DamageType.FIRE: 1.2, DamageType.ELECTRIC: 1.0, DamageType.POISON: 1.0},
		"speed": 4.0, "attack_range": 1.2, "detect_range": 8.0,
	},
	&"dog": {
		"name": "ENEMY_HOUND", "hp": 70, "damage": 9, "armor": 3,
		"weak_spot": "head", "behaviors": [Behavior.CHASE, Behavior.SWARM],
		"inflicts": [Status.BLEED, Status.FEAR],
		"resistances": {DamageType.BULLET: 1.0, DamageType.SLASH: 1.1, DamageType.BLUNT: 1.0, DamageType.FIRE: 1.0, DamageType.ELECTRIC: 1.0, DamageType.POISON: 1.0},
		"speed": 6.0, "attack_range": 1.4, "detect_range": 16.0,
	},
}

func get_entry(roster_id: StringName) -> Dictionary:
	return roster.get(roster_id, {})

func get_entry_for_ai(ai_id: StringName) -> Dictionary:
	var roster_id: StringName = AI_TO_ROSTER.get(ai_id, ai_id)
	return get_entry(roster_id)

static func behavior_name(b: int) -> String:
	match b:
		Behavior.CHASE: return "chase"
		Behavior.COVER: return "cover"
		Behavior.SWARM: return "swarm"
		Behavior.FLEE: return "flee"
	return "?"

static func status_name(s: int) -> String:
	match s:
		Status.BLEED: return "bleed"
		Status.BURN: return "burn"
		Status.POISON: return "poison"
		Status.SLOW: return "slow"
		Status.STUN: return "stun"
		Status.FEAR: return "fear"
	return "?"
