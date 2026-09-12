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
	},
	## PLAN.md Stage 3: 4th branch (GDD §8 wants 4, project had 3). Built on
	## the two real, already-live stealth mechanics (player_3d.gd's noise
	## emission, base_monster.gd's investigate-timer) rather than a new
	## visibility-multiplier system that doesn't exist anywhere in the
	## codebase yet - reuse before writing.
	"stealth": {
		"name": "Stealth",
		"skills": {
			"silent_steps": {
				"name": "SKILL_SILENT_STEPS_NAME",
				"description": "SKILL_SILENT_STEPS_DESC",
				"cost": 1,
				"requires": [],
				"max_level": 3,
				"effect_per_level": 0.15
			},
			"cold_trail": {
				"name": "SKILL_COLD_TRAIL_NAME",
				"description": "SKILL_COLD_TRAIL_DESC",
				"cost": 2,
				"requires": ["silent_steps"],
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
			# Read live by weapon_base.gd at the point each stat is used.
			pass
		"max_health":
			if player.stats:
				player.stats.max_hp += 20
		"health_regen":
			# Read live each frame by player_3d.gd's _physics_process.
			pass
		"stamina_boost":
			if player.stats:
				player.stats.stamina_max += 30
		"battery_capacity":
			player.battery_max += 25
		"light_radius":
			if player.has_method("refresh_flashlight_range"):
				player.refresh_flashlight_range()
		"inventory_space":
			InventoryManager.add_slots(5)
		"move_speed":
			if player.stats:
				player.stats.walk_speed *= 1.1
				player.stats.run_speed *= 1.1
		"xp_boost":
			# Multiplier applied in XP gain
			pass
		"loot_luck":
			# Read live by district_loot.gd at roll time.
			pass
		"silent_steps":
			# Read directly each frame by player_3d.gd's noise_radius calc
			pass
		"cold_trail":
			# Read directly by base_monster.gd when setting _investigate_timer
			pass

## Static audit 2026-09-08: load_data() below used to call
## _apply_skill_effect() itself, at a moment (SaveSystem's data-parse phase)
## that runs BEFORE the player node exists - it silently no-op'd for every
## "push once" skill above every single time a save was loaded, since
## get_tree().get_first_node_in_group("player") was always empty. Split out
## so player_3d.gd can call this once its own _ready() confirms the player
## actually exists. Also fixes a second bug in the same loop: a stored
## level N only replayed the per-level effect once instead of N times.
func reapply_all_effects() -> void:
	for skill_id in _unlocked_skills:
		var level: int = int(_unlocked_skills[skill_id])
		for lvl in range(1, level + 1):
			_apply_skill_effect(skill_id, lvl)

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

## Anti-tamper sanity clamp (RELEASE CONVERGENCE, STEP 5): type-check the
## dictionary (a hand-edited save could put any JSON value there) and bound
## skill_points — see xp_manager.gd's load_data() for the same rationale.
func load_data(data: Dictionary) -> void:
	var unlocked: Variant = data.get("unlocked_skills", {})
	_unlocked_skills = unlocked if unlocked is Dictionary else {}
	_skill_points = clampi(int(data.get("skill_points", 0)), 0, 9999)
	# Effects are NOT reapplied here - this runs before the player node
	# exists (see reapply_all_effects()'s comment). player_3d.gd calls
	# reapply_all_effects() itself once it's ready.