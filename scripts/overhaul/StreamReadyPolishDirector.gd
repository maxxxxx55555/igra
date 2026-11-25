extends CanvasLayer

const FADE := Color("#060f13")
const BRASS := Color("#c9a24a")
var _curtain := ColorRect.new()
var _card := Label.new()
var _tween: Tween
var _charge := 1.0
var _lamp: Node3D
var _height := 0.0

func _ready() -> void:
	layer = 16
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.color = FADE
	_curtain.modulate.a = 0.0
	_curtain.hide()
	add_child(_curtain)
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#0f1314")
	panel.border_color = BRASS
	panel.border_width_bottom = 2
	panel.content_margin_left = 22
	panel.content_margin_right = 22
	panel.content_margin_top = 9
	panel.content_margin_bottom = 9
	var plaque := PanelContainer.new()
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plaque.add_theme_stylebox_override("panel",panel)
	center.add_child(plaque)
	_card.add_theme_color_override("font_color",BRASS)
	_card.add_theme_font_size_override("font_size", 30)
	plaque.add_child(_card)
	EventBus.player_battery_changed.connect(_on_charge)

func transition(index: int, enter: Callable) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_card.text = "DISTRICT_NAME_%02d" % (index + 1)
	_curtain.show()
	_curtain.modulate.a = 0.0
	var fade_time := 0.0 if SettingsManager.get_setting("reduce_ui_motion", false) else 0.18
	_tween = create_tween()
	_tween.tween_property(_curtain,"modulate:a",1.0,fade_time)
	_tween.tween_callback(enter)
	_tween.tween_interval(0.55)
	_tween.tween_property(_curtain,"modulate:a",0.0,fade_time)
	_tween.tween_callback(_curtain.hide)

func _on_charge(value: float) -> void:
	_charge = clampf(value,0.0,1.0)

func _process(delta: float) -> void:
	if not is_instance_valid(_lamp):
		var player := GameManager.player as Node3D
		if not is_instance_valid(player):
			return
		_lamp = player.get_node_or_null("ModelPivot/FlashlightPivot") as Node3D
		if _lamp == null:
			return
		_height = _lamp.position.y
	var sag := 0.0 if SettingsManager.get_setting("reduce_camera_motion",false) else 0.065 * (1.0 - smoothstep(0.0,0.20,_charge))
	_lamp.position.y = move_toward(_lamp.position.y,_height-sag,delta*0.12)

func _exit_tree() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
	if is_instance_valid(_lamp):
		_lamp.position.y = _height
