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
    AudioServer.set_bus_mute(0, true)
    EventBus.enemy_killed.connect(func(_id: StringName) -> void: enemies_killed += 1)
    _change_state(GameState.MENU)

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
        EventBus.inventory_notice.emit("Нет сохранения")
        return
    _enter_play_and_reload()

func _enter_play_and_reload() -> void:
    _change_state(GameState.PLAYING)
    UIManager.close_all_blocking()
    EventBus.game_started.emit()
    get_tree().reload_current_scene()

func pause_game() -> void:
    if current_state == GameState.PLAYING:
        _change_state(GameState.PAUSED)
        get_tree().paused = true

func resume_game() -> void:
    if current_state == GameState.PAUSED:
        _change_state(GameState.PLAYING)
        get_tree().paused = false

func trigger_death() -> void:
    Endings.mark_ended()
    _change_state(GameState.DEAD)
    get_tree().paused = false
    EventBus.game_over.emit()

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