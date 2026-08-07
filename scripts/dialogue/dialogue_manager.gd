
extends Node

class DialogueData:
	var speaker: String
	var text: String
	var choices: Array[Dictionary]

var _dialogues: Dictionary[String, Dictionary] = {}

var _current_id: String = ""

signal dialogue_started(dialogue_id: String)

signal dialogue_ended()

signal dialogue_line(speaker: String, text: String, choices: Array[Dictionary])

func _ready() -> void:
	_load_dialogues()

func _load_dialogues() -> void:
	_dialogues = {
		"intro": {
			"lines": [
				{"speaker": "???", "text": "Ты слышишь меня?", "choices": []},
				{"speaker": "Игрок", "text": "Кто здесь?", "choices": [{"text": "Кто ты?", "next": "intro_2"}, {"text": "Что происходит?", "next": "intro_3"}]},
			]
		},
		"intro_2": {
			"lines": [
				{"speaker": "???", "text": "Меня давно нет. Но я слежу. И я вижу — ты ищешь свет.", "choices": []},
				{"speaker": "???", "text": "Найди распределительный щит. Запусти питание. Это первый шаг.", "choices": [{"text": "Я понял.", "next": "end"}]},
			]
		},
		"intro_3": {
			"lines": [
				{"speaker": "???", "text": "Город мёртв. Но не до конца. Ты можешь вернуть его.", "choices": []},
				{"speaker": "???", "text": "Ищи распределительный щит. Восстанови питание.", "choices": [{"text": "Хорошо.", "next": "end"}]},
			]
		},
		"end": {
			"lines": [
				{"speaker": "???", "text": "Удачи... она тебе понадобится.", "choices": []},
			]
		},
	}

func show_dialogue(dialogue_id: String) -> void:
	if not _dialogues.has(dialogue_id):
		# push_warning("DialogueManager: unknown dialogue: ", dialogue_id)
		return
	_current_id = dialogue_id
	dialogue_started.emit(dialogue_id)
	_show_next_line()

func _show_next_line() -> void:
	var data: Dictionary = _dialogues.get(_current_id, {})
	var lines: Array = data.get("lines", [])
	if lines.is_empty():
		dialogue_ended.emit()
		return
	var line: Dictionary = lines[0]
	dialogue_line.emit(line.get("speaker", ""), line.get("text", ""), line.get("choices", []))

func advance() -> void:
	if _current_id.is_empty():
		return
	
	var data: Dictionary = _dialogues.get(_current_id, {})
	var lines: Array = data.get("lines", [])
	if lines.is_empty():
		dialogue_ended.emit()
		return
	var line: Dictionary = lines[0]
	if not line.get("choices", []).is_empty():
		return
	lines.pop_front()
	_dialogues[_current_id]["lines"] = lines
	_show_next_line()

func make_choice(next_id: String) -> void:
	show_dialogue(next_id)