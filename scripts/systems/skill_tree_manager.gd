extends Node

signal skill_unlocked(skill_id: StringName)
signal skill_xp_gained(skill_id: StringName, amount: int)

const SKILL_TREES: Dictionary = {
	"combat": {
		"name": "Combat",
		"skills": {
			"damage_boost_1": {
				"name": "SKILL_DAMAGE_BOOST_1_NAME",
				"description": "SKILL_DAMAGE_BOOST_1_DESC",
				"cost": 1,
				"requires": [],
				"max_level": 3,
				"effect_per_level": 0.1
			},
			"damage_boost_2": {
				"name": "SKILL_DAMAGE_BOOST_2_NAME",
				"description": "SKILL_DAMAGE_BOOST_2_DESC",
				"cost": 2,
				"requires": ["damage_boost_1"],
				"max_level": 3,
				"effect_per_level": 0.1
			},
			"crit_chance": {
				"name": "SKILL_CRIT_CHANCE_NAME",
				"description": "SKILL_CRIT_CHANCE_DESC",
				"cost": 2,
				"requires": ["damage_boost_1"],
				"max_level": 3,
				"effect_per_level": 0.05
			},
			"fire_rate": {
				"name": "SKILL_FIRE_RATE_NAME",
				"description": "SKILL_FIRE_RATE_DESC",
				"cost": 2,
				"requires": [],
				"max_level": 2,
				"effect_per_level": 0.15
			},
			"reload_speed": {
				"name": "SKILL_RELOAD_SPEED_NAME",
				"description": "SKILL_RELOAD_SPEED_DESC",
				"cost": 1,
				"requires": ["fire_rate"],
				"max_level": 2,
				"effect_per_level": 0.25
			},
		}
	},
	"survival": {
		"name": "Survival",
		"skills": {
			"max_health": {
				"name": "SKILL_MAX_HEALTH_NAME",
				"description": "SKILL_MAX_HEALTH_DESC",
				"cost": 1,
				"requires": [],
				"max_level": 3,
				"effect_per_level": 20
			},
			"health_regen": {
				"name": "SKILL_HEALTH_REGEN_NAME",
				"description": "SKILL_HEALTH_REGEN_DESC",
				"cost": 2,
				"requires": ["max_health"],
				"max_level": 2,
				"effect_per_level": 2
			},
			"stamina_boost": {
				"name": "SKILL_STAMINA_BOOST_NAME",
				"description": "SKILL_STAMINA_BOOST_DESC",
				"cost": 1,
				"requires": [],
				"max_level": 2,
				"effect_per_level": 30
			},
			"battery_capacity": {
				"name": "SKILL_BATTERY_CAPACITY_NAME",
				"description": "SKILL_BATTERY_CAPACITY_DESC",
				"cost": 1,
				"requires": [],
				"max_level": 2,
				"effect_per_level": 25
			},
			"light_radius": {
				"name": "SKILL_LIGHT_RADIUS_NAME",
				"description": "SKILL_LIGHT_RADIUS_DESC",
				"cost": 1,
				"requires": ["battery_capacity"],
				"max_level": 2,
				"effect_per_level": 0.2
			},
		}
	},
	"utility": {
		"name": "Utility",
		"skills": {
			"inventory_space": {
				"name": "SKILL_INVENTORY_SPACE_NAME",
				"description": "SKILL_INVENTORY_SPACE_DESC",
				"cost": 1,
				"requires": [],
				"max_level": 3,
				"effect_per_level": 5
			},
			"move_speed": {
				"name": "SKILL_MOVE_SPEED_NAME",
				"description": "SKILL_MOVE_SPEED_DESC",
				"cost": 1,
				"requires": [],
				"max_level": 2,
				"effect_per_level": 0.1
			},
			"stealth": {
				"name": "SKILL_STEALTH_NAME",
				"description": "SKILL_STEALTH_DESC",
				"cost": 2,
				"requires": ["move_speed"],
				"max_level": 2,
				"effect_per_level": 0.25
			},
			"xp_boost": {
				"name": "SKILL_XP_BOOST_NAME",
				"description": "SKILL_XP_BOOST_DESC",
				"cost": 2,
				"requires": [],
				"max_level": 2,
				"effect_per_level": 0.15
			},
			"loot_luck": {
				"name": "SKILL_LOOT_LUCK_NAME",
				"description": "SKILL_LOOT_LUCK_DESC",
				"cost": 2,
				"requires": ["xp_boost"],
				"max_level": 2,
				"effect_per_level": 0.2
			},
		}
	}
}

