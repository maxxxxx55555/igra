class_name MusicDirector
extends Node

## Адаптивная музыка: слоёный микс с плавными переходами по игровой ситуации.
## Состояния: MENU -> AMBIENT -> TENSION -> BATTLE -> BOSS -> VICTORY.
## Два плеера с перекрёстным затуханием, чтобы смена трека не щёлкала.
## Author: OpenCode
## Version: 2.0.0

#region Signals
signal track_changed(state: int)
#endregion

#region Enums
enum Mood { MENU, AMBIENT, TENSION, BATTLE, BOSS, VICTORY }
#endregion

#region Constants
const TRACKS: Dictionary = {
	Mood.MENU: "res://assets/audio/music/music_menu_dark.wav",
	Mood.AMBIENT: "res://assets/audio/music/music_ambient.wav",
	Mood.TENSION: "res://assets/audio/music/music_tension.wav",
	Mood.BATTLE: "res://assets/audio/music/music_battle.wav",
	Mood.BOSS: "res://assets/audio/music/music_boss_dark.wav",
	Mood.VICTORY: "res://assets/audio/music/music_victory.wav",
}
## Эмбиент по районам: у каждого района своя фоновая тема.
const AMBIENT_BY_DISTRICT: Dictionary = {
	&"suburbs": "res://assets/audio/music/music_ambient.wav",
	&"residential": "res://assets/audio/music/music_ambient.wav",
	&"old_town": "res://assets/audio/music/music_ambient_dark.wav",
}
const FADE_TIME: float = 2.2          ## Длительность перекрёстного затухания, с
const FULL_DB: float = -8.0           ## Рабочая громкость музыки
const MUTE_DB: float = -60.0
const EVAL_INTERVAL: float = 0.5      ## Как часто пересчитывать настроение, с
const TENSION_RANGE: float = 22.0     ## Дистанция появления тревожного трека, м
const BATTLE_RANGE: float = 9.0       ## Дистанция перехода в боевой трек, м
const CALM_DELAY: float = 6.0         ## Задержка возврата к спокойной музыке, с
#endregion

#region Public Variables
var mood: Mood = Mood.MENU
#endregion

#region Private Variables
var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _active: AudioStreamPlayer
var _fade: Tween
var _eval_timer: float = 0.0
var _combat_hold: float = 0.0
var _boss_active: bool = false
var _cache: Dictionary = {}
var _ambient_path: String = TRACKS[Mood.AMBIENT]
#endregion

#region Virtual Methods
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_a = _make_player("MusicA")
	_b = _make_player("MusicB")
	_active = _a
	EventBus.game_started.connect(func() -> void: set_mood(Mood.AMBIENT))
	EventBus.game_won.connect(func() -> void: set_mood(Mood.VICTORY))
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.player_detected.connect(func(_id: StringName) -> void: _combat_hold = CALM_DELAY)
	EventBus.enemy_attack.connect(func(_d: int) -> void: _combat_hold = CALM_DELAY)
	EventBus.district_entered.connect(_on_district_entered)
	set_mood(Mood.MENU, true)

func _process(delta: float) -> void:
	_combat_hold = maxf(0.0, _combat_hold - delta)
	_eval_timer -= delta
	if _eval_timer > 0.0:
		return
	_eval_timer = EVAL_INTERVAL
	_evaluate()
#endregion

#region Public Methods
## Переключает настроение. instant=true — без затухания (старт игры).
## force=true — перезапустить даже то же настроение (смена трека района).
func set_mood(new_mood: Mood, instant: bool = false, force: bool = false) -> void:
	if new_mood == mood and _active.playing and not force:
		return
	mood = new_mood
	var stream := _load(new_mood)
	if stream == null:
		return
	var next: AudioStreamPlayer = _b if _active == _a else _a
	next.stream = stream
	next.volume_db = MUTE_DB if not instant else FULL_DB
	next.play()
	if _fade != null and _fade.is_valid():
		_fade.kill()
	if instant:
		_active.stop()
		_active = next
	else:
		var prev := _active
		_fade = create_tween().set_parallel(true)
		_fade.tween_property(next, "volume_db", FULL_DB, FADE_TIME)
		_fade.tween_property(prev, "volume_db", MUTE_DB, FADE_TIME)
		_fade.chain().tween_callback(prev.stop)
		_active = next
	track_changed.emit(int(new_mood))

## Включает музыку босса до его смерти.
func enter_boss() -> void:
	_boss_active = true
	set_mood(Mood.BOSS)

func stop_music() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_a.stop()
	_b.stop()
#endregion

#region Private Methods
func _make_player(p_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = p_name
	p.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
	p.volume_db = MUTE_DB
	add_child(p)
	return p

func _load(m: Mood) -> AudioStream:
	var path: String = _ambient_path if m == Mood.AMBIENT else TRACKS.get(m, "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	if _cache.has(path):
		return _cache[path]
	var s := load(path) as AudioStream
	if s is AudioStreamWAV:
		(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_cache[path] = s
	return s

## Смена района: подменяем эмбиент-трек; если он сейчас звучит — плавный кроссфейд.
func _on_district_entered(district_id: StringName) -> void:
	var path: String = AMBIENT_BY_DISTRICT.get(district_id, "")
	if path == "" or path == _ambient_path:
		return
	_ambient_path = path
	if mood == Mood.AMBIENT:
		set_mood(Mood.AMBIENT, false, true)

## Выбор настроения по игровой ситуации: босс > бой > тревога > спокойствие.
func _evaluate() -> void:
	if mood == Mood.VICTORY:
		return
	if not GameManager.is_playing():
		if GameManager.is_menu() and mood != Mood.MENU:
			set_mood(Mood.MENU)
		return
	if _boss_active:
		if mood != Mood.BOSS:
			set_mood(Mood.BOSS)
		return
	var nearest := _nearest_enemy_distance()
	var target: Mood = Mood.AMBIENT
	if nearest <= BATTLE_RANGE or _combat_hold > 0.0:
		target = Mood.BATTLE
	elif nearest <= TENSION_RANGE:
		target = Mood.TENSION
	if target != mood:
		set_mood(target)

func _nearest_enemy_distance() -> float:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player) or not (player is Node3D):
		return 1e9
	var ppos: Vector3 = (player as Node3D).global_position
	var best: float = 1e9
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node3D and is_instance_valid(e):
			if e.has_method("is_alive") and not e.is_alive():
				continue
			best = minf(best, (e as Node3D).global_position.distance_to(ppos))
	return best

func _on_boss_defeated(_boss_id: String) -> void:
	_boss_active = false
	_combat_hold = 0.0
#endregion

var _active_player: AudioStreamPlayer
var _next_player: AudioStreamPlayer
var _pending_fade: bool = false
var _fade_t: float = 0.0
var _fade_duration: float = 2.0
var _current_track: String = ""

func _on_district_theme_changed(district_id: StringName) -> void:
	var theme: Dictionary = DistrictThemes.get_theme(district_id)
	var path: String = theme.get("music", "")
	if path == _current_track: return
	_current_track = path
	if path == "" or not ResourceLoader.exists(path): return
	if _active_player == null:
		_active_player = AudioStreamPlayer.new()
		_active_player.bus = "Music"
		add_child(_active_player)
	_next_player = AudioStreamPlayer.new()
	_next_player.bus = "Music"
	_next_player.stream = load(path)
	_next_player.volume_db = -60.0
	add_child(_next_player)
	_next_player.play()
	_pending_fade = true
	_fade_t = 0.0