extends Node

enum GameState { BOOT, MENU, PLAYING, PAUSED, DEAD, WIN }

var current_state: GameState = GameState.BOOT
var current_level: int = 1
var play_time: float = 0.0
var enemies_killed: int = 0

## HUD, экономика и инвентарь обращаются к GameManager.player. Ссылку не храним
## жёстко: сцена перезагружается при новой игре и старый узел становится битым —
## ищем по группе "player" и кэшируем, пока экземпляр валиден.
var _player_cache: Node = null
var player: Node:
	get:
		if is_instance_valid(_player_cache):
			return _player_cache
		var tree := get_tree()
		_player_cache = tree.get_first_node_in_group("player") if tree != null else null
		return _player_cache

## Волновой режим засчитывает убийства напрямую, минуя EventBus.enemy_killed.
func add_kill() -> void:
	enemies_killed += 1

func is_menu() -> bool: return current_state == GameState.MENU
func is_playing() -> bool: return current_state == GameState.PLAYING
func is_paused() -> bool: return current_state == GameState.PAUSED
func is_dead() -> bool: return current_state == GameState.DEAD
func is_win() -> bool: return current_state == GameState.WIN

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Master-шина раньше глушилась здесь безусловно и нигде не размьючивалась —
	# игра запускалась полностью беззвучной. Громкостью владеет SettingsManager.
	AudioServer.set_bus_mute(0, false)
	EventBus.enemy_killed.connect(func(_id: StringName) -> void: enemies_killed += 1)
	# Смерть игрока не была ни с чем связана: player_3d.take_damage() при hp <= 0
	# шлёт EventBus.game_over, но подписчик на него был только в game_over.gd,
	# который живёт в scenes/ui/game_over.tscn и в игру не инстанцируется.
	# В итоге игрок умирал, а игра продолжалась как ни в чём не бывало.
	# trigger_death() переводит состояние в DEAD, и UIManager открывает экран.
	EventBus.game_over.connect(_on_player_game_over)
	AdService.reward_granted.connect(_on_ad_reward)
	_change_state(GameState.MENU)

## Step 5: rewarded-ad payouts land here so every consumer (death screen's
## revive button, a future HUD battery-boost button) shares one place that
## actually applies the reward instead of each caller reimplementing it.
func _on_ad_reward(reward_id: StringName, _amount: int) -> void:
	var p := get_tree().get_first_node_in_group("player")
	match reward_id:
		&"revive":
			revive_player()
		&"extra_battery":
			if p and p.has_method("add_battery"):
				p.add_battery(50.0)

## GDD §5.4's respawn HP ratio (50%), but in place rather than at a
## checkpoint — this is the ad-revive path, not the standard death flow.
func revive_player() -> void:
	if current_state != GameState.DEAD:
		return
	var p := get_tree().get_first_node_in_group("player")
	if p == null:
		return
	if p.has_method("heal"):
		var max_hp: float = p.stats.max_hp if ("stats" in p and p.stats) else 100.0
		p.heal(max_hp * 0.5)
	_change_state(GameState.PLAYING)
	get_tree().paused = false
	UIManager.close_all_blocking()

## Защита от повторного входа: урон может прийти несколько раз за кадр.
func _on_player_game_over() -> void:
	if current_state == GameState.DEAD:
		return
	trigger_death()

func _process(delta: float) -> void:
	if is_playing():
		play_time += delta

func unlock_level(level: int) -> void:
	if level > current_level:
		current_level = level

func reset_run() -> void:
	current_level = 1
	play_time = 0.0
	enemies_killed = 0

func _change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return
	current_state = new_state
	EventBus.game_state_changed.emit(int(new_state))

func start_new_game() -> void:
	SaveSystem.reset_all()
	_enter_play_and_reload()

func continue_game() -> void:
	if not SaveSystem.load_all():
		EventBus.inventory_notice.emit(LocalizationManager.t("NO_SAVE"))
		return
	_enter_play_and_reload()

## Переводит автолоады в боевое состояние, но НЕ трогает дерево сцен.
## Раньше здесь стоял reload_current_scene(): при старте из меню он
## перезагружал само меню, а игровой мир так и не появлялся.
func _enter_play_and_reload() -> void:
	_change_state(GameState.PLAYING)
	UIManager.close_all_blocking()
	EventBus.game_started.emit()

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		_change_state(GameState.PAUSED)
		get_tree().paused = true

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		_change_state(GameState.PLAYING)
		get_tree().paused = false

func trigger_death() -> void:
	if current_state == GameState.DEAD:
		return
	Endings.mark_ended()
	_change_state(GameState.DEAD)
	get_tree().paused = false
	# game_over здесь НЕ переизлучаем: этот сигнал шлёт сам игрок, когда у него
	# кончилось здоровье, и именно он нас сюда и привёл. Повторный emit гонял бы
	# сигнал по кругу через _on_player_game_over.

func trigger_win() -> void:
	Endings.mark_ended()
	_change_state(GameState.WIN)
	EventBus.game_won.emit()

func return_to_menu() -> void:
	get_tree().paused = false
	var was_menu := current_state == GameState.MENU
	UIManager.close_all_blocking()
	_change_state(GameState.MENU)
	# Сплэш закрывается вызовом return_to_menu(), когда состояние УЖЕ MENU.
	# _change_state в этом случае молчит, а close_all_blocking() выше успевает
	# закрыть главное меню — игрок оставался на пустом экране с одним фоном.
	# Поэтому при переходе MENU->MENU шлём событие вручную.
	if was_menu:
		EventBus.game_state_changed.emit(int(GameState.MENU))