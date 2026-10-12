extends Node
## Shared UI-sound helper. Prefers the real assets/audio/sfx/ui_*.wav files
## from the art pass; falls back to a procedural beep if a file is missing
## (keeps this autoload usable even on a fresh/partial asset checkout).
##
## Every button gets click(), hover() and press_pulse() from _wire below. error()/save()/achievement() need
## no per-caller wiring at all — they listen on EventBus signals that
## already fire at the right moments project-wide.

const _DIR: String = "res://assets/audio/sfx/"

## Семь CC0-стингеров из пасса ui-audio. Все идут на шину UI одним выстрелом
## (docs/CERT_UIAUDIO.md §4): шина сухая, без компрессора и реверба, поэтому
## короткий стингер не ныряет под музыку и не тянет за собой хвост.
const _UI_DIR: String = "res://assets/audio/ui/"

## Стингеры лежат на диске тише музыкальной подложки, а не громче: RMS
## стингеров -22..-25 dB против -14..-15 dB у бедов, то есть на слух они
## тонули под музыкой при unity gain. Поднимаем на шине UI.
##
## Заявленную в CERT_UIAUDIO цель «на 6-10 dB выше RMS бедов» этим путём не
## взять: для неё нужно +15 dB, а пики файлов лежат на -11 dBFS, так что
## сумма ушла бы в клиппинг. Берём столько, сколько есть до 0 dBFS с запасом:
## стингер выходит примерно вровень с бедом и слышен за счёт транзиента и
## другого спектра. Честно выше бедов можно сделать только перемастерингом
## исходников или дакингом музыки — см. docs/KNOWN_ISSUES.md.
const _UI_GAIN_DB: Dictionary = {
	# пик -6.1 dBFS — этому нужен меньший подъём, иначе клиппинг
	"menu_click": 4.0,
}
const _UI_GAIN_DEFAULT_DB: float = 9.0

func _ready() -> void:
	EventBus.achievement_unlocked.connect(func(_id: String) -> void: achievement())
	EventBus.inventory_notice.connect(func(_msg: String) -> void: error())
	EventBus.purchase_failed.connect(func(_item_id: String, _reason: String) -> void: error())
	EventBus.game_saved.connect(func() -> void: save())
	EventBus.secret_found.connect(func(_id: String) -> void: play_ui("secret_discovery_sting"))
	EventBus.quest_completed.connect(func(_id: String) -> void: play_ui("daily_complete_sting"))
	EventBus.level_completed.connect(func(_id: String) -> void: play_ui("daily_complete_sting"))
	EventBus.boss_spawned.connect(func() -> void: play_ui("boss_sting"))
	EventBus.boss_defeated.connect(func() -> void: play_ui("boss_sting"))
	# Раньше на ui_screen_opened звучал процедурный клик из audio_manager.
	# Его глушит guard "_has_ui_sting", поэтому настоящий клик надо повесить
	# сюда — иначе переходы между экранами стали бы беззвучными.
	EventBus.ui_screen_opened.connect(func(_id: String) -> void: play_ui("menu_click"))
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_wire_late_autoloads")

## UISFX объявлен в project.godot раньше (строка 68), чем EndingsManager (107)
## и DailyChallengeManager (109): на момент нашего _ready() этих синглтонов
## в дереве ещё нет, и прямое обращение дало бы Nil. Поэтому подписки на них
## откладываются на кадр, когда автолоады уже подняты.
func _wire_late_autoloads() -> void:
	var endings := get_node_or_null("/root/EndingsManager")
	if endings != null:
		# Не на game_won: там MusicDirector уже запускает music_victory и
		# cue_victory разом, и стингер под ними не слышно вовсе.
		# ending_reached приходит и на концовках после смерти
		# (dark/survivor), где музыки победы нет и стингер — единственная
		# звуковая точка.
		endings.ending_reached.connect(func(_id: StringName) -> void: play_ui("ending_sting"))
	var daily := get_node_or_null("/root/DailyChallengeManager")
	if daily != null:
		daily.completed.connect(func(_reward: int) -> void: play_ui("daily_complete_sting"))
		daily.streak_milestone.connect(func(_days: int) -> void: play_ui("streak_milestone_sting"))

