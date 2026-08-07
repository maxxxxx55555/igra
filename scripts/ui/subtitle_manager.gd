

extends CanvasLayer

var subtitle_label: Label
var speaker_label: Label

var _queue: Array[Dictionary] = []
var _showing: bool = false

func _ready() -> void:
	layer = 60
	speaker_label = Label.new()
	speaker_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	speaker_label.position.y = 500
	add_child(speaker_label)
	subtitle_label = Label.new()
	subtitle_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle_label.position.y = 540
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle_label)

func show_subtitle(text: String, speaker: String = "", duration: float = 3.0) -> void:
	_queue.append({"text": text, "speaker": speaker, "duration": duration})
	if not _showing:
		_process_queue()

func _process_queue() -> void:
	if _queue.is_empty():
		_showing = false
		subtitle_label.text = ""
		speaker_label.text = ""
		return
	_showing = true
	var entry = _queue.pop_front()
	speaker_label.text = entry.speaker + ":" if entry.speaker else ""
	subtitle_label.text = entry.text
	await get_tree().create_timer(entry.duration).timeout
	_process_queue()

func show_random_ambient() -> void:
	var phrases = [
		"Chto-to dvizhetsja v temnote...",
		"Slyshish? Eto zvuk shagov.",
		"Veter... ili vzdoh?",
		"Zdes kto-to byl nedavno.",
		"Ne vyklyuchaj fonarik."
	]
	show_subtitle(phrases[randi() % phrases.size()], "", 4.0)