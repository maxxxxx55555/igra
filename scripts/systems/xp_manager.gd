extends Node

signal xp_gained(amount: int)
signal level_up(new_level: int)
signal skill_point_earned()

@export var base_xp_per_level: int = 100
@export var xp_growth_factor: float = 1.5

var _level: int = 1
var _current_xp: int = 0
var _xp_to_next: int = 100
var _total_skill_points: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_xp_to_next = base_xp_per_level
	
	# Listen for XP events
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.puzzle_solved.connect(_on_puzzle_solved)
	EventBus.district_restored.connect(_on_district_restored)
	EventBus.secret_found.connect(_on_secret_found)

func _on_enemy_killed(monster_id: StringName) -> void:
	var xp_rewards = {
		"shadow": 10,
		"crawler": 15,
		"watcher": 20,
		"hunter": 30,
		"destroyer": 50,
		"boss": 500,
	}
	var xp = xp_rewards.get(String(monster_id), 10)
	_add_xp(xp)

func _on_puzzle_solved(puzzle_id: StringName, district_id: StringName) -> void:
	_add_xp(50)

func _on_district_restored(district_id: StringName, stage: int) -> void:
	_add_xp(100)

func _on_secret_found(secret_id: StringName) -> void:
	_add_xp(75)

## Публичная точка входа: секретные комнаты и квесты начисляют опыт напрямую.
func add_xp(amount: int) -> void:
	_add_xp(amount)

func _add_xp(amount: int) -> void:
	# Apply XP boost from skills
	var boost = 1.0
	if SkillTreeManager.is_unlocked("xp_boost"):
		var level = SkillTreeManager.get_skill_level("xp_boost")
		boost += 0.15 * level
	
	amount = int(amount * boost * NewGamePlus.get_xp_multiplier())
	
	_current_xp += amount
	xp_gained.emit(amount)
	
	while _current_xp >= _xp_to_next:
		_level_up()
	
	EventBus.settings_changed.emit("xp", _current_xp)

func _level_up() -> void:
	_current_xp -= _xp_to_next
	_level += 1
	_xp_to_next = int(base_xp_per_level * pow(xp_growth_factor, _level - 1))
	
	_total_skill_points += 1
	SkillTreeManager.add_skill_points(1)
	
	level_up.emit(_level)
	skill_point_earned.emit()
	
	UIManager.show_notification(tr("Level Up! Now level %d") % _level)

func get_level() -> int:
	return _level

func get_current_xp() -> int:
	return _current_xp

func get_xp_to_next() -> int:
	return _xp_to_next

func get_xp_progress() -> float:
	return float(_current_xp) / _xp_to_next

func get_total_skill_points() -> int:
	return _total_skill_points

func save_data() -> Dictionary:
	return {
		"level": _level,
		"current_xp": _current_xp,
		"xp_to_next": _xp_to_next,
		"total_skill_points": _total_skill_points
	}

func load_data(data: Dictionary) -> void:
	_level = data.get("level", 1)
	_current_xp = data.get("current_xp", 0)
	_xp_to_next = data.get("xp_to_next", base_xp_per_level)
	_total_skill_points = data.get("total_skill_points", 0)