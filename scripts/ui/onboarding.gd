extends CanvasLayer
const CFG_PATH := "user://onboarding.cfg"
var _queue: Array[Dictionary] = []
var _shown: Dictionary = {}
var _active: bool = false

func _ready() -> void:
	layer = 35
	_load_shown()
	var sm := get_node("/root/SettingsManager")
	if sm and sm.to_dict().get("hints", true) == false:
		_active = false
		return
	_active = true
	EventBus.player_state_changed.connect(func(_s: int): _show("wasd"))
	EventBus.flashlight_state_changed.connect(func(_on: bool): _show("flashlight"))
	EventBus.monster_spotted.connect(func(_id): _show("shadow"))
	EventBus.player_interact_available.connect(func(_a: bool): _show("interact"))
	EventBus.inventory_toggle_requested.connect(func(): _show("inventory"))

func _show(id: String) -> void:
	if not _active:
		return
	if _shown.get(id, false):
		return
	_shown[id] = true
	_save_shown()
	var texts := {
		"wasd": "WASD / джойстик — движение",
		"flashlight": "F — фонарик. Свет садит батарею, но отпугивает тени",
		"shadow": "Тени боятся света. Держи луч на них — или прячься",
		"interact": "E — взаимодействовать с объектами",
		"inventory": "Tab — инвентарь. Следи за весом",
	}
	var msg: String = texts.get(id, "")
	if msg.is_empty():
		return
	var toast := Label.new()
	toast.text = msg
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.size = Vector2(400, 36)
	var vp := get_viewport().get_visible_rect().size
	toast.position = Vector2(vp.x / 2.0 - 200, vp.y - 160)
	toast.add_theme_color_override("font_color", Color(0.847, 0.824, 0.769))
	toast.add_theme_font_size_override("font_size", 14)
	toast.modulate = Color(1, 1, 1, 0)
	add_child(toast)
	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.3)
	tween.tween_interval(4.0)
	tween.tween_property(toast, "modulate:a", 0.0, 0.3)
	tween.tween_callback(toast.queue_free)

func _load_shown() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) == OK:
		for k in cfg.get_value("onboarding", "shown", {}):
			_shown[k] = true

func _save_shown() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("onboarding", "shown", _shown)
	cfg.save(CFG_PATH)
