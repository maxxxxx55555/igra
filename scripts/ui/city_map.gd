extends Control

const CANON := ["suburbs","residential","park","school","hospital","gas_station","police","warehouses","industrial","substation","power_station"]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.07, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var t := Label.new()
	t.text = "CITY POWER MAP"
	t.position = Vector2(20, 10)
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
	add_child(t)
	var b := Button.new()
	b.text = "Close (K)"
	b.position = Vector2(20, 520)
	b.pressed.connect(_close)
	add_child(b)

func _close() -> void:
	visible = false

func _draw() -> void:
	var pg := get_node_or_null("/root/PowerGrid")
	var i := 0
	for id in CANON:
		var col := i % 4
		var row := i / 4
		var pos := Vector2(140.0 + float(col) * 180.0, 120.0 + float(row) * 130.0)
		var on := false
		if pg != null and pg.has_method("is_powered"):
			on = pg.is_powered(StringName(id))
		var c := Color(0.3, 1.0, 0.5) if on else Color(0.35, 0.35, 0.4)
		draw_circle(pos, 14.0, c)
		draw_string(ThemeDB.fallback_font, pos + Vector2(-50, 32), id, HORIZONTAL_ALIGNMENT_LEFT, 140, 12, Color.WHITE)
		i += 1