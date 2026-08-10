extends Node

signal state_changed(new_state: StringName, prev_state: StringName)

enum GameFlowState {
	BOOT,
	SPLASH,
	MAIN_MENU,
	LOADING,
	PLAYING,
	PAUSE,
	SETTINGS,
	INVENTORY,
	CITY_MAP,
	DIALOG,
	DEAD,
	WIN,
	CREDITS,
	SHOP,
	QUEST_JOURNAL,
	BESTIARY,
	STATS,
	ACHIEVEMENTS,
	SAVES,
	FLASHLIGHT_UPGRADE,
	PHOTO_MODE,
	CONTROLS_TOUCH,
	WEATHER,
	WORKBENCH,
	PUZZLE_CABLES,
	RADIO,
	STORY_SCENE,
	FINAL_NIGHT,
	POWER_GRID,
	EVENTS,
	TUTORIAL
}

var current_state: GameFlowState = GameFlowState.BOOT
var _prev_state: GameFlowState = GameFlowState.BOOT
var _transitioning: bool = false

const STATE_NAMES: Dictionary = {
	GameFlowState.BOOT: "BOOT",
	GameFlowState.SPLASH: "SPLASH",
	GameFlowState.MAIN_MENU: "MAIN_MENU",
	GameFlowState.LOADING: "LOADING",
	GameFlowState.PLAYING: "PLAYING",
	GameFlowState.PAUSE: "PAUSE",
	GameFlowState.SETTINGS: "SETTINGS",
	GameFlowState.INVENTORY: "INVENTORY",
	GameFlowState.CITY_MAP: "CITY_MAP",
	GameFlowState.DIALOG: "DIALOG",
	GameFlowState.DEAD: "DEAD",
	GameFlowState.WIN: "WIN",
	GameFlowState.CREDITS: "CREDITS",
	GameFlowState.SHOP: "SHOP",
	GameFlowState.QUEST_JOURNAL: "QUEST_JOURNAL",
	GameFlowState.BESTIARY: "BESTIARY",
	GameFlowState.STATS: "STATS",
	GameFlowState.ACHIEVEMENTS: "ACHIEVEMENTS",
	GameFlowState.SAVES: "SAVES",
	GameFlowState.FLASHLIGHT_UPGRADE: "FLASHLIGHT_UPGRADE",
	GameFlowState.PHOTO_MODE: "PHOTO_MODE",
	GameFlowState.CONTROLS_TOUCH: "CONTROLS_TOUCH",
	GameFlowState.WEATHER: "WEATHER",
	GameFlowState.WORKBENCH: "WORKBENCH",
	GameFlowState.PUZZLE_CABLES: "PUZZLE_CABLES",
	GameFlowState.RADIO: "RADIO",
	GameFlowState.STORY_SCENE: "STORY_SCENE",
	GameFlowState.FINAL_NIGHT: "FINAL_NIGHT",
	GameFlowState.POWER_GRID: "POWER_GRID",
	GameFlowState.EVENTS: "EVENTS",
	GameFlowState.TUTORIAL: "TUTORIAL"
}

const OVERLAY_SCREENS: Array = [
	GameFlowState.INVENTORY,
	GameFlowState.CITY_MAP,
	GameFlowState.QUEST_JOURNAL,
	GameFlowState.BESTIARY,
	GameFlowState.STATS,
	GameFlowState.ACHIEVEMENTS,
	GameFlowState.SHOP,
	GameFlowState.FLASHLIGHT_UPGRADE,
	GameFlowState.PHOTO_MODE,
	GameFlowState.CONTROLS_TOUCH,
	GameFlowState.WEATHER,
	GameFlowState.WORKBENCH,
	GameFlowState.PUZZLE_CABLES,
	GameFlowState.RADIO,
	GameFlowState.SAVES,
	GameFlowState.SETTINGS,
	GameFlowState.DIALOG,
]

var _screens: Node
var _fade: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_screens = get_node_or_null("/root/Screens")
	_fade = get_node_or_null("FadeTransition")
	
	# Initial state - sync transition for _ready
	current_state = GameFlowState.BOOT
	_enter_state(GameFlowState.BOOT)
	
	# Connect events
	EventBus.game_state_changed.connect(_on_game_state_changed)
	EventBus.ui_screen_opened.connect(_on_ui_screen_opened)
	EventBus.ui_screen_closed.connect(_on_ui_screen_closed)

