class_name MusicDirector
extends Node

## Адаптивная музыка: два плеера с кроссфейдом плюс слой напряжения.
## Настроения: MENU -> AMBIENT -> TENSION -> BATTLE -> BOSS -> VICTORY,
## выбираются по дистанции до ближайшего врага и по событиям боя.
##
## Поверх настроений работают 5 слоёв из GDD §25.2 (Ambient_Dark/Ambient_Lit/
## Threat_Low/Threat_High/Action_Sting): они лежали в assets/audio/music
## готовыми .ogg, но в коде не было ни одной ссылки на них — их громкость
## теперь ведётся от стадии электросети и близости монстров.

#region Signals
signal track_changed(state: int)
#endregion

#region Enums
enum Mood { MENU, AMBIENT, TENSION, BATTLE, BOSS, VICTORY }
#endregion

#region Constants
const TRACKS: Dictionary = {
	Mood.MENU: "res://assets/audio/music/abandoned_hallways.mp3",
	Mood.AMBIENT: "res://assets/audio/music/music_ambient.wav",
	Mood.TENSION: "res://assets/audio/music/music_tension.wav",
	Mood.BATTLE: "res://assets/audio/music/music_battle.wav",
	Mood.BOSS: "res://assets/audio/music/music_boss_dark.wav",
	Mood.VICTORY: "res://assets/audio/music/music_victory.wav",
}
## Эмбиент по районам: у каждого своя атмосферная подложка.
const AMBIENT_BY_DISTRICT: Dictionary = {
	&"suburbs": "res://assets/audio/music/music_ambient.wav",
	&"residential": "res://assets/audio/music/residential.wav",
	&"park": "res://assets/audio/music/park.wav",
	&"school": "res://assets/audio/music/abandoned_hallways_alt.mp3",
	&"hospital": "res://assets/audio/music/abandoned_hallways_alt.mp3",
	&"gas_station": "res://assets/audio/music/downtown.wav",
	&"police": "res://assets/audio/music/downtown.wav",
	&"warehouses": "res://assets/audio/music/harbor.wav",
	&"industrial": "res://assets/audio/music/industrial.wav",
	&"substation": "res://assets/audio/music/music_ambient_dark.wav",
	&"power_station": "res://assets/audio/music/music_ambient_dark.wav",
}

## Слои GDD §25.2. Ambient_Dark/Lit ведутся стадией электросети,
## Threat_Low/High — близостью монстров, Action_Sting бьёт разово.
const LAYERS: Dictionary = {
	"ambient_dark": "res://assets/audio/music/Ambient_Dark.ogg",
	"ambient_lit": "res://assets/audio/music/Ambient_Lit.ogg",
	"threat_low": "res://assets/audio/music/Threat_Low.ogg",
	"threat_high": "res://assets/audio/music/Threat_High.ogg",
}
const STING_PATH: String = "res://assets/audio/music/Action_Sting.ogg"
const LAYER_DB: float = -12.0
const LAYER_LERP: float = 1.5
const FADE_TIME: float = 2.2          ## Длительность кроссфейда, с
const FULL_DB: float = -8.0           ## Рабочая громкость трека
const MUTE_DB: float = -60.0
const EVAL_INTERVAL: float = 0.5      ## Как часто пересчитываем настроение, с
const TENSION_RANGE: float = 22.0     ## Дистанция появления напряжения, м
const BATTLE_RANGE: float = 9.0       ## Дистанция перехода в бой, м
const CALM_DELAY: float = 6.0         ## Задержка возврата в спокойствие, с
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
var _layers: Dictionary = {}          ## имя слоя -> AudioStreamPlayer
var _layer_target: Dictionary = {}    ## имя слоя -> целевая громкость 0..1
var _sting: AudioStreamPlayer = null
#endregion

#region Virtual Methods
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_a = _make_player("MusicA")
	_b = _make_player("MusicB")
	_active = _a
	_build_layers()
	EventBus.game_started.connect(func() -> void: set_mood(Mood.AMBIENT))
	EventBus.game_won.connect(func() -> void: set_mood(Mood.VICTORY))
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.player_detected.connect(func(_id: StringName) -> void:
		_combat_hold = CALM_DELAY
		play_sting())
	EventBus.enemy_attack.connect(func(_d: int) -> void: _combat_hold = CALM_DELAY)
	EventBus.district_entered.connect(_on_district_entered)
	set_mood(Mood.MENU, true)

