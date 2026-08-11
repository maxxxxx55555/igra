extends Control

@export var enable_radio: bool = true

const PANEL := Color("#141b24")
const PANEL_EDGE := Color("#2a3340")
const BRASS := Color("#c9a24a")
const BRASS_DIM := Color("#8a7338")
const EMBER := Color("#b4452f")
const STEEL_TEXT := Color("#aeb6bf")
const BONE_TEXT := Color("#d8d2c4")
const STAMINA := Color("#5f8a4e")

const CHANNELS := [
	{"key": "RADIO_EMERGENCY1", "name_tr": "RADIO_EMERGENCY1", "transcript_tr": "RADIO_TRANSCRIPT_E1", "duration": 90.0, "coords": null},
	{"key": "RADIO_EMERGENCY2", "name_tr": "RADIO_EMERGENCY2", "transcript_tr": "RADIO_TRANSCRIPT_E2", "duration": 103.0, "coords": Vector2(137, 89)},
	{"key": "RADIO_MILITARY", "name_tr": "RADIO_MILITARY", "transcript_tr": "RADIO_TRANSCRIPT_MIL", "duration": 75.0, "coords": null},
	{"key": "RADIO_UNKNOWN", "name_tr": "RADIO_UNKNOWN", "transcript_tr": "RADIO_TRANSCRIPT_UNK", "duration": 120.0, "coords": null},
	{"key": "RADIO_DISTRESS", "name_tr": "RADIO_DISTRESS", "transcript_tr": "RADIO_TRANSCRIPT_SOS", "duration": 65.0, "coords": Vector2(203, 56)},
]

var _selected_idx: int = -1
var _is_playing: bool = false
var _play_time: float = 0.0
var _duration: float = 0.0
var _channel_wave_bars: Array = []
var _player_wave_bars: Array = []

@onready var _channel_list: VBoxContainer
@onready var _player_panel: ColorRect
@onready var _channel_name: Label
@onready var _time_label: Label
@onready var _transcript_label: Label
@onready var _coords_label: Label

func _ready() -> void:
	if not enable_radio: return
	_build_ui()

func _build_ui() -> void:
	_channel_list = VBoxContainer.new()
	_channel_list.size = Vector2(size.x * 0.4, size.y - 10)
	_channel_list.position = Vector2(0, 0)
	add_child(_channel_list)

	for i in CHANNELS.size():
		var ch = CHANNELS[i]
		var row = ColorRect.new()
		row.color = Color(0, 0, 0, 0)
		row.size = Vector2(_channel_list.size.x, 36)
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		_channel_list.add_child(row)

		var lbl := Label.new()
		lbl.text = tr(ch.name_tr)
		lbl.size = Vector2(row.size.x - 50, 28)
		lbl.position = Vector2(5, 4)
		lbl.add_theme_color_override("font_color", STEEL_TEXT)
		lbl.add_theme_font_size_override("font_size", 10)
		row.add_child(lbl)

		var wave := ColorRect.new()
		wave.color = BRASS_DIM
		wave.size = Vector2(30, 8)
		wave.position = Vector2(row.size.x - 36, 14)
		row.add_child(wave)
		_channel_wave_bars.append(wave)

		var click_area := ColorRect.new()
		click_area.color = Color(0, 0, 0, 0)
		click_area.size = row.size
		click_area.mouse_filter = Control.MOUSE_FILTER_STOP
		row.add_child(click_area)
		var idx := i
		click_area.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_select_channel(idx)
		)

	var px := size.x * 0.42
	_player_panel = ColorRect.new()
	_player_panel.color = PANEL
	_player_panel.size = Vector2(size.x * 0.55, size.y - 10)
	_player_panel.position = Vector2(px, 0)
	add_child(_player_panel)

	_channel_name = Label.new()
	_channel_name.text = ""
	_channel_name.size = Vector2(_player_panel.size.x - 20, 22)
	_channel_name.position = Vector2(10, 6)
	_channel_name.add_theme_color_override("font_color", BONE_TEXT)
	_channel_name.add_theme_font_size_override("font_size", 14)
	_player_panel.add_child(_channel_name)

	var waveform_bg := ColorRect.new()
	waveform_bg.color = PANEL_EDGE
	waveform_bg.size = Vector2(_player_panel.size.x - 20, 60)
	waveform_bg.position = Vector2(10, 34)
	_player_panel.add_child(waveform_bg)
	var total_bars := 14
	var bar_gap := 3
	var bar_w := (waveform_bg.size.x - (total_bars - 1) * bar_gap) / total_bars
	for wi in total_bars:
		var bar := ColorRect.new()
		bar.color = BRASS
		var bh := 8.0 + (wi * 7 + 5) % 40
		bar.size = Vector2(bar_w, bh)
		bar.position = Vector2(wi * (bar_w + bar_gap), waveform_bg.size.y - bh)
		waveform_bg.add_child(bar)
		_player_wave_bars.append(bar)

	_time_label = Label.new()
	_time_label.text = "00:00 / 00:00"
	_time_label.size = Vector2(140, 18)
	_time_label.position = Vector2(10, 100)
	_time_label.add_theme_color_override("font_color", BRASS)
	_time_label.add_theme_font_size_override("font_size", 11)
	_player_panel.add_child(_time_label)

	_transcript_label = Label.new()
	_transcript_label.text = ""
	_transcript_label.size = Vector2(_player_panel.size.x - 20, 50)
	_transcript_label.position = Vector2(10, 124)
	_transcript_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_transcript_label.add_theme_color_override("font_color", STEEL_TEXT)
	_transcript_label.add_theme_font_size_override("font_size", 10)
	_player_panel.add_child(_transcript_label)

	_coords_label = Label.new()
	_coords_label.text = ""
	_coords_label.size = Vector2(_player_panel.size.x - 20, 18)
	_coords_label.position = Vector2(10, 178)
	_coords_label.add_theme_color_override("font_color", BRASS_DIM)
	_coords_label.add_theme_font_size_override("font_size", 10)
	_player_panel.add_child(_coords_label)

	var stop_btn := Button.new()
	stop_btn.text = tr("RADIO_STOP")
	stop_btn.size = Vector2(100, 28)
	stop_btn.position = Vector2(10, _player_panel.size.y - 34)
	_player_panel.add_child(stop_btn)
	stop_btn.pressed.connect(_stop_playback)

	var remove_btn := Button.new()
	remove_btn.text = tr("RADIO_REMOVE")
	remove_btn.size = Vector2(100, 28)
	remove_btn.position = Vector2(_player_panel.size.x - 110, _player_panel.size.y - 34)
	_player_panel.add_child(remove_btn)
	remove_btn.pressed.connect(_remove_channel)