func _on_game_state_changed(state: int) -> void:
	# Маппинг GameManager.GameState -> GameFlowState.
	# ВАЖНО: индексы должны совпадать с enum в scripts/core/game_manager.gd:
	#   BOOT=0, MENU=1, PLAYING=2, PAUSED=3, DEAD=4, WIN=5
	# Раньше таблица была сдвинута на единицу (0:MENU, 1:PLAYING, 2:PAUSE...),
	# из-за чего вход в PLAYING(2) трактовался как PAUSE и _show_pause()
	# ставил get_tree().paused = true — игра замирала сразу после старта.
	var mapping: Dictionary = {
		GameManager.GameState.BOOT: GameFlowState.BOOT,
		GameManager.GameState.MENU: GameFlowState.MAIN_MENU,
		GameManager.GameState.PLAYING: GameFlowState.PLAYING,
		GameManager.GameState.PAUSED: GameFlowState.PAUSE,
		GameManager.GameState.DEAD: GameFlowState.DEAD,
		GameManager.GameState.WIN: GameFlowState.WIN,
	}
	if mapping.has(state):
		# Sync transition for test compatibility
		var target = mapping[state]
		if target != current_state:
			_prev_state = current_state
			current_state = target
			state_changed.emit(STATE_NAMES.get(target, "UNKNOWN"), STATE_NAMES.get(_prev_state, "UNKNOWN"))
			_enter_state(target)

func _on_ui_screen_opened(screen_id: StringName) -> void:
	var mapping: Dictionary = {
		&"pause": GameFlowState.PAUSE,
		&"settings": GameFlowState.SETTINGS,
		&"inventory": GameFlowState.INVENTORY,
		&"city_map": GameFlowState.CITY_MAP,
		&"quest_journal": GameFlowState.QUEST_JOURNAL,
		&"bestiary": GameFlowState.BESTIARY,
		GameFlowState.STATS: GameFlowState.STATS,
		GameFlowState.ACHIEVEMENTS: GameFlowState.ACHIEVEMENTS,
		GameFlowState.SHOP: GameFlowState.SHOP,
		GameFlowState.FLASHLIGHT_UPGRADE: GameFlowState.FLASHLIGHT_UPGRADE,
		GameFlowState.PHOTO_MODE: GameFlowState.PHOTO_MODE,
		GameFlowState.CONTROLS_TOUCH: GameFlowState.CONTROLS_TOUCH,
		GameFlowState.WEATHER: GameFlowState.WEATHER,
		GameFlowState.WORKBENCH: GameFlowState.WORKBENCH,
		GameFlowState.PUZZLE_CABLES: GameFlowState.PUZZLE_CABLES,
		GameFlowState.RADIO: GameFlowState.RADIO,
		GameFlowState.SAVES: GameFlowState.SAVES,
		GameFlowState.SETTINGS: GameFlowState.SETTINGS,
		GameFlowState.DIALOG: GameFlowState.DIALOG,
	}
	if mapping.has(screen_id):
		_transition_to_overlay(mapping[screen_id])

func _on_ui_screen_closed(screen_id: StringName) -> void:
	# If we were in an overlay, return to playing
	if current_state in OVERLAY_SCREENS and not _any_overlay_open():
		transition_to(GameFlowState.PLAYING)

func _any_overlay_open() -> bool:
	if not _screens or not _screens.has_method("is_any_open"):
		return false
	return _screens.is_any_open()

func transition_to(target: GameFlowState) -> void:
	if _transitioning or target == current_state:
		return
	
	_prev_state = current_state
	_transitioning = true
	
	# Handle exit logic
	_exit_state(current_state)
	
	# Fade transition
	var fade_done: Array = [false]
	if _fade and _fade.has_method("fade_out"):
		_fade.fade_out(0.3).finished.connect(func(): fade_done[0] = true)
	else:
		fade_done[0] = true
	
	await _wait_for_fade()
	
	current_state = target
	state_changed.emit(STATE_NAMES.get(target, "UNKNOWN"), STATE_NAMES.get(_prev_state, "UNKNOWN"))
	
	# Handle enter logic
	_enter_state(current_state)
	
	_transitioning = false

