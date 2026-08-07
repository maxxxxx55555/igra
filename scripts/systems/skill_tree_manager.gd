extends Node

signal skill_unlocked(skill_id: StringName)
signal skill_xp_gained(skill_id: StringName, amount: int)

const SKILL_TREES: Dictionary = {
	"combat": {
		"name": "Combat",
		"skills": {
			"damage_boost_1": {
				"name": "Damage Boost I",
				"description": "+10% weapon damage",
				"cost": 1,
				"requires": [],
				"max_level": 3,
				"effect_per_level": 0.1
			},
			"damage_boost_2": {
				"name": "Damage Boost II",
				"description": "+10% weapon damage",
				"cost": 2,
				"requires": ["damage_boost_1"],
				"max_level": 3,
				"effect_per_level": 0.1
			},
			"crit_chance": {
				"name": "Critical Strike",
				"description": "+5% critical hit chance",
				"cost": 2,
				"requires": ["damage_boost_1"],
				"max_level": 3,
				"effect_per_level": 0.05
			},
			"fire_rate": {
				"name": "Rapid Fire",
				"description": "+15% fire rate",
				"cost": 2,
				"requires": [],
				"max_level": 2,
				"effect_per_level": 0.15
			},
			"reload_speed": {
				"name": "Quick Reload",
				"description": "+25% reload speed",
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
				"name": "Vitality",
				"description": "+20 max health",
				"cost": 1,
				"requires": [],
				"max_level": 3,
				"effect_per_level": 20
			},
			"health_regen": {
				"name": "Regeneration",
				"description": "+2 HP/sec regeneration",
				"cost": 2,
				"requires": ["max_health"],
				"max_level": 2,
				"effect_per_level": 2
			},
			"stamina_boost": {
				"name": "Endurance",
				"description": "+30 max stamina",
				"cost": 1,
				"requires": [],
				"max_level": 2,
				"effect_per_level": 30
			},
			"battery_capacity": {
				"name": "Power Cells",
				"description": "+25 max battery",
				"cost": 1,
				"requires": [],
				"max_level": 2,
				"effect_per_level": 25
			},
			"light_radius": {
				"name": "Illumination",
				"description": "+20% flashlight range",
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
				"name": "Pack Rat",
				"description": "+5 inventory slots",
				"cost": 1,
				"requires": [],
				"max_level": 3,
				"effect_per_level": 5
			},
			"move_speed": {
				"name": "Lightfoot",
				"description": "+10% movement speed",
				"cost": 1,
				"requires": [],
				"max_level": 2,
				"effect_per_level": 0.1
			},
			"stealth": {
				"name": "Ghost",
				"description": "Enemies detect you 25% slower",
				"cost": 2,
				"requires": ["move_speed"],
				"max_level": 2,
				"effect_per_level": 0.25
			},
			"xp_boost": {
				"name": "Fast Learner",
				"description": "+15% XP gain",
				"cost": 2,
				"requires": [],
				"max_level": 2,
				"effect_per_level": 0.15
			},
			"loot_luck": {
				"name": "Scavenger",
				"description": "+20% rare loot chance",
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
			if player.has_method("set_max_stamina"):
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