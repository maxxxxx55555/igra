extends Control

@onready var _vbox: VBoxContainer = get_node_or_null("VBox")

var _layout: Dictionary = {
	"button_size": 56, "opacity": 80,
	"joystick_x": 15, "joystick_y": 75,
	"cluster_x": 85, "cluster_y": 75,
}


func _ready() -> void:
	visible = false
	_build()



func _build() -> void:
	if _vbox == null:
		return
	for c in _vbox.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = "TOUCH CONTROL SETTINGS"
	title.add_theme_color_override("font_color", Color("#d8d2c4"))
	title.add_theme_font_size_override("font_size", 28)
	_vbox.add_child(title)
	_add_slider("Button size", _layout.button_size, 40, 80, "button_size")
	_add_slider("Opacity %", _layout.opacity, 30, 100, "opacity")
	var tip := Label.new()
	tip.text = "Adjust layout to fit your hand."
	tip.add_theme_color_override("font_color", Color("#aeb6bf"))
	_vbox.add_child(tip)


func _add_slider(label: String, val: float, mn: float, mx: float, key: String) -> void:
	var hbox := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.add_theme_color_override("font_color", Color("#aeb6bf"))
	hbox.add_child(l)
	var sl := HSlider.new()
	sl.min_value = mn
	sl.max_value = mx
	sl.value = val
	sl.value_changed.connect(func(v: float): _layout[key] = v)
	hbox.add_child(sl)
	_vbox.add_child(hbox)


func show_screen() -> void:
	visible = true
	_build()