func _select_channel(idx: int) -> void:
	if idx < 0 or idx >= CHANNELS.size(): return
	_selected_idx = idx
	var ch = CHANNELS[idx]
	_channel_name.text = tr(ch.name_tr)
	_duration = ch.duration
	_play_time = 0.0
	_is_playing = true
	_time_label.text = "00:00 / " + _format_time(_duration)
	_transcript_label.text = tr(ch.transcript_tr)
	if ch.coords != null:
		_coords_label.text = tr("RADIO_COORDINATES") + " X:" + str(ch.coords.x) + " Y:" + str(ch.coords.y)
		EventBus.radar_marker_added.emit(ch.coords)
	else:
		_coords_label.text = ""

func _stop_playback() -> void:
	_is_playing = false
	_play_time = 0.0
	_time_label.text = "00:00 / " + _format_time(_duration)

func _remove_channel() -> void:
	if _selected_idx < 0 or _selected_idx >= CHANNELS.size(): return
	_is_playing = false
	_play_time = 0.0
	_selected_idx = -1
	_channel_name.text = ""
	_time_label.text = "00:00 / 00:00"
	_transcript_label.text = ""
	_coords_label.text = ""

func _process(delta: float) -> void:
	for i in _channel_wave_bars.size():
		var h := 4.0 + absf(sin(Time.get_ticks_msec() * 0.003 * (i + 1))) * 16.0
		_channel_wave_bars[i].size.y = h
		_channel_wave_bars[i].position.y = 14 - (h - 8) * 0.5

	for i in _player_wave_bars.size():
		var h := 6.0 + absf(sin(Time.get_ticks_msec() * 0.005 * (i + 1))) * 28.0
		_player_wave_bars[i].size.y = h
		_player_wave_bars[i].position.y = 60 - h

	if _is_playing and _selected_idx >= 0:
		_play_time += delta
		var ch = CHANNELS[_selected_idx]
		if _play_time >= ch.duration:
			_play_time = ch.duration
			_is_playing = false
		_time_label.text = _format_time(_play_time) + " / " + _format_time(ch.duration)

func _format_time(t: float) -> String:
	var m := int(t) / 60
	var s = int(t) % 60
	return "%02d:%02d" % [m, s]