func _wait_for_fade() -> void:
	# Simple wait - in practice, wait for fade signal
	await get_tree().create_timer(0.1).timeout

func _transition_to_overlay(target: GameFlowState) -> void:
	if target in OVERLAY_SCREENS:
		_prev_state = current_state
		current_state = target
		state_changed.emit(STATE_NAMES.get(target, "UNKNOWN"), STATE_NAMES.get(_prev_state, "UNKNOWN"))
		_enter_state(target)

func _exit_state(state: GameFlowState) -> void:
	match state:
		GameFlowState.PLAYING:
			pass
		GameFlowState.MAIN_MENU:
			pass
		GameFlowState.PAUSE:
			pass
		GameFlowState.DEAD:
			pass
		GameFlowState.WIN:
			pass
		GameFlowState.CREDITS:
			pass

func _enter_state(state: GameFlowState) -> void:
	match state:
		GameFlowState.BOOT:
			_start_boot()
		GameFlowState.SPLASH:
			_show_splash()
		GameFlowState.MAIN_MENU:
			_show_main_menu()
		GameFlowState.LOADING:
			_show_loading()
		GameFlowState.PLAYING:
			_resume_game()
		GameFlowState.PAUSE:
			_show_pause()
		GameFlowState.SETTINGS:
			_show_settings()
		GameFlowState.INVENTORY:
			_show_inventory()
		GameFlowState.CITY_MAP:
			_show_city_map()
		GameFlowState.DIALOG:
			pass
		GameFlowState.DEAD:
			_show_death()
		GameFlowState.WIN:
			_show_victory()
		GameFlowState.CREDITS:
			_show_credits()

func _start_boot() -> void:
	# Boot sequence: load resources, then splash
	await get_tree().create_timer(0.5).timeout
	transition_to(GameFlowState.SPLASH)

func _show_splash() -> void:
	if _screens and _screens.has_method("show_screen"):
		_screens.show_screen("Splash")

func _show_main_menu() -> void:
	if _screens and _screens.has_method("show_screen"):
		_screens.show_screen("MainMenu")
		EventBus.ui_screen_opened.emit(&"main_menu")

func _show_loading() -> void:
	if _screens and _screens.has_method("show_screen"):
		_screens.show_screen("Loading")

func _resume_game() -> void:
	if _screens and _screens.has_method("hide_all"):
		_screens.hide_all()
	get_tree().paused = false

func _show_pause() -> void:
	get_tree().paused = true
	if _screens and _screens.has_method("show_screen"):
		_screens.show_screen("Pause")
		EventBus.ui_screen_opened.emit(&"pause")

func _show_settings() -> void:
	if _screens and _screens.has_method("show_screen"):
		_screens.show_screen("Settings")
		EventBus.ui_screen_opened.emit(&"settings")

func _show_inventory() -> void:
	if _screens and _screens.has_method("show_screen"):
		_screens.show_screen("Inventory")
		EventBus.ui_screen_opened.emit(&"inventory")

func _show_city_map() -> void:
	if _screens and _screens.has_method("show_screen"):
		_screens.show_screen("CityMap")
		EventBus.ui_screen_opened.emit(&"city_map")

func _show_death() -> void:
	if _screens and _screens.has_method("show_screen"):
		_screens.show_screen("Death")
		EventBus.ui_screen_opened.emit(&"death")

func _show_victory() -> void:
	if _screens and _screens.has_method("show_screen"):
		_screens.show_screen("Victory")
		EventBus.ui_screen_opened.emit(&"victory")

func _show_credits() -> void:
	if _screens and _screens.has_method("show_screen"):
		_screens.show_screen("Credits")
		EventBus.ui_screen_opened.emit(&"credits")

func get_state_name(state: GameFlowState = current_state) -> String:
	return STATE_NAMES.get(state, "UNKNOWN")

func is_overlay(state: GameFlowState) -> bool:
	return state in OVERLAY_SCREENS

func is_gameplay_state(state: GameFlowState) -> bool:
	return state == GameFlowState.PLAYING