

extends Button

@export 

var loc_key: String = ""

func _ready() -> void:
	if loc_key != "":
		text = LocalizationManager.t(loc_key)
	LocalizationManager.language_changed.connect(_on_lang)
	# hover mikroanimacija
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	focus_entered.connect(_on_enter)
	focus_exited.connect(_on_exit)

func _on_lang(_l: String) -> void:
	if loc_key != "":
		text = LocalizationManager.t(loc_key)

func _on_enter() -> void:
	

	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1.2, 1.1, 0.8), 0.12)
	tw.parallel().tween_property(self, "scale", Vector2(1.04, 1.04), 0.12)

func _on_exit() -> void:
	

	var tw = create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.12)
	tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.12)