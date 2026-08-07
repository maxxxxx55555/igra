extends Node
## Autoload "SaveLoad".  Coins, lives, powered districts, current district.
## Auto-saves on district_entered / pause / game_saved signal.

const SAVE_PATH := "user://saves/save_0.json"
const MAX_LIVES := 3

var coins: int = 0
var lives: int = MAX_LIVES
var powered: Dictionary = {}
var current_district: StringName = &""
var flashlight_battery: float = 1.0
var player_position: Vector3 = Vector3.ZERO
var _ending_shown: bool = false
var _bus: Node

func _ready() -> void:
	_ensure_save_dir()
	_bus = get_node_or_null("/root/EventBus")
	if _bus != null:
		_bus.district_entered.connect(_on_district_entered)
		_bus.game_saved.connect(_on_game_saved)
		_bus.shop_purchased.connect(_on_shop_purchased)
		_bus.player_caught.connect(_on_player_caught)
	if FileAccess.file_exists(SAVE_PATH):
		load_game()

func _ensure_save_dir() -> void:
	var d := DirAccess.open("user://")
	if d != null and not d.dir_exists("saves"):
		d.make_dir_recursive("saves")

func _on_district_entered(d: StringName) -> void:
	current_district = d
	save_game()

func _on_game_saved() -> void:
	save_game()

func _on_shop_purchased(item: StringName) -> void:
	if item == &"medkit":
		lives = min(MAX_LIVES, lives + 1)
		if _bus != null:
			_bus.emit_lives(lives)
	elif item == &"battery":
		flashlight_battery = min(1.0, flashlight_battery + 0.25)
	elif item == &"stamina":
		pass
	save_game()

func _on_player_caught() -> void:
	lives = max(0, lives - 1)
	if _bus != null:
		_bus.emit_lives(lives)
	if lives <= 0:
		var sl := get_tree().root.get_node_or_null("SaveLoad")
		if sl != null:
			sl._ending_shown = true
		var es := get_tree().root.get_node_or_null("EndingScreen")
		if es == null:
			es = load("res://scripts/ui/ending_screen.gd").new()
			get_tree().root.add_child(es)
		if es.has_method("show_ending"):
			es.show_ending("lose")
	save_game()

func get_lives() -> int: return lives
func get_coins() -> int: return coins
func is_powered(d: StringName) -> bool: return powered.get(d, false)
func mark_ending_shown() -> void: _ending_shown = true

func set_coins(c: int) -> void:
	coins = max(0, c)
	if _bus != null:
		_bus.emit_coin(coins)

func add_coins(c: int) -> void:
	set_coins(coins + c)

func set_powered(d: StringName, v: bool) -> void:
	powered[d] = v
	if v and _bus != null:
		_bus.emit_district_powered(d)
	save_game()

func save_game() -> void:
	_ensure_save_dir()
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		# push_warning("[SaveLoad] cannot open save for write")
		return
	var data := {
		"coins": coins,
		"lives": lives,
		"powered": powered,
		"current_district": String(current_district),
		"flashlight_battery": flashlight_battery,
		"player_position": [player_position.x, player_position.y, player_position.z],
		"ending_shown": _ending_shown
	}
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

func load_game() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var txt := f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		return false
	coins = int(data.get("coins", 0))
	lives = int(data.get("lives", MAX_LIVES))
	powered = data.get("powered", {})
	current_district = StringName(String(data.get("current_district", "")))
	flashlight_battery = float(data.get("flashlight_battery", 1.0))
	var pp = data.get("player_position", [0, 0, 0])
	if pp is Array and pp.size() >= 3:
		player_position = Vector3(float(pp[0]), float(pp[1]), float(pp[2]))
	_ending_shown = bool(data.get("ending_shown", false))
	if _bus != null:
		_bus.emit_coin(coins)
		_bus.emit_lives(lives)
	return true

func reset() -> void:
	coins = 0
	lives = MAX_LIVES
	powered = {}
	current_district = &""
	flashlight_battery = 1.0
	player_position = Vector3.ZERO
	_ending_shown = false
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))