## Одиночный проигрыш стингера на шине UI. Имя — без префикса "ui_" и без
## расширения: play_ui("boss_sting") -> res://assets/audio/ui/ui_boss_sting.ogg
func play_ui(sound: String) -> void:
	var path := _UI_DIR + "ui_" + sound + ".ogg"
	if not ResourceLoader.exists(path):
		return
	var p := AudioStreamPlayer.new()
	p.bus = &"UI"
	p.volume_db = float(_UI_GAIN_DB.get(sound, _UI_GAIN_DEFAULT_DB))
	p.stream = load(path)
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

## Every button of the UI answers a press (the click and a pulse) and a hover (a tick; the swell is ThemeSetup's), and a tab change clicks (docs/POLISH.md).
## A node is looked at one frame after it enters the tree, when its own screen has wired what it wants: a button that already has the click is left
## alone, and so is every control of the HUD (the touch buttons have their own press).
func _on_node_added(node: Node) -> void:
	if node is BaseButton or node is TabContainer:
		_wire.call_deferred(node)

func _wire(node: Node) -> void:
	if not is_instance_valid(node) or node.has_meta(&"ui_feel") or _in_hud(node):
		return
	node.set_meta(&"ui_feel", true)
	var tabs := node as TabContainer
	if tabs != null:
		tabs.tab_changed.connect(func(_tab: int) -> void: click())
		return
	var button := node as BaseButton
	if button.pressed.is_connected(click):
		return
	button.pressed.connect(click)
	button.pressed.connect(press_pulse.bind(button))
	button.mouse_entered.connect(hover)

func _in_hud(node: Node) -> bool:
	var up: Node = node
	while up != null:
		if up.is_in_group("hud"):
			return true
		up = up.get_parent()
	return false

func click() -> void:
	if ResourceLoader.exists(_UI_DIR + "ui_menu_click.ogg"):
		play_ui("menu_click")
		return
	_play("ui_click", 800.0, 0.05)

func hover() -> void:
	_play("ui_hover", 1000.0, 0.03)

## docs/GAMEFEEL_SPEC.md UI press micro-scale; _wire gives it to every button.
const PRESS_SCALE: float = 0.95
const PRESS_SEC: float = 0.1

func press_pulse(control: Control) -> void:
	if not is_instance_valid(control):
		return
	if bool(SettingsManager.get_setting("reduce_ui_motion", false)):
		return
	control.pivot_offset = control.size / 2.0
	control.scale = Vector2(PRESS_SCALE, PRESS_SCALE)
	var tw := create_tween()
	tw.tween_property(control, "scale", Vector2.ONE, PRESS_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func error() -> void:
	_play("ui_error", 260.0, 0.12)

func save() -> void:
	_play("ui_save", 950.0, 0.08)

func achievement() -> void:
	if ResourceLoader.exists(_UI_DIR + "ui_achievement_sting.ogg"):
		play_ui("achievement_sting")
		return
	_play("ui_achievement", 1400.0, 0.15)

func pickup() -> void:
	_beep(1200.0, 0.09)

func _play(file: String, fallback_freq: float, fallback_dur: float) -> void:
	var path := _DIR + file + ".wav"
	if ResourceLoader.exists(path):
		var p := AudioStreamPlayer.new()
		p.bus = &"UI"
		p.stream = load(path)
		add_child(p)
		p.play()
		p.finished.connect(p.queue_free)
	else:
		_beep(fallback_freq, fallback_dur)

func _beep(freq: float, dur: float) -> void:
	var sr := 22050
	var n := int(sr * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / sr
		var env := 1.0 - t / dur
		var v := int(sin(t * freq * TAU) * env * 12000.0)
		data.encode_s16(i * 2, v)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sr
	stream.data = data
	var p := AudioStreamPlayer.new()
	p.bus = &"UI"
	p.stream = stream
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
