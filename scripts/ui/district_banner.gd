extends Control

var _label: Label
var _t: float = 0.0
var _show: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	position = Vector2(-220, 110)
	size = Vector2(440, 48)
	_label = Label.new()
	_label.position = Vector2(14, 10)
	_label.size = Vector2(420, 36)
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color("#c9a24a"))  # brass
	add_child(_label)
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("district_entered"):
		bus.district_entered.connect(_on_district)
	visible = false

func _on_district(id: StringName) -> void:
	if _label != null:
		_label.text = String(id).to_upper()
	_t = 0.0
	_show = true
	visible = true

func _process(delta: float) -> void:
	if not _show:
		return
	_t += delta
	if _t > 3.5:
		_show = false
		visible = false