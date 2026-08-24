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
		# WAVE 6 P1: GDD §6.2 Hunter = hp 120 / damage 35 / hearing 12m
		# (was 80/8/14 - a data-mapping bug, Hunter's real stats never
		# matched its own design doc; charge attack dealt <1/4 documented
		# damage). speed left untouched - see docs/PLANS.md for why.
		"name": "ENEMY_RUNNER", "hp": 120, "damage": 35, "armor": 2,
		"weak_spot": "body", "behaviors": [Behavior.CHASE],
		"inflicts": [Status.BLEED],
		"resistances": {DamageType.BULLET: 1.1, DamageType.SLASH: 1.0, DamageType.BLUNT: 1.0, DamageType.FIRE: 1.0, DamageType.ELECTRIC: 1.0, DamageType.POISON: 1.0},
		"speed": 5.5, "attack_range": 1.4, "detect_range": 12.0,
	},
	&"rotter": {
		"name": "ENEMY_ROTTER", "hp": 140, "damage": 10, "armor": 15,
		"weak_spot": "blunt", "behaviors": [Behavior.CHASE],
		"inflicts": [Status.POISON],
		"resistances": {DamageType.BULLET: 0.8, DamageType.SLASH: 0.8, DamageType.BLUNT: 1.5, DamageType.FIRE: 1.0, DamageType.ELECTRIC: 1.0, DamageType.POISON: 1.0},
		"speed": 1.2, "attack_range": 1.8, "detect_range": 5.0,
	},
	&"spitter": {
		"name": "ENEMY_SPITTER", "hp": 140, "damage": 10, "armor": 5,
		"weak_spot": "head", "behaviors": [Behavior.COVER],
		"inflicts": [Status.POISON],
		"resistances": {DamageType.BULLET: 1.0, DamageType.SLASH: 1.0, DamageType.BLUNT: 1.0, DamageType.FIRE: 1.2, DamageType.ELECTRIC: 1.0, DamageType.POISON: 0.5},
		"speed": 2.5, "attack_range": 9.0, "detect_range": 15.0, "ranged": true,
	},
	&"beast": {
		# WAVE 6 P1: GDD §6.2 "Архитектор (босс)" = hp 800 / damage 40
		# (was 1200/30 - this entry's hp coincidentally matched Tvar's
		# separate, correct &"tvar" entry below, suggesting "beast" was a
		# leftover placeholder never updated once Tvar got its own real
		# entry). "mini_boss" flag kept off since this IS the final boss,
		# not the mini-boss (Tvar already carries mini_boss correctly).
		"name": "ENEMY_BEAST", "hp": 800, "damage": 40, "armor": 25,
		"weak_spot": "head", "behaviors": [Behavior.CHASE],
		"inflicts": [Status.BLEED, Status.STUN],
		"resistances": {DamageType.BULLET: 0.5, DamageType.SLASH: 0.6, DamageType.BLUNT: 0.7, DamageType.FIRE: 0.8, DamageType.ELECTRIC: 0.9, DamageType.POISON: 0.4},
		"speed": 3.2, "attack_range": 3.0, "detect_range": 20.0,
	},
	&"sniper": {
		# WAVE 6 P1: this entry drives Watcher (see AI_TO_ROSTER), not a
		# ranged sniper - GDD §6.2 Watcher = hp 80 / damage 12 / hearing 8m,
		# a stationary sentinel with STUN->rage on light, no ranged attack.
		# Was 160/25/25 with attack_range 18 - Watcher effectively sniped
		# the player from 18m with no telegraph.
		"name": "ENEMY_SNIPER", "hp": 80, "damage": 12, "armor": 10,
		"weak_spot": "head", "behaviors": [Behavior.COVER],
		"inflicts": [Status.BLEED],
		"resistances": {DamageType.BULLET: 0.8, DamageType.SLASH: 1.1, DamageType.BLUNT: 1.0, DamageType.FIRE: 1.0, DamageType.ELECTRIC: 1.0, DamageType.POISON: 1.0},
		"speed": 2.8, "attack_range": 18.0, "detect_range": 8.0, "ranged": true,
	},
	&"armored": {
		# WAVE 6 P1: GDD §6.2 Destroyer = hp 200 / damage 25 / hearing 15m
		# (was 400/20/10 - exactly double the documented HP).
		"name": "ENEMY_ARMORED", "hp": 200, "damage": 25, "armor": 35,
		"weak_spot": "back", "behaviors": [Behavior.CHASE],
		"inflicts": [Status.STUN],
		"resistances": {DamageType.BULLET: 0.4, DamageType.SLASH: 0.5, DamageType.BLUNT: 0.6, DamageType.FIRE: 1.0, DamageType.ELECTRIC: 1.4, DamageType.POISON: 0.7},
		"speed": 2.0, "attack_range": 1.8, "detect_range": 15.0,
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
		# WAVE 6 P1: this entry drives Crawler (see AI_TO_ROSTER), not
		# Hound (a separate, already-correct &"hound" entry exists below
		# for the real Hound). GDD §6.2 Crawler = hp 50 / damage 20 /
		# hearing 10m (was 70/9/16 - less than a quarter documented damage).
		"name": "ENEMY_HOUND", "hp": 50, "damage": 20, "armor": 3,
		"weak_spot": "head", "behaviors": [Behavior.CHASE, Behavior.SWARM],
		"inflicts": [Status.BLEED, Status.FEAR],
		"resistances": {DamageType.BULLET: 1.0, DamageType.SLASH: 1.1, DamageType.BLUNT: 1.0, DamageType.FIRE: 1.0, DamageType.ELECTRIC: 1.0, DamageType.POISON: 1.0},
		"speed": 6.0, "attack_range": 1.4, "detect_range": 10.0,
	},
	&"sharpshooter": {
		"name": "ENEMY_SHARPSHOOTER", "hp": 60, "damage": 50, "armor": 10,
		"weak_spot": "back", "behaviors": [Behavior.COVER],
		"inflicts": [],
		"resistances": {DamageType.BULLET: 1.0, DamageType.SLASH: 1.0, DamageType.BLUNT: 1.0, DamageType.FIRE: 1.0, DamageType.ELECTRIC: 1.0, DamageType.POISON: 1.0},
		"speed": 1.8, "attack_range": 18.0, "detect_range": 6.0, "ranged": true, "loot_ammo": true,
	},
	&"brute": {
		"name": "ENEMY_BRUTE", "hp": 350, "damage": 30, "armor": 15,
		"weak_spot": "fire_electric", "behaviors": [Behavior.CHASE],
		"inflicts": [],
		"resistances": {DamageType.BULLET: 0.85, DamageType.SLASH: 1.0, DamageType.BLUNT: 0.85, DamageType.FIRE: 1.5, DamageType.ELECTRIC: 1.5, DamageType.POISON: 1.0},
		"speed": 1.5, "attack_range": 2.2, "detect_range": 10.0,
	},
	&"burner": {
		"name": "ENEMY_BURNER", "hp": 90, "damage": 15, "armor": 5,
		"weak_spot": "fire_immune", "behaviors": [Behavior.COVER],
		"inflicts": [Status.BURN],
		"resistances": {DamageType.BULLET: 1.0, DamageType.SLASH: 1.0, DamageType.BLUNT: 1.0, DamageType.FIRE: 0.1, DamageType.ELECTRIC: 1.0, DamageType.POISON: 1.0},
		"speed": 3.0, "attack_range": 8.0, "detect_range": 10.0, "ranged": true,
	},
	&"hound": {
		"name": "ENEMY_HOUND_PACK", "hp": 40, "damage": 18, "armor": 0,
		"weak_spot": "bullet", "behaviors": [Behavior.CHASE, Behavior.SWARM],
		"inflicts": [],
		"resistances": {DamageType.BULLET: 1.5, DamageType.SLASH: 1.0, DamageType.BLUNT: 1.0, DamageType.FIRE: 1.0, DamageType.ELECTRIC: 1.0, DamageType.POISON: 1.0},
		"speed": 5.4, "attack_range": 1.4, "detect_range": 18.0,
	},
	&"tvar": {
		"name": "ENEMY_TVAR", "hp": 1200, "damage": 40, "armor": 20,
		"weak_spot": "strobe_combo", "behaviors": [Behavior.CHASE],
		"inflicts": [],
		"resistances": {DamageType.BULLET: 0.6, DamageType.SLASH: 0.7, DamageType.BLUNT: 0.8, DamageType.FIRE: 0.9, DamageType.ELECTRIC: 1.5, DamageType.POISON: 0.6},
		"speed": 3.0, "attack_range": 3.0, "detect_range": 16.0, "mini_boss": true,
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