func _process(delta: float) -> void:
	_combat_hold = maxf(0.0, _combat_hold - delta)
	_tick_layers(delta)
	_eval_timer -= delta
	if _eval_timer > 0.0:
		return
	_eval_timer = EVAL_INTERVAL
	_evaluate()
#endregion

#region Public Methods
## Переключить настроение. instant=true — без кроссфейда (старт игры).
## force=true — перезапустить даже то же настроение (смена района).
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

## Включить босс-тему и удерживать её.
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

## Зацикливание фоновой музыки. Настройки .import не в репозитории, поэтому
## включаем цикл в коде — иначе на свежем клоне трек проиграет один раз и стихнет.
static func _force_loop(s: AudioStream) -> void:
	if s is AudioStreamWAV:
		(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif s is AudioStreamOggVorbis or s is AudioStreamMP3:
		s.set("loop", true)

func _load(m: Mood) -> AudioStream:
	var path: String = _ambient_path if m == Mood.AMBIENT else TRACKS.get(m, "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	if _cache.has(path):
		return _cache[path]
	var s := load(path) as AudioStream
	_force_loop(s)
	_cache[path] = s
	return s

## Смена района: подменяем эмбиент-слой и перезапускаем, если он играет.
func _on_district_entered(district_id: StringName) -> void:
	var path: String = AMBIENT_BY_DISTRICT.get(district_id, "")
	if path == "" or path == _ambient_path:
		return
	_ambient_path = path
	if mood == Mood.AMBIENT:
		set_mood(Mood.AMBIENT, false, true)

## Выбор настроения по обстановке: босс > бой > тревога > спокойствие.
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

func _on_boss_defeated() -> void:
	_boss_active = false
	_combat_hold = 0.0
#endregion

## ── Слои GDD §25.2 ──────────────────────────────────────────────────────────

func _build_layers() -> void:
	for key in LAYERS:
		var path: String = LAYERS[key]
		if not ResourceLoader.exists(path):
			continue
		var pl := AudioStreamPlayer.new()
		pl.name = "Layer_" + String(key)
		pl.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
		var s := load(path) as AudioStream
		_force_loop(s)
		pl.stream = s
		pl.volume_db = MUTE_DB
		add_child(pl)
		pl.play()
		_layers[key] = pl
		_layer_target[key] = 0.0
	if ResourceLoader.exists(STING_PATH):
		_sting = AudioStreamPlayer.new()
		_sting.name = "ActionSting"
		_sting.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
		_sting.stream = load(STING_PATH) as AudioStream
		_sting.volume_db = LAYER_DB
		add_child(_sting)

## Разовый акцент при обнаружении игрока.
func play_sting() -> void:
	if _sting != null and not _sting.playing:
		_sting.play()

func _tick_layers(delta: float) -> void:
	if _layers.is_empty():
		return
	_update_layer_targets()
	var w: float = clampf(delta * LAYER_LERP, 0.0, 1.0)
	for key in _layers:
		var pl: AudioStreamPlayer = _layers[key]
		var want: float = _layer_target.get(key, 0.0)
		var want_db: float = LAYER_DB if want > 0.01 else MUTE_DB
		pl.volume_db = lerpf(pl.volume_db, want_db, w)

## Тёмный слой — когда район обесточен, светлый — когда свет вернулся;
## слои угрозы поднимаются по мере приближения монстров.
func _update_layer_targets() -> void:
	if not GameManager.is_playing():
		for key in _layer_target:
			_layer_target[key] = 0.0
		return
	var stage: int = 0
	var dm := get_node_or_null("/root/DistrictManager")
	if dm != null:
		stage = PowerGrid.get_stage(StringName(dm.current_district))
	_layer_target["ambient_dark"] = 1.0 if stage <= 1 else 0.0
	_layer_target["ambient_lit"] = 1.0 if stage >= 2 else 0.0
	var d: float = _nearest_enemy_distance()
	_layer_target["threat_high"] = 1.0 if (d <= BATTLE_RANGE or _combat_hold > 0.0) else 0.0
	_layer_target["threat_low"] = 1.0 if (d <= TENSION_RANGE and d > BATTLE_RANGE) else 0.0