var _unlocked_skills: Dictionary = {}  # skill_id -> level
var _skill_points: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func add_skill_points(amount: int) -> void:
	_skill_points += amount
	EventBus.settings_changed.emit("skill_points", _skill_points)

func get_skill_points() -> int:
	return _skill_points

func is_unlocked(skill_id: StringName) -> bool:
	for tree in SKILL_TREES.values():
		if tree.skills.has(skill_id):
			return _unlocked_skills.get(skill_id, 0) > 0
	return false

func get_skill_level(skill_id: StringName) -> int:
	return _unlocked_skills.get(skill_id, 0)

func can_unlock(skill_id: StringName) -> bool:
	for tree in SKILL_TREES.values():
		if tree.skills.has(skill_id):
			var skill = tree.skills[skill_id]
			var current_level = _unlocked_skills.get(skill_id, 0)
			if current_level >= skill.max_level:
				return false
			if _skill_points < skill.cost:
				return false
			for req in skill.requires:
				if not is_unlocked(req):
					return false
			return true
	return false

func unlock_skill(skill_id: StringName) -> bool:
	if not can_unlock(skill_id):
		return false
	
	for tree in SKILL_TREES.values():
		if tree.skills.has(skill_id):
			var skill = tree.skills[skill_id]
			_skill_points -= skill.cost
			_unlocked_skills[skill_id] = _unlocked_skills.get(skill_id, 0) + 1
			_apply_skill_effect(skill_id, _unlocked_skills[skill_id])
			skill_unlocked.emit(skill_id)
			EventBus.settings_changed.emit("skill_points", _skill_points)
			return true
	return false

func _apply_skill_effect(skill_id: StringName, level: int) -> void:
	# Apply effects to player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	match skill_id:
		"damage_boost_1", "damage_boost_2", "crit_chance", "fire_rate", "reload_speed":
			# Handled by weapon system
			pass
		"max_health":
			if player.has_method("set_max_health"):
				player.set_max_health(player.max_health + 20)
		"health_regen":
			# Add regen to player stats
			pass
		"stamina_boost":
			if player.has_method("set_max_stamina") and player.stats:
				player.set_max_stamina(player.stats.stamina_max + 30)
		"battery_capacity":
			if player.has_method("set_max_battery"):
				player.set_max_battery(player.battery + 25)
		"light_radius":
			# Handled by flashlight
			pass
		"inventory_space":
			InventoryManager.add_slots(5)
		"move_speed":
			if player.stats:
				player.stats.walk_speed *= 1.1
				player.stats.run_speed *= 1.1
		"stealth":
			# Handled by enemy AI detection
			pass
		"xp_boost":
			# Multiplier applied in XP gain
			pass
		"loot_luck":
			# Handled by loot system
			pass

func get_tree_data(tree_id: StringName) -> Dictionary:
	return SKILL_TREES.get(tree_id, {})

func get_all_trees() -> Dictionary:
	return SKILL_TREES

func get_unlocked_skills() -> Dictionary:
	return _unlocked_skills.duplicate()

## Тот же пробел, что и у XpManager: reset_all() никогда сюда не заглядывал —
## очки/разблокированные скиллы переживали "новую игру".
func reset() -> void:
	_unlocked_skills = {}
	_skill_points = 0

func save_data() -> Dictionary:
	return {
		"unlocked_skills": _unlocked_skills,
		"skill_points": _skill_points
	}

func load_data(data: Dictionary) -> void:
	_unlocked_skills = data.get("unlocked_skills", {})
	_skill_points = data.get("skill_points", 0)
	
	# Re-apply all effects
	for skill_id in _unlocked_skills:
		_apply_skill_effect(skill_id, _unlocked_skills[skill_id])