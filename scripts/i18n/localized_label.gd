

extends Label

@export 

var loc_key: String = ""

func _ready() -> void:
	if loc_key != "": text = LocalizationManager.t(loc_key)
	_apply_dir()
	LocalizationManager.language_changed.connect(_on_lang)

func _on_lang(_l: String) -> void:
	if loc_key != "": text = LocalizationManager.t(loc_key)
	_apply_dir()

func _apply_dir() -> void:
	if LocalizationManager.is_rtl():
		text_direction = Control.TEXT_DIRECTION_RTL
		horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	else:
		text_direction = Control.TEXT_DIRECTION_AUTO
		horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